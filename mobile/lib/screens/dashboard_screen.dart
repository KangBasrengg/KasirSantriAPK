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

  void _showTransactionDetail(Map<String, dynamic> trx) async {
    showDialog(
      context: context,
      builder: (_) => _TransactionDetailDialog(transactionId: trx['id'], formatCurrency: formatCurrency),
    );
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
    final profitBulanIni = p['bulan_ini'] as Map<String, dynamic>? ?? {};
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
          _buildStatCard(
            'Laba Bulan Ini',
            formatCurrency.format(num.tryParse(profitBulanIni['laba']?.toString() ?? '0') ?? 0),
            'Penjualan: ${formatCurrency.format(num.tryParse(profitBulanIni['penjualan']?.toString() ?? '0') ?? 0)}',
            const Color(0xFF059669),
            Icons.trending_up,
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
          Row(
            children: [
              Text('Transaksi Terakhir', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(width: 8),
              const Text('(tap untuk detail)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          ... transaksiTerakhir.map((t) {
            final trans = t as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () => _showTransactionDetail(trans),
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: const Icon(Icons.receipt, color: Colors.blue, size: 20),
                ),
                title: Text(trans['nomor_transaksi'] ?? '-', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text(trans['waktu'] != null ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(trans['waktu'])) : '-'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatCurrency.format(num.tryParse(trans['total']?.toString() ?? '0') ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: trans['metode_bayar'] == 'tunai' ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        trans['metode_bayar']?.toString() ?? 'tunai',
                        style: TextStyle(fontSize: 10, color: trans['metode_bayar'] == 'tunai' ? Colors.green : Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
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

// ============ Transaction Detail Dialog ============
class _TransactionDetailDialog extends StatefulWidget {
  final dynamic transactionId;
  final NumberFormat formatCurrency;
  const _TransactionDetailDialog({required this.transactionId, required this.formatCurrency});

  @override
  State<_TransactionDetailDialog> createState() => _TransactionDetailDialogState();
}

class _TransactionDetailDialogState extends State<_TransactionDetailDialog> {
  Map<String, dynamic>? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final res = await ApiService.getTransactionDetail(widget.transactionId);
      if (mounted) setState(() { _detail = res; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Detail Transaksi'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        child: _isLoading
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : _error != null
            ? Text('Gagal: $_error')
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('No. Transaksi', _detail!['nomor_transaksi'] ?? '-'),
                    _infoRow('Waktu', _detail!['waktu'] != null
                      ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(_detail!['waktu']))
                      : '-'),
                    _infoRow('Metode Bayar', (_detail!['metode_bayar'] ?? 'tunai').toString().toUpperCase()),
                    _infoRow('Kasir', _detail!['kasir_nama'] ?? '-'),
                    const Divider(height: 24),
                    const Text('Rincian Pembelian:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...(_detail!['items'] as List? ?? []).map((item) {
                      final i = item as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(i['nama_produk'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${i['qty']} x ${widget.formatCurrency.format(num.tryParse(i['harga_jual']?.toString() ?? '0') ?? 0)}',
                                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Text(widget.formatCurrency.format(num.tryParse(i['subtotal']?.toString() ?? '0') ?? 0),
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        Text(widget.formatCurrency.format(num.tryParse(_detail!['total']?.toString() ?? '0') ?? 0),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.blue)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Bayar', style: TextStyle(fontSize: 14)),
                        Text(widget.formatCurrency.format(num.tryParse(_detail!['bayar']?.toString() ?? '0') ?? 0),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if ((num.tryParse(_detail!['kembalian']?.toString() ?? '0') ?? 0) > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Kembalian', style: TextStyle(fontSize: 14)),
                          Text(widget.formatCurrency.format(num.tryParse(_detail!['kembalian']?.toString() ?? '0') ?? 0),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        ],
      ),
    );
  }
}
