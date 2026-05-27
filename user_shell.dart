import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'map_screen.dart';
import 'explore_screen.dart';
import 'my_bookings_screen.dart';
import 'my_space_screen.dart';
import 'profile_screen.dart';
import 'booking_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class UserShell extends StatefulWidget {
  const UserShell({super.key});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _currentIndex = 0;
  final _supabase = Supabase.instance.client;
  late final PageController _pageController =
  PageController(initialPage: 0);

  final List<Widget> _screens = const [
    MapScreen(),
    ExploreScreen(),
    MyBookingsScreen(),
    MySpaceScreen(),
    ProfileScreen(),
  ];

  final List<String> _navLabels = [
    'Map',
    'Explore',
    'Bookings',
    'Spaces',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    bookingTabNotifier.addListener(_onTabSwitch);
  }

  void _onTabSwitch() {
    final i = bookingTabNotifier.value;
    setState(() => _currentIndex = i);
    _pageController.jumpToPage(i);
  }

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    bookingTabNotifier.removeListener(_onTabSwitch);
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _showSignOutSheet() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding:
        const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Sign out?',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3)),
            const SizedBox(height: 6),
            Text(
              'You\'ll need to sign back in to access your account.',
              style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 13,
                  height: 1.4),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color:
                          Colors.white.withOpacity(0.08)),
                    ),
                    child: Center(
                      child: Text('Cancel',
                          style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFEF4444)
                              .withOpacity(0.4)),
                    ),
                    child: Center(
                      child: Text('Sign out',
                          style: GoogleFonts.inter(
                              color: const Color(0xFFEF4444),
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await _supabase.auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          HapticFeedback.lightImpact();
        },
        children: _screens,
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, bottomPad + 12),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
                color: Colors.white.withOpacity(0.07)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
                _navLabels.length, _buildNavItem),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isActive = _currentIndex == index;
    final color = isActive
        ? const Color(0xFFDEFF6E)
        : Colors.white.withOpacity(0.35);

    return GestureDetector(
      onTap: () => _onTabTap(index),
      onLongPress: index == 4 ? _showSignOutSheet : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ✅ Plain icon — no circle, no animation
            SizedBox(
              width: 22, height: 22,
              child: _navIcon(index, color),
            ),

            const SizedBox(height: 4),

            // Label
            Text(
              _navLabels[index],
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: color,
              ),
            ),

            const SizedBox(height: 3),

            // Active dot
            Container(
              width: isActive ? 4 : 0,
              height: isActive ? 4 : 0,
              decoration: BoxDecoration(
                color: const Color(0xFFDEFF6E),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(int index, Color color) {
    const size = 22.0;
    switch (index) {
      case 0:
        return PhosphorIcon(
            PhosphorIcons.mapPin(PhosphorIconsStyle.bold),
            color: color, size: size);
      case 1:
        return PhosphorIcon(
            PhosphorIcons.compass(PhosphorIconsStyle.bold),
            color: color, size: size);
      case 2:
        return PhosphorIcon(
            PhosphorIcons.ticket(PhosphorIconsStyle.bold),
            color: color, size: size);
      case 3:
        return PhosphorIcon(
            PhosphorIcons.buildings(PhosphorIconsStyle.bold),
            color: color, size: size);
      case 4:
        return PhosphorIcon(
            PhosphorIcons.userCircle(PhosphorIconsStyle.bold),
            color: color, size: size);
      default:
        return const SizedBox.shrink();
    }
  }
}
