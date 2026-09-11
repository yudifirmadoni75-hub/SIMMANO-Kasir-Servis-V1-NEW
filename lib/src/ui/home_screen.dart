import 'package:flutter/material.dart';
import '../services/app_store.dart';
import '../models/models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;
  final store = globalStore;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        if (!store.ready) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final pages = [
          Home(store: store, on: (i) => setState(() => tab = i)),
          Cashier(store: store),
          History(store: store),
          Settings(store: store),
        ];
        return Scaffold(
          body: pages[tab],
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
              NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: 'Kasir'),
              NavigationDestination(icon: Icon(Icons.history), label: 'Riwayat'),
              NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Pengaturan'),
            ],
          ),
        );
      },
    );
  }
}

class Header extends StatelessWidget {
  final String title; final String sub;
  const Header(this.title, this.sub, {super.key});
  @override Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Image.asset('assets/simmano_logo.png', height: 42, fit: BoxFit.contain),
      const SizedBox(height: 10),
      Text(title, style: Theme.of(c).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
      Text(sub, style: Theme.of(c).textTheme.bodyMedium),
    ]),
  );
}

class Home extends StatelessWidget {
  final AppStore store; final void Function(int) on;
  const Home({required this.store, required this.on, super.key});
  @override Widget build(BuildContext c) => ListView(padding: const EdgeInsets.only(bottom: 24), children: [
    const Header('SIMMANO', 'Kasir & Servis • Offline'),
    Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      Expanded(child: _Stat('Penjualan', store.sales.fold<double>(0, (a, b) => a + b.total))),
      const SizedBox(width: 10),
      Expanded(child: _Stat('Servis masuk', store.services.length.toDouble())),
    ])),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
      _Action('Transaksi Baru', Icons.point_of_sale, () => on(1)),
      _Action('Terima Servis', Icons.build, () => _serviceDialog(c, store)),
      _Action('Riwayat', Icons.history, () => on(2)),
      _Action('Produk', Icons.inventory, () => _productDialog(c, store)),
      _Action('Laporan', Icons.assessment, () => _reportDialog(c, store)),
    ])),
  ]);
}

class _Stat extends StatelessWidget {
  final String title; final double value;
  const _Stat(this.title, this.value);
  @override Widget build(BuildContext c) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title), const SizedBox(height: 8), Text('Rp${value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))])));
}

class _Action extends StatelessWidget {
  final String title; final IconData icon; final VoidCallback onTap;
  const _Action(this.title, this.icon, this.onTap);
  @override Widget build(BuildContext c) => Card(child: ListTile(leading: CircleAvatar(child: Icon(icon)), title: Text(title), trailing: const Icon(Icons.chevron_right), onTap: onTap));
}

class Cashier extends StatefulWidget {
  final AppStore store;
  const Cashier({required this.store, super.key});
  @override State<Cashier> createState() => _CashierState();
}
class _CashierState extends State<Cashier> {
  Product? p;
  final qty = TextEditingController(text: '1');
  final customer = TextEditingController();
  final paid = TextEditingController();
  @override void dispose() { qty.dispose(); customer.dispose(); paid.dispose(); super.dispose(); }
  @override Widget build(BuildContext c) {
    final q = int.tryParse(qty.text) ?? 0;
    final total = p == null ? 0 : p!.price * q;
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Header('Kasir', 'Penjualan'),
      DropdownButtonFormField<Product>(initialValue: p, decoration: const InputDecoration(labelText: 'Produk', border: OutlineInputBorder()), items: widget.store.products.where((x) => x.active).map((x) => DropdownMenuItem(value: x, child: Text('${x.name} • Rp${x.price.toStringAsFixed(0)} • stok ${x.stock}'))).toList(), onChanged: (v) => setState(() => p = v)),
      const SizedBox(height: 12),
      TextField(controller: qty, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Jumlah', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: customer, decoration: const InputDecoration(labelText: 'Pelanggan (opsional)', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: paid, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Pembayaran / DP', hintText: 'Maks. Rp${total.toStringAsFixed(0)}', border: const OutlineInputBorder())),
      const SizedBox(height: 16),
      if (p != null) Text('Total: Rp${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      FilledButton(onPressed: () async {
        if (p == null) return;
        final ok = await widget.store.sell(p!, q, customer.text, double.tryParse(paid.text) ?? total);
        if (!c.mounted) return;
        ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(ok ? 'Penjualan tersimpan' : 'Transaksi gagal: stok tidak cukup atau data tidak valid')));
        if (ok) { paid.clear(); customer.clear(); setState(() {}); }
      }, child: const Text('Simpan & Buat Nota')),
    ]);
  }
}

