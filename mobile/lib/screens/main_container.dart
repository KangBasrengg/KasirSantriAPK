import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import 'dashboard_screen.dart';
import 'pos_screen.dart';
import 'products_screen.dart';
import 'reports_screen.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class MainContainer extends StatefulWidget {
  const MainContainer({Key? key}) : super(key: key);

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _selectedIndex = 1; // Default to POS for quick access
  String _userName = '';
  
  final GlobalKey<DashboardScreenState> _dashKey = GlobalKey();
  final GlobalKey<PosScreenState> _posKey = GlobalKey();
  final GlobalKey<ProductsScreenState> _productsKey = GlobalKey();
  final GlobalKey<ReportsScreenState> _reportsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _userName = prefs.getString('user_name') ?? 'User');
    }
  }

  void _onRefresh() {
    switch (_selectedIndex) {
      case 0: _dashKey.currentState?.fetchData(); break;
      case 1: _posKey.currentState?.fetchProducts(); break;
      case 2: _productsKey.currentState?.fetchProducts(); break;
      case 3: _reportsKey.currentState?.fetchReport(); break;
    }
  }

  void _showAccountSettings() {
    showDialog(
      context: context,
      builder: (ctx) => _AccountSettingsDialog(
        onNameChanged: (newName) {
          setState(() => _userName = newName);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/icon.png', width: 32, height: 32),
            const SizedBox(width: 10),
            const Text('TokoKas', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Ganti Tema',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'settings') {
                _showAccountSettings();
              } else if (value == 'logout') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Keluar'),
                    content: const Text('Yakin ingin keluar dari aplikasi?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Keluar'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ApiService.logout();
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'settings', child: Row(children: [Icon(Icons.settings, size: 20), SizedBox(width: 8), Text('Pengaturan Akun')])),
              const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, size: 20, color: Colors.red), SizedBox(width: 8), Text('Keluar', style: TextStyle(color: Colors.red))])),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      child: Text(
                        _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const Text('TokoKas Mobile', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: _selectedIndex == 0,
              onTap: () { setState(() => _selectedIndex = 0); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Kasir (POS)'),
              selected: _selectedIndex == 1,
              onTap: () { setState(() => _selectedIndex = 1); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Produk'),
              selected: _selectedIndex == 2,
              onTap: () { setState(() => _selectedIndex = 2); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Laporan'),
              selected: _selectedIndex == 3,
              onTap: () { setState(() => _selectedIndex = 3); Navigator.pop(context); },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Pengaturan Akun'),
              onTap: () { Navigator.pop(context); _showAccountSettings(); },
            ),
            const Spacer(),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('© 2026 TokoKas', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Copyright by Muhammad Nuril', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  const Text('v2.0', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardScreen(key: _dashKey),
          PosScreen(key: _posKey),
          ProductsScreen(key: _productsKey),
          ReportsScreen(key: _reportsKey),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dash'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'POS'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Produk'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Laporan'),
        ],
      ),
    );
  }
}

// ============ Account Settings Dialog ============
class _AccountSettingsDialog extends StatefulWidget {
  final Function(String) onNameChanged;
  const _AccountSettingsDialog({required this.onNameChanged});

  @override
  State<_AccountSettingsDialog> createState() => _AccountSettingsDialogState();
}

class _AccountSettingsDialogState extends State<_AccountSettingsDialog> {
  final _namaController = TextEditingController();
  final _pwLamaController = TextEditingController();
  final _pwBaruController = TextEditingController();
  bool _saving = false;
  String? _successMsg;
  String? _errorMsg;
  bool _showPwLama = false;
  bool _showPwBaru = false;

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  void _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    _namaController.text = prefs.getString('user_name') ?? '';
  }

  @override
  void dispose() {
    _namaController.dispose();
    _pwLamaController.dispose();
    _pwBaruController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() { _saving = true; _successMsg = null; _errorMsg = null; });
    try {
      final payload = <String, dynamic>{'nama': _namaController.text};
      if (_pwBaruController.text.isNotEmpty) {
        if (_pwLamaController.text.isEmpty) {
          setState(() { _errorMsg = 'Password lama wajib diisi.'; _saving = false; });
          return;
        }
        if (_pwBaruController.text.length < 6) {
          setState(() { _errorMsg = 'Password baru minimal 6 karakter.'; _saving = false; });
          return;
        }
        payload['password_lama'] = _pwLamaController.text;
        payload['password_baru'] = _pwBaruController.text;
      }

      final res = await ApiService.updateProfile(payload);
      setState(() { _successMsg = res['message']; });
      widget.onNameChanged(_namaController.text);
      _pwLamaController.clear();
      _pwBaruController.clear();
    } catch (e) {
      setState(() { _errorMsg = e.toString().replaceFirst('Exception: ', ''); });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pengaturan Akun'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_successMsg != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
                  child: Text(_successMsg!, style: TextStyle(color: Colors.green.shade800, fontSize: 13)),
                ),
              if (_errorMsg != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                  child: Text(_errorMsg!, style: TextStyle(color: Colors.red.shade800, fontSize: 13)),
                ),
              TextField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 16),
              const Align(alignment: Alignment.centerLeft, child: Text('Ubah Password (opsional)', style: TextStyle(fontSize: 13, color: Colors.grey))),
              const SizedBox(height: 8),
              TextField(
                controller: _pwLamaController,
                obscureText: !_showPwLama,
                decoration: InputDecoration(
                  labelText: 'Password Lama',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(icon: Icon(_showPwLama ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _showPwLama = !_showPwLama)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pwBaruController,
                obscureText: !_showPwBaru,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(icon: Icon(_showPwBaru ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _showPwBaru = !_showPwBaru)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Simpan'),
        ),
      ],
    );
  }
}
