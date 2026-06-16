import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class ProductsScreen extends StatefulWidget {
  final Key? refreshKey;
  const ProductsScreen({Key? key, this.refreshKey}) : super(key: key);

  @override
  State<ProductsScreen> createState() => ProductsScreenState();
}

class ProductsScreenState extends State<ProductsScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  String _search = '';
  final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getProducts(search: _search);
      if (mounted) {
        setState(() {
          _products = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showProductForm({dynamic product}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProductFormDialog(
        product: product,
        onSuccess: () {
          fetchProducts();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: fetchProducts,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Theme.of(context).cardTheme.color,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (val) {
                  _search = val;
                  fetchProducts();
                },
              ),
            ),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                  ? const Center(child: Text('Tidak ada produk ditemukan'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final p = _products[index] as Map<String, dynamic>;
                        final stok = int.tryParse(p['stok']?.toString() ?? '0') ?? 0;
                        final stokMin = int.tryParse(p['stok_minimum']?.toString() ?? '5') ?? 5;
                        final isKritis = stok <= stokMin;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            onTap: () => _showProductForm(product: p),
                            leading: Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: (p['foto_url'] != null && p['foto_url'].toString().isNotEmpty)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      p['foto_url'], 
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2, color: Colors.blue),
                                    ),
                                  )
                                : const Icon(Icons.inventory_2, color: Colors.blue),
                            ),
                            title: Text(p['nama']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Stok: $stok ${p['satuan'] ?? 'pcs'}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(formatCurrency.format(num.tryParse(p['harga_jual']?.toString() ?? '0') ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                if (isKritis)
                                  const Text('Stok Tipis!', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ProductFormDialog extends StatefulWidget {
  final dynamic product;
  final VoidCallback onSuccess;

  const ProductFormDialog({Key? key, this.product, required this.onSuccess}) : super(key: key);

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _skuController;
  late TextEditingController _hargaBeliController;
  late TextEditingController _hargaJualController;
  late TextEditingController _stokController;
  late TextEditingController _stokMinController;
  late TextEditingController _satuanController;
  
  dynamic _selectedCategoryId;
  List<dynamic> _categories = [];
  File? _imageFile;
  bool _isSaving = false;
  bool _isLoadingCats = true;

  @override
  void initState() {
    super.initState();
    final p = widget.product as Map<String, dynamic>?;
    _namaController = TextEditingController(text: p?['nama']?.toString() ?? '');
    _skuController = TextEditingController(text: p?['sku']?.toString() ?? '');
    _hargaBeliController = TextEditingController(text: p?['harga_beli']?.toString() ?? '');
    _hargaJualController = TextEditingController(text: p?['harga_jual']?.toString() ?? '');
    _stokController = TextEditingController(text: p?['stok']?.toString() ?? '0');
    _stokMinController = TextEditingController(text: p?['stok_minimum']?.toString() ?? '5');
    _satuanController = TextEditingController(text: p?['satuan']?.toString() ?? 'pcs');
    _selectedCategoryId = p?['kategori_id'];
    _fetchCategories();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _skuController.dispose();
    _hargaBeliController.dispose();
    _hargaJualController.dispose();
    _stokController.dispose();
    _stokMinController.dispose();
    _satuanController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final res = await ApiService.getCategories();
      if (mounted) {
        setState(() {
          _categories = res;
          _isLoadingCats = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCats = false);
    }
  }

  void _addCategory() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Kategori'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nama Kategori'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              try {
                await ApiService.createCategory(controller.text);
                Navigator.pop(ctx);
                _fetchCategories();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  String _generateSKU() {
    final rand = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(8, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product as Map<String, dynamic>?;
    final isEdit = p != null;
    final hasRemoteIcon = p != null && p['foto_url'] != null && p['foto_url'].toString().isNotEmpty;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: _isLoadingCats 
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 100, width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          image: _imageFile != null 
                            ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                            : (hasRemoteIcon
                                ? DecorationImage(image: NetworkImage(p['foto_url'].toString()), fit: BoxFit.cover)
                                : null),
                        ),
                        child: (_imageFile == null && !hasRemoteIcon)
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [Icon(Icons.camera_alt, color: Colors.grey), Text('Foto', style: TextStyle(color: Colors.grey, fontSize: 12))],
                            )
                          : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _namaController,
                      decoration: const InputDecoration(labelText: 'Nama Produk *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _skuController,
                            decoration: InputDecoration(
                              labelText: 'SKU', 
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: () => setState(() => _skuController.text = _generateSKU()),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _satuanController,
                            decoration: const InputDecoration(labelText: 'Satuan', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<dynamic>(
                            value: _selectedCategoryId,
                            decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                            items: _categories.map<DropdownMenuItem<dynamic>>((cat) {
                              return DropdownMenuItem<dynamic>(
                                value: cat['id'],
                                child: Text(cat['nama']?.toString() ?? '-'),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedCategoryId = val),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _addCategory,
                          tooltip: 'Tambah Kategori',
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _hargaBeliController,
                            decoration: const InputDecoration(labelText: 'Harga Beli', border: OutlineInputBorder(), prefixText: 'Rp '),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _hargaJualController,
                            decoration: const InputDecoration(labelText: 'Harga Jual *', border: OutlineInputBorder(), prefixText: 'Rp '),
                            keyboardType: TextInputType.number,
                            validator: (v) => v == null || v.isEmpty ? 'Harga jual wajib diisi' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _stokController,
                            decoration: const InputDecoration(labelText: 'Stok', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _stokMinController,
                            decoration: const InputDecoration(labelText: 'Stok Min', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ),
      actions: [
        TextButton(onPressed: _isSaving ? null : () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Simpan'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      // Auto generate SKU if empty
      String sku = _skuController.text;
      if (sku.isEmpty) sku = _generateSKU();

      final payload = {
        'nama': _namaController.text,
        'sku': sku,
        'satuan': _satuanController.text,
        'kategori_id': _selectedCategoryId?.toString() ?? '',
        'harga_beli': _hargaBeliController.text,
        'harga_jual': _hargaJualController.text,
        'stok': _stokController.text,
        'stok_minimum': _stokMinController.text,
      };

      if (widget.product != null) {
        await ApiService.updateProduct(widget.product['id'], payload, _imageFile);
      } else {
        await ApiService.createProduct(payload, _imageFile);
      }
      
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
