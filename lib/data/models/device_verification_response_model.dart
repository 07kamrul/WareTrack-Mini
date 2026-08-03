class DeviceVerificationResponseModel {
  const DeviceVerificationResponseModel({
    required this.message,
    required this.status,
    required this.data,
  });

  final String message;
  final bool status;
  final DeviceVerificationDataModel? data;

  factory DeviceVerificationResponseModel.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'];

    return DeviceVerificationResponseModel(
      message: json['message']?.toString() ?? '',
      status: json['status'] == true,
      data: dataJson is Map<String, dynamic>
          ? DeviceVerificationDataModel.fromJson(dataJson)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'message': message, 'status': status, 'data': data?.toJson()};
  }
}

class DeviceVerificationDataModel {
  const DeviceVerificationDataModel({
    required this.companyId,
    required this.code,
    required this.datachar01,
    required this.datachar02,
    this.datachar03,
    required this.accesscode,
    required this.status,
  });

  final String companyId;
  final String code;
  final String datachar01;
  final String datachar02;

  /// Server-reported trial-end timestamp (e.g. "2026-07-30 13:08:51"),
  /// returned on the Trial build's code-verify response. Null when the
  /// field is absent (e.g. Standard build) or not present in this
  /// response. See TrialService / kTrialEndTime.
  final String? datachar03;
  final String accesscode;
  final String status;

  factory DeviceVerificationDataModel.fromJson(Map<String, dynamic> json) {
    return DeviceVerificationDataModel(
      companyId: json['company_id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      datachar01: json['datachar01']?.toString() ?? '',
      datachar02: json['datachar02']?.toString() ?? '',
      datachar03: json['datachar03']?.toString(),
      accesscode: json['accesscode']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_id': companyId,
      'code': code,
      'datachar01': datachar01,
      'datachar02': datachar02,
      if (datachar03 != null) 'datachar03': datachar03,
      'accesscode': accesscode,
      'status': status,
    };
  }
}
