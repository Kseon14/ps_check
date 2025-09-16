import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';

import 'ga.dart';
import 'hive_wrapper.dart'; // for migration only; you can remove after

class SqlWrapper {
  static final SqlWrapper _instance = SqlWrapper._internal();
  factory SqlWrapper.instance() => _instance;
  SqlWrapper._internal();

  final _lock = Lock();
  Database? _db;

  Future<Database> _openDb() async {
    if (_db != null) return _db!;

    final dbDir = await getDatabasesPath();
    await Directory(dbDir).create(recursive: true);
    final dbPath = p.join(dbDir, 'ps_check.db');

    _db = await openDatabase(
      dbPath,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');

        // ✅ Use rawQuery for PRAGMAs that return rows (avoids "not an error")
        try {
          // Check current mode
          final current = await db.rawQuery('PRAGMA journal_mode;');
          final mode = (current.first.values.first as String).toLowerCase();
          if (mode != 'wal') {
            await db.rawQuery('PRAGMA journal_mode = WAL;');
          }
        } catch (e) {
          // If anything odd happens, just continue with default journal mode
          debugPrint('WAL enable skipped: $e');
        }

        // Also set synchronous level via rawQuery (safe on iOS)
        await db.rawQuery('PRAGMA synchronous = NORMAL;');
      },
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE game_attributes (
          gameId TEXT PRIMARY KEY,
          type TEXT NOT NULL,
          imgUrl TEXT,
          discountedValue INTEGER,
          url TEXT NOT NULL,
          conceptId TEXT,
          addon INTEGER NOT NULL DEFAULT 0,
          releaseDate TEXT
        );
      ''');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_game_type ON game_attributes(type);');
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          // Add the new column if coming from v1
          await db.execute('ALTER TABLE game_attributes ADD COLUMN releaseDate TEXT;');
        }
      },
    );
    return _db!;
  }


  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  // ---------- CRUD (parity with HiveWrapper) ----------

  Future<void> putIfNotExist(GameAttributes gm) async {
    final db = await _openDb();
    await _lock.synchronized(() async {
      await db.insert(
        'game_attributes',
        gm.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore, // do nothing if exists
      );
    });
  }

  Future<void> save(GameAttributes gm) async {
    final db = await _openDb();
    await _lock.synchronized(() async {
      // Upsert behavior
      await db.insert(
        'game_attributes',
        gm.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<List<GameAttributes>> readFromDb() async {
    final db = await _openDb();
    final rows = await db.query('game_attributes', orderBy: 'rowid DESC');
    return rows.map(GameAttributesSql.fromMap).toList();
  }

  Future<GameAttributes?> getByIdFromDb(String? id) async {
    final db = await _openDb();
    final rows = await db.query('game_attributes',
        where: 'gameId = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return GameAttributesSql.fromMap(rows.first);
  }

  Future<void> removeFromDb(String id) async {
    final db = await _openDb();
    await _lock.synchronized(() async {
      await db.delete('game_attributes', where: 'gameId = ?', whereArgs: [id]);
    });
  }

  Future<void> flush() async {
    // no-op in SQLite; transactions already commit
  }

  // ---------- One-time Hive -> SQLite migration ----------

  Future<void> migrateFromHiveIfNeeded(HiveWrapper hive) async {
    final db = await _openDb();

    // Quick check: if SQLite already has data, skip migration.
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM game_attributes'),
    );
    if ((count ?? 0) > 0) {
      return;
    }

    // Read from Hive
    await hive.init();
    final List<GameAttributes> hiveRows =
        (await hive.readFromDb())?.cast<GameAttributes>() ?? const [];

    if (hiveRows.isEmpty) {
      // Nothing to migrate
      await hive.close();
      return;
    }

    // Insert in a single transaction (fast + atomic)
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final gm in hiveRows) {
        batch.insert(
          'game_attributes',
          gm.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    });

    // Close Hive, optionally delete Hive box file later
    await hive.close();
    // Optional: after you ship the migration & verify, remove Hive files.
  }
}
