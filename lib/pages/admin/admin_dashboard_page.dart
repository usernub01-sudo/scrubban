import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'admin_login_page.dart';
import 'admin_orders_page.dart';
import 'admin_products_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _authService = AuthService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الأدمن'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                _authService.currentEmail ?? '',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('تسجيل الخروج'),
                  content: const Text('هل تريد تسجيل الخروج من لوحة التحكم؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('إلغاء'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'خروج',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm != true) return;
              await _authService.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AdminLoginPage()),
                (route) => false,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;
          if (isNarrow) return _buildNarrowLayout();
          return _buildWideLayout();
        },
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildNarrowLayout() {
    return IndexedStack(
      index: _selectedIndex,
      children: const [
        AdminProductsPage(),
        AdminOrdersPage(), // ← بدل الـPlaceholder
      ],
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Container(
          width: 220,
          color: Colors.grey.shade100,
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildSidebarItem(
                index: 0,
                icon: Icons.inventory_2_outlined,
                label: 'المنتجات',
              ),
              _buildSidebarItem(
                index: 1,
                icon: Icons.receipt_long_outlined,
                label: 'الطلبات',
              ),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _selectedIndex,
            children: const [
              AdminProductsPage(),
              AdminOrdersPage(), // ← بدل الـPlaceholder
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        color: selected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : null,
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade700,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildBottomNav(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 700) return null;

    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (i) => setState(() => _selectedIndex = i),
      selectedItemColor: Theme.of(context).colorScheme.primary,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          label: 'المنتجات',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          label: 'الطلبات',
        ),
      ],
    );
  }
}
