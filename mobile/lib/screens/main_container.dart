import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  
  final GlobalKey<DashboardScreenState> _dashKey = GlobalKey();
  final GlobalKey<PosScreenState> _posKey = GlobalKey();
  final GlobalKey<ProductsScreenState> _productsKey = GlobalKey();
  final GlobalKey<ReportsScreenState> _reportsKey = GlobalKey();

  void _onRefresh() {
    switch (_selectedIndex) {
      case 0: _dashKey.currentState?.fetchData(); break;
      case 1: _posKey.currentState?.fetchProducts(); break;
      case 2: _productsKey.currentState?.fetchProducts(); break;
      case 3: _reportsKey.currentState?.fetchReport(); break;
    }
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
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiService.logout();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
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
                    Image.asset('assets/icon.png', width: 64, height: 64, color: Colors.white),
                    const SizedBox(height: 12),
                    const Text('TokoKas Mobile', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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
                  const Text('v1.9', style: TextStyle(fontSize: 10, color: Colors.grey)),
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
