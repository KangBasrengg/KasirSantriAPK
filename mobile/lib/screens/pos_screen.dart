import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class PosScreen extends StatefulWidget {
  @override
  _PosScreenState createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  List<dynamic> _products = [];
  List<Map<String, dynamic>> _cart = [];
  bool _isLoading = true;
  String _searchQuery = '';

  final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getProducts(search: _searchQuery);
      setState(() => _products = data);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addToCart(dynamic product) {
    if (product['stok'] <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok habis!')));
      return;
    }

    setState(() {
      final index = _cart.indexWhere((item) => item['id'] == product['id']);
      if (index >= 0) {
        if (_cart[index]['qty'] >= product['stok']) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Melebihi stok!')));
          return;
        }
        _cart[index]['qty']++;
      } else {
        _cart.add({
          'id': product['id'],
          'nama': product['nama'],
          'harga_jual': double.parse(product['harga_jual'].toString()),
          'stok': product['stok'],
          'qty': 1,
        });
      }
    });
  }

  void _updateQty(int id, int delta) {
    setState(() {
      final index = _cart.indexWhere((item) => item['id'] == id);
      if (index >= 0) {
        final newQty = _cart[index]['qty'] + delta;
        if (newQty <= 0) {
          _cart.removeAt(index);
        } else if (newQty > _cart[index]['stok']) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Melebihi stok!')));
        } else {
          _cart[index]['qty'] = newQty;
        }
      }
    });
  }

  double get _total => _cart.fold(0, (sum, item) => sum + (item['harga_jual'] * item['qty']));

  void _checkout() {
    if (_cart.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _PaymentModal(
          total: _total,
          cart: _cart,
          onSuccess: () {
            setState(() { _cart.clear(); });
            _fetchProducts();
          },
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          // Left Side: Products
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari produk (Nama atau SKU)...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Theme.of(context).cardTheme.color,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (val) {
                      _searchQuery = val;
                      _fetchProducts();
                    },
                  ),
                ),
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isWide ? 4 : 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (ctx, i) {
                          final p = _products[i];
                          final isHabis = p['stok'] <= 0;
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: isHabis ? null : () => _addToCart(p),
                              child: Opacity(
                                opacity: isHabis ? 0.5 : 1.0,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        color: Theme.of(context).brightness == Brightness.light ? Colors.grey.shade100 : Colors.blueGrey.shade900,
                                        child: Stack(
                                          children: [
                                            const Center(child: Icon(Icons.shopping_bag_outlined, size: 32, color: Colors.grey)),
                                            if (isHabis)
                                              Positioned(
                                                top: 8, right: 8,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                                                  child: const Text('HABIS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p['nama'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          const SizedBox(height: 4),
                                          Text(formatCurrency.format(double.parse(p['harga_jual'].toString())), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w800, fontSize: 14)),
                                          const SizedBox(height: 2),
                                          Text('Stok: ${p['stok']}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                )
              ],
            ),
          ),
          
          // Right Side: Cart (Visible only on wide screens or as a side panel)
          if (isWide)
            Container(
              width: 350,
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: _buildCartPanel(),
            ),
        ],
      ),
      floatingActionButton: !isWide ? FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => Container(
              height: MediaQuery.of(context).size.height * 0.8,
              child: _buildCartPanel(),
            ),
          );
        },
        label: Text('Keranjang (${_cart.length})'),
        icon: const Icon(Icons.shopping_cart),
      ) : null,
    );
  }

  Widget _buildCartPanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pesanan Saat Ini', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              if (_cart.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(12)),
                  child: Text('${_cart.length} item', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        Expanded(
          child: _cart.isEmpty 
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    const Text('Belum ada produk di keranjang', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _cart.length,
                itemBuilder: (ctx, i) {
                  final item = _cart[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['nama'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(formatCurrency.format(item['harga_jual']), style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                            ),
                            Text(formatCurrency.format(item['harga_jual'] * item['qty']), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _qtyBtn(Icons.remove, () => _updateQty(item['id'], -1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('${item['qty']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            _qtyBtn(Icons.add, () => _updateQty(item['id'], 1)),
                          ],
                        )
                      ],
                    ),
                  );
                },
              )
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light ? Colors.grey.shade50 : Colors.black26,
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Text(formatCurrency.format(_total), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _cart.isEmpty ? null : _checkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Bayar Sekarang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 32, height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Theme.of(context).dividerColor)),
        ),
      ),
    );
  }
}

