import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/bookings_tab.dart';
import 'tabs/tiers_tab.dart';
import 'tabs/analytics_tab.dart';
import 'tabs/space_tab.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen>{
  final _supabase = Supabase.instance.client;

  // Single declaration
  int _currentIndex = 0;
  Map<String, dynamic>? _selectedSpace;
  List<Map<String, dynamic>> _spaces = [];
  bool _isLoading = true;
  int _pendingCount = 0;
  int _unreadCount = 0;


  // Navigation labels (Bottom Tab)
  final List<String> _navLabels = [
    'Home',
    'Bookings',
    'Tiers',
    'Analytics',
    'Space',
  ];

  @override
  void initState() {
    super.initState();
    _loadSpaceAndCounts();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
  }

  // BACKEND LOGIC

  Future<void> _loadSpaceAndCounts() async {
    setState(() => _isLoading = true);
    try {
      final userId =
          _supabase.auth.currentUser!.id;

      final spacesRes = await _supabase
          .from('spaces')
          .select()
          .eq('admin_id', userId);

      final spaces =
      List<Map<String, dynamic>>.from(
          spacesRes);

      if (spaces.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final selectedSpace =
          _selectedSpace ?? spaces[0];

      final pendingRes = await _supabase
          .from('bookings')
          .select('id')
          .eq('space_id', selectedSpace['id'])
          .eq('status', 'pending');

      final notifRes = await _supabase
          .from('notifications')
          .select('id')
          .eq('recipient_id', userId)
          .eq('is_read', false);

      setState(() {
        _spaces = spaces;
        _selectedSpace = selectedSpace;
        _pendingCount =
            (pendingRes as List).length;
        _unreadCount = (notifRes as List).length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Shell load error: $e');
    }
  }

  void _showAdminLogoutSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(context).padding.bottom +
                24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color:
                    Colors.white.withOpacity(0.1),
                    borderRadius:
                    BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Sign Out',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3)),
            const SizedBox(height: 6),
            Text(
              'You will be returned to the login screen.',
              style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 13,
                  height: 1.4),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      Navigator.pop(context),
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(
                        vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withOpacity(0.06),
                      borderRadius:
                      BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white
                              .withOpacity(0.08)),
                    ),
                    child: Center(
                      child: Text('Cancel',
                          style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight:
                              FontWeight.w600)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    await _supabase.auth.signOut();
                  },
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(
                        vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444)
                          .withOpacity(0.12),
                      borderRadius:
                      BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(
                              0xFFEF4444)
                              .withOpacity(0.4)),
                    ),
                    child: Center(
                      child: Text('Sign Out',
                          style: GoogleFonts.inter(
                              color: const Color(
                                  0xFFEF4444),
                              fontSize: 14,
                              fontWeight:
                              FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF111111),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFDEFF6E),
            strokeWidth: 2,
          ),
        ),
      );
    }


    final spaceId =
    _selectedSpace!['id'] as String;
    final spaceName =
    _selectedSpace!['name'] as String;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF111111),
        extendBody: true,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            DashboardTab(
              space: _selectedSpace!,
              spaces: _spaces,
              unreadCount: _unreadCount,
              onSpaceSwitch: (space) {
                setState(
                        () => _selectedSpace = space);
                _loadSpaceAndCounts();
              },
              onRefresh: _loadSpaceAndCounts,
              onSwitchTab: (index) => setState(() => _currentIndex = index),
            ),
            BookingsTab(
              spaceId: spaceId,
              onRefresh: _loadSpaceAndCounts,
            ),
            TiersTab(
              key: ValueKey('tiers_${_selectedSpace!['image_url'] ?? ''}'),
              spaceId: spaceId,
              spaceName: spaceName,
            ),
            AnalyticsTab(
              spaceId: spaceId,
              space: _selectedSpace,
            ),
            SpaceTab(
              spaceId: _selectedSpace!['id'] as String,
              onSpaceUpdated: (updatedSpace) {
                setState(() => _selectedSpace = updatedSpace);
                _loadSpaceAndCounts();
              },
            ),
          ],
        ),
        bottomNavigationBar:
        _buildFloatingNav(context),
      ),
    );
  }

  Widget _buildFloatingNav(
      BuildContext context) {
    final bottomPad =
        MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, bottomPad + 12),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius:
          BorderRadius.circular(32),
          border: Border.all(
            color:
            Colors.white.withOpacity(0.07),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
              Colors.black.withOpacity(0.5),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceAround,
          children: List.generate(
            _navLabels.length,
            _buildNavItem,
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
    final showBadge = index == 1 && _pendingCount > 0;

    return GestureDetector(
      onTap: () => _onTabTap(index),
      onLongPress: index == 4
          ? _showAdminLogoutSheet
          : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // Icon and Badge
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 24, height: 24,
                  child: _navIcon(index, isActive),
                ),
                if (showBadge)
                  Positioned(
                    top: -4, right: -4,
                    child: Container(
                      width: 14, height: 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$_pendingCount',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 5),

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

  Widget _navIcon(int index, bool isActive) {
    final color = isActive
        ? const Color(0xFFDEFF6E)
        : Colors.white.withOpacity(0.45);
    const size = 22.0;

    switch (index) {
      case 0:
        return PhosphorIcon(
            PhosphorIcons.squaresFour(PhosphorIconsStyle.bold),
            color: color, size: size);
      case 1:
        return PhosphorIcon(
            PhosphorIcons.calendarCheck(PhosphorIconsStyle.bold),
            color: color, size: size);
      case 2:
        return PhosphorIcon(
            PhosphorIcons.stack(PhosphorIconsStyle.bold),
            color: color, size: size);
      case 3:
        return PhosphorIcon(
            PhosphorIcons.chartBar(PhosphorIconsStyle.bold),
            color: color, size: size);
      case 4:
        return PhosphorIcon(
            PhosphorIcons.buildings(PhosphorIconsStyle.bold),
            color: color, size: size);
      default:
        return const SizedBox.shrink();
    }
  }
}