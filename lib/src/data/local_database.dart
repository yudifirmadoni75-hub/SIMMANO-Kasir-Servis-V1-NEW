import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  LocalDatabase._();
  static final instance = LocalDatabase._();
  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'simmano_kasir_servis_v1.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('PRAGMA foreign_keys = ON');
      await db.execute('''CREATE TABLE products(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, price REAL NOT NULL, stock INTEGER NOT NULL DEFAULT 0, active INTEGER NOT NULL DEFAULT 1)''');
      await db.execute('''CREATE TABLE customers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT NOT NULL DEFAULT '')''');
      await db.execute('''CREATE TABLE sales(id INTEGER PRIMARY KEY AUTOINCREMENT, number TEXT NOT NULL UNIQUE, customer TEXT NOT NULL DEFAULT '', total REAL NOT NULL, paid REAL NOT NULL DEFAULT 0, due_date TEXT, created_at TEXT NOT NULL)''');
      await db.execute('''CREATE TABLE sale_items(id INTEGER PRIMARY KEY AUTOINCREMENT, sale_id INTEGER NOT NULL REFERENCES sales(id) ON DELETE CASCADE, product_id INTEGER NOT NULL REFERENCES products(id), qty INTEGER NOT NULL, unit_price REAL NOT NULL, subtotal REAL NOT NULL)''');
      await db.execute('''CREATE TABLE service_orders(id INTEGER PRIMARY KEY AUTOINCREMENT, number TEXT NOT NULL UNIQUE, customer TEXT NOT NULL, phone TEXT NOT NULL DEFAULT '', item TEXT NOT NULL, complaint TEXT NOT NULL DEFAULT '', total REAL NOT NULL, paid REAL NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'Diterima', created_at TEXT NOT NULL)''');
      await db.execute('''CREATE TABLE service_payments(id INTEGER PRIMARY KEY AUTOINCREMENT, service_id INTEGER NOT NULL REFERENCES service_orders(id) ON DELETE CASCADE, amount REAL NOT NULL, created_at TEXT NOT NULL)''');
      await db.execute('''CREATE TABLE app_counters(name TEXT PRIMARY KEY, value INTEGER NOT NULL DEFAULT 0)''');
      await db.execute('INSERT INTO app_counters(name,value) VALUES (?,0)', ['sale']);
      await db.execute('INSERT INTO app_counters(name,value) VALUES (?,0)', ['service']);
      await db.insert('products', {'name': 'Produk Contoh', 'price': 10000.0, 'stock': 10, 'active': 1});
    }, onOpen: (db) async => db.execute('PRAGMA foreign_keys = ON'));
    return _db!;
  }

  Future<String> nextNumber(String kind, String prefix, DateTime d) async {
    final database = await db;
    return database.transaction((txn) async {
      final rows = await txn.query('app_counters', columns: ['value'], where: 'name = ?', whereArgs: [kind]);
      final current = rows.isEmpty ? 0 : (rows.first['value'] as int);
      final next = current + 1;
      await txn.update('app_counters', {'value': next}, where: 'name = ?', whereArgs: [kind]);
      final date = '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
      return '$prefix-$date-${next.toString().padLeft(4, '0')}';
    });
  }
}
