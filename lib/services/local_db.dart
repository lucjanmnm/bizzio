import 'dart:io';
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

  Future<void> init() async {
    sqfliteFfiInit();
    final docsDir = await getApplicationDocumentsDirectory();
    final path = join(docsDir.path, 'bizzio.db');
    _db = await databaseFactoryFfi.openDatabase(path, options: OpenDatabaseOptions(
      version: 1,
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
            FOREIGN KEY(projectId) REFERENCES projects(id)
          )
        ''');
      },
    ));
  }

  Future<List<Client>> getAllClients() async {
    final maps = await _db.query('clients');
    return maps.map((m) => Client.fromMap(m)).toList();
  }

  Future<int> addClient(Client client) async {
    return await _db.insert('clients', client.toMap());
  }

  Future<int> updateClient(Client client) async {
    return await _db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<int> deleteClient(int id) async {
    return await _db.delete(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Project>> getAllProjects() async {
    final maps = await _db.query('projects');
    return maps.map((m) => Project.fromMap(m)).toList();
  }

  Future<int> addProject(Project project) async {
    return await _db.insert('projects', project.toMap());
  }

  Future<int> updateProject(Project project) async {
    return await _db.update(
      'projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<int> deleteProject(int id) async {
    return await _db.delete(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Invoice>> getAllInvoices() async {
    final maps = await _db.query('invoices');
    return maps.map((m) => Invoice.fromMap(m)).toList();
  }

  Future<int> addInvoice(Invoice invoice) async {
    return await _db.insert('invoices', invoice.toMap());
  }

  Future<int> updateInvoice(Invoice invoice) async {
    return await _db.update(
      'invoices',
      invoice.toMap(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
  }

  Future<int> deleteInvoice(int id) async {
    return await _db.delete(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
