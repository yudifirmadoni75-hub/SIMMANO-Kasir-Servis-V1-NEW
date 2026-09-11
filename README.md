# SIMMANO KASIR & SERVIS V1

Aplikasi Flutter **offline-first** untuk kasir dan servis.

## Status audit
- Persistence offline sudah dipindahkan dari memory-only ke SQLite lokal melalui `sqflite`.
- Produk, stok, penjualan, detail penjualan, servis, dan pembayaran servis tersimpan di database perangkat.
- Penjualan menggunakan transaksi database atomik: stok berkurang dan header/detail penjualan disimpan dalam satu transaksi.
- Pembayaran servis dicatat ke tabel pembayaran dan total paid pada servis diperbarui secara atomik.
- Nomor transaksi memiliki counter lokal untuk menghindari benturan nomor ketika aplikasi offline.
- State UI memakai satu `globalStore`, sehingga perubahan database direfleksikan ke seluruh tab.
- Validasi dasar mencegah nama kosong, harga/stok negatif, qty <= 0, pembayaran negatif, dan pembayaran melebihi sisa tagihan.
- Status servis dibatasi ke: Diterima, Diproses, Selesai, Diambil, Batal.
- Logo SIMMANO tersedia sebagai asset dan ikon aplikasi Android.

## Alur transaksi yang diaudit
### Penjualan
1. Pilih produk.
2. Masukkan jumlah.
3. Sistem membaca stok terbaru dari SQLite.
4. Sistem menghitung total.
5. Pembayaran/DP dibatasi maksimal total.
6. Dalam satu database transaction: validasi stok -> kurangi stok -> simpan sales -> simpan sale_items.
7. Jika salah satu langkah gagal, perubahan transaksi dibatalkan.
8. Riwayat dan stok diperbarui dari database.

### Servis
1. Terima nama pelanggan, WhatsApp, barang, keluhan, dan estimasi biaya.
2. Sistem membuat nomor servis lokal.
3. Data disimpan ke SQLite dengan status `Diterima` dan paid `0`.
4. Status dapat bergerak melalui status yang diizinkan.
5. Pembayaran dicatat sebagai histori `service_payments` dan saldo servis diperbarui atomik.

## Struktur utama
- `lib/src/app.dart` — root aplikasi/theme.
- `lib/src/models/` — model data.
- `lib/src/data/local_database.dart` — SQLite schema dan koneksi lokal.
- `lib/src/services/app_store.dart` — repository/state/business flow offline.
- `lib/src/ui/` — UI prototype.
- `assets/simmano_logo.png` — brand logo.
- `android/app/src/main/res/mipmap-*` — launcher icon.

## Catatan
Database saat ini **lokal di perangkat**. Backup/restore file database dan sinkronisasi cloud belum diaktifkan pada tahap ini; itu dipisahkan agar tidak merusak integritas data V1.

## Verifikasi di GitHub/Codespaces
```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

APK release dapat dihasilkan melalui workflow GitHub Actions setelah project berada di repository.
