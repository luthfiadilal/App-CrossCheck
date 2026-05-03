import 'package:crosscheck/features/monitoring/presentation/pages/approval_page.dart';
import 'package:crosscheck/features/monitoring/presentation/pages/mandor_history_page.dart';
import 'package:crosscheck/features/monitoring/presentation/pages/mandor_home_page.dart';
import 'package:crosscheck/features/monitoring/presentation/pages/qr_generator_page.dart';
import 'package:crosscheck/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class MainScreen extends StatefulWidget {
  final String role; // Role from login (e.g., 'MANDOR')

  const MainScreen({super.key, required this.role});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;
  late final List<BottomNavigationBarItem> _navItems;

  @override
  void initState() {
    super.initState();
    // Setup pages based on role
    if (widget.role.startsWith('MANDOR')) {
      _pages = [
        const MandorHomePage(),
        const MandorHistoryPage(),
        const ProfilePage(),
      ];
      _navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
      ];
    } else {
      // ASISTEN / KEPALA
      _pages = [
        const ApprovalPage(), // Tab Utama adalah List Approval
        const QrGeneratorPage(), // Fitur QR Generator
        const MandorHistoryPage(), // Tetap bisa lihat history
        const ProfilePage(),
      ];
      _navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in_outlined), activeIcon: Icon(Icons.assignment_turned_in), label: 'Approval'),
        BottomNavigationBarItem(icon: Icon(Icons.qr_code_2_outlined), activeIcon: Icon(Icons.qr_code_2), label: 'QR Generator'),
        BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
      ];
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.grey,
        type: BottomNavigationBarType.fixed, // Added for 4 items
        items: _navItems,
      ),
    );
  }
}
