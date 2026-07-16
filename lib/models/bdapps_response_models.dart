/// Typed response models for the four BDApps PHP endpoints.
///
/// The shapes here mirror exactly what the PHP files return - see
/// `BDApps_SDK/send_otp.php`, `verify_otp.php`, `check_subscription.php`
/// and `unsubscribe.php` for the canonical definitions.
library;

/// Result of POST /send_otp.php.
///
/// On success:
/// ```
/// {
///   "success": true,
///   "referenceNo": "...",
///   "statusCode": "S1000",
///   "statusDetail": "...",
///   "version": "1.0"
/// }
/// ```
///
/// On failure:
/// ```
/// {
///   "success": false,
///   "message": "Invalid mobile number format",
///   "referenceNo": null,
///   ...
/// }
/// ```
class SendOtpResponse {
  final bool success;
  final String? referenceNo;
  final String? statusCode;
  final String? statusDetail;
  final String? version;
  final String? message;
  final String? subscriberId;

  const SendOtpResponse({
    required this.success,
    this.referenceNo,
    this.statusCode,
    this.statusDetail,
    this.version,
    this.message,
    this.subscriberId,
  });

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) {
    return SendOtpResponse(
      success: json['success'] == true,
      referenceNo: json['referenceNo']?.toString(),
      statusCode: json['statusCode']?.toString(),
      statusDetail: json['statusDetail']?.toString(),
      version: json['version']?.toString(),
      message: json['message']?.toString(),
      subscriberId: json['subscriberId']?.toString(),
    );
  }
}

/// Result of POST /verify_otp.php.
///
/// Sample success:
/// ```
/// {
///   "statusCode": "S1000",
///   "statusDetail": "Success",
///   "subscriptionStatus": "REGISTERED",
///   "subscriberId": "tel:88018xxxxxxx",
///   "version": "1.0"
/// }
/// ```
class VerifyOtpResponse {
  final String statusCode;
  final String statusDetail;
  final String subscriptionStatus;
  final String subscriberId;
  final String? version;

  const VerifyOtpResponse({
    required this.statusCode,
    required this.statusDetail,
    required this.subscriptionStatus,
    required this.subscriberId,
    this.version,
  });

  bool get isSuccess => statusCode.toUpperCase() == 'S1000';
  bool get isRegistered =>
      subscriptionStatus.toUpperCase() == 'REGISTERED' && isSuccess;

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      statusCode: (json['statusCode'] ?? '').toString(),
      statusDetail: (json['statusDetail'] ?? '').toString(),
      subscriptionStatus: (json['subscriptionStatus'] ?? '').toString(),
      subscriberId: (json['subscriberId'] ?? '').toString(),
      version: json['version']?.toString(),
    );
  }
}

/// Result of POST /check_subscription.php.
///
/// Sample:
/// ```
/// {
///   "subscriptionStatus": "REGISTERED",
///   "isSubscribed": true,
///   "statusCode": "S1000",
///   "statusDetail": "Success",
///   "version": "1.0",
///   "subscriberId": "tel:88018xxxxxxx"
/// }
/// ```
class SubscriptionStatusResponse {
  final String subscriptionStatus;
  final bool isSubscribed;
  final String? statusCode;
  final String? statusDetail;
  final String? version;
  final String? subscriberId;
  final String? error;

  const SubscriptionStatusResponse({
    required this.subscriptionStatus,
    required this.isSubscribed,
    this.statusCode,
    this.statusDetail,
    this.version,
    this.subscriberId,
    this.error,
  });

  bool get isRegistered =>
      subscriptionStatus.toUpperCase() == 'REGISTERED' || isSubscribed;

  factory SubscriptionStatusResponse.fromJson(Map<String, dynamic> json) {
    final status = (json['subscriptionStatus'] ?? '').toString();
    return SubscriptionStatusResponse(
      subscriptionStatus: status,
      isSubscribed: json['isSubscribed'] == true ||
          status.toUpperCase() == 'REGISTERED',
      statusCode: json['statusCode']?.toString(),
      statusDetail: json['statusDetail']?.toString(),
      version: json['version']?.toString(),
      subscriberId: json['subscriberId']?.toString(),
      error: json['error']?.toString(),
    );
  }
}

/// Result of POST /unsubscribe.php.
///
/// Sample:
/// ```
/// {
///   "success": true,
///   "subscriberId": "tel:88018xxxxxxx",
///   "action": "0",
///   "version": "1.0",
///   "statusCode": "S1000",
///   "statusDetail": "Success",
///   "subscriptionStatus": "UNREGISTERED"
/// }
/// ```
class UnsubscribeResponse {
  final bool success;
  final String? subscriberId;
  final String? action;
  final String? version;
  final String? statusCode;
  final String? statusDetail;
  final String? subscriptionStatus;
  final String? error;
  final String? rawResponse;

  const UnsubscribeResponse({
    required this.success,
    this.subscriberId,
    this.action,
    this.version,
    this.statusCode,
    this.statusDetail,
    this.subscriptionStatus,
    this.error,
    this.rawResponse,
  });

  factory UnsubscribeResponse.fromJson(Map<String, dynamic> json) {
    return UnsubscribeResponse(
      success: json['success'] == true,
      subscriberId: json['subscriberId']?.toString(),
      action: json['action']?.toString(),
      version: json['version']?.toString(),
      statusCode: json['statusCode']?.toString(),
      statusDetail: json['statusDetail']?.toString(),
      subscriptionStatus: json['subscriptionStatus']?.toString(),
      error: json['error']?.toString(),
      rawResponse: json['rawResponse']?.toString(),
    );
  }
}