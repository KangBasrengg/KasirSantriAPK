import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getDashboard();
      setState(() => _data = res);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_data == null) return const Center(child: Text('Gagal memuat data'));

    final d = _data!;
    
    return RefreshIndicator(
      onRefresh: _fetchDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatCard(
            'Omzet Hari Ini',
            formatCurrency.format(d['hari_ini']['omzet']),
            '${d['hari_ini']['jumlah_transaksi']} transaksi',
            Colors.blue,
            Icons.trending_up,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            'Omzet Bulan Ini',
            formatCurrency.format(d['bulan_ini']['omzet']),
            '${d['bulan_ini']['jumlah_transaksi']} transaksi',
            Colors.green,
            Icons.shopping_cart,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Produk',
                  '${d['total_produk']}',
                  'produk aktif',
                  Colors.purple,
                  Icons.inventory,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Stok Kritis',
                  '${d['stok_kritis']}',
                  'perlu restock',
                  Colors.red,
                  Icons.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Transaksi Terakhir', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ... (d['transaksi_terakhir'] as List).map((t) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(t['nomor_transaksi'], style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
              subtitle: Text(DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(t['waktu']))),
              trailing: Text(formatCurrency.format(t['total']), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
          )).toList(),
          if ((d['transaksi_terakhir'] as List).isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Belum ada transaksi')),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String sub, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
