import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _salesData;
  String _periode = 'harian';
  final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getSalesReport(periode: _periode);
      setState(() => _salesData = res);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Periode:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'harian', label: Text('Hari')),
                    ButtonSegment(value: 'mingguan', label: Text('Minggu')),
                    ButtonSegment(value: 'bulanan', label: Text('Bulan')),
                  ],
                  selected: {_periode},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _periode = newSelection.first;
                      _fetchReport();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_salesData != null)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('Total Omzet'),
                        Text(formatCurrency.format(_salesData!['ringkasan']['total_omzet']), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Transaksi'),
                            Text('${_salesData!['ringkasan']['total_transaksi']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Detail Periode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                ... (_salesData!['laporan'] as List).map((l) => Card(
                  child: ListTile(
                    title: Text(l['periode'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${l['jumlah_transaksi']} transaksi'),
                    trailing: Text(formatCurrency.format(l['total_penjualan']), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                )).toList(),
              ],
            ),
          ),
      ],
    );
  }
}
