import 'dart:convert';

import 'package:waretrack_mini/core/database/app_database.dart';
import 'package:waretrack_mini/core/constants/verification_storage_keys.dart';
import 'package:waretrack_mini/core/models/completed_work_models.dart';
import 'package:waretrack_mini/core/models/inspection_work_type.dart';
import 'package:waretrack_mini/core/services/storage_service.dart';
import 'package:waretrack_mini/data/models/receiving_inspection_item.dart';
import 'package:waretrack_mini/data/local/receiving_repository.dart';

final class ReceivingRepositoryImpl implements ReceivingRepository {
  const ReceivingRepositoryImpl({
    required LocalStorage localStorage,
    required AppDatabase database,
    InspectionWorkType workType = InspectionWorkType.receiving,
  }) : _localStorage = localStorage,
       _database = database,
       _workType = workType;

  static const String _receivingStorageKey = 'receiving_inspections';

  final LocalStorage _localStorage;
  final AppDatabase _database;
  final InspectionWorkType _workType;

  String get _storageKey => _workType == InspectionWorkType.receiving
      ? _receivingStorageKey
      : '${_workType.name}_inspections';

  @override
  Future<List<ReceivingInspectionItem>> recordInspection({
    required String slipNumber,
    required String barcode,
    required int quantity,
  }) async {
    final normalizedSlip = _normalizeSlip(slipNumber);
    final normalizedBarcode = _normalizeBarcode(barcode);

    if (normalizedSlip.isEmpty) {
      throw ReceivingRepositoryException.invalidSlip;
    }

    if (normalizedBarcode.isEmpty) {
      throw ReceivingRepositoryException.invalidBarcode;
    }

    final items = await _readItems();
    ReceivingInspectionItem? scannedItem;
    final remainingItems = <ReceivingInspectionItem>[];

    for (final item in items) {
      if (item.slipNumber == normalizedSlip &&
          item.barcode == normalizedBarcode) {
        final nextQuantity = item.inspectedQuantity + quantity;
        scannedItem = item.copyWith(
          inspectedQuantity: nextQuantity,
          status: nextQuantity >= item.expectedQuantity
              ? ReceivingInspectionStatus.completed
              : ReceivingInspectionStatus.pending,
        );
        continue;
      }

      remainingItems.add(item);
    }

    scannedItem ??= ReceivingInspectionItem(
      id: _newInspectionId(normalizedSlip, normalizedBarcode),
      slipNumber: normalizedSlip,
      barcode: normalizedBarcode,
      productName: '',
      expectedQuantity: quantity,
      inspectedQuantity: quantity,
      status: ReceivingInspectionStatus.completed,
    );

    final updatedItems = <ReceivingInspectionItem>[
      scannedItem,
      ...remainingItems,
    ];

    await _writeItems(updatedItems);
    return updatedItems
        .where((item) => item.slipNumber == normalizedSlip)
        .toList(growable: false);
  }

  @override
  Future<List<ReceivingInspectionItem>> undoLastScan({
    required String slipNumber,
    required String barcode,
    required int previousQuantity,
  }) async {
    final normalizedSlip = _normalizeSlip(slipNumber);
    final normalizedBarcode = _normalizeBarcode(barcode);

    if (normalizedSlip.isEmpty) {
      throw ReceivingRepositoryException.invalidSlip;
    }

    if (normalizedBarcode.isEmpty) {
      throw ReceivingRepositoryException.invalidBarcode;
    }

    if (previousQuantity < 0) {
      throw ReceivingRepositoryException.invalidBarcode;
    }

    final items = await _readItems();
    var didUndoScan = false;
    final updatedItems = [
      for (final item in items)
        if (item.slipNumber == normalizedSlip &&
            item.barcode == normalizedBarcode &&
            item.inspectedQuantity > previousQuantity)
          () {
            didUndoScan = true;
            return item.copyWith(
              inspectedQuantity: previousQuantity,
              status: previousQuantity >= item.expectedQuantity
                  ? ReceivingInspectionStatus.completed
                  : ReceivingInspectionStatus.pending,
            );
          }()
        else
          item,
    ];

    if (!didUndoScan) {
      throw ReceivingRepositoryException.invalidBarcode;
    }

    await _writeItems(updatedItems);
    return updatedItems
        .where((item) => item.slipNumber == normalizedSlip)
        .toList(growable: false);
  }

