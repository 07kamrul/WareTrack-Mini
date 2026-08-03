import 'package:path/path.dart' as p;
import 'package:waretrack_mini/core/database/table_names.dart';
import 'package:waretrack_mini/core/models/completed_work_models.dart';
import 'package:waretrack_mini/data/models/receiving_completed_work.dart';
import 'package:waretrack_mini/data/models/receiving_inspection_item.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class AppDatabase {
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  });

  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  });

  Future<int> delete(String table, {String? where, List<Object?>? whereArgs});

  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  });

  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]);

  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action, {
    bool? exclusive,
  });

  Future<void> saveCompletedWork({
    required String slipNumber,
    required List<ReceivingInspectionItem> items,
    required InspectionWorkType workType,
    required String userId,
  });

  Future<List<CompletedOrderRecord>> readCompletedWorks({
    required InspectionWorkType workType,
  });

  Future<List<CompletedItemRecord>> readCompletedWorkDetails(
    String slipNumber, {
    required InspectionWorkType workType,
  });

  Future<void> deleteCompletedWork(
    String slipNumber, {
    required InspectionWorkType workType,
  });

  /// Marks a completed work order as successfully sent so the "sent" status
  /// persists across app restarts.
  Future<void> markCompletedWorkSent(
    String slipNumber, {
    required InspectionWorkType workType,
  });
}

final class SqfliteAppDatabase implements AppDatabase {
  Database? _database;

  static const int databaseVersion = 9;
  static const String databaseName = 'smartphone_handy_app.db';

  static const List<InspectionWorkType> _workTypes = [
    InspectionWorkType.receiving,
    InspectionWorkType.shipping,
    InspectionWorkType.stocking,
    InspectionWorkType.inventory,
  ];

