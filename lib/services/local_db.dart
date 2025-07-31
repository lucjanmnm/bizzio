import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/client.dart';
import '../models/project.dart';
import '../models/invoice.dart';

class LocalDb {
  LocalDb._privateConstructor();
  static final LocalDb instance = LocalDb._privateConstructor();

  late final Database _db;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    sqfliteFfiInit();

    final docsDir = await getApplicationDocumentsDirectory();
    final path = join(docsDir.path, 'bizzio.db');

    _db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE clients(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              email TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE projects(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              clientId INTEGER NOT NULL,
              title TEXT NOT NULL,
              dueDate TEXT NOT NULL,
              FOREIGN KEY(clientId) REFERENCES clients(id)
            )
          ''');
          await db.execute('''
            CREATE TABLE invoices(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              projectId INTEGER NOT NULL,
              amount REAL NOT NULL,
              date TEXT NOT NULL,
              dueDate TEXT NOT NULL,
              status TEXT NOT NULL DEFAULT 'Pending',
              FOREIGN KEY(projectId) REFERENCES projects(id)
            )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('''
              ALTER TABLE invoices
              ADD COLUMN dueDate TEXT NOT NULL DEFAULT '1970-01-01'
            ''');
          }
          if (oldVersion < 3) {
            await db.execute('''
              ALTER TABLE invoices
              ADD COLUMN status TEXT NOT NULL DEFAULT 'Pending'
            ''');
          }
        },
      ),
    );
  }

  Future<List<Client>> getAllClients() async {
    final maps = await _db.query('clients');
    return maps.map((m) => Client.fromMap(m)).toList();
  }
  Future<int> addClient(Client c) => _db.insert('clients', c.toMap());
  Future<int> updateClient(Client c) => _db.update(
        'clients',
        c.toMap(),
        where: 'id = ?',
        whereArgs: [c.id],
      );
  Future<int> deleteClient(int id) => _db.delete(
        'clients',
        where: 'id = ?',
        whereArgs: [id],
      );

  Future<List<Project>> getAllProjects() async {
    final maps = await _db.query('projects');
    return maps.map((m) => Project.fromMap(m)).toList();
  }
  Future<int> addProject(Project p) => _db.insert('projects', p.toMap());
  Future<int> updateProject(Project p) => _db.update(
        'projects',
        p.toMap(),
        where: 'id = ?',
        whereArgs: [p.id],
      );
  Future<int> deleteProject(int id) => _db.delete(
        'projects',
        where: 'id = ?',
        whereArgs: [id],
      );

  Future<List<Invoice>> getAllInvoices() async {
    final maps = await _db.query('invoices');
    return maps.map((m) => Invoice.fromMap(m)).toList();
  }

  Future<int> addInvoice(Invoice inv) => _db.insert('invoices', inv.toMap());
  Future<int> updateInvoice(Invoice inv) => _db.update(
        'invoices',
        inv.toMap(),
        where: 'id = ?',
        whereArgs: [inv.id],
      );
  Future<int> upsertInvoice(Invoice inv) async =>
      inv.id == null ? addInvoice(inv) : updateInvoice(inv);
  Future<int> deleteInvoice(int id) =>
      _db.delete('invoices', where: 'id = ?', whereArgs: [id]);
}