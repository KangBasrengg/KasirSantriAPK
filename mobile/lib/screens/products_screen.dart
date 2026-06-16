import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  String _search = '';
  final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getProducts(search: _search);
      setState(() => _products = res);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showProductForm({dynamic product}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProductFormDialog(
        product: product,
        onSuccess: () {
          _fetchProducts();
        },
      ),
    );
  }

  void _deleteProduct(int id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Apakah Anda yakin ingin menghapus "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService.deleteProduct(id);
                _fetchProducts();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
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
                _fetchProducts();
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
                      final p = _products[index];
                      final isKritis = p['stok'] <= (p['stok_minimum'] ?? 5);
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
                            child: p['foto_url'] != null 
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(p['foto_url'], fit: BoxFit.cover),
                                )
                              : const Icon(Icons.inventory_2, color: Colors.blue),
                          ),
                          title: Text(p['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Stok: ${p['stok']} ${p['satuan'] ?? 'pcs'}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(formatCurrency.format(double.parse(p['harga_jual'].toString())), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
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
  
  int? _selectedCategoryId;
  List<dynamic> _categories = [];
  File? _imageFile;
  bool _isSaving = false;
  bool _isLoadingCats = true;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _namaController = TextEditingController(text: p?['nama'] ?? '');
    _skuController = TextEditingController(text: p?['sku'] ?? '');
    _hargaBeliController = TextEditingController(text: p?['harga_beli']?.toString() ?? '');
    _hargaJualController = TextEditingController(text: p?['harga_jual']?.toString() ?? '');
    _stokController = TextEditingController(text: p?['stok']?.toString() ?? '');
    _stokMinController = TextEditingController(text: p?['stok_minimum']?.toString() ?? '5');
    _satuanController = TextEditingController(text: p?['satuan'] ?? 'pcs');
    _selectedCategoryId = p?['kategori_id'];
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final res = await ApiService.getCategories();
      setState(() {
        _categories = res;
        _isLoadingCats = false;
      });
    } catch (e) {
      setState(() => _isLoadingCats = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoadingCats 
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 120, width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          image: _imageFile != null 
                            ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                            : (widget.product?['foto_url'] != null 
                                ? DecorationImage(image: NetworkImage(widget.product['foto_url']), fit: BoxFit.cover)
                                : null),
                        ),
                        child: (_imageFile == null && widget.product?['foto_url'] == null)
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [Icon(Icons.camera_alt, size: 40, color: Colors.grey), Text('Foto', style: TextStyle(color: Colors.grey))],
                            )
                          : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _namaController,
                      decoration: const InputDecoration(labelText: 'Nama Produk *', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _skuController,
                            decoration: const InputDecoration(labelText: 'SKU', border: OutlineInputBorder()),
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
                    DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                      items: _categories.map<DropdownMenuItem<int>>((cat) => DropdownMenuItem<int>(
                        value: cat['id'],
                        child: Text(cat['nama']),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
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
                            validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
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
      final payload = {
        'nama': _namaController.text,
        'sku': _skuController.text,
        'satuan': _satuanController.text,
        'kategori_id': _selectedCategoryId ?? '',
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