class _PaymentModal extends StatefulWidget {
  final double total;
  final List<Map<String, dynamic>> cart;
  final VoidCallback onSuccess;

  const _PaymentModal({required this.total, required this.cart, required this.onSuccess});

  @override
  State<_PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<_PaymentModal> {
  String _metode = 'tunai';
  final _bayarController = TextEditingController();
  bool _isProcessing = false;
  final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    double bayar = double.tryParse(_bayarController.text) ?? 0;
    double kembalian = bayar - widget.total;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24, right: 24, top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pembayaran', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                const Text('Total Tagihan', style: TextStyle(color: Colors.grey)),
                Text(formatCurrency.format(widget.total), style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              _metodeItem('tunai', 'Tunai'),
              const SizedBox(width: 8),
              _metodeItem('transfer', 'Transfer'),
              const SizedBox(width: 8),
              _metodeItem('qris', 'QRIS'),
            ],
          ),
          const SizedBox(height: 24),
          if (_metode == 'tunai') ...[
            const Text('Jumlah Bayar (Rp)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _bayarController,
              decoration: InputDecoration(
                hintText: '0',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixText: 'Rp ',
                contentPadding: const EdgeInsets.all(16),
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              keyboardType: TextInputType.number,
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _quickMoney(widget.total, 'Uang Pas'),
                const SizedBox(width: 8),
                _quickMoney(50000, '50K'),
                const SizedBox(width: 8),
                _quickMoney(100000, '100K'),
              ],
            ),
            if (kembalian >= 0 && _bayarController.text.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text('Kembalian', style: TextStyle(color: Colors.white, fontSize: 13)),
                    Text(formatCurrency.format(kembalian), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isProcessing || (_metode == 'tunai' && kembalian < 0) ? null : _handlePayment,
              child: _isProcessing 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text('Selesaikan Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metodeItem(String value, String label) {
    bool isActive = _metode == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _metode = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: isActive ? Theme.of(context).primaryColor : Theme.of(context).dividerColor, width: 2),
            borderRadius: BorderRadius.circular(8),
            color: isActive ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Theme.of(context).primaryColor : Colors.grey)),
        ),
      ),
    );
  }

  Widget _quickMoney(double amount, String label) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          _bayarController.text = amount.toInt().toString();
          setState(() {});
        },
        child: Text(label),
      ),
    );
  }

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);
    try {
      double bayar = _metode == 'tunai' ? (double.tryParse(_bayarController.text) ?? 0) : widget.total;
      final items = widget.cart.map((i) => {'produk_id': i['id'], 'qty': i['qty']}).toList();
      final res = await ApiService.createTransaction(items, _metode, bayar);
      
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 16),
                const Text('Transaksi Berhasil!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(res['nomor_transaksi'], style: const TextStyle(color: Colors.grey, fontFamily: 'monospace')),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [const Text('Total'), Text(formatCurrency.format(res['total']), style: const TextStyle(fontWeight: FontWeight.bold))],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text('Bayar ($_metode)'), Text(formatCurrency.format(res['bayar']), style: const TextStyle(fontWeight: FontWeight.bold))],
                      ),
                      if (res['kembalian'] > 0) ...[
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [const Text('Kembalian'), Text(formatCurrency.format(res['kembalian']), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))],
                        ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                )
              ],
            ),
          )
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
