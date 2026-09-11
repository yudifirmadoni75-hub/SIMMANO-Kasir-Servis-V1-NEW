import 'package:flutter/foundation.dart';
import '../data/local_database.dart';
import '../models/models.dart';

class AppStore extends ChangeNotifier {
  final products = <Product>[];
  final sales = <Sale>[];
  final services = <ServiceOrder>[];
  bool ready = false;

  Future<void> init() async {
    final db = await LocalDatabase.instance.db;
    products
      ..clear()
      ..addAll((await db.query('products', orderBy: 'id ASC')).map((r) => Product(id: r['id'] as int, name: r['name'] as String, price: (r['price'] as num).toDouble(), stock: r['stock'] as int, active: (r['active'] as int) == 1)));
    await _reloadTransactions();
    ready = true;
    notifyListeners();
  }

  Future<void> _reloadTransactions() async {
    final db = await LocalDatabase.instance.db;
    sales
      ..clear()
      ..addAll((await db.query('sales', orderBy: 'created_at DESC')).map((r) => Sale(number: r['number'] as String, customer: r['customer'] as String, total: (r['total'] as num).toDouble(), paid: (r['paid'] as num).toDouble(), dueDate: r['due_date'] == null ? null : DateTime.tryParse(r['due_date'] as String), createdAt: DateTime.parse(r['created_at'] as String))));
    services
      ..clear()
      ..addAll((await db.query('service_orders', orderBy: 'created_at DESC')).map((r) => ServiceOrder(number: r['number'] as String, customer: r['customer'] as String, phone: r['phone'] as String, item: r['item'] as String, complaint: r['complaint'] as String, total: (r['total'] as num).toDouble(), paid: (r['paid'] as num).toDouble(), status: r['status'] as String, createdAt: DateTime.parse(r['created_at'] as String))));
  }

  Future<void> addProduct(String name, double price, int stock) async {
    if (name.trim().isEmpty || price < 0 || stock < 0) return;
    final db = await LocalDatabase.instance.db;
    final id = await db.insert('products', {'name': name.trim(), 'price': price, 'stock': stock, 'active': 1});
    products.add(Product(id: id, name: name.trim(), price: price, stock: stock));
    notifyListeners();
  }

  Future<bool> sell(Product product, int qty, String customer, double paid) async {
    if (!ready || qty <= 0) return false;
    final db = await LocalDatabase.instance.db;
    final total = product.price * qty;
    final safePaid = paid.clamp(0, total).toDouble();
    final now = DateTime.now();
    final number = await LocalDatabase.instance.nextNumber('sale', 'SM', now);
    try {
      await db.transaction((txn) async {
        final rows = await txn.query('products', columns: ['stock'], where: 'id = ? AND active = 1', whereArgs: [product.id]);
        if (rows.isEmpty || (rows.first['stock'] as int) < qty) throw StateError('Stok tidak cukup');
        await txn.update('products', {'stock': (rows.first['stock'] as int) - qty}, where: 'id = ?', whereArgs: [product.id]);
        final saleId = await txn.insert('sales', {'number': number, 'customer': customer.trim(), 'total': total, 'paid': safePaid, 'created_at': now.toIso8601String()});
        await txn.insert('sale_items', {'sale_id': saleId, 'product_id': product.id, 'qty': qty, 'unit_price': product.price, 'subtotal': total});
      });
      product.stock -= qty;
      await _reloadTransactions();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> receiveService(String customer, String phone, String item, String complaint, double total) async {
    if (customer.trim().isEmpty || item.trim().isEmpty || total < 0) return;
    final db = await LocalDatabase.instance.db;
    final now = DateTime.now();
    final number = await LocalDatabase.instance.nextNumber('service', 'SV', now);
    await db.insert('service_orders', {'number': number, 'customer': customer.trim(), 'phone': phone.trim(), 'item': item.trim(), 'complaint': complaint.trim(), 'total': total, 'paid': 0.0, 'status': 'Diterima', 'created_at': now.toIso8601String()});
    await _reloadTransactions();
    notifyListeners();
  }

  Future<void> payService(ServiceOrder service, double amount) async {
    if (amount <= 0 || service.outstanding <= 0) return;
    final safe = amount.clamp(0, service.outstanding).toDouble();
    final db = await LocalDatabase.instance.db;
    final rows = await db.query('service_orders', columns: ['id','paid','total'], where: 'number = ?', whereArgs: [service.number], limit: 1);
    if (rows.isEmpty) return;
    final id = rows.first['id'] as int;
    await db.transaction((txn) async {
      await txn.update('service_orders', {'paid': (rows.first['paid'] as num).toDouble() + safe}, where: 'id = ?', whereArgs: [id]);
      await txn.insert('service_payments', {'service_id': id, 'amount': safe, 'created_at': DateTime.now().toIso8601String()});
    });
    await _reloadTransactions();
    notifyListeners();
  }

  Future<void> status(ServiceOrder service, String value) async {
    const allowed = {'Diterima', 'Diproses', 'Selesai', 'Diambil', 'Batal'};
    if (!allowed.contains(value)) return;
    final db = await LocalDatabase.instance.db;
    await db.update('service_orders', {'status': value}, where: 'number = ?', whereArgs: [service.number]);
    await _reloadTransactions();
    notifyListeners();
  }
}

final globalStore = AppStore();
final store = globalStore;
