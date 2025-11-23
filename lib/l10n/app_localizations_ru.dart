// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'APP';

  @override
  String get welcome => 'Добро пожаловать!';

  @override
  String get signInToContinue => 'Войдите чтобы продолжить';

  @override
  String get email => 'Электронная почта';

  @override
  String get emailPlaceholder => 'Введите вашу электронную почту';

  @override
  String get emailRequired => 'Пожалуйста, введите электронную почту';

  @override
  String get password => 'Пароль';

  @override
  String get passwordPlaceholder => 'Введите пароль';

  @override
  String get passwordRequired => 'Пожалуйста, введите пароль';

  @override
  String get signIn => 'Войти';

  @override
  String get signUp => 'Создать компанию';

  @override
  String get logout => 'Выйти';

  @override
  String get home => 'Главная';

  @override
  String get search => 'Поиск';

  @override
  String get add => 'Добавить';

  @override
  String get notifications => 'Уведомления';

  @override
  String get profile => 'Профиль';

  @override
  String get emailAndPasswordRequired => 'Требуется электронная почта и пароль';

  @override
  String get signupTitle => 'Create a Company';

  @override
  String get signupStep1Title => 'Company Type';

  @override
  String get signupStep1Consumer => 'Consumer';

  @override
  String get signupStep1Supplier => 'Supplier';

  @override
  String get signupStep2Title => 'Owner Details';

  @override
  String get signupStep2FirstName => 'First name';

  @override
  String get signupStep2FirstNamePlaceholder => 'Please enter your first name';

  @override
  String get signupStep2LastName => 'Last name';

  @override
  String get signupStep2LastNamePlaceholder => 'Please enter your last name';

  @override
  String get signupStep2PhoneNumber => 'Phone number';

  @override
  String get signupStep2PhoneNumberPlaceholder => '+7-000-000-00-00';

  @override
  String get signupStep2Email => 'Email';

  @override
  String get signupStep2EmailPlaceholder => 'example@mail.com';

  @override
  String get signupStep2Password => 'Password';

  @override
  String get signupStep2passwordPlaceholder => 'Enter your password';

  @override
  String get signupStep2passwordRequired => 'Please enter your password';

  @override
  String get signupStep3Title => 'Company Details';

  @override
  String get signupStep3Name => 'Company name';

  @override
  String get signupStep3NamePlaceholder => 'Enter company name';

  @override
  String get signupStep3Description => 'Description';

  @override
  String get signupStep3DescriptionPlaceholder => 'Enter company description';

  @override
  String get signupStep3Logo => 'Company logo';

  @override
  String get signupStep3LogoPlaceholder => 'Select logo file';

  @override
  String get signupStep3Location => 'Location';

  @override
  String get signupStep3LocationPlaceholder => 'Select city';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonBackToLogin => 'Back to sign in';

  @override
  String get errorLoadingCitiesTitle => 'Unable to load cities';

  @override
  String get settingsUserProfile => 'User profile';

  @override
  String get settingsCompanyProfile => 'Company profile';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get userProfileTitle => 'User profile';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get userRole => 'Role';

  @override
  String get userLocale => 'Locale';

  @override
  String get companyLabel => 'Company';

  @override
  String get refreshProfile => 'Refresh profile';

  @override
  String get errorLoadingProfile => 'Failed to load profile';

  @override
  String get noUserProfile => 'No user profile available';

  @override
  String get companyProfileTitle => 'Company profile';

  @override
  String get companyName => 'Name';

  @override
  String get companyLocation => 'Location';

  @override
  String get companyType => 'Тип компании';

  @override
  String get companyDescription => 'Description';

  @override
  String get companyId => 'Company ID';

  @override
  String get refreshCompany => 'Refresh company';

  @override
  String get errorLoadingCompany => 'Failed to load company';

  @override
  String get noCompanyProfile => 'No company profile available';

  @override
  String get companyTypeSupplier => 'Поставщик';

  @override
  String get companyTypeConsumer => 'Потребитель';

  @override
  String get settingsStaffManagement => 'Staff Management';

  @override
  String get staffManagementTitle => 'Staff Management';

  @override
  String get catalogCreateProductTitle => 'Create product';

  @override
  String get catalogProductNameLabel => 'Name';

  @override
  String get catalogProductDescriptionLabel => 'Description';

  @override
  String get catalogProductStockQuantityLabel => 'Stock quantity';

  @override
  String get catalogProductRetailPriceLabel => 'Retail price';

  @override
  String get catalogProductThresholdLabel => 'Threshold';

  @override
  String get catalogProductBulkPriceLabel => 'Bulk price';

  @override
  String get catalogProductMinimumOrderLabel => 'Minimum order';

  @override
  String get catalogProductUnitLabel => 'Unit';

  @override
  String get catalogProductImagesLabel => 'Product images';

  @override
  String get catalogProductImagesPlaceholder =>
      'Select product images (up to 5)';

  @override
  String get catalogProductImagesMaxExceededTitle => 'Maximum images reached';

  @override
  String get catalogProductImagesMaxExceededMessage =>
      'You can only add up to 5 images. Some images were not added.';

  @override
  String get catalogCreateProductSuccess => 'Product created successfully';

  @override
  String catalogCreateProductErrorGeneric(Object error) {
    return 'Failed to create product: $error';
  }

  @override
  String get catalogEditProductTitle => 'Edit product';

  @override
  String get catalogUpdateProductSuccess => 'Product updated successfully';

  @override
  String catalogUpdateProductErrorGeneric(Object error) {
    return 'Failed to update product: $error';
  }

  @override
  String get catalogDeleteProductTitle => 'Delete product';

  @override
  String get catalogDeleteProductMessage =>
      'Are you sure you want to delete this product? This action cannot be undone.';

  @override
  String get catalogDeleteProductSuccess => 'Product deleted successfully';

  @override
  String catalogDeleteProductErrorGeneric(Object error) {
    return 'Failed to delete product: $error';
  }

  @override
  String get staffCreateUserSuccess => 'User created successfully';

  @override
  String get staffDeleteUserTitle => 'Delete user';

  @override
  String get staffDeleteUserMessage =>
      'Are you sure you want to delete this user? This action cannot be undone.';

  @override
  String get staffDeleteUserSuccess => 'User deleted successfully';

  @override
  String staffDeleteUserErrorGeneric(Object error) {
    return 'Failed to delete user: $error';
  }

  @override
  String get chatTitle => 'Chat';

  @override
  String get chatTypeMessage => 'Type a message...';

  @override
  String get chatCannotSendMessages => 'Cannot send messages';

  @override
  String get chatLoadingPermissions => 'Loading permissions...';

  @override
  String get chatErrorLoadingPermissions => 'Error loading permissions';

  @override
  String get chatOnlyConsumerContact =>
      'Only consumer contact can send messages';

  @override
  String get chatOnlyAssignedSalesman =>
      'Only assigned salesman can send messages';

  @override
  String get chatAttachmentImage => 'Image';

  @override
  String get chatAttachmentFile => 'File';

  @override
  String get chatAttachmentAudio => 'Audio';

  @override
  String get chatSelectImageSource => 'Select Image Source';

  @override
  String get chatImageSourceGallery => 'Gallery';

  @override
  String get chatImageSourceCamera => 'Camera';

  @override
  String chatErrorUploadFile(Object error) {
    return 'Failed to upload file: $error';
  }

  @override
  String chatErrorUploadAudio(Object error) {
    return 'Failed to upload audio: $error';
  }

  @override
  String chatErrorUploadImage(Object error) {
    return 'Failed to upload image: $error';
  }

  @override
  String get chatMicrophonePermissionDenied => 'Microphone permission denied';

  @override
  String chatErrorStartRecording(Object error) {
    return 'Failed to start recording: $error';
  }

  @override
  String get chatRecordingFileNotFound => 'Recording file not found';

  @override
  String chatErrorProcessRecording(Object error) {
    return 'Failed to process recording: $error';
  }

  @override
  String chatErrorSendImage(Object error) {
    return 'Failed to send image: $error';
  }

  @override
  String chatErrorSendFile(Object error) {
    return 'Failed to send file: $error';
  }

  @override
  String chatErrorSendAudio(Object error) {
    return 'Failed to send audio: $error';
  }

  @override
  String chatErrorSendMessage(Object error) {
    return 'Failed to send message: $error';
  }

  @override
  String get chatCannotOpenFileUrl => 'Cannot open file URL';

  @override
  String chatErrorDownloadFile(Object error) {
    return 'Failed to download file: $error';
  }

  @override
  String chatErrorPlayAudio(Object error) {
    return 'Failed to play audio: $error';
  }

  @override
  String get chatNoMessages => 'No messages yet';

  @override
  String chatError(Object error) {
    return 'Error: $error';
  }

  @override
  String get chatAttachFile => 'Attach file';

  @override
  String get chatDownloadFile => 'Download file';

  @override
  String get chatPause => 'Pause';

  @override
  String get chatPlay => 'Play';

  @override
  String get chatStopRecording => 'Stop recording';

  @override
  String get chatRecordAudio => 'Record audio';

  @override
  String get chatFailedToLoadImage => 'Failed to load image';

  @override
  String chatUserUnknown(Object userId) {
    return 'User $userId';
  }

  @override
  String chatOrderCreated(Object orderId, Object status) {
    return 'Order #$orderId created with status $status';
  }

  @override
  String chatOrderCreatedNoId(Object status) {
    return 'Order created with status $status';
  }

  @override
  String chatComplaintCreated(Object complaintId, Object status) {
    return 'Complaint #$complaintId created with status $status';
  }

  @override
  String chatComplaintCreatedNoId(Object status) {
    return 'Complaint created with status $status';
  }

  @override
  String chatOrderStatusChanged(
    Object newStatus,
    Object oldStatus,
    Object orderId,
  ) {
    return 'Order #$orderId status changed from $oldStatus to $newStatus';
  }

  @override
  String chatOrderStatusChangedNoId(Object newStatus, Object oldStatus) {
    return 'Order status changed from $oldStatus to $newStatus';
  }

  @override
  String chatComplaintStatusChanged(
    Object complaintId,
    Object newStatus,
    Object oldStatus,
  ) {
    return 'Complaint #$complaintId status changed from $oldStatus to $newStatus';
  }

  @override
  String chatComplaintStatusChangedNoId(Object newStatus, Object oldStatus) {
    return 'Complaint status changed from $oldStatus to $newStatus';
  }

  @override
  String chatOrderStatusRemoved(Object oldStatus, Object orderId) {
    return 'Order #$orderId status removed (was $oldStatus)';
  }

  @override
  String chatOrderStatusRemovedNoId(Object oldStatus) {
    return 'Order status removed (was $oldStatus)';
  }

  @override
  String chatComplaintStatusRemoved(Object complaintId, Object oldStatus) {
    return 'Complaint #$complaintId status removed (was $oldStatus)';
  }

  @override
  String chatComplaintStatusRemovedNoId(Object oldStatus) {
    return 'Complaint status removed (was $oldStatus)';
  }

  @override
  String chatBySender(Object senderName) {
    return 'By $senderName';
  }

  @override
  String get complaintDetailsTitle => 'Complaint Details';

  @override
  String get complaintNotFound => 'Complaint not found';

  @override
  String get complaintInformation => 'Complaint Information';

  @override
  String get complaintDescription => 'Description';

  @override
  String get complaintCreated => 'Created';

  @override
  String get complaintUpdated => 'Updated';

  @override
  String get complaintResolutionNotes => 'Resolution Notes';

  @override
  String get complaintOrderCancelled => 'Order Cancelled';

  @override
  String get complaintAssignedPersonnel => 'Assigned Personnel';

  @override
  String get complaintAssignedSalesman => 'Assigned Salesman';

  @override
  String get complaintAssignedManager => 'Assigned Manager';

  @override
  String get complaintNoManagerAssigned => 'No manager assigned';

  @override
  String get complaintNoPersonnelAssigned => 'No personnel assigned';

  @override
  String get complaintHistory => 'History';

  @override
  String get complaintNoHistory => 'No history available';

  @override
  String get complaintOpenChat => 'Open Chat';

  @override
  String get complaintActions => 'Actions';

  @override
  String get complaintEscalateToManager => 'Escalate to Manager';

  @override
  String get complaintResolve => 'Resolve';

  @override
  String get complaintClose => 'Close';

  @override
  String get complaintClaimComplaint => 'Claim Complaint';

  @override
  String get complaintEscalateTitle => 'Escalate Complaint';

  @override
  String get complaintEscalateNotes =>
      'Optional: Add notes explaining why you are escalating:';

  @override
  String get complaintEscalateNotesLabel => 'Notes';

  @override
  String get complaintEscalate => 'Escalate';

  @override
  String get complaintEscalatedSuccess => 'Complaint escalated successfully';

  @override
  String complaintEscalateError(Object error) {
    return 'Error escalating complaint: $error';
  }

  @override
  String get complaintClaimTitle => 'Claim Complaint';

  @override
  String get complaintClaimMessage =>
      'Are you sure you want to claim this complaint? You will be responsible for managing it.';

  @override
  String get complaintClaim => 'Claim';

  @override
  String get complaintClaimedSuccess => 'Complaint claimed successfully';

  @override
  String complaintClaimError(Object error) {
    return 'Error claiming complaint: $error';
  }

  @override
  String get complaintResolveTitle => 'Resolve Complaint';

  @override
  String get complaintResolveNotes => 'Please provide resolution notes:';

  @override
  String get complaintResolveNotesLabel => 'Resolution Notes';

  @override
  String get complaintCancelOrder => 'Cancel Order';

  @override
  String get complaintResolveNotesRequired => 'Please enter resolution notes';

  @override
  String get complaintResolvedSuccess => 'Complaint resolved successfully';

  @override
  String complaintResolveError(Object error) {
    return 'Error resolving complaint: $error';
  }

  @override
  String get complaintCloseTitle => 'Close Complaint';

  @override
  String get complaintCloseNotes =>
      'Please provide notes explaining why the complaint is being closed:';

  @override
  String get complaintClosedSuccess => 'Complaint closed successfully';

  @override
  String complaintCloseError(Object error) {
    return 'Error closing complaint: $error';
  }

  @override
  String complaintByUser(Object userName) {
    return 'By: $userName';
  }

  @override
  String get complaintStatusOpen => 'OPEN';

  @override
  String get complaintStatusEscalated => 'ESCALATED';

  @override
  String get complaintStatusInProgress => 'IN PROGRESS';

  @override
  String get complaintStatusResolved => 'RESOLVED';

  @override
  String get complaintStatusClosed => 'CLOSED';

  @override
  String get orderDetailsTitle => 'Order Details';

  @override
  String get orderNotFound => 'Order not found';

  @override
  String get orderLinking => 'Linking';

  @override
  String get orderCreateComplaint => 'Create Complaint';

  @override
  String get orderCreateComplaintReason =>
      'Please provide a reason for your complaint:';

  @override
  String get orderComplaintReasonLabel => 'Reason of Complaint';

  @override
  String get orderComplaintReasonRequired =>
      'Please enter a reason for the complaint';

  @override
  String get orderComplaintCreatedSuccess => 'Complaint created successfully';

  @override
  String orderComplaintCreateError(Object error) {
    return 'Error creating complaint: $error';
  }

  @override
  String get orderChangeStatusTitle => 'Change Order Status';

  @override
  String orderChangeStatusMessage(Object newStatus, Object oldStatus) {
    return 'Change order status from \"$oldStatus\" to \"$newStatus\"?';
  }

  @override
  String get orderChange => 'Change';

  @override
  String orderStatusChanged(Object status) {
    return 'Order status changed to $status';
  }

  @override
  String orderStatusChangeError(Object error) {
    return 'Error changing order status: $error';
  }

  @override
  String orderCreated(Object date) {
    return 'Created: $date';
  }

  @override
  String orderUpdated(Object date) {
    return 'Updated: $date';
  }

  @override
  String get orderComplaint => 'Complaint';

  @override
  String get orderProducts => 'Products';

  @override
  String get orderNoProducts => 'No products in this order';

  @override
  String get orderTotal => 'Total';

  @override
  String orderQuantity(Object quantity) {
    return 'Quantity: $quantity';
  }

  @override
  String orderPricePerUnit(Object price) {
    return 'Price per unit: $price ₸';
  }

  @override
  String orderSubtotal(Object subtotal) {
    return '$subtotal ₸';
  }

  @override
  String orderProductId(Object productId) {
    return 'Product #$productId';
  }

  @override
  String get orderSupplier => 'Supplier';

  @override
  String get orderConsumer => 'Consumer';

  @override
  String get orderAssignedSalesperson => 'Assigned Salesperson';

  @override
  String get orderConsumerStaff => 'Consumer Staff';

  @override
  String get companiesCompany => 'Company';

  @override
  String get commonCreate => 'Create';

  @override
  String get linkingsPending => 'Pending';

  @override
  String get linkingsAccepted => 'Accepted';

  @override
  String get linkingsRejected => 'Rejected';

  @override
  String get linkingsUnlinked => 'Unlinked';

  @override
  String get linkingsNoLinkings => 'No linkings found';

  @override
  String linkingsNoCompaniesMatch(Object query) {
    return 'No companies found matching \"$query\"';
  }

  @override
  String get linkingsSearchCompanies => 'Search companies...';

  @override
  String linkingsMessage(Object message) {
    return 'Message: $message';
  }

  @override
  String linkingsCreated(Object date) {
    return 'Created: $date';
  }

  @override
  String get linkingsAcceptedSuccess => 'Linking accepted';

  @override
  String linkingsAcceptError(Object error) {
    return 'Error accepting linking: $error';
  }

  @override
  String get linkingsRejectedSuccess => 'Linking rejected';

  @override
  String linkingsRejectError(Object error) {
    return 'Error rejecting linking: $error';
  }

  @override
  String get linkingsDetailsTitle => 'Linking Details';

  @override
  String get linkingsFailedToLoadCompany => 'Failed to load company';

  @override
  String get linkingsFailedToLoadContactPerson =>
      'Failed to load contact person';

  @override
  String get linkingsFailedToLoadSalesperson => 'Failed to load salesperson';

  @override
  String get linkingsCompany => 'Company';

  @override
  String get linkingsConsumerContact => 'Consumer Contact';

  @override
  String get linkingsSupplierContact =>
      'Supplier Contact (Assigned Salesperson)';

  @override
  String get linkingsOpenChat => 'Open Chat';

  @override
  String get linkingsUnlinkTitle => 'Unlink Companies';

  @override
  String get linkingsUnlinkMessage =>
      'Are you sure you want to unlink these companies? This action cannot be undone.';

  @override
  String get linkingsUnlink => 'Unlink';

  @override
  String get linkingsUnlinkedSuccess => 'Companies unlinked';

  @override
  String linkingsUnlinkError(Object error) {
    return 'Error unlinking: $error';
  }

  @override
  String get linkingsReject => 'Reject';

  @override
  String get linkingsAccept => 'Accept';

  @override
  String get supplierComplaintsNoAssigned => 'No assigned complaints';

  @override
  String get supplierComplaintsNoEscalated => 'No escalated complaints';

  @override
  String get supplierComplaintsNoManaged => 'No managed complaints';

  @override
  String get supplierComplaintsNoComplaints => 'No complaints';

  @override
  String get supplierComplaintsNoLinkingsComplaints =>
      'No complaints for your linkings';

  @override
  String get supplierComplaintsEscalated => 'Escalated';

  @override
  String get supplierComplaintsMyManaged => 'My Managed';

  @override
  String get supplierComplaintsAllComplaints => 'All Complaints';

  @override
  String get supplierComplaintsMyLinkings => 'My Linkings';

  @override
  String get supplierComplaintsClaim => 'Claim';

  @override
  String get supplierComplaintsUserNotFound => 'User not found';

  @override
  String get supplierComplaintsUnknownRole => 'Unknown user role';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardRevenueTrend => 'Revenue Trend';

  @override
  String get dashboardOrderStatus => 'Order Status';

  @override
  String get dashboardRecentOrders => 'Recent Orders';

  @override
  String get dashboardLowStockAlert => 'Low Stock Alert';

  @override
  String get dashboardTotalRevenue => 'Total Revenue';

  @override
  String get dashboardOrdersToday => 'Orders Today';

  @override
  String get dashboardCreatedOrders => 'Created Orders';

  @override
  String get dashboardLowStock => 'Low Stock';

  @override
  String get dashboardNoRevenueData => 'No revenue data available';

  @override
  String get dashboardNoOrderData => 'No order data available';

  @override
  String get dashboardNoRecentOrders => 'No recent orders';

  @override
  String get dashboardNoLowStockAlerts => 'No low stock alerts';

  @override
  String dashboardErrorLoading(Object error) {
    return 'Error loading dashboard: $error';
  }

  @override
  String dashboardStock(Object current, Object threshold) {
    return 'Stock: $current / $threshold';
  }

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String get cartEmptyMessage => 'Add products from companies to get started';

  @override
  String get cartFailedToLoadProducts => 'Failed to load products';

  @override
  String get cartCheckout => 'Checkout';

  @override
  String get cartConfirmCheckout => 'Confirm Checkout';

  @override
  String cartCheckoutMessage(Object companyName) {
    return 'Complete order with $companyName?';
  }

  @override
  String cartTotal(Object total) {
    return 'Total: $total ₸';
  }

  @override
  String cartItems(Object count) {
    return 'Items: $count';
  }

  @override
  String get cartUserCompanyNotFound => 'User company not found';

  @override
  String cartVerifyLinkingError(Object error) {
    return 'Failed to verify linking: $error';
  }

  @override
  String get cartLinkingNotAccepted =>
      'Linking with this supplier is not accepted';

  @override
  String get cartNoValidProducts => 'No valid products to order';

  @override
  String get cartOrderCreatedSuccess => 'Order created successfully';

  @override
  String cartOrderCreateError(Object error) {
    return 'Failed to create order: $error';
  }

  @override
  String cartErrorLoadingCompany(Object error) {
    return 'Error loading company: $error';
  }

  @override
  String cartTotalLabel(Object total) {
    return 'Total: $total ₸';
  }

  @override
  String cartPricePerUnit(Object price, Object unit) {
    return '$price ₸ / $unit';
  }

  @override
  String cartItemTotal(Object total) {
    return 'Total: $total ₸';
  }

  @override
  String get cartRemove => 'Remove';

  @override
  String cartQuantity(Object unit) {
    return 'Quantity ($unit)';
  }

  @override
  String get companiesSearchCompanies => 'Search companies...';

  @override
  String get companiesErrorLoading => 'Error loading companies';

  @override
  String get companiesNoCompanies => 'No companies yet';

  @override
  String companiesNoMatch(Object query) {
    return 'No companies found matching \"$query\"';
  }

  @override
  String get companiesDetailsTitle => 'Company Details';

  @override
  String get companiesFailedToFetch => 'Failed to fetch';

  @override
  String get companiesDescription => 'Description';

  @override
  String get companiesProducts => 'Products';

  @override
  String get companiesNoProducts => 'No products available';

  @override
  String get companiesSendLinking => 'Send Linking';

  @override
  String get companiesLinkingPending => 'Linking Pending';

  @override
  String get companiesLinkingRejected => 'Linking Rejected';

  @override
  String get companiesUnlinked => 'Unlinked';

  @override
  String get companiesSendLinkingRequest => 'Send Linking Request';

  @override
  String get companiesLinkingMessage => 'Message';

  @override
  String get companiesLinkingMessagePlaceholder => 'Enter your message...';

  @override
  String get companiesLinkingMessageRequired => 'Message cannot be empty';

  @override
  String get companiesLinkingRequestSent => 'Linking request sent successfully';

  @override
  String companiesLinkingRequestError(Object error) {
    return 'Error sending linking request: $error';
  }

  @override
  String get ordersNoLinkings => 'No linkings found';

  @override
  String get ordersNoOrders => 'No orders';

  @override
  String ordersNoOrdersStatus(Object status) {
    return 'No orders with status: $status';
  }

  @override
  String ordersNoCompaniesMatch(Object query) {
    return 'No companies found matching \"$query\"';
  }

  @override
  String get ordersSearchCompanies => 'Search companies...';

  @override
  String get ordersAll => 'All';

  @override
  String ordersLinkingNumber(Object linkingId) {
    return 'Linking #$linkingId';
  }

  @override
  String ordersOrderNumber(Object orderId) {
    return 'Order #$orderId';
  }

  @override
  String ordersCreated(Object date) {
    return 'Created: $date';
  }

  @override
  String get productDetailsTitle => 'Product Details';

  @override
  String get productAddToCart => 'Add to Cart';

  @override
  String get productDetails => 'Details';

  @override
  String get productUnit => 'Unit';

  @override
  String get productStockQuantity => 'Stock quantity';

  @override
  String get productRetailPrice => 'Retail price';

  @override
  String get productBulkPrice => 'Bulk price';

  @override
  String get productMinimumOrder => 'Minimum order';

  @override
  String get productThreshold => 'Threshold';

  @override
  String productAddedToCart(Object quantity, Object unit) {
    return 'Added $quantity $unit to cart';
  }

  @override
  String get catalogNoProducts => 'No products yet';

  @override
  String catalogNoProductsMatch(Object query) {
    return 'No products found matching \"$query\"';
  }

  @override
  String get catalogSearchProducts => 'Search products...';

  @override
  String catalogStock(Object quantity) {
    return 'Stock: $quantity';
  }

  @override
  String get catalogUserNotFound => 'User profile or company ID not found.';

  @override
  String get catalogCompanyNotFound => 'Company not found.';

  @override
  String get catalogSupplierOnly => 'Catalog is available for suppliers only.';

  @override
  String addToCartTitle(Object productName) {
    return '$productName';
  }

  @override
  String addToCartPricePerUnit(Object unit) {
    return 'Price per $unit:';
  }

  @override
  String addToCartQuantity(Object unit) {
    return 'Quantity ($unit)';
  }

  @override
  String get addToCartEnterQuantity => 'Enter quantity';

  @override
  String get addToCartQuantityRequired => 'Please enter a quantity';

  @override
  String get addToCartInvalidNumber => 'Please enter a valid number';

  @override
  String get addToCartQuantityGreaterThanZero =>
      'Quantity must be greater than 0';

  @override
  String addToCartMinimumOrder(Object minimum, Object unit) {
    return 'Minimum order is $minimum $unit';
  }

  @override
  String addToCartOnlyAvailable(Object stock, Object unit) {
    return 'Only $stock $unit available';
  }

  @override
  String addToCartAvailable(Object stock, Object unit) {
    return 'Available: $stock $unit';
  }

  @override
  String addToCartMinimum(Object minimum, Object unit) {
    return 'Minimum: $minimum $unit';
  }

  @override
  String get addToCartButton => 'Add to Cart';

  @override
  String get settingsEnglish => 'English';

  @override
  String get settingsRussian => 'Русский';

  @override
  String get settingsSignupFailed => 'Signup failed';

  @override
  String get userProfileCompany => 'Company';

  @override
  String get userProfileLoading => 'Loading...';

  @override
  String get userProfileUpdatedSuccess => 'Profile updated successfully';

  @override
  String get userProfileUserIdMissing => 'User ID is missing';

  @override
  String userProfileFieldRequired(Object fieldLabel) {
    return '$fieldLabel is required.';
  }

  @override
  String userProfileFieldInvalidInteger(Object fieldLabel) {
    return '$fieldLabel must be a valid integer.';
  }

  @override
  String get userEditUserIdMissing => 'User ID is missing';

  @override
  String get userEditProfileUpdatedSuccess => 'Profile updated successfully';

  @override
  String get companyProfileCompanyLogo => 'Company Logo';

  @override
  String get companyProfileSelectLogo => 'Select company logo';

  @override
  String get companyProfileUpdatedSuccess =>
      'Company profile updated successfully';

  @override
  String get companyProfileCompanyIdMissing => 'Company ID is missing';

  @override
  String get companyProfileNameRequired => 'Name is required';

  @override
  String get companyProfileLocationRequired => 'Location is required';

  @override
  String get companyEditLogo => 'Company Logo';

  @override
  String get companyEditLogoPlaceholder => 'Select company logo';

  @override
  String get companyEditCompanyIdMissing => 'Company ID is missing';

  @override
  String get companyEditProfileUpdatedSuccess =>
      'Company profile updated successfully';

  @override
  String get staffManagementUserNotFound => 'User not found';

  @override
  String staffManagementFieldRequired(Object fieldLabel) {
    return '$fieldLabel is required.';
  }

  @override
  String imageGalleryTitle(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String get commonNA => 'N/A';

  @override
  String get commonBy => 'By';

  @override
  String get commonNotAssigned => 'Not assigned';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonError => 'Error';

  @override
  String get commonOK => 'OK';

  @override
  String get commonEnglish => 'English';

  @override
  String get commonRussian => 'Русский';
}
