import 'package:waretrack_mini/data/models/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.code,
    required super.companyId,
    required super.status,
    required super.kcode1,
    required super.accesscode,
    required super.datachar01,
    required super.datachar02,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      companyId: _parseInt(json['company_id']),
      code: _parseInt(json['code']),
      datachar01: json['datachar01']?.toString() ?? '',
      datachar02: json['datachar02']?.toString() ?? '',
      accesscode: _parseInt(json['accesscode']),
      status: _parseInt(json['status']),
      kcode1: _parseInt(json['kcode2']),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      "code": code,
      "companyId": companyId,
      "status": status,
      "kcode1": kcode1,
      "accesscode": accesscode,
      "datachar01": datachar01,
      "datachar02": datachar02,
    };
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
