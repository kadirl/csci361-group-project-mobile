import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/chat_provider.dart';
import '../../../core/providers/company_profile_provider.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../../../core/utils/s3_upload_utils.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/chat.dart';
import '../../../data/models/complaint.dart';
import '../../../data/models/linking.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../../data/repositories/uploads_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../supplier/views/catalog/product/product_image_gallery_view.dart';

/// Reusable chat view widget for linking or order chats.
/// 
/// [linkingId] - The linking ID for linking chats (null for order chats).
/// [orderId] - The order ID for order chats (null for linking chats).
/// [linking] - The linking object (required for linking chats and order chats to check permissions).
/// [order] - The order object (required for order chats to check permissions).
/// [canSendMessages] - Whether the current user can send messages (optional override).
class ChatView extends ConsumerStatefulWidget {
  const ChatView({
    super.key,
    this.linkingId,
    this.orderId,
    this.linking,
    this.order,
    this.canSendMessages,
  }) : assert(
          (linkingId != null && linking != null) || (orderId != null && order != null && linking != null),
          'Either linkingId with linking or orderId with order and linking must be provided',
        );

  final int? linkingId;
  final int? orderId;
  final Linking? linking;
  final Order? order;
  final bool? canSendMessages;

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<int, AppUser> _senderCache = {};
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoadingSenders = false;
  bool _hasText = false;
  
  // Image upload state
  Uint8List? _pendingImageBytes;
  String? _pendingImageUrl;
  bool _isUploadingImage = false;
  String? _pendingImageFilename;
  
  // Cached complaint for permission checks
  Complaint? _cachedComplaint;

