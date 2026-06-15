import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addToCart(dynamic product) {
    if (product['stok'] <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stok habis!')));
      return;
    }

    setState(() {
      final index = _cart.indexWhere((item) => item['id'] == product['id']);
      if (index >= 0) {
        if (_cart[index]['qty'] >= product['stok']) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Melebihi stok!')));
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

  double get _total => _cart.fold(0, (sum, item) => sum + (item['harga_jual'] * item['qty']));

  void _checkout() {
    if (_cart.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        String metode = 'tunai';
        final bayarController = TextEditingController();
        bool isProcessing = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16, right: 16, top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Total Pembayaran', style: TextStyle(fontSize: 16)),
                  Text(formatCurrency.format(_total), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                  SizedBox(height: 24),
                  
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'tunai', label: Text('Tunai')),
                      ButtonSegment(value: 'transfer', label: Text('Transfer')),
                      ButtonSegment(value: 'qris', label: Text('QRIS')),
                    ],
                    selected: {metode},
                    onSelectionChanged: (Set<String> newSelection) {
                      setModalState(() => metode = newSelection.first);
                    },
                  ),
                  SizedBox(height: 16),
                  
                  if (metode == 'tunai')
                    TextField(
                      controller: bayarController,
                      decoration: InputDecoration(
                        labelText: 'Uang Diterima',
                        border: OutlineInputBorder(),
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  
                  SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: isProcessing ? null : () async {
                      double bayar = _total;
                      if (metode == 'tunai') {
                        bayar = double.tryParse(bayarController.text) ?? 0;
                        if (bayar < _total) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uang kurang!')));
                          return;
                        }
                      }

                      setModalState(() => isProcessing = true);
                      try {
                        final items = _cart.map((i) => {'produk_id': i['id'], 'qty': i['qty']}).toList();
                        final res = await ApiService.createTransaction(items, metode, bayar);
                        Navigator.pop(context); // Tutup modal
                        
                        // Sukses
                        setState(() { _cart.clear(); });
                        _fetchProducts(); // Refresh stok
                        
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text('Transaksi Berhasil!'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('No: ${res['nomor_transaksi']}'),
                                Text('Kembalian: ${formatCurrency.format(res['kembalian'])}'),
                              ],
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: Text('Tutup'))
                            ],
                          )
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                        setModalState(() => isProcessing = false);
                      }
                    },
                    child: isProcessing ? CircularProgressIndicator(color: Colors.white) : Text('Selesaikan Transaksi', style: TextStyle(fontSize: 16)),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kasir (POS)'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await ApiService.logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
            },
          )
        ],
      ),
      body: Row(
        children: [
          // Kiri: Daftar Produk
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari produk...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.all(0)
                    ),
                    onChanged: (val) {
                      _searchQuery = val;
                      _fetchProducts();
                    },
                  ),
                ),
                Expanded(
                  child: _isLoading 
                    ? Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        padding: EdgeInsets.all(8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (ctx, i) {
                          final p = _products[i];
                          final isHabis = p['stok'] <= 0;
                          return InkWell(
                            onTap: () => _addToCart(p),
                            child: Card(
                              color: isHabis ? Colors.grey.shade200 : Colors.white,
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text(p['nama'], textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold)),
                                    SizedBox(height: 4),
                                    Text(formatCurrency.format(double.parse(p['harga_jual'].toString())), style: TextStyle(color: Colors.blue.shade700)),
                                    SizedBox(height: 4),
                                    Text('Stok: ${p['stok']}', style: TextStyle(color: isHabis ? Colors.red : Colors.grey, fontSize: 12)),
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
          // Kanan: Keranjang
          Container(
            width: MediaQuery.of(context).size.width > 600 ? 300 : 250,
            color: Colors.grey.shade50,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.blue.shade50,
                  width: double.infinity,
                  child: Text('Pesanan Saat Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Expanded(
                  child: _cart.isEmpty 
                    ? Center(child: Text('Keranjang Kosong'))
                    : ListView.builder(
                        itemCount: _cart.length,
                        itemBuilder: (ctx, i) {
                          final item = _cart[i];
                          return ListTile(
                            title: Text(item['nama'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            subtitle: Text('${formatCurrency.format(item['harga_jual'])} x ${item['qty']}'),
                            trailing: Text(formatCurrency.format(item['harga_jual'] * item['qty']), style: TextStyle(fontWeight: FontWeight.bold)),
                            onLongPress: () {
                              setState(() { _cart.removeAt(i); });
                            },
                          );
                        },
                      )
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))]
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total:', style: TextStyle(fontSize: 16)),
                          Text(formatCurrency.format(_total), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                        ],
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _cart.isEmpty ? null : _checkout,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                          child: Text('Bayar', style: TextStyle(fontSize: 18)),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
