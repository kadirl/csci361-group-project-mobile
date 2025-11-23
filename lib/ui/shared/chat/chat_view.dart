import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
import '../../../l10n/app_localizations.dart';
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
  
  // File upload state
  Uint8List? _pendingFileBytes;
  String? _pendingFileUrl;
  bool _isUploadingFile = false;
  String? _pendingFileFilename;
  String? _pendingFileExtension;
  
  // Audio upload state
  Uint8List? _pendingAudioBytes;
  String? _pendingAudioUrl;
  bool _isUploadingAudio = false;
  String? _pendingAudioFilename;
  String? _pendingAudioExtension;
  
  // Audio recording state
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  
  // Cached complaint for permission checks
  Complaint? _cachedComplaint;
  
  // Audio player state - one player per message
  final Map<int, AudioPlayer> _audioPlayers = {};
  final Map<int, bool> _audioPlayingStates = {};
  final Map<int, Duration?> _audioDurations = {};
  final Map<int, Duration?> _audioPositions = {};

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
    
    // Dispose all audio players
    for (final player in _audioPlayers.values) {
      player.dispose();
    }
    _audioPlayers.clear();
    _audioPlayingStates.clear();
    _audioDurations.clear();
    _audioPositions.clear();
    
    // Stop recording if active and dispose recorder
    if (_isRecording) {
      _audioRecorder.stop();
    }
    _audioRecorder.dispose();
    
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
  String _getHintText(bool canSend, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (canSend) {
      return l10n.chatTypeMessage;
    }

    if (widget.linking == null) {
      return l10n.chatCannotSendMessages;
    }

    final userState = ref.read(userProfileProvider);
    final companyState = ref.read(companyProfileProvider);

    if (userState.isLoading || companyState.isLoading) {
      return l10n.chatLoadingPermissions;
    }

    if (userState.hasError || companyState.hasError) {
      return l10n.chatErrorLoadingPermissions;
    }

    final currentUser = userState.value;
    final currentCompany = companyState.value;

    if (currentUser == null || currentCompany == null) {
      return l10n.chatCannotSendMessages;
    }

    final bool isConsumerSide = currentCompany.id == widget.linking!.consumerCompanyId;
    final bool isSupplierSide = currentCompany.id == widget.linking!.supplierCompanyId;

    if (isConsumerSide) {
      return l10n.chatOnlyConsumerContact;
    } else if (isSupplierSide) {
      return l10n.chatOnlyAssignedSalesman;
    } else {
      return l10n.chatCannotSendMessages;
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

  // Show attachment type selection menu.
  void _showAttachmentMenu() {
    if (!_canSendMessages()) {
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: Text(AppLocalizations.of(context)!.chatAttachmentImage),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(AppLocalizations.of(context)!.chatAttachmentFile),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.audiotrack),
                title: Text(AppLocalizations.of(context)!.chatAttachmentAudio),
                onTap: () {
                  Navigator.pop(context);
                  _pickAudio();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Pick file from system file picker.
  Future<void> _pickFile() async {
    if (!_canSendMessages()) {
      return;
    }

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.single.bytes == null) {
        return;
      }

      final PlatformFile file = result.files.single;
      final Uint8List fileBytes = file.bytes!;
      
      // Extract filename and extension
      final String filename = file.name;
      final int dotIndex = filename.lastIndexOf('.');
      final String extension = dotIndex != -1 && dotIndex < filename.length - 1
          ? filename.substring(dotIndex + 1).toLowerCase()
          : 'bin';

      // Set pending file for preview
      setState(() {
        _pendingFileBytes = fileBytes;
        _pendingFileUrl = null;
        _isUploadingFile = true;
        _pendingFileFilename = filename;
        _pendingFileExtension = extension;
      });

      // Upload to S3
      final UploadsRepository uploadsRepository = ref.read(uploadsRepositoryProvider);
      final String uploadedUrl = await S3UploadUtils.uploadToS3(
        uploadsRepository: uploadsRepository,
        fileBytes: fileBytes,
        fileExtension: extension,
        filename: filename,
      );

      if (mounted) {
        setState(() {
          _pendingFileUrl = uploadedUrl;
          _isUploadingFile = false;
        });
      }
    } catch (e) {
      log('ChatView -> Failed to pick/upload file: $e');
      if (mounted) {
        setState(() {
          _pendingFileBytes = null;
          _pendingFileUrl = null;
          _isUploadingFile = false;
          _pendingFileFilename = null;
          _pendingFileExtension = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.chatErrorUploadFile(e.toString()))),
        );
      }
    }
  }

  // Pick audio file from system file picker.
  Future<void> _pickAudio() async {
    if (!_canSendMessages()) {
      return;
    }

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result == null || result.files.single.bytes == null) {
        return;
      }

      final PlatformFile file = result.files.single;
      final Uint8List audioBytes = file.bytes!;
      
      // Extract filename and extension
      final String filename = file.name;
      final int dotIndex = filename.lastIndexOf('.');
      final String extension = dotIndex != -1 && dotIndex < filename.length - 1
          ? filename.substring(dotIndex + 1).toLowerCase()
          : 'mp3';

      // Set pending audio for preview
      setState(() {
        _pendingAudioBytes = audioBytes;
        _pendingAudioUrl = null;
        _isUploadingAudio = true;
        _pendingAudioFilename = filename;
        _pendingAudioExtension = extension;
      });

      // Upload to S3
      final UploadsRepository uploadsRepository = ref.read(uploadsRepositoryProvider);
      final String uploadedUrl = await S3UploadUtils.uploadToS3(
        uploadsRepository: uploadsRepository,
        fileBytes: audioBytes,
        fileExtension: extension,
        filename: filename,
      );

      if (mounted) {
        setState(() {
          _pendingAudioUrl = uploadedUrl;
          _isUploadingAudio = false;
        });
      }
    } catch (e) {
      log('ChatView -> Failed to pick/upload audio: $e');
      if (mounted) {
        setState(() {
          _pendingAudioBytes = null;
          _pendingAudioUrl = null;
          _isUploadingAudio = false;
          _pendingAudioFilename = null;
          _pendingAudioExtension = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.chatErrorUploadAudio(e.toString()))),
        );
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
      builder: (BuildContext dialogContext) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.chatSelectImageSource),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(l10n.chatImageSourceGallery),
                onTap: () => Navigator.of(dialogContext).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(l10n.chatImageSourceCamera),
                onTap: () => Navigator.of(dialogContext).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
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
          SnackBar(content: Text(AppLocalizations.of(context)!.chatErrorUploadImage(e.toString()))),
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

  // Remove pending file.
  void _removePendingFile() {
    setState(() {
      _pendingFileBytes = null;
      _pendingFileUrl = null;
      _isUploadingFile = false;
      _pendingFileFilename = null;
      _pendingFileExtension = null;
    });
  }

  // Remove pending audio.
  void _removePendingAudio() {
    setState(() {
      _pendingAudioBytes = null;
      _pendingAudioUrl = null;
      _isUploadingAudio = false;
      _pendingAudioFilename = null;
      _pendingAudioExtension = null;
    });
  }

  // Toggle audio recording (start or stop).
  Future<void> _toggleRecording() async {
    if (!_canSendMessages()) {
      return;
    }

    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  // Start audio recording.
  Future<void> _startRecording() async {
    try {
      // Check permission
      if (!await _audioRecorder.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.chatMicrophonePermissionDenied)),
          );
        }
        return;
      }

      // Get temporary directory for recording
      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = '${tempDir.path}/audio_$timestamp.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      // Update duration every second
      _updateRecordingDuration();
    } catch (e) {
      log('ChatView -> Failed to start recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.chatErrorStartRecording(e.toString()))),
        );
      }
    }
  }

  // Update recording duration.
  void _updateRecordingDuration() {
    if (!_isRecording || !mounted) return;

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isRecording) {
        setState(() {
          _recordingDuration = _recordingDuration + const Duration(seconds: 1);
        });
        _updateRecordingDuration();
      }
    });
  }

  // Stop audio recording and upload.
  Future<void> _stopRecording() async {
    try {
      final String? path = await _audioRecorder.stop();
      
      if (path == null || !File(path).existsSync()) {
        if (mounted) {
          setState(() {
            _isRecording = false;
            _recordingDuration = Duration.zero;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.chatRecordingFileNotFound)),
          );
        }
        return;
      }

      // Read the recorded file
      final File audioFile = File(path);
      final Uint8List audioBytes = await audioFile.readAsBytes();
      
      // Generate filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filename = 'recording_$timestamp.m4a';

      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
        _pendingAudioBytes = audioBytes;
        _pendingAudioUrl = null;
        _isUploadingAudio = true;
        _pendingAudioFilename = filename;
        _pendingAudioExtension = 'm4a';
      });

      // Upload to S3
      final UploadsRepository uploadsRepository = ref.read(uploadsRepositoryProvider);
      final String uploadedUrl = await S3UploadUtils.uploadToS3(
        uploadsRepository: uploadsRepository,
        fileBytes: audioBytes,
        fileExtension: 'm4a',
        filename: filename,
      );

      if (mounted) {
        setState(() {
          _pendingAudioUrl = uploadedUrl;
          _isUploadingAudio = false;
        });
      }

      // Clean up temporary file
      try {
        await audioFile.delete();
      } catch (e) {
        log('ChatView -> Failed to delete temp recording file: $e');
      }
    } catch (e) {
      log('ChatView -> Failed to stop/upload recording: $e');
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingDuration = Duration.zero;
          _pendingAudioBytes = null;
          _pendingAudioUrl = null;
          _isUploadingAudio = false;
          _pendingAudioFilename = null;
          _pendingAudioExtension = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.chatErrorProcessRecording(e.toString()))),
        );
      }
    }
  }

  // Format recording duration for display.
  String _formatRecordingDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Send a message (text, image, file, or audio).
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
            SnackBar(content: Text(AppLocalizations.of(context)!.chatErrorSendImage(e.toString()))),
          );
        }
      }
      return;
    }

    // Send file if pending
    if (_pendingFileUrl != null) {
      try {
        final notifier = widget.linkingId != null
            ? ref.read(linkingChatProvider.notifier)
            : ref.read(orderChatProvider.notifier);

        // For file messages, body is JSON with url and filename
        final String fileBody = jsonEncode({
          'url': _pendingFileUrl!,
          'filename': _pendingFileFilename ?? 'file',
        });
        await notifier.sendMessage(
          body: fileBody,
          type: MessageType.file,
        );

        // Clear pending file
        _removePendingFile();

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
            SnackBar(content: Text(AppLocalizations.of(context)!.chatErrorSendFile(e.toString()))),
          );
        }
      }
      return;
    }

    // Send audio if pending
    if (_pendingAudioUrl != null) {
      try {
        final notifier = widget.linkingId != null
            ? ref.read(linkingChatProvider.notifier)
            : ref.read(orderChatProvider.notifier);

        // For audio messages, body is always just the URL string
        await notifier.sendMessage(
          body: _pendingAudioUrl!,
          type: MessageType.audio,
        );

        // Clear pending audio
        _removePendingAudio();

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
            SnackBar(content: Text(AppLocalizations.of(context)!.chatErrorSendAudio(e.toString()))),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.chatErrorSendMessage(e.toString()))),
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
  String _getSenderName(ChatMessage message, BuildContext context) {
    if (message.senderName != null && message.senderName!.isNotEmpty) {
      return message.senderName!;
    }

    final sender = _senderCache[message.senderId];
    if (sender != null) {
      return '${sender.firstName} ${sender.lastName}';
    }

    final l10n = AppLocalizations.of(context)!;
    return l10n.chatUserUnknown(message.senderId);
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
    final name = _getSenderName(message, context);
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
  String _formatUpdateMessage(ChatMessage message, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              return l10n.chatOrderCreated(entityId, formattedNewStatus);
            } else {
              return l10n.chatOrderCreatedNoId(formattedNewStatus);
            }
          } else if (entity == 'complaint') {
            if (entityId != null) {
              return l10n.chatComplaintCreated(entityId, formattedNewStatus);
            } else {
              return l10n.chatComplaintCreatedNoId(formattedNewStatus);
            }
          }
        }
        // Handle case where both statuses are present (status change)
        else if (oldStatus != null && newStatus != null) {
          final String formattedOldStatus = formatStatus(oldStatus);
          final String formattedNewStatus = formatStatus(newStatus);
          
          if (entity == 'order') {
            if (entityId != null) {
              return l10n.chatOrderStatusChanged(formattedNewStatus, formattedOldStatus, entityId);
            } else {
              return l10n.chatOrderStatusChangedNoId(formattedNewStatus, formattedOldStatus);
            }
          } else if (entity == 'complaint') {
            if (entityId != null) {
              return l10n.chatComplaintStatusChanged(entityId, formattedNewStatus, formattedOldStatus);
            } else {
              return l10n.chatComplaintStatusChangedNoId(formattedNewStatus, formattedOldStatus);
            }
          }
        }
        // Handle case where only new_status is null (shouldn't happen, but handle gracefully)
        else if (oldStatus != null && newStatus == null) {
          final String formattedOldStatus = formatStatus(oldStatus);
          
          if (entity == 'order') {
            if (entityId != null) {
              return l10n.chatOrderStatusRemoved(formattedOldStatus, entityId);
            } else {
              return l10n.chatOrderStatusRemovedNoId(formattedOldStatus);
            }
          } else if (entity == 'complaint') {
            if (entityId != null) {
              return l10n.chatComplaintStatusRemoved(entityId, formattedOldStatus);
            } else {
              return l10n.chatComplaintStatusRemovedNoId(formattedOldStatus);
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
  Widget _buildUpdateMessage(ChatMessage message, BuildContext context) {
    final sender = _senderCache[message.senderId];
    final senderName = sender != null
        ? '${sender.firstName} ${sender.lastName}'
        : _getSenderName(message, context);

    // Format the message body
    final String formattedBody = _formatUpdateMessage(message, context);

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
                '${AppLocalizations.of(context)!.commonBy} $senderName',
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
  Widget _buildImageMessage(ChatMessage message, bool isCurrentUser, BuildContext context) {
    final userState = ref.watch(userProfileProvider);
    final currentUser = userState.value;
    final isOwnMessage = currentUser?.id == message.senderId;
    final String? imageUrl = _extractImageUrl(message);

    if (imageUrl == null) {
      // Fallback to text message if URL extraction fails
      return _buildTextMessage(message, isCurrentUser, context);
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
                      _getSenderName(message, context),
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
                                AppLocalizations.of(context)!.chatFailedToLoadImage,
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

  // Extract file URL from message body.
  // For file messages, body is JSON with url and filename.
  String? _extractFileUrl(ChatMessage message, BuildContext context) {
    if (message.messageType != MessageType.file) {
      return null;
    }

    try {
      final String trimmedBody = message.body.trim();
      if (trimmedBody.isEmpty) {
        return null;
      }

      // Try to parse as JSON first (for file messages)
      final Map<String, dynamic> data = jsonDecode(trimmedBody) as Map<String, dynamic>;
      final String? url = data['url'] as String?;
      if (url != null && (url.startsWith('http://') || url.startsWith('https://'))) {
        return url;
      }
    } catch (e) {
      // If JSON parsing fails, try as direct URL (backward compatibility)
      final String trimmedBody = message.body.trim();
      if (trimmedBody.startsWith('http://') || trimmedBody.startsWith('https://')) {
        return trimmedBody;
      }
      log('ChatView -> Failed to extract file URL: $e');
    }

    return null;
  }

  // Extract filename from file message body.
  // For file messages, body is JSON with url and filename.
  String _extractFileFilename(ChatMessage message, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (message.messageType != MessageType.file) {
      return l10n.chatAttachmentFile;
    }

    try {
      final String trimmedBody = message.body.trim();
      if (trimmedBody.isEmpty) {
        return l10n.chatAttachmentFile;
      }

      // Try to parse as JSON first (for file messages)
      final Map<String, dynamic> data = jsonDecode(trimmedBody) as Map<String, dynamic>;
      final String? filename = data['filename'] as String?;
      if (filename != null && filename.isNotEmpty) {
        return filename;
      }
    } catch (e) {
      // If JSON parsing fails, try to extract from URL (backward compatibility)
      final String? url = _extractFileUrl(message, context);
      if (url != null) {
        try {
          final uri = Uri.parse(url);
          final pathSegments = uri.pathSegments;
          if (pathSegments.isNotEmpty) {
            final filename = pathSegments.last;
            // Remove query parameters if present in filename
            final cleanFilename = filename.split('?').first;
            if (cleanFilename.isNotEmpty) {
              return cleanFilename;
            }
          }
        } catch (e2) {
          log('ChatView -> Failed to extract filename from URL: $e2');
        }
      }
      log('ChatView -> Failed to extract filename from JSON: $e');
    }

    return AppLocalizations.of(context)!.chatAttachmentFile;
  }

  // Download file by opening URL.
  Future<void> _downloadFile(String url, BuildContext context) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.chatCannotOpenFileUrl)),
          );
        }
      }
    } catch (e) {
      log('ChatView -> Failed to download file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.chatErrorDownloadFile(e.toString()))),
        );
      }
    }
  }

  // Build file message widget with filename and download button.
  Widget _buildFileMessage(ChatMessage message, bool isCurrentUser, BuildContext context) {
    final userState = ref.watch(userProfileProvider);
    final currentUser = userState.value;
    final isOwnMessage = currentUser?.id == message.senderId;
    final String? fileUrl = _extractFileUrl(message, context);

    if (fileUrl == null) {
      // Fallback to text message if URL extraction fails
      return _buildTextMessage(message, isCurrentUser, context);
    }

    final String filename = _extractFileFilename(message, context);
    final String displayFilename = filename.length > 30 
        ? '${filename.substring(0, 27)}...' 
        : filename;

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
                      _getSenderName(message, context),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  decoration: BoxDecoration(
                    color: isOwnMessage
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.insert_drive_file,
                        color: isOwnMessage
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          displayFilename,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isOwnMessage
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () => _downloadFile(fileUrl, context),
                        icon: Icon(
                          Icons.download,
                          color: isOwnMessage
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        tooltip: AppLocalizations.of(context)!.chatDownloadFile,
                      ),
                    ],
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

  // Extract audio URL from message body.
  // For audio messages, body is always a direct URL string.
  String? _extractAudioUrl(ChatMessage message) {
    if (message.messageType != MessageType.audio) {
      return null;
    }

    final String trimmedBody = message.body.trim();
    if (trimmedBody.isNotEmpty) {
      if (trimmedBody.startsWith('http://') || trimmedBody.startsWith('https://')) {
        return trimmedBody;
      }
    }

    return null;
  }

  // Initialize audio player for a message if not already initialized.
  Future<void> _initializeAudioPlayer(ChatMessage message) async {
    if (_audioPlayers.containsKey(message.messageId)) {
      return;
    }

    final String? audioUrl = _extractAudioUrl(message);
    if (audioUrl == null) {
      return;
    }

    try {
      final player = AudioPlayer();
      await player.setUrl(audioUrl);
      
      // Listen to player state changes
      player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _audioPlayingStates[message.messageId] = state.playing;
          });
        }
      });

      // Listen to duration changes
      player.durationStream.listen((duration) {
        if (mounted) {
          setState(() {
            _audioDurations[message.messageId] = duration;
          });
        }
      });

      // Listen to position changes
      player.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _audioPositions[message.messageId] = position;
          });
        }
      });

      if (mounted) {
        setState(() {
          _audioPlayers[message.messageId] = player;
          _audioPlayingStates[message.messageId] = false;
        });
      }
    } catch (e) {
      log('ChatView -> Failed to initialize audio player: $e');
    }
  }

  // Toggle play/pause for audio message.
  Future<void> _toggleAudioPlayback(ChatMessage message) async {
    await _initializeAudioPlayer(message);
    
    final player = _audioPlayers[message.messageId];
    if (player == null) {
      return;
    }

    try {
      final isPlaying = _audioPlayingStates[message.messageId] ?? false;
      if (isPlaying) {
        await player.pause();
      } else {
        await player.play();
      }
    } catch (e) {
      log('ChatView -> Failed to toggle audio playback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.chatErrorPlayAudio(e.toString()))),
        );
      }
    }
  }

  // Format duration for display.
  String _formatDuration(Duration? duration) {
    if (duration == null) {
      return '0:00';
    }
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // Build audio message widget with play/pause button.
  Widget _buildAudioMessage(ChatMessage message, bool isCurrentUser, BuildContext context) {
    final userState = ref.watch(userProfileProvider);
    final currentUser = userState.value;
    final isOwnMessage = currentUser?.id == message.senderId;
    final String? audioUrl = _extractAudioUrl(message);

    if (audioUrl == null) {
      // Fallback to text message if URL extraction fails
      return _buildTextMessage(message, isCurrentUser, context);
    }

    // Initialize player if not already done
    _initializeAudioPlayer(message);

    final isPlaying = _audioPlayingStates[message.messageId] ?? false;
    final duration = _audioDurations[message.messageId];
    final position = _audioPositions[message.messageId];

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
                      _getSenderName(message, context),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  decoration: BoxDecoration(
                    color: isOwnMessage
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _toggleAudioPlayback(message),
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: isOwnMessage
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        iconSize: 28,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        tooltip: isPlaying ? AppLocalizations.of(context)!.chatPause : AppLocalizations.of(context)!.chatPlay,
                      ),
                      const SizedBox(width: 8),
                      if (duration != null && position != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(
                                value: duration.inMilliseconds > 0
                                    ? position.inMilliseconds / duration.inMilliseconds
                                    : 0.0,
                                backgroundColor: isOwnMessage
                                    ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.3)
                                    : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isOwnMessage
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: isOwnMessage
                                              ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.8)
                                              : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                                          fontSize: 11,
                                        ),
                                  ),
                                  Text(
                                    _formatDuration(duration),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: isOwnMessage
                                              ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.8)
                                              : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                                          fontSize: 11,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      else
                        Icon(
                          Icons.audiotrack,
                          color: isOwnMessage
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                    ],
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
  Widget _buildTextMessage(ChatMessage message, bool isCurrentUser, BuildContext context) {
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
                      _getSenderName(message, context),
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
        title: Text(AppLocalizations.of(context)!.chatTitle),
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
                              AppLocalizations.of(context)!.chatError(chatState.error ?? ''),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _connectChat,
                              child: Text(AppLocalizations.of(context)!.commonRetry),
                            ),
                          ],
                        ),
                      )
                    : chatState.messages.isEmpty
                        ? Center(
                            child: Text(
                              AppLocalizations.of(context)!.chatNoMessages,
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
                                return _buildUpdateMessage(message, context);
                              }
                              
                              // Check if this is an image message.
                              if (message.messageType == MessageType.image) {
                                return _buildImageMessage(message, false, context);
                              }
                              
                              // Check if this is a file message.
                              if (message.messageType == MessageType.file) {
                                return _buildFileMessage(message, false, context);
                              }
                              
                              // Check if this is an audio message.
                              if (message.messageType == MessageType.audio) {
                                return _buildAudioMessage(message, false, context);
                              }
                              
                              // Regular text message.
                              return _buildTextMessage(message, false, context);
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
                      _pendingImageFilename ?? AppLocalizations.of(context)!.chatAttachmentImage,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // File preview (if pending)
          if (_pendingFileBytes != null)
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
                  // File icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: _isUploadingFile
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.insert_drive_file,
                              size: 32,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _pendingFileFilename ?? AppLocalizations.of(context)!.chatAttachmentFile,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_pendingFileExtension != null)
                          Text(
                            _pendingFileExtension!.toUpperCase(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 10,
                                ),
                          ),
                      ],
                    ),
                  ),
                  if (!_isUploadingFile)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      iconSize: 20,
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      onPressed: _removePendingFile,
                    ),
                ],
              ),
            ),

          // Audio preview (if pending)
          if (_pendingAudioBytes != null)
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
                  // Audio icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: _isUploadingAudio
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.audiotrack,
                              size: 32,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _pendingAudioFilename ?? AppLocalizations.of(context)!.chatAttachmentAudio,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_pendingAudioExtension != null)
                          Text(
                            _pendingAudioExtension!.toUpperCase(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 10,
                                ),
                          ),
                      ],
                    ),
                  ),
                  if (!_isUploadingAudio)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      iconSize: 20,
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      onPressed: _removePendingAudio,
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
                    // Paperclip button for attachments (image, file, audio)
                    IconButton(
                      onPressed: canSend && 
                          chatState.isConnected && 
                          !_isUploadingImage && 
                          !_isUploadingFile && 
                          !_isUploadingAudio
                          ? _showAttachmentMenu
                          : null,
                      icon: const Icon(Icons.attach_file),
                      tooltip: AppLocalizations.of(context)!.chatAttachFile,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: canSend && chatState.isConnected,
                        decoration: InputDecoration(
                          hintText: _getHintText(canSend, context),
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
                    // Show record button when no text, send button when text exists
                    _hasText || 
                        (_pendingImageUrl != null && !_isUploadingImage) ||
                        (_pendingFileUrl != null && !_isUploadingFile) ||
                        (_pendingAudioUrl != null && !_isUploadingAudio)
                        ? IconButton(
                            onPressed: canSend && chatState.isConnected ? _sendMessage : null,
                            icon: const Icon(Icons.send),
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(
                                onPressed: canSend && 
                                    chatState.isConnected && 
                                    !_isUploadingImage && 
                                    !_isUploadingFile && 
                                    !_isUploadingAudio
                                    ? _toggleRecording
                                    : null,
                                icon: Icon(
                                  _isRecording ? Icons.stop : Icons.mic,
                                  color: _isRecording 
                                      ? Theme.of(context).colorScheme.error
                                      : Theme.of(context).colorScheme.primary,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: _isRecording
                                      ? Theme.of(context).colorScheme.errorContainer
                                      : Theme.of(context).colorScheme.primaryContainer,
                                  foregroundColor: _isRecording
                                      ? Theme.of(context).colorScheme.onErrorContainer
                                      : Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                                tooltip: _isRecording ? AppLocalizations.of(context)!.chatStopRecording : AppLocalizations.of(context)!.chatRecordAudio,
                              ),
                              if (_isRecording)
                                Positioned(
                                  bottom: 4,
                                  child: Text(
                                    _formatRecordingDuration(_recordingDuration),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context).colorScheme.onErrorContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
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

