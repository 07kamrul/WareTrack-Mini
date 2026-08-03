import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/data/models/trial_status_model.dart';

void main() {
  group('TrialStatusModel.fromJson', () {
    test('parses the real backend response as active', () {
      final json = {
        'message': 'This is Verified Device',
        'status': true,
        'data': {
          'company_id': null,
          'code': null,
          'datachar01': '標準',
          'datachar02': 'Ver 1.0',
          'datachar03': '2026-07-28 20:55:34',
          'created_at': '2026-07-25 20:55:34',
          'accesscode': '83948291',
          'status': '1',
        },
      };

      final model = TrialStatusModel.fromJson(json);

      expect(model.isActive, isTrue);
      expect(model.expireDate, DateTime.parse('2026-07-28 20:55:34'));
    });

    test('treats data.status "0" as expired', () {
      final json = {
        'message': 'expired',
        'status': true,
        'data': {'status': '0', 'datachar03': '2026-07-20 00:00:00'},
      };

      final model = TrialStatusModel.fromJson(json);

      expect(model.isActive, isFalse);
    });

    test('treats a missing data.status as active, not expired', () {
      final json = {
        'message': 'ok',
        'status': true,
        'data': <String, dynamic>{},
      };

      final model = TrialStatusModel.fromJson(json);

      expect(model.isActive, isTrue);
      expect(model.expireDate, isNull);
    });

    test('prefers an explicit expire_date over datachar03', () {
      final json = {
        'message': 'ok',
        'status': true,
        'data': {
          'status': '1',
          'expire_date': '2026-09-01',
          'datachar03': '2026-07-28 20:55:34',
        },
      };

      final model = TrialStatusModel.fromJson(json);

      expect(model.expireDate, DateTime.parse('2026-09-01'));
    });
  });
}