class History extends StatelessWidget {
  final AppStore store;
  const History({required this.store, super.key});
  @override Widget build(BuildContext c) => ListView(padding: const EdgeInsets.all(20), children: [
    const Header('Riwayat', 'Penjualan & Servis'),
    if (store.sales.isEmpty && store.services.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('Belum ada transaksi'))),
    ...store.sales.map((s) => Card(child: ListTile(title: Text(s.number), subtitle: Text('${s.customer.isEmpty ? 'Umum' : s.customer} • Rp${s.total.toStringAsFixed(0)}'), trailing: Text(s.outstanding > 0 ? 'Rp${s.outstanding.toStringAsFixed(0)}' : 'Lunas')))),
    ...store.services.map((s) => Card(child: ListTile(onTap: () => _serviceDetail(c, store, s), title: Text(s.number), subtitle: Text('${s.item} • ${s.status}'), trailing: Text(s.outstanding > 0 ? 'Rp${s.outstanding.toStringAsFixed(0)}' : 'Lunas')))),
  ]);
}

class Settings extends StatelessWidget {
  final AppStore store;
  const Settings({required this.store, super.key});
  @override Widget build(BuildContext c) => ListView(padding: const EdgeInsets.all(20), children: [
    const Header('Pengaturan', 'Profil toko, nota, data, akses'),
    const Card(child: ListTile(leading: Icon(Icons.store), title: Text('Profil Toko'), subtitle: Text('Nama, alamat, telepon, WhatsApp'))),
    const Card(child: ListTile(leading: Icon(Icons.receipt_long), title: Text('Nota'), subtitle: Text('Format dan pesan nota'))),
    const Card(child: ListTile(leading: Icon(Icons.backup), title: Text('Data'), subtitle: Text('Database tersimpan lokal di perangkat'))),
    const Card(child: ListTile(leading: Icon(Icons.lock), title: Text('Akses'), subtitle: Text('PIN dan hak akses'))),
  ]);
}

void _serviceDialog(BuildContext c, AppStore s) {
  final a = TextEditingController(), b = TextEditingController(), d = TextEditingController(), e = TextEditingController(), f = TextEditingController();
  showDialog(context: c, builder: (_) => AlertDialog(title: const Text('Terima Servis'), content: SingleChildScrollView(child: Column(children: [
    TextField(controller: a, decoration: const InputDecoration(labelText: 'Nama pelanggan')),
    TextField(controller: b, decoration: const InputDecoration(labelText: 'No. WhatsApp')),
    TextField(controller: d, decoration: const InputDecoration(labelText: 'Barang')),
    TextField(controller: e, decoration: const InputDecoration(labelText: 'Keluhan')),
    TextField(controller: f, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Estimasi biaya')),
  ])), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')), FilledButton(onPressed: () async { await s.receiveService(a.text, b.text, d.text, e.text, double.tryParse(f.text) ?? 0); if (c.mounted) Navigator.pop(c); }, child: const Text('Simpan & Buat Nota'))]));
}

void _serviceDetail(BuildContext c, AppStore s, ServiceOrder service) {
  final amount = TextEditingController();
  showDialog(context: c, builder: (_) => AlertDialog(title: Text(service.number), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('${service.customer} • ${service.phone}'), Text(service.item), Text('Keluhan: ${service.complaint}'), Text('Total: Rp${service.total.toStringAsFixed(0)}'), Text('Sisa: Rp${service.outstanding.toStringAsFixed(0)}'),
    const SizedBox(height: 12), DropdownButtonFormField<String>(initialValue: service.status, items: const ['Diterima','Diproses','Selesai','Diambil','Batal'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) { if (v != null) s.status(service, v); }),
    TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Bayar / DP')),
  ]), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tutup')), FilledButton(onPressed: () async { await s.payService(service, double.tryParse(amount.text) ?? 0); if (c.mounted) Navigator.pop(c); }, child: const Text('Simpan Pembayaran'))]));
}

void _productDialog(BuildContext c, AppStore s) {
  final a = TextEditingController(), b = TextEditingController(), d = TextEditingController();
  showDialog(context: c, builder: (_) => AlertDialog(title: const Text('Produk'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: a, decoration: const InputDecoration(labelText: 'Nama')), TextField(controller: b, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga jual')), TextField(controller: d, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stok'))]), actions: [FilledButton(onPressed: () async { await s.addProduct(a.text, double.tryParse(b.text) ?? 0, int.tryParse(d.text) ?? 0); if (c.mounted) Navigator.pop(c); }, child: const Text('Simpan'))]));
}

void _reportDialog(BuildContext c, AppStore s) {
  showDialog(context: c, builder: (_) => AlertDialog(title: const Text('Laporan'), content: Text('Penjualan: Rp${s.sales.fold<double>(0, (a, b) => a + b.total).toStringAsFixed(0)}\nPiutang penjualan: Rp${s.sales.fold<double>(0, (a, b) => a + b.outstanding).toStringAsFixed(0)}\nServis: ${s.services.length}'), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tutup'))]));
}