  @override
  Future<List<CompletedOrderRecord>> readCompletedWorks() {
    return _database.readCompletedWorks(workType: _workType);
  }

  @override
  Future<List<CompletedItemRecord>> readCompletedWorkDetails(
    String slipNumber,
  ) async {
    final normalizedSlip = _normalizeSlip(slipNumber);

    if (normalizedSlip.isEmpty) {
      throw ReceivingRepositoryException.invalidSlip;
    }

    return _database.readCompletedWorkDetails(
      normalizedSlip,
      workType: _workType,
    );
  }

  @override
  Future<void> deleteCompletedWork(String slipNumber) async {
    final normalizedSlip = _normalizeSlip(slipNumber);

    if (normalizedSlip.isEmpty) {
      throw ReceivingRepositoryException.invalidSlip;
    }

    await _database.deleteCompletedWork(normalizedSlip, workType: _workType);

    final items = await _readItems();
    await _writeItems([
      for (final item in items)
        if (item.slipNumber != normalizedSlip) item,
    ]);
  }

  @override
  Future<List<ReceivingInspectionItem>> readCompletedWorkItems(
    String slipNumber,
  ) async {
    final normalizedSlip = _normalizeSlip(slipNumber);

    if (normalizedSlip.isEmpty) {
      throw ReceivingRepositoryException.invalidSlip;
    }

    final details = await _database.readCompletedWorkDetails(
      normalizedSlip,
      workType: _workType,
    );
    final savedItems = [
      for (final detail in details)
        ReceivingInspectionItem(
          id: _savedInspectionId(normalizedSlip, detail.code),
          slipNumber: normalizedSlip,
          barcode: detail.code,
          productName: '',
          expectedQuantity: detail.quantity,
          inspectedQuantity: detail.quantity,
          status: ReceivingInspectionStatus.completed,
        ),
    ];
    final existingItems = await _readItems();
    final updatedItems = [
      for (final item in existingItems)
        if (item.slipNumber != normalizedSlip) item,
      ...savedItems,
    ];

    await _writeItems(updatedItems);
    return savedItems;
  }

  @override
  Future<List<ReceivingInspectionItem>> completeWork(String slipNumber) async {
    final normalizedSlip = _normalizeSlip(slipNumber);

    if (normalizedSlip.isEmpty) {
      throw ReceivingRepositoryException.invalidSlip;
    }

    final items = await _readItems();

    final updatedItems = [
      for (final item in items)
        if (item.slipNumber == normalizedSlip) ...[
          () {
            return item.copyWith(status: ReceivingInspectionStatus.completed);
          }(),
        ] else
          item,
    ];

    await _writeItems(updatedItems);
    final slipItems = updatedItems
        .where((item) => item.slipNumber == normalizedSlip)
        .toList(growable: false);
    final userId = (await _localStorage.readString(kCode))?.trim() ?? '';
    await _database.saveCompletedWork(
      slipNumber: normalizedSlip,
      items: slipItems,
      workType: _workType,
      userId: userId,
    );
    return slipItems;
  }

  @override
  Future<List<ReceivingInspectionItem>> resetInspectionItem({
    required String slipNumber,
    required String itemId,
  }) async {
    final normalizedSlip = _normalizeSlip(slipNumber);
    final normalizedItemId = itemId.trim();

    if (normalizedSlip.isEmpty) {
      throw ReceivingRepositoryException.invalidSlip;
    }

    final items = await _readItems();
    var didFindItem = false;

    final updatedItems = [
      for (final item in items)
        if (item.slipNumber == normalizedSlip && item.id == normalizedItemId)
          () {
            didFindItem = true;
            return item.copyWith(
              inspectedQuantity: 0,
              status: ReceivingInspectionStatus.pending,
            );
          }()
        else
          item,
    ];

    if (!didFindItem) {
      throw ReceivingRepositoryException.invalidBarcode;
    }

    await _writeItems(updatedItems);
    return updatedItems
        .where((item) => item.slipNumber == normalizedSlip)
        .toList(growable: false);
  }