  Future<Database> get _db async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final dbPath = await getDatabasesPath();
    final database = await openDatabase(
      p.join(dbPath, databaseName),
      version: databaseVersion,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 5) {
          await _migrateToVersion5(db);
        }
        if (oldVersion < 6) {
          await _migrateToVersion6(db);
        }
        if (oldVersion < 7) {
          await _migrateToVersion7(db);
        }
        if (oldVersion < 8) {
          await _migrateToVersion8(db);
        }
        if (oldVersion < 9) {
          await _migrateToVersion9(db);
        }
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );

    _database = database;
    return database;
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final database = await _db;
    return database.insert(
      table,
      values,
      nullColumnHack: nullColumnHack,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final database = await _db;
    return database.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final database = await _db;
    return database.delete(table, where: where, whereArgs: whereArgs);
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final database = await _db;
    return database.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final database = await _db;
    return database.rawQuery(sql, arguments);
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action, {
    bool? exclusive,
  }) async {
    final database = await _db;
    return database.transaction(action, exclusive: exclusive);
  }

  Future<void> _createTables(DatabaseExecutor db) async {
    for (final workType in _workTypes) {
      await _createOrderTable(db, workType);
      await _createDetailsTable(db, workType);
    }
  }

  Future<void> _createOrderTable(
    DatabaseExecutor db,
    InspectionWorkType workType,
  ) async {
    final shelfNumberColumn = _usesShelfStorage(workType)
        ? 'shelf_number TEXT NOT NULL,'
        : '';
    await db.execute('''
CREATE TABLE IF NOT EXISTS ${AppTables.completedOrders(workType)} (
  slip_number TEXT PRIMARY KEY,
  $shelfNumberColumn
  total_quantity INTEGER NOT NULL DEFAULT 0,
  completed_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  user_id TEXT NOT NULL DEFAULT '',
  is_sent INTEGER NOT NULL DEFAULT 0
)
''');
  }

  Future<void> _createDetailsTable(
    DatabaseExecutor db,
    InspectionWorkType workType,
  ) async {
    final orderTable = AppTables.completedOrders(workType);
    final detailTable = AppTables.completedOrderDetails(workType);
    final shelfNumberColumn = _usesShelfStorage(workType)
        ? 'shelf_number TEXT NOT NULL,'
        : '';
    final uniqueColumns = _usesShelfStorage(workType)
        ? 'slip_number, shelf_number, code'
        : 'slip_number, code';
    final scannedAtColumn = _usesShelfStorage(workType)
        ? 'scanned_at'
        : 'created_at';
    await db.execute('''
CREATE TABLE IF NOT EXISTS $detailTable (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  slip_number TEXT NOT NULL,
  $shelfNumberColumn
  code TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  $scannedAtColumn TEXT NOT NULL,
  user_id TEXT NOT NULL DEFAULT '',
  UNIQUE($uniqueColumns),
  FOREIGN KEY(slip_number)
    REFERENCES $orderTable(slip_number)
    ON DELETE CASCADE
)
''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${detailTable}_slip '
      'ON $detailTable(slip_number)',
    );
  }

  Future<void> _migrateToVersion5(Database db) async {
    await db.transaction((txn) async {
      final hadOldOrders = await _tableExists(
        txn,
        AppTables.receivingCompletedOrders,
      );
      final hadOldDetails = await _tableExists(
        txn,
        AppTables.receivingCompletedOrderDetails,
      );

      if (hadOldOrders) {
        await txn.execute(
          'ALTER TABLE ${AppTables.receivingCompletedOrders} '
          'RENAME TO receiving_completed_orders_old',
        );
      }
      if (hadOldDetails) {
        await txn.execute(
          'ALTER TABLE ${AppTables.receivingCompletedOrderDetails} '
          'RENAME TO receiving_completed_order_details_old',
        );
      }

      await _createTables(txn);

      if (hadOldOrders) {
        await _migrateOldOrders(txn);
        await txn.execute('DROP TABLE receiving_completed_orders_old');
      }
      if (hadOldDetails) {
        await _migrateOldDetails(txn);
        await txn.execute('DROP TABLE receiving_completed_order_details_old');
      }
    });
  }

  Future<void> _migrateOldOrders(DatabaseExecutor db) async {
    final columns = await db.rawQuery(
      'PRAGMA table_info(receiving_completed_orders_old)',
    );
    final hasWorkType = columns.any((column) => column['name'] == 'work_type');

    for (final workType in _workTypes) {
      final tableName = AppTables.completedOrders(workType);
      final shelfNumberColumn = _usesShelfStorage(workType)
          ? '  shelf_number,\n'
          : '';
      final shelfNumberValue = _usesShelfStorage(workType)
          ? '  slip_number,\n'
          : '';
      final whereClause = _oldWorkTypeWhereClause(
        workType: workType,
        hasWorkType: hasWorkType,
      );

      await db.execute('''
INSERT OR REPLACE INTO $tableName (
  slip_number,
$shelfNumberColumn  total_quantity,
  completed_at,
  updated_at,
  user_id
)
SELECT
  slip_number,
$shelfNumberValue  MAX(total_quantity) AS total_quantity,
  MAX(completed_at) AS completed_at,
  MAX(updated_at) AS updated_at,
  '' AS user_id
FROM receiving_completed_orders_old
$whereClause
GROUP BY slip_number
''');
    }
  }

  Future<void> _migrateOldDetails(DatabaseExecutor db) async {
    final columns = await db.rawQuery(
      'PRAGMA table_info(receiving_completed_order_details_old)',
    );
    final hasWorkType = columns.any((column) => column['name'] == 'work_type');
    final hasUserId = columns.any((column) => column['name'] == 'user_id');
    final userIdExpression = hasUserId ? 'MAX(user_id)' : "''";

    for (final workType in _workTypes) {
      final tableName = AppTables.completedOrderDetails(workType);
      final shelfNumberColumn = _usesShelfStorage(workType)
          ? '  shelf_number,\n'
          : '';
      final shelfNumberValue = _usesShelfStorage(workType)
          ? '  slip_number,\n'
          : '';
      final scannedAtColumn = _usesShelfStorage(workType)
          ? 'scanned_at'
          : 'created_at';
      final sourceWhereClause = _oldWorkTypeWhereClause(
        workType: workType,
        hasWorkType: hasWorkType,
      );
      final whereClause =
          '$sourceWhereClause${sourceWhereClause == 'WHERE 1 = 0' ? '' : '''
${sourceWhereClause.isEmpty ? 'WHERE' : 'AND'} EXISTS (
  SELECT 1
  FROM ${AppTables.completedOrders(workType)} orders
  WHERE orders.slip_number =
    receiving_completed_order_details_old.slip_number
)
'''}';

      await db.execute('''
INSERT OR REPLACE INTO $tableName (
  slip_number,
$shelfNumberColumn  code,
  quantity,
  $scannedAtColumn,
  user_id
)
SELECT
  slip_number,
$shelfNumberValue  code,
  SUM(quantity) AS quantity,
  MAX(created_at) AS created_at,
  $userIdExpression AS user_id
FROM receiving_completed_order_details_old
$whereClause
GROUP BY slip_number, code
''');
    }
  }

  Future<void> _migrateToVersion6(Database db) async {
    await db.transaction((txn) async {
      for (final workType in _workTypes) {
        await _addTextColumnIfMissing(
          txn,
          tableName: AppTables.completedOrders(workType),
          columnName: 'user_id',
        );
        await _addTextColumnIfMissing(
          txn,
          tableName: AppTables.completedOrderDetails(workType),
          columnName: 'user_id',
        );
      }
    });
  }

  Future<void> _migrateToVersion7(Database db) async {
    await db.transaction((txn) async {
      final orderTable = AppTables.stockingCompletedOrders;
      await _addTextColumnIfMissing(
        txn,
        tableName: orderTable,
        columnName: 'shelf_number',
      );
      await txn.execute(
        'UPDATE $orderTable SET shelf_number = slip_number '
        "WHERE shelf_number = ''",
      );

      final detailTable = AppTables.stockingCompletedOrderDetails;
      const legacyTable = 'stocking_completed_order_details';
      final hasCurrentTable = await _tableExists(txn, detailTable);
      final hasLegacyTable = await _tableExists(txn, legacyTable);

      if (!hasCurrentTable && !hasLegacyTable) {
        await _createDetailsTable(txn, InspectionWorkType.stocking);
        return;
      }

      if (hasCurrentTable) {
        final columns = await txn.rawQuery('PRAGMA table_info($detailTable)');
        if (columns.any((column) => column['name'] == 'shelf_number')) {
          return;
        }
      }

      final sourceTable = hasLegacyTable ? legacyTable : detailTable;
      const oldTable = 'stocking_completed_items_v6';
      if (sourceTable == detailTable) {
        await txn.execute('ALTER TABLE $detailTable RENAME TO $oldTable');
      }
      await _createDetailsTable(txn, InspectionWorkType.stocking);
      final migratedSource = sourceTable == detailTable
          ? oldTable
          : sourceTable;
      final sourceColumns = await txn.rawQuery(
        'PRAGMA table_info($migratedSource)',
      );
      final userIdExpression =
          sourceColumns.any((column) => column['name'] == 'user_id')
          ? 'user_id'
          : "''";
      await txn.execute('''
INSERT OR REPLACE INTO $detailTable (
  slip_number,
  shelf_number,
  code,
  quantity,
  scanned_at,
  user_id
)
SELECT
  slip_number,
  slip_number,
  code,
  quantity,
  created_at,
  $userIdExpression
FROM $migratedSource
''');
      await txn.execute('DROP TABLE $migratedSource');
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_${detailTable}_slip '
        'ON $detailTable(slip_number)',
      );
      if (hasCurrentTable && hasLegacyTable) {
        await txn.execute('DROP TABLE $legacyTable');
      }
    });
  }

  Future<void> _migrateToVersion8(Database db) async {
    await db.transaction((txn) async {
      await _migrateShelfStorageTables(txn, InspectionWorkType.inventory);
    });
  }

  Future<void> _migrateToVersion9(Database db) async {
    await db.transaction((txn) async {
      for (final workType in _workTypes) {
        await _addIntColumnIfMissing(
          txn,
          tableName: AppTables.completedOrders(workType),
          columnName: 'is_sent',
        );
      }
    });
  }

  Future<void> _migrateShelfStorageTables(
    DatabaseExecutor txn,
    InspectionWorkType workType,
  ) async {
    final orderTable = AppTables.completedOrders(workType);
    await _addTextColumnIfMissing(
      txn,
      tableName: orderTable,
      columnName: 'shelf_number',
    );
    await txn.execute(
      'UPDATE $orderTable SET shelf_number = slip_number '
      "WHERE shelf_number = ''",
    );

    final detailTable = AppTables.completedOrderDetails(workType);
    if (!await _tableExists(txn, detailTable)) {
      await _createDetailsTable(txn, workType);
      return;
    }

    final columns = await txn.rawQuery('PRAGMA table_info($detailTable)');
    if (columns.any((column) => column['name'] == 'shelf_number')) {
      return;
    }

    final oldTable = '${detailTable}_v7';
    await txn.execute('ALTER TABLE $detailTable RENAME TO $oldTable');
    await _createDetailsTable(txn, workType);
    final oldColumns = await txn.rawQuery('PRAGMA table_info($oldTable)');
    final userIdExpression =
        oldColumns.any((column) => column['name'] == 'user_id')
        ? 'user_id'
        : "''";
    await txn.execute('''
INSERT OR REPLACE INTO $detailTable (
  slip_number,
  shelf_number,
  code,
  quantity,
  scanned_at,
  user_id
)
SELECT
  slip_number,
  slip_number,
  code,
  quantity,
  created_at,
  $userIdExpression
FROM $oldTable
''');
    await txn.execute('DROP TABLE $oldTable');
  }

  Future<void> _addTextColumnIfMissing(
    DatabaseExecutor db, {
    required String tableName,
    required String columnName,
  }) async {
    if (!await _tableExists(db, tableName)) {
      return;
    }

    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    final hasColumn = columns.any((column) => column['name'] == columnName);
    if (hasColumn) {
      return;
    }

    await db.execute(
      "ALTER TABLE $tableName ADD COLUMN $columnName TEXT NOT NULL DEFAULT ''",
    );
  }

  Future<void> _addIntColumnIfMissing(
    DatabaseExecutor db, {
    required String tableName,
    required String columnName,
  }) async {
    if (!await _tableExists(db, tableName)) {
      return;
    }

    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    final hasColumn = columns.any((column) => column['name'] == columnName);
    if (hasColumn) {
      return;
    }

    await db.execute(
      'ALTER TABLE $tableName ADD COLUMN $columnName INTEGER NOT NULL DEFAULT 0',
    );
  }

  Future<bool> _tableExists(DatabaseExecutor db, String tableName) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      [tableName],
    );
    return rows.isNotEmpty;
  }

  @override
  Future<void> saveCompletedWork({
    required String slipNumber,
    required List<ReceivingInspectionItem> items,
    required InspectionWorkType workType,
    required String userId,
  }) async {
    final normalizedSlip = slipNumber.trim();
    final normalizedUserId = userId.trim();
    final orderTable = AppTables.completedOrders(workType);
    final detailTable = AppTables.completedOrderDetails(workType);
    final detailsByCode = <(String, String), int>{};

    for (final item in items) {
      if ((!_usesShelfStorage(workType) && item.slipNumber != normalizedSlip) ||
          item.inspectedQuantity < 0 ||
          (!_usesShelfStorage(workType) && item.inspectedQuantity == 0)) {
        continue;
      }

      final shelfNumber = item.slipNumber.trim();
      final code = _usesShelfStorage(workType)
          ? item.barcode.trim()
          : item.barcode.trim().toUpperCase();
      if (shelfNumber.isEmpty || code.isEmpty) {
        continue;
      }

      final detailKey = (shelfNumber, code);
      detailsByCode.update(
        detailKey,
        (quantity) => quantity + item.inspectedQuantity,
        ifAbsent: () => item.inspectedQuantity,
      );
    }

    final localNow = DateTime.now();
    final now = localNow.toUtc().toIso8601String();
    final totalQuantity = detailsByCode.values.fold<int>(
      0,
      (total, quantity) => total + quantity,
    );

    await transaction((txn) async {
      final persistedSlip = _usesShelfStorage(workType)
          ? await _nextShelfStorageSlipNumber(
              txn,
              orderTable: orderTable,
              localNow: localNow,
              menuName: workType.menuName,
            )
          : normalizedSlip;

      await txn.insert(orderTable, <String, Object?>{
        'slip_number': persistedSlip,
        'total_quantity': totalQuantity,
        'completed_at': now,
        'updated_at': now,
        'user_id': normalizedUserId,
        if (_usesShelfStorage(workType)) 'shelf_number': normalizedSlip,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await txn.delete(
        detailTable,
        where: 'slip_number = ?',
        whereArgs: [persistedSlip],
      );

      for (final entry in detailsByCode.entries) {
        final values = <String, Object?>{
          'slip_number': persistedSlip,
          'code': entry.key.$2,
          'quantity': entry.value,
          _usesShelfStorage(workType) ? 'scanned_at' : 'created_at': now,
          'user_id': normalizedUserId,
        };
        if (_usesShelfStorage(workType)) {
          values['shelf_number'] = entry.key.$1;
        }
        await txn.insert(
          detailTable,
          values,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Builds the shelf-style slip number while holding the save transaction.
  ///
  /// The timestamp format only has one-second precision. If another save has
  /// already claimed the current second, move to the next free second so the
  /// primary key remains unique without changing the required format.
  static Future<String> _nextShelfStorageSlipNumber(
    DatabaseExecutor db, {
    required String orderTable,
    required DateTime localNow,
    required String menuName,
  }) async {
    var candidateTime = localNow;
    while (true) {
      final candidate = _formatShelfStorageSlipNumber(
        candidateTime,
        menuName: menuName,
      );
      final existing = await db.query(
        orderTable,
        columns: const ['slip_number'],
        where: 'slip_number = ?',
        whereArgs: [candidate],
        limit: 1,
      );
      if (existing.isEmpty) {
        return candidate;
      }
      candidateTime = candidateTime.add(const Duration(seconds: 1));
    }
  }

  static String _formatShelfStorageSlipNumber(
    DateTime localDateTime, {
    required String menuName,
  }) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '$menuName'
        '${localDateTime.year.toString().padLeft(4, '0')}'
        '${twoDigits(localDateTime.month)}'
        '${twoDigits(localDateTime.day)}'
        '${twoDigits(localDateTime.hour)}'
        '${twoDigits(localDateTime.minute)}'
        '${twoDigits(localDateTime.second)}';
  }

  @override
  Future<List<CompletedOrderRecord>> readCompletedWorks({
    required InspectionWorkType workType,
  }) async {
    final orderTable = AppTables.completedOrders(workType);
    final detailTable = AppTables.completedOrderDetails(workType);
    final rows = await rawQuery('''
SELECT
  orders.slip_number,
  orders.total_quantity,
  orders.completed_at,
  orders.is_sent,
  COUNT(details.id) AS total_items
FROM $orderTable orders
LEFT JOIN $detailTable details
  ON details.slip_number = orders.slip_number
GROUP BY
  orders.slip_number,
  orders.total_quantity,
  orders.completed_at,
  orders.updated_at,
  orders.is_sent
ORDER BY orders.updated_at DESC
''');

    return [
      for (final row in rows)
        ReceivingCompletedWork(
          slipNumber: row['slip_number']! as String,
          totalItems: row['total_items']! as int,
          totalQuantity: row['total_quantity']! as int,
          completedAt: DateTime.parse(row['completed_at']! as String),
          workType: workType,
          isSent: ((row['is_sent'] as int?) ?? 0) != 0,
        ),
    ];
  }

  @override
  Future<List<CompletedItemRecord>> readCompletedWorkDetails(
    String slipNumber, {
    required InspectionWorkType workType,
  }) async {
    final normalizedSlip = slipNumber.trim();
    final detailTable = AppTables.completedOrderDetails(workType);
    final rows = await query(
      detailTable,
      where: 'slip_number = ?',
      whereArgs: [normalizedSlip],
      orderBy: 'id ASC',
    );

    return [
      for (final row in rows)
        ReceivingCompletedWorkDetail(
          slipNumber: _usesShelfStorage(workType)
              ? row['shelf_number']! as String
              : row['slip_number']! as String,
          code: row['code']! as String,
          quantity: row['quantity']! as int,
          createdAt: DateTime.parse(
            row[_usesShelfStorage(workType) ? 'scanned_at' : 'created_at']!
                as String,
          ),
          userId: row['user_id']! as String,
          workType: workType,
        ),
    ];
  }

  @override
  Future<void> deleteCompletedWork(
    String slipNumber, {
    required InspectionWorkType workType,
  }) async {
    final normalizedSlip = slipNumber.trim();
    final orderTable = AppTables.completedOrders(workType);
    final detailTable = AppTables.completedOrderDetails(workType);

    await transaction((txn) async {
      await txn.delete(
        detailTable,
        where: 'slip_number = ?',
        whereArgs: [normalizedSlip],
      );
      await txn.delete(
        orderTable,
        where: 'slip_number = ?',
        whereArgs: [normalizedSlip],
      );
    });
  }

  @override
  Future<void> markCompletedWorkSent(
    String slipNumber, {
    required InspectionWorkType workType,
  }) async {
    final normalizedSlip = slipNumber.trim();
    if (normalizedSlip.isEmpty) {
      return;
    }

    await update(
      AppTables.completedOrders(workType),
      <String, Object?>{'is_sent': 1},
      where: 'slip_number = ?',
      whereArgs: [normalizedSlip],
    );
  }

  static String _oldWorkTypeWhereClause({
    required InspectionWorkType workType,
    required bool hasWorkType,
  }) {
    if (!hasWorkType) {
      return workType == InspectionWorkType.receiving ? '' : 'WHERE 1 = 0';
    }

    final values = switch (workType) {
      InspectionWorkType.receiving => ['receiving'],
      InspectionWorkType.shipping => ['shipping'],
      InspectionWorkType.stocking => [
        'stocking',
        'shelfPlacement',
        'shelf_placement',
      ],
      InspectionWorkType.inventory => ['inventory', 'stocktaking'],
    };
    return 'WHERE COALESCE(work_type, \'receiving\') '
        'IN (${values.map((value) => "'$value'").join(', ')})';
  }

  static bool _usesShelfStorage(InspectionWorkType workType) {
    return workType == InspectionWorkType.stocking ||
        workType == InspectionWorkType.inventory;
  }
}
