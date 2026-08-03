/// Parses the trial-verification data the server returns from
/// `POST /device-verify` on the trial build.
///
/// Confirmed contract (the endpoint reuses the generic device-verification
/// response shape — there is no dedicated `trial_status` field):
/// ```json
/// { "status": true, "message": "This is Verified Device",
///   "data": { "status": "1", "datachar03": "2026-07-28 20:55:34", ... } }
/// ```
/// `data.status` is the explicit active/expired signal ("0" is the only
/// expired value the backend sends; anything else, including a missing
/// field, is treated as active so an unrelated/absent field never
/// spuriously locks out a verified device). `data.datachar03` is the trial
/// expiration timestamp; `expire_date` / `trial_expire_date` are also
/// accepted in case the backend later adds a dedicated field.
class TrialStatusModel {
  const TrialStatusModel({
    required this.isActive,
    required this.expireDate,
    required this.message,
  });

  final bool isActive;
  final DateTime? expireDate;
  final String message;

  factory TrialStatusModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final Map<String, dynamic> dataJson = data is Map<String, dynamic>
        ? data
        : const <String, dynamic>{};

    final status = dataJson['status']?.toString();
    final dateValue =
        dataJson['expire_date']?.toString() ??
        dataJson['trial_expire_date']?.toString() ??
        dataJson['datachar03']?.toString();

    return TrialStatusModel(
      isActive: status != '0',
      expireDate: dateValue == null ? null : DateTime.tryParse(dateValue),
      message: json['message']?.toString() ?? '',
    );
  }
}