  @override
  Future<List<ReceivingInspectionItem>> deleteInspectionItem({
    required String slipNumber,
    required String itemId,
  }) async {
    final normalizedSlip = _normalizeSlip(slipNumber);
    final normalizedItemId = itemId.trim();

    if (normalizedSlip.isEmpty) {
      throw ReceivingRepositoryException.invalidSlip;
    }

    final items = await _readItems();
    var didFindItem = false;
    final updatedItems = <ReceivingInspectionItem>[];

    for (final item in items) {
      if (item.slipNumber == normalizedSlip && item.id == normalizedItemId) {
        didFindItem = true;
        continue;
      }

      updatedItems.add(item);
    }

    if (!didFindItem) {
      throw ReceivingRepositoryException.invalidBarcode;
    }

    await _writeItems(updatedItems);
    return updatedItems
        .where((item) => item.slipNumber == normalizedSlip)
        .toList(growable: false);
  }

  Future<List<ReceivingInspectionItem>> _readItems() async {
    final jsonText = await _localStorage.readString(_storageKey);
    if (jsonText == null || jsonText.isEmpty) {
      return _seedItems;
    }

    final decoded = jsonDecode(jsonText) as List<dynamic>;
    return decoded
        .map((item) => _itemFromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> _writeItems(List<ReceivingInspectionItem> items) async {
    await _localStorage.writeString(
      _storageKey,
      jsonEncode(items.map(_itemToJson).toList(growable: false)),
    );
  }

  @override
  Future<void> discardTemporaryWork() => _writeItems(const []);

  static String _normalizeSlip(String value) => value.trim();

  static String _normalizeBarcode(String value) => value.trim();

  static String _newInspectionId(String slipNumber, String barcode) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return 'RCV-$slipNumber-$barcode-$timestamp';
  }

  static String _savedInspectionId(String slipNumber, String barcode) {
    return 'RCV-$slipNumber-$barcode-SAVED';
  }

  static Map<String, dynamic> _itemToJson(ReceivingInspectionItem item) {
    return {
      'id': item.id,
      'slipNumber': item.slipNumber,
      'barcode': item.barcode,
      'productName': item.productName,
      'expectedQuantity': item.expectedQuantity,
      'inspectedQuantity': item.inspectedQuantity,
      'status': item.status.name,
    };
  }

  static ReceivingInspectionItem _itemFromJson(Map<String, dynamic> json) {
    return ReceivingInspectionItem(
      id: json['id'] as String,
      slipNumber: json['slipNumber'] as String,
      barcode: json['barcode'] as String,
      productName: json['productName'] as String,
      expectedQuantity: json['expectedQuantity'] as int,
      inspectedQuantity: json['inspectedQuantity'] as int,
      status: json['status'] == ReceivingInspectionStatus.completed.name
          ? ReceivingInspectionStatus.completed
          : ReceivingInspectionStatus.pending,
    );
  }

  static const List<ReceivingInspectionItem> _seedItems = [
    ReceivingInspectionItem(
      id: 'RCV-1001-001',
      slipNumber: 'RCV-1001',
      barcode: '4901234567894',
      productName: 'Sample Item A',
      expectedQuantity: 12,
      inspectedQuantity: 0,
      status: ReceivingInspectionStatus.pending,
    ),
    ReceivingInspectionItem(
      id: 'RCV-1001-002',
      slipNumber: 'RCV-1001',
      barcode: 'COLGIS-A-002',
      productName: 'Sample Item B',
      expectedQuantity: 8,
      inspectedQuantity: 0,
      status: ReceivingInspectionStatus.pending,
    ),
    ReceivingInspectionItem(
      id: 'RCV-1002-001',
      slipNumber: 'RCV-1002',
      barcode: '4580000000011',
      productName: 'Sample Item C',
      expectedQuantity: 5,
      inspectedQuantity: 0,
      status: ReceivingInspectionStatus.pending,
    ),
  ];
}

enum ReceivingRepositoryException { invalidSlip, invalidBarcode }
