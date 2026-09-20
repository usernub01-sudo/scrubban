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
    final isNarrow = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            Expanded(
              child: isNarrow ? _buildNarrowLayout() : _buildWideLayout(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isNarrow ? _buildMobileNav() : null,
    );
  }

  // ============================================================
  // Top Bar
  // ============================================================
  Widget _buildTopBar() {
    final email = _authService.currentEmail ?? 'admin';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          const SizedBox(width: 8),
          // Logo mark
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.dashboard_outlined,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'ADMIN',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 3,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          // Account menu
          PopupMenuButton<String>(
            tooltip: 'Account',
            offset: const Offset(0, 48),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            onSelected: (value) async {
              if (value == 'logout') {
                await _handleLogout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SIGNED IN AS',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF999999),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 16, color: Colors.red),
                    SizedBox(width: 10),
                    Text(
                      'Sign out',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFDDDDDD),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      email.isNotEmpty ? email[0].toUpperCase() : 'A',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.expand_more,
                    size: 16,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Narrow Layout
  // ============================================================
  Widget _buildNarrowLayout() {
    return IndexedStack(
      index: _selectedIndex,
      children: const [AdminProductsPage(), AdminOrdersPage()],
    );
  }

  // ============================================================
  // Wide Layout
  // ============================================================
  Widget _buildWideLayout() {
    return Row(
      children: [
        // Sidebar
        Container(
          width: 240,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(color: Color(0xFFEEEEEE), width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'MENU',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF999999),
                    letterSpacing: 2.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSidebarItem(
                index: 0,
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2,
                label: 'Products',
              ),
              _buildSidebarItem(
                index: 1,
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long,
                label: 'Orders',
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Color(0xFF999999),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Order-request store',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: IndexedStack(
            index: _selectedIndex,
            children: const [AdminProductsPage(), AdminOrdersPage()],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Sidebar Item
  // ============================================================
  Widget _buildSidebarItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final selected = _selectedIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Stack(
        children: [
          // Active indicator
          if (selected)
            Positioned(
              left: 0,
              top: 8,
              bottom: 8,
              child: Container(width: 2, color: Colors.black87),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            child: Row(
              children: [
                Icon(
                  selected ? activeIcon : icon,
                  size: 18,
                  color: selected ? Colors.black87 : const Color(0xFF999999),
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? Colors.black87 : const Color(0xFF666666),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Mobile Nav
  // ============================================================
  Widget _buildMobileNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildMobileNavItem(
              index: 0,
              icon: Icons.inventory_2_outlined,
              activeIcon: Icons.inventory_2,
              label: 'Products',
            ),
            _buildMobileNavItem(
              index: 1,
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long,
              label: 'Orders',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final selected = _selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? activeIcon : icon,
                size: 22,
                color: selected ? Colors.black87 : const Color(0xFF999999),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? Colors.black87 : const Color(0xFF999999),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Logout
  // ============================================================
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text(
          'Sign out?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        content: const Text(
          'You will need to sign in again to access the admin dashboard.',
          style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: Colors.black87,
                letterSpacing: 1.5,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'SIGN OUT',
              style: TextStyle(
                color: Colors.red,
                letterSpacing: 1.5,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
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
  }
}
