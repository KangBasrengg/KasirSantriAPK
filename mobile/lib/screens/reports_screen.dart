import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => ReportsScreenState();
}

class ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _salesData;
  String? _errorMessage;
  String _periode = 'harian';
  final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    fetchReport();
  }

  Future<void> fetchReport() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _salesData = null;
      _errorMessage = null;
    });
    try {
      final res = await ApiService.getSalesReport(periode: _periode);
      if (mounted) {
        setState(() {
          _salesData = res;
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

  void _showTransactionDetails(String dateLabel) {
    // Attempt to parse date from label if it's harian
    String? filterDate;
    if (_periode == 'harian') {
       filterDate = dateLabel; // Usually YYYY-MM-DD
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionListSheet(filterDate: filterDate),
    );
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
                    if (mounted) {
                      setState(() {
                        _periode = newSelection.first;
                      });
                      fetchReport();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_errorMessage != null)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: fetchReport, child: const Text('Coba Lagi')),
                  ],
                ),
              ),
            ),
          )
        else if (_salesData != null && _salesData!.containsKey('ringkasan'))
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
                        Text(formatCurrency.format(num.tryParse(_salesData!['ringkasan']?['total_omzet']?.toString() ?? '0') ?? 0), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Transaksi'),
                            Text('${_salesData!['ringkasan']?['total_transaksi'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Detail Periode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const Text('Klik untuk detail', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                if (_salesData!['laporan'] != null && (_salesData!['laporan'] as List).isNotEmpty)
                  ... (_salesData!['laporan'] as List).map((l) {
                    final row = l as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        onTap: () => _showTransactionDetails(row['periode']?.toString() ?? ''),
                        title: Text(row['periode']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${row['jumlah_transaksi'] ?? 0} transaksi'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(formatCurrency.format(num.tryParse(row['total_penjualan']?.toString() ?? '0') ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  }).toList()
                else
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Tidak ada data untuk periode ini')),
                  ),
              ],
            ),
          )
        else
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Data kosong', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class TransactionListSheet extends StatefulWidget {
  final String? filterDate;
  const TransactionListSheet({Key? key, this.filterDate}) : super(key: key);

  @override
  State<TransactionListSheet> createState() => _TransactionListSheetState();
}

class _TransactionListSheetState extends State<TransactionListSheet> {
  bool _isLoading = true;
  List<dynamic> _transactions = [];
  final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await ApiService.getTransactions(date: widget.filterDate);
      if (mounted) {
        setState(() {
          _transactions = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.filterDate != null ? 'Transaksi ${widget.filterDate}' : 'Riwayat Transaksi', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _transactions.isEmpty
                ? const Center(child: Text('Tidak ada transaksi'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _transactions.length,
                    itemBuilder: (ctx, i) {
                      final t = _transactions[i];
                      return Card(
                        child: ListTile(
                          title: Text(t['nomor_transaksi'], style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                          subtitle: Text(DateFormat('HH:mm').format(DateTime.parse(t['waktu'])) + ' • ' + t['metode_bayar'].toString().toUpperCase()),
                          trailing: Text(formatCurrency.format(num.parse(t['total'].toString())), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
