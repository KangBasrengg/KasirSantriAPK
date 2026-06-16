import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _profitData;
  bool _isLoading = true;
  String? _errorMessage;
  final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getDashboard(),
        ApiService.getProfitReport(),
      ]);
      
      if (mounted) {
        setState(() {
          _data = results[0];
          _profitData = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    if (_errorMessage != null || _data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage ?? 'Gagal memuat data', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: fetchData, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }

    final d = _data!;
    final p = _profitData ?? {
      'hari_ini': {'penjualan': 0, 'modal': 0, 'laba': 0},
      'bulan_ini': {'penjualan': 0, 'modal': 0, 'laba': 0}
    };
    
    final hariIni = d['hari_ini'] as Map<String, dynamic>? ?? {};
    final bulanIni = d['bulan_ini'] as Map<String, dynamic>? ?? {};
    final profitHariIni = p['hari_ini'] as Map<String, dynamic>? ?? {};
    final transaksiTerakhir = d['transaksi_terakhir'] as List? ?? [];
    
    return RefreshIndicator(
      onRefresh: fetchData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatCard(
            'Omzet Hari Ini',
            formatCurrency.format(num.tryParse(hariIni['omzet']?.toString() ?? '0') ?? 0),
            '${hariIni['jumlah_transaksi'] ?? 0} transaksi',
            Colors.blue,
            Icons.trending_up,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            'Laba Hari Ini',
            formatCurrency.format(num.tryParse(profitHariIni['laba']?.toString() ?? '0') ?? 0),
            'Modal: ${formatCurrency.format(num.tryParse(profitHariIni['modal']?.toString() ?? '0') ?? 0)}',
            Colors.orange,
            Icons.account_balance_wallet,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            'Omzet Bulan Ini',
            formatCurrency.format(num.tryParse(bulanIni['omzet']?.toString() ?? '0') ?? 0),
            '${bulanIni['jumlah_transaksi'] ?? 0} transaksi',
            Colors.green,
            Icons.shopping_cart,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Produk',
                  '${d['total_produk'] ?? 0}',
                  'produk aktif',
                  Colors.purple,
                  Icons.inventory,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Stok Kritis',
                  '${d['stok_kritis'] ?? 0}',
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
          ... transaksiTerakhir.map((t) {
            final trans = t as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(trans['nomor_transaksi'] ?? '-', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                subtitle: Text(trans['waktu'] != null ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(trans['waktu'])) : '-'),
                trailing: Text(formatCurrency.format(num.tryParse(trans['total']?.toString() ?? '0') ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ),
            );
          }).toList(),
          if (transaksiTerakhir.isEmpty)
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