  @override
  void initState() {
    super.initState();
    _connectChat();
    _loadComplaintIfNeeded();
    
    // Listen to text changes to update send button state.
    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (_hasText != hasText) {
        setState(() {
          _hasText = hasText;
        });
      }
    });
  }

  // Load complaint for order chats to check manager permissions
  Future<void> _loadComplaintIfNeeded() async {
    if (widget.orderId != null) {
      try {
        final complaintRepo = ref.read(complaintRepositoryProvider);
        final complaint = await complaintRepo.getComplaintByOrderId(
          orderId: widget.orderId!,
        );
        if (mounted) {
          setState(() {
            _cachedComplaint = complaint;
          });
        }
      } catch (e) {
        // No complaint exists or error - that's fine
        log('ChatView -> No complaint found for order ${widget.orderId}: $e');
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Connect to chat based on type.
  Future<void> _connectChat() async {
    if (widget.linkingId != null) {
      await ref.read(linkingChatProvider.notifier).connectLinkingChat(
            linkingId: widget.linkingId!,
          );
    } else if (widget.orderId != null) {
      await ref.read(orderChatProvider.notifier).connectOrderChat(
            orderId: widget.orderId!,
          );
    }
  }

  // Check if current user can send messages.
  bool _canSendMessages() {
    log('ChatView -> ========== PERMISSION CHECK START ==========');
    
    // Use override if provided.
    if (widget.canSendMessages != null) {
      log('ChatView -> Using override: canSendMessages=${widget.canSendMessages}');
      return widget.canSendMessages!;
    }

    // For linking chats, check permissions based on company side.
    if (widget.linking == null) {
      log('ChatView -> ERROR: widget.linking is NULL - cannot check permissions');
      return false;
    }

    log('ChatView -> Linking ID: ${widget.linking!.linkingId}');
    log('ChatView -> Linking consumerCompanyId: ${widget.linking!.consumerCompanyId}');
    log('ChatView -> Linking supplierCompanyId: ${widget.linking!.supplierCompanyId}');
    log('ChatView -> Linking requestedByUserId: ${widget.linking!.requestedByUserId}');
    log('ChatView -> Linking assignedSalesmanUserId: ${widget.linking!.assignedSalesmanUserId}');

    final userState = ref.watch(userProfileProvider);
    final companyState = ref.watch(companyProfileProvider);
    
    log('ChatView -> User state: isLoading=${userState.isLoading}, hasError=${userState.hasError}, hasValue=${userState.hasValue}');
    log('ChatView -> Company state: isLoading=${companyState.isLoading}, hasError=${companyState.hasError}, hasValue=${companyState.hasValue}');
    
    // Wait for user profile and company profile to load.
    if (userState.isLoading || companyState.isLoading) {
      log('ChatView -> BLOCKED: Still loading user or company profile');
      return false; // Still loading, wait
    }

    if (userState.hasError || companyState.hasError) {
      log('ChatView -> BLOCKED: Error loading profiles - userError=${userState.hasError}, companyError=${companyState.hasError}');
      if (userState.hasError) {
        log('ChatView -> User error: ${userState.error}');
      }
      if (companyState.hasError) {
        log('ChatView -> Company error: ${companyState.error}');
      }
      return false; // Error loading profile
    }

    final currentUser = userState.value;
    final currentCompany = companyState.value;
    
    log('ChatView -> Current user: ${currentUser?.id} (firstName: ${currentUser?.firstName}, lastName: ${currentUser?.lastName})');
    log('ChatView -> Current company: ${currentCompany?.id} (name: ${currentCompany?.name}, type: ${currentCompany?.companyType})');
    
    if (currentUser == null) {
      log('ChatView -> BLOCKED: currentUser is NULL');
      return false; // Missing user info
    }
    
    if (currentUser.id == null) {
      log('ChatView -> BLOCKED: currentUser.id is NULL');
      return false; // Missing user ID
    }
    
    if (currentCompany == null) {
      log('ChatView -> BLOCKED: currentCompany is NULL');
      return false; // Missing company info
    }
    
    if (currentCompany.id == null) {
      log('ChatView -> BLOCKED: currentCompany.id is NULL');
      return false; // Missing company ID
    }

    // Check which side of the linking the user is on.
    final bool isConsumerSide = currentCompany.id == widget.linking!.consumerCompanyId;
    final bool isSupplierSide = currentCompany.id == widget.linking!.supplierCompanyId;

    log('ChatView -> Side check: isConsumerSide=$isConsumerSide, isSupplierSide=$isSupplierSide');
    log('ChatView -> Company ID comparison: currentCompany.id=${currentCompany.id} == consumerCompanyId=${widget.linking!.consumerCompanyId} ? $isConsumerSide');
    log('ChatView -> Company ID comparison: currentCompany.id=${currentCompany.id} == supplierCompanyId=${widget.linking!.supplierCompanyId} ? $isSupplierSide');

    // Check if this is an order chat or linking chat
    final bool isOrderChat = widget.orderId != null && widget.order != null;

    if (isConsumerSide) {
      log('ChatView -> Detected as CONSUMER SIDE');
      
      if (isOrderChat) {
        // Order chat: Consumer side - Only the consumer staff who created the order can send messages.
        log('ChatView -> Order chat - Consumer side');
        log('ChatView -> Order consumerStaffId: ${widget.order!.consumerStaffId}');
        
        final canSend = currentUser.id == widget.order!.consumerStaffId;
        log('ChatView -> Order chat consumer permission check:');
        log('ChatView ->   currentUser.id=${currentUser.id} (type: ${currentUser.id.runtimeType})');
        log('ChatView ->   order.consumerStaffId=${widget.order!.consumerStaffId} (type: ${widget.order!.consumerStaffId.runtimeType})');
        log('ChatView ->   IDs match? ${currentUser.id == widget.order!.consumerStaffId}');
        log('ChatView ->   RESULT: canSend=$canSend');
        
        if (!canSend) {
          log('ChatView -> BLOCKED: Order chat consumer side - User ID (${currentUser.id}) does NOT match consumerStaffId (${widget.order!.consumerStaffId})');
        }
        
        log('ChatView -> ========== PERMISSION CHECK END ==========');
        return canSend;
      } else {
        // Linking chat: Consumer side - Only the consumer contact person (requester) can send messages.
        log('ChatView -> Linking chat - Consumer side');
        if (widget.linking!.requestedByUserId == 0) {
          log('ChatView -> BLOCKED: Consumer side - requestedByUserId is 0 (no requester found)');
          return false;
        }
        
        final canSend = currentUser.id == widget.linking!.requestedByUserId;
        log('ChatView -> Consumer permission check:');
        log('ChatView ->   currentUser.id=${currentUser.id} (type: ${currentUser.id.runtimeType})');
        log('ChatView ->   requestedByUserId=${widget.linking!.requestedByUserId} (type: ${widget.linking!.requestedByUserId.runtimeType})');
        log('ChatView ->   IDs match? ${currentUser.id == widget.linking!.requestedByUserId}');
        log('ChatView ->   RESULT: canSend=$canSend');
        
        if (!canSend) {
          log('ChatView -> BLOCKED: Consumer side - User ID (${currentUser.id}) does NOT match requestedByUserId (${widget.linking!.requestedByUserId})');
        }
        
        log('ChatView -> ========== PERMISSION CHECK END ==========');
        return canSend;
      }
    } else if (isSupplierSide) {
      log('ChatView -> Detected as SUPPLIER SIDE');
      
      // For order chats, check if user is assigned manager for the complaint
      if (isOrderChat) {
        log('ChatView -> Order chat - Supplier side');
        
        // Check if assigned salesman can send
        if (widget.linking!.assignedSalesmanUserId != null &&
            currentUser.id == widget.linking!.assignedSalesmanUserId) {
          log('ChatView -> Allowed: User is assigned salesman');
          log('ChatView -> ========== PERMISSION CHECK END ==========');
          return true;
        }
        
        // Check if user is assigned manager for the complaint (using cached complaint)
        if (_cachedComplaint != null && _cachedComplaint!.assignedManagerId != null) {
          final isAssignedManager = currentUser.id == _cachedComplaint!.assignedManagerId;
          log('ChatView -> Complaint found for order ${widget.orderId}');
          log('ChatView ->   assignedManagerId=${_cachedComplaint!.assignedManagerId}');
          log('ChatView ->   currentUser.id=${currentUser.id}');
          log('ChatView ->   Is assigned manager? $isAssignedManager');
          
          if (isAssignedManager) {
            log('ChatView -> Allowed: User is assigned manager for complaint');
            log('ChatView -> ========== PERMISSION CHECK END ==========');
            return true;
          }
        } else {
          log('ChatView -> No complaint found or no assigned manager for order ${widget.orderId}');
        }
        
        // If not assigned manager, check salesman assignment
        if (widget.linking!.assignedSalesmanUserId == null) {
          log('ChatView -> BLOCKED: Supplier side - assignedSalesmanUserId is NULL (no salesman assigned)');
          log('ChatView -> ========== PERMISSION CHECK END ==========');
          return false;
        }
        
        final canSend = currentUser.id == widget.linking!.assignedSalesmanUserId;
        log('ChatView -> Supplier permission check (salesman):');
        log('ChatView ->   currentUser.id=${currentUser.id} (type: ${currentUser.id.runtimeType})');
        log('ChatView ->   assignedSalesmanUserId=${widget.linking!.assignedSalesmanUserId} (type: ${widget.linking!.assignedSalesmanUserId.runtimeType})');
        log('ChatView ->   IDs match? ${currentUser.id == widget.linking!.assignedSalesmanUserId}');
        log('ChatView ->   RESULT: canSend=$canSend');
        
        if (!canSend) {
          log('ChatView -> BLOCKED: Supplier side - User ID (${currentUser.id}) does NOT match assignedSalesmanUserId (${widget.linking!.assignedSalesmanUserId})');
        }
        
        log('ChatView -> ========== PERMISSION CHECK END ==========');
        return canSend;
      } else {
        // Linking chat: Only the assigned salesman can send messages
        if (widget.linking!.assignedSalesmanUserId == null) {
          log('ChatView -> BLOCKED: Supplier side - assignedSalesmanUserId is NULL (no salesman assigned)');
          log('ChatView -> ========== PERMISSION CHECK END ==========');
          return false;
        }
        
        final canSend = currentUser.id == widget.linking!.assignedSalesmanUserId;
        log('ChatView -> Supplier permission check:');
        log('ChatView ->   currentUser.id=${currentUser.id} (type: ${currentUser.id.runtimeType})');
        log('ChatView ->   assignedSalesmanUserId=${widget.linking!.assignedSalesmanUserId} (type: ${widget.linking!.assignedSalesmanUserId.runtimeType})');
        log('ChatView ->   IDs match? ${currentUser.id == widget.linking!.assignedSalesmanUserId}');
        log('ChatView ->   RESULT: canSend=$canSend');
        
        if (!canSend) {
          log('ChatView -> BLOCKED: Supplier side - User ID (${currentUser.id}) does NOT match assignedSalesmanUserId (${widget.linking!.assignedSalesmanUserId})');
        }
        
        log('ChatView -> ========== PERMISSION CHECK END ==========');
        return canSend;
      }
    } else {
      // User's company is not part of this linking.
      log('ChatView -> BLOCKED: User company (${currentCompany.id}) is NOT part of linking');
      log('ChatView ->   consumerCompanyId=${widget.linking!.consumerCompanyId}');
      log('ChatView ->   supplierCompanyId=${widget.linking!.supplierCompanyId}');
      log('ChatView -> ========== PERMISSION CHECK END ==========');
      return false;
    }
  }

  // Get appropriate hint text based on permission state.
  String _getHintText(bool canSend) {
    if (canSend) {
      return 'Type a message...';
    }

    if (widget.linking == null) {
      return 'Cannot send messages';
    }

    final userState = ref.read(userProfileProvider);
    final companyState = ref.read(companyProfileProvider);

    if (userState.isLoading || companyState.isLoading) {
      return 'Loading permissions...';
    }

    if (userState.hasError || companyState.hasError) {
      return 'Error loading permissions';
    }

    final currentUser = userState.value;
    final currentCompany = companyState.value;

    if (currentUser == null || currentCompany == null) {
      return 'Cannot send messages';
    }

    final bool isConsumerSide = currentCompany.id == widget.linking!.consumerCompanyId;
    final bool isSupplierSide = currentCompany.id == widget.linking!.supplierCompanyId;

    if (isConsumerSide) {
      return 'Only consumer contact can send messages';
    } else if (isSupplierSide) {
      return 'Only assigned salesman can send messages';
    } else {
      return 'Cannot send messages';
    }
  }

  // Load sender information for a message.
  Future<void> _loadSender(int senderId) async {
    if (_senderCache.containsKey(senderId) || _isLoadingSenders) {
      return;
    }

    setState(() {
      _isLoadingSenders = true;
    });

    try {
      final userRepo = ref.read(userRepositoryProvider);
      final user = await userRepo.getUserById(userId: senderId);
      
      if (mounted) {
        setState(() {
          _senderCache[senderId] = user;
          _isLoadingSenders = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSenders = false;
        });
      }
    }
  }

  // Pick image from gallery or camera.
  Future<void> _pickImage() async {
    if (!_canSendMessages()) {
      return;
    }

    // Show dialog to choose source
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(dialogContext).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.of(dialogContext).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) {
      return;
    }

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile == null) {
        return;
      }

      // Read image bytes
      final Uint8List imageBytes = await pickedFile.readAsBytes();
      
      // Extract filename and extension
      final String filePath = pickedFile.path;
      final String filename = filePath.split('/').last;
      final int dotIndex = filePath.lastIndexOf('.');
      final String extension = dotIndex != -1 && dotIndex < filePath.length - 1
          ? filePath.substring(dotIndex + 1).toLowerCase()
          : 'jpg';

      // Set pending image for preview
      setState(() {
        _pendingImageBytes = imageBytes;
        _pendingImageUrl = null;
        _isUploadingImage = true;
        _pendingImageFilename = filename;
      });

      // Upload to S3
      final UploadsRepository uploadsRepository = ref.read(uploadsRepositoryProvider);
      final String uploadedUrl = await S3UploadUtils.uploadToS3(
        uploadsRepository: uploadsRepository,
        fileBytes: imageBytes,
        fileExtension: extension,
        filename: filename,
      );

      if (mounted) {
        setState(() {
          _pendingImageUrl = uploadedUrl;
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      log('ChatView -> Failed to pick/upload image: $e');
      if (mounted) {
        setState(() {
          _pendingImageBytes = null;
          _pendingImageUrl = null;
          _isUploadingImage = false;
          _pendingImageFilename = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  // Remove pending image.
  void _removePendingImage() {
    setState(() {
      _pendingImageBytes = null;
      _pendingImageUrl = null;
      _isUploadingImage = false;
      _pendingImageFilename = null;
    });
  }

  // Send a message (text or image).
  Future<void> _sendMessage() async {
    if (!_canSendMessages()) {
      return;
    }

    // Send image if pending
    if (_pendingImageUrl != null) {
      try {
        final notifier = widget.linkingId != null
            ? ref.read(linkingChatProvider.notifier)
            : ref.read(orderChatProvider.notifier);

        // For image messages, body is always just the URL string
        await notifier.sendMessage(
          body: _pendingImageUrl!,
          type: MessageType.image,
        );

        // Clear pending image
        _removePendingImage();

        // Scroll to bottom after sending
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send image: $e')),
          );
        }
      }
      return;
    }

    // Send text message
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    try {
      final notifier = widget.linkingId != null
          ? ref.read(linkingChatProvider.notifier)
          : ref.read(orderChatProvider.notifier);

      await notifier.sendMessage(body: text);
      _messageController.clear();
      
      // Scroll to bottom after sending.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  // Format timestamp for display.
  String _formatTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) {
      return '';
    }

    try {
      final DateTime dateTime = DateTime.parse(timestamp);
      final DateFormat formatter = DateFormat('HH:mm');
      return formatter.format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }

  // Get sender name for a message.
  String _getSenderName(ChatMessage message) {
    if (message.senderName != null && message.senderName!.isNotEmpty) {
      return message.senderName!;
    }

    final sender = _senderCache[message.senderId];
    if (sender != null) {
      return '${sender.firstName} ${sender.lastName}';
    }

    return 'User ${message.senderId}';
  }

  // Get sender initials for avatar.
  String _getSenderInitials(ChatMessage message) {
    final sender = _senderCache[message.senderId];
    if (sender != null) {
      final firstName = sender.firstName.isNotEmpty ? sender.firstName[0] : '';
      final lastName = sender.lastName.isNotEmpty ? sender.lastName[0] : '';
      return '$firstName$lastName'.toUpperCase();
    }

    // Fallback to first letter of sender name.
    final name = _getSenderName(message);
    if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }

    return '?';
  }

  // Build avatar widget for a message.
  Widget _buildAvatar(ChatMessage message) {
    // Use user profile picture if available (when implemented).
    // For now, use initials in a circle.
    return CircleAvatar(
      radius: 20,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Text(
        _getSenderInitials(message),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Format update message body into readable text.
  String _formatUpdateMessage(ChatMessage message) {
    try {
      // Try to parse the message body as JSON
      final Map<String, dynamic> data = jsonDecode(message.body) as Map<String, dynamic>;
      
      final String? event = data['event'] as String?;
      final String? entity = data['entity'] as String?;
      
      // Handle status_change events
      if (event == 'status_change') {
        final String? oldStatus = data['old_status'] as String?;
        final String? newStatus = data['new_status'] as String?;
        final int? entityId = (data['id'] as num?)?.toInt();
        
        // Capitalize first letter of status
        String formatStatus(String status) {
          if (status.isEmpty) return status;
          return status[0].toUpperCase() + status.substring(1);
        }
        
        // Handle case where old_status is null (new entity created)
        if (oldStatus == null && newStatus != null) {
          final String formattedNewStatus = formatStatus(newStatus);
          
          if (entity == 'order') {
            if (entityId != null) {
              return 'Order #$entityId created with status $formattedNewStatus';
            } else {
              return 'Order created with status $formattedNewStatus';
            }
          } else if (entity == 'complaint') {
            if (entityId != null) {
              return 'Complaint #$entityId created with status $formattedNewStatus';
            } else {
              return 'Complaint created with status $formattedNewStatus';
            }
          }
        }
        // Handle case where both statuses are present (status change)
        else if (oldStatus != null && newStatus != null) {
          final String formattedOldStatus = formatStatus(oldStatus);
          final String formattedNewStatus = formatStatus(newStatus);
          
          if (entity == 'order') {
            if (entityId != null) {
              return 'Order #$entityId status changed from $formattedOldStatus to $formattedNewStatus';
            } else {
              return 'Order status changed from $formattedOldStatus to $formattedNewStatus';
            }
          } else if (entity == 'complaint') {
            if (entityId != null) {
              return 'Complaint #$entityId status changed from $formattedOldStatus to $formattedNewStatus';
            } else {
              return 'Complaint status changed from $formattedOldStatus to $formattedNewStatus';
            }
          }
        }
        // Handle case where only new_status is null (shouldn't happen, but handle gracefully)
        else if (oldStatus != null && newStatus == null) {
          final String formattedOldStatus = formatStatus(oldStatus);
          
          if (entity == 'order') {
            if (entityId != null) {
              return 'Order #$entityId status removed (was $formattedOldStatus)';
            } else {
              return 'Order status removed (was $formattedOldStatus)';
            }
          } else if (entity == 'complaint') {
            if (entityId != null) {
              return 'Complaint #$entityId status removed (was $formattedOldStatus)';
            } else {
              return 'Complaint status removed (was $formattedOldStatus)';
            }
          }
        }
      }
      
      // If parsing fails or event type is unknown, return original body
      return message.body;
    } catch (e) {
      // If JSON parsing fails, return original body
      log('ChatView -> Failed to parse update message: $e');
      return message.body;
    }
  }

  // Build update message widget (full width, no sender).
  Widget _buildUpdateMessage(ChatMessage message) {
    final sender = _senderCache[message.senderId];
    final senderName = sender != null
        ? '${sender.firstName} ${sender.lastName}'
        : _getSenderName(message);

    // Format the message body
    final String formattedBody = _formatUpdateMessage(message);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formattedBody,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'By $senderName',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
              ),
              Text(
                _formatTime(message.sentAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Extract image URL from message body.
  // For image/audio/file messages, body is always a direct URL string.
  String? _extractImageUrl(ChatMessage message) {
    if (message.messageType != MessageType.image) {
      return null;
    }

    final String trimmedBody = message.body.trim();
    if (trimmedBody.isNotEmpty) {
      // Body is always a direct URL for image messages
      if (trimmedBody.startsWith('http://') || trimmedBody.startsWith('https://')) {
        return trimmedBody;
      }
    }

    return null;
  }

  // Build image message widget (thumbnail in bubble, clickable to full screen).
  Widget _buildImageMessage(ChatMessage message, bool isCurrentUser) {
    final userState = ref.watch(userProfileProvider);
    final currentUser = userState.value;
    final isOwnMessage = currentUser?.id == message.senderId;
    final String? imageUrl = _extractImageUrl(message);

    if (imageUrl == null) {
      // Fallback to text message if URL extraction fails
      return _buildTextMessage(message, isCurrentUser);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwnMessage) ...[
            _buildAvatar(message),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isOwnMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isOwnMessage)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0, right: 4.0),
                    child: Text(
                      _getSenderName(message),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                    ),
                  ),
                GestureDetector(
                  onTap: () {
                    // Open full-screen image gallery
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ProductImageGalleryView(
                          imageUrls: [imageUrl],
                          initialIndex: 0,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 250,
                      maxHeight: 250,
                    ),
                    decoration: BoxDecoration(
                      color: isOwnMessage
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: 250,
                        height: 250,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return Container(
                            width: 250,
                            height: 250,
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          width: 250,
                          height: 250,
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Failed to load image',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    _formatTime(message.sentAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 11,
                        ),
                  ),
                ),
              ],
            ),
          ),
          if (isOwnMessage) ...[
            const SizedBox(width: 8),
            _buildAvatar(message),
          ],
        ],
      ),
    );
  }

  // Build regular text message widget (bubble style).
  Widget _buildTextMessage(ChatMessage message, bool isCurrentUser) {
    final userState = ref.watch(userProfileProvider);
    final currentUser = userState.value;
    final isOwnMessage = currentUser?.id == message.senderId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwnMessage) ...[
            _buildAvatar(message),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isOwnMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isOwnMessage)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0, left: 4.0),
                    child: Text(
                      _getSenderName(message),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: isOwnMessage
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Text(
                    message.body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isOwnMessage
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    _formatTime(message.sentAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 11,
                        ),
                  ),
                ),
              ],
            ),
          ),
          if (isOwnMessage) ...[
            const SizedBox(width: 8),
            _buildAvatar(message),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = widget.linkingId != null
        ? ref.watch(linkingChatProvider)
        : ref.watch(orderChatProvider);

    // Load sender information for all messages.
    for (final message in chatState.messages) {
      if (!isUpdateMessage(message.messageType) &&
          !_senderCache.containsKey(message.senderId)) {
        _loadSender(message.senderId);
      }
    }

    // Auto-scroll to bottom when new messages arrive.
    if (chatState.messages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }

    final canSend = _canSendMessages();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          // Messages list.
          Expanded(
            child: chatState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : chatState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error: ${chatState.error}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _connectChat,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : chatState.messages.isEmpty
                        ? Center(
                            child: Text(
                              'No messages yet',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            itemCount: chatState.messages.length,
                            itemBuilder: (context, index) {
                              final message = chatState.messages[index];
                              
                              // Check if this is an update message.
                              if (isUpdateMessage(message.messageType)) {
                                return _buildUpdateMessage(message);
                              }
                              
                              // Check if this is an image message.
                              if (message.messageType == MessageType.image) {
                                return _buildImageMessage(message, false);
                              }
                              
                              // Regular text message.
                              return _buildTextMessage(message, false);
                            },
                          ),
          ),

          // Image preview thumbnail (if pending)
          if (_pendingImageBytes != null)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Thumbnail preview
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Container(
                          width: 64,
                          height: 64,
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: _isUploadingImage
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : Image.memory(
                                  _pendingImageBytes!,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      // Remove button
                      if (!_isUploadingImage)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              iconSize: 16,
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: _removePendingImage,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _pendingImageFilename ?? 'Image',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Input field.
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // Paperclip button for image upload
                    IconButton(
                      onPressed: canSend && chatState.isConnected && !_isUploadingImage
                          ? _pickImage
                          : null,
                      icon: const Icon(Icons.attach_file),
                      tooltip: 'Attach image',
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: canSend && chatState.isConnected,
                        decoration: InputDecoration(
                          hintText: _getHintText(canSend),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 10.0,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: canSend ? (_) => _sendMessage() : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: canSend && 
                          chatState.isConnected && 
                          (_hasText || (_pendingImageUrl != null && !_isUploadingImage))
                          ? _sendMessage
                          : null,
                      icon: const Icon(Icons.send),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

