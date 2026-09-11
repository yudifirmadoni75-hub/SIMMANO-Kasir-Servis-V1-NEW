class Product {
  int id;
  String name;
  double price;
  int stock;
  bool active;
  Product({required this.id, required this.name, required this.price, this.stock = 0, this.active = true});
}

class Customer {
  int id;
  String name;
  String phone;
  Customer({required this.id, required this.name, this.phone = ''});
}

class Sale {
  String number;
  String customer;
  double total;
  double paid;
  DateTime createdAt;
  DateTime? dueDate;
  Sale({required this.number, required this.customer, required this.total, required this.paid, required this.createdAt, this.dueDate});
  double get outstanding => (total - paid).clamp(0, double.infinity);
}

class ServiceOrder {
  String number;
  String customer;
  String phone;
  String item;
  String complaint;
  double total;
  double paid;
  String status;
  DateTime createdAt;
  ServiceOrder({required this.number, required this.customer, required this.phone, required this.item, required this.complaint, required this.total, this.paid = 0, this.status = 'Diterima', required this.createdAt});
  double get outstanding => (total - paid).clamp(0, double.infinity);
}
