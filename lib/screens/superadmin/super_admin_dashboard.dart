import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() =>
      _SuperAdminDashboardState();
}

class _SuperAdminDashboardState
    extends State<SuperAdminDashboard> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _pendingSpaces = [];
  List<Map<String, dynamic>> _approvedSpaces = [];
  List<Map<String, dynamic>> _rejectedSpaces = [];
  bool _isLoading = true;
  String _currentFilter = 'pending';

  final _filters = ['pending', 'approved', 'rejected'];

  @override
  void initState() {
    super.initState();
    _loadSpaces();
  }

  // ── BACKEND (all unchanged) ───────────────────

  Future<void> _loadSpaces() async {
    setState(() => _isLoading = true);
    try {
      final all = await _supabase
          .from('spaces')
          .select(
          '*, users!spaces_admin_id_fkey(name, email, phone)')
          .order('created_at', ascending: false);

      final spaces =
      List<Map<String, dynamic>>.from(all);

      setState(() {
        _pendingSpaces = spaces
            .where((s) =>
        s['is_verified'] == false &&
            s['is_active'] == false)
            .toList();
        _approvedSpaces = spaces
            .where((s) =>
        s['is_verified'] == true &&
            s['is_active'] == true)
            .toList();
        _rejectedSpaces = spaces
            .where((s) =>
        s['is_verified'] == false &&
            s['is_active'] == true)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Super admin error: $e');
    }
  }

  Future<void> _approveSpace(
      String spaceId, String adminId) async {
    try {
      await _supabase.from('spaces').update({
        'is_verified': true,
        'is_active': true,
      }).eq('id', spaceId);

      await _supabase.from('notifications').insert({
        'recipient_id': adminId,
        'booking_id': null,
        'message':
        'Your space has been approved and is now live on HIVE!',
      });

      if (mounted) {
        _snack('Space approved and is now live');
        _loadSpaces();
      }
    } catch (e) {
      if (mounted)
        _snack('Error: $e', isError: true);
    }
  }

  Future<void> _rejectSpace(
      String spaceId, String adminId) async {
    final ctrl = TextEditingController();
    String? reason;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx)
                  .viewInsets
                  .bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C1E),
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(
                24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white
                            .withOpacity(0.1),
                        borderRadius:
                        BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),

                Row(children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444)
                          .withOpacity(0.1),
                      borderRadius:
                      BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFEF4444)
                              .withOpacity(0.3)),
                    ),
                    child: const Icon(
                        Icons.block_rounded,
                        color: Color(0xFFEF4444),
                        size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text('Reject Space',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight:
                              FontWeight.w800)),
                      Text(
                          'The admin will be notified',
                          style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 12)),
                    ],
                  ),
                ]),
                const SizedBox(height: 20),

                Text('Reason for rejection',
                    style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3)),
                const SizedBox(height: 8),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius:
                    BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white
                            .withOpacity(0.08)),
                  ),
                  child: TextField(
                    controller: ctrl,
                    maxLines: 4,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14),
                    decoration: InputDecoration(
                      hintText:
                      'Explain why this space is being rejected...',
                      hintStyle: GoogleFonts.inter(
                          color: Colors.white24,
                          fontSize: 13),
                      border: InputBorder.none,
                      contentPadding:
                      const EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pop(context),
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(
                            vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withOpacity(0.06),
                          borderRadius:
                          BorderRadius.circular(13),
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
                      onTap: () {
                        reason = ctrl.text.trim();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(
                            vertical: 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444)
                              .withOpacity(0.12),
                          borderRadius:
                          BorderRadius.circular(13),
                          border: Border.all(
                              color: const Color(
                                  0xFFEF4444)
                                  .withOpacity(0.4)),
                        ),
                        child: Center(
                          child: Text('Reject',
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
        ),
      ),
    );

    if (reason == null || reason!.isEmpty) return;

    try {
      await _supabase.from('spaces').update({
        'is_verified': false,
        'is_active': true,
      }).eq('id', spaceId);

      await _supabase.from('notifications').insert({
        'recipient_id': adminId,
        'booking_id': null,
        'message':
        'Your space registration was not approved. Reason: $reason',
      });

      if (mounted) {
        _snack('Space rejected — admin notified');
        _loadSpaces();
      }
    } catch (e) {
      if (mounted)
        _snack('Error: $e', isError: true);
    }
  }

  // ── Logout sheet ──────────────────────────────

  void _showLogoutSheet() {
    HapticFeedback.mediumImpact();
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
            MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    height: 1.4)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    decoration: BoxDecoration(
                      color:
                      Colors.white.withOpacity(0.06),
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
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444)
                          .withOpacity(0.12),
                      borderRadius:
                      BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFEF4444)
                              .withOpacity(0.4)),
                    ),
                    child: Center(
                      child: Text('Sign Out',
                          style: GoogleFonts.inter(
                              color:
                              const Color(0xFFEF4444),
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

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.inter(
              color: isError ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600)),
      backgroundColor: isError
          ? const Color(0xFFEF4444)
          : const Color(0xFFDEFF6E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Helpers ───────────────────────────────────

  List<Map<String, dynamic>> get _currentSpaces {
    switch (_currentFilter) {
      case 'approved': return _approvedSpaces;
      case 'rejected': return _rejectedSpaces;
      default: return _pendingSpaces;
    }
  }

  Color _filterColor(String f) {
    switch (f) {
      case 'approved': return const Color(0xFF34D399);
      case 'rejected': return const Color(0xFFEF4444);
      default: return const Color(0xFFFBBF24);
    }
  }

  // ── BUILD ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad =
        MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Column(children: [

        // ── Header ────────────────────────────
        Container(
          color: const Color(0xFF111111),
          padding: EdgeInsets.fromLTRB(
              20, topPad + 16, 20, 16),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(children: [
                // HIVE badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEFF6E),
                    borderRadius:
                    BorderRadius.circular(8),
                  ),
                  child: Text('HIVE',
                      style: GoogleFonts.inter(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1)),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius:
                    BorderRadius.circular(6),
                    border: Border.all(
                        color: Colors.white
                            .withOpacity(0.1)),
                  ),
                  child: Text('Super Admin',
                      style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight:
                          FontWeight.w600)),
                ),
                const Spacer(),

                // Long-press avatar for logout
                GestureDetector(
                  onLongPress: _showLogoutSheet,
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withOpacity(0.06),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white
                              .withOpacity(0.1)),
                    ),
                    child: Center(
                      child: PhosphorIcon(
                        PhosphorIcons.userCircle(
                            PhosphorIconsStyle.bold),
                        color: Colors.white54,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 16),

              Text('Space Registrations',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
              const SizedBox(height: 2),
              Text(
                '${_pendingSpaces.length} pending review',
                style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 13),
              ),
              const SizedBox(height: 16),

              // ── Filter pills ─────────────────
              Row(children: [
                ..._filters.map((f) {
                  final active = _currentFilter == f;
                  final color = _filterColor(f);
                  final count = f == 'pending'
                      ? _pendingSpaces.length
                      : f == 'approved'
                      ? _approvedSpaces.length
                      : _rejectedSpaces.length;

                  return GestureDetector(
                    onTap: () => setState(
                            () => _currentFilter = f),
                    child: AnimatedContainer(
                      duration: const Duration(
                          milliseconds: 200),
                      margin: const EdgeInsets.only(
                          right: 8),
                      padding: const EdgeInsets
                          .symmetric(
                          horizontal: 14,
                          vertical: 8),
                      decoration: BoxDecoration(
                        color: active
                            ? color
                            : Colors.white
                            .withOpacity(0.06),
                        borderRadius:
                        BorderRadius.circular(20),
                        border: Border.all(
                          color: active
                              ? Colors.transparent
                              : Colors.white
                              .withOpacity(0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            f[0].toUpperCase() +
                                f.substring(1),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: active
                                  ? (f == 'approved'
                                  ? Colors.black
                                  : Colors.white)
                                  : Colors.white54,
                            ),
                          ),
                          if (count > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets
                                  .symmetric(
                                  horizontal: 6,
                                  vertical: 1),
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.black
                                    .withOpacity(0.2)
                                    : color.withOpacity(
                                    0.15),
                                borderRadius:
                                BorderRadius.circular(
                                    10),
                              ),
                              child: Text('$count',
                                  style: GoogleFonts.inter(
                                      color: active
                                          ? (f == 'approved'
                                          ? Colors.black
                                          : Colors.white)
                                          : color,
                                      fontSize: 10,
                                      fontWeight:
                                      FontWeight.w700)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ]),
            ],
          ),
        ),

        // ── Long press hint ───────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 6),
          child: Text(
            'Long-press the profile icon to sign out',
            style: GoogleFonts.inter(
                color: Colors.white12,
                fontSize: 10),
          ),
        ),

        // ── List ──────────────────────────────
        Expanded(
          child: _isLoading
              ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFFDEFF6E),
                  strokeWidth: 2))
              : _currentSpaces.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
            onRefresh: _loadSpaces,
            color: const Color(0xFFDEFF6E),
            backgroundColor:
            const Color(0xFF1C1C1E),
            child: ListView.builder(
              padding:
              EdgeInsets.fromLTRB(
                  20, 8, 20,
                  bottomPad + 40),
              itemCount:
              _currentSpaces.length,
              itemBuilder: (_, i) =>
                  _buildSpaceCard(
                      _currentSpaces[i]),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Empty state ───────────────────────────────

  Widget _buildEmpty() {
    final msgs = {
      'pending': 'No pending registrations',
      'approved': 'No approved spaces yet',
      'rejected': 'No rejected spaces',
    };
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withOpacity(0.08)),
            ),
            child: Center(
              child: PhosphorIcon(
                PhosphorIcons.buildings(
                    PhosphorIconsStyle.regular),
                color: Colors.white24,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(msgs[_currentFilter] ?? 'Nothing here',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Pull to refresh',
              style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 13)),
        ],
      ),
    );
  }

  // ── Space card ────────────────────────────────

  Widget _buildSpaceCard(
      Map<String, dynamic> space) {
    final isPending = _currentFilter == 'pending';
    final admin =
        (space['users'] as Map<String, dynamic>?) ??
            {'name': 'Unknown', 'email': ''};
    final name = space['name'] as String? ?? '';
    final address =
        space['address'] as String? ?? '';
    final desc =
        space['description'] as String? ?? '';
    final imageUrl =
    space['image_url'] as String?;
    final adminName =
        admin['name'] as String? ?? 'Unknown';
    final adminEmail =
        admin['email'] as String? ?? '';

    // Initials
    final parts = adminName.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : adminName.isNotEmpty
        ? adminName[0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending
              ? const Color(0xFFFBBF24).withOpacity(0.2)
              : Colors.white.withOpacity(0.07),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [

        // ── Hero image ────────────────────────
        SizedBox(
          height: 160,
          width: double.infinity,
          child: Stack(fit: StackFit.expand, children: [
            imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _imgFallback())
                : _imgFallback(),

            // Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0x00000000),
                    Color(0xBB1C1C1E),
                    Color(0xFF1C1C1E),
                  ],
                  stops: [0.0, 0.4, 0.78, 1.0],
                ),
              ),
            ),

            // Status badge
            Positioned(
              top: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius:
                  BorderRadius.circular(20),
                  border: Border.all(
                    color: _filterColor(_currentFilter)
                        .withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: _filterColor(
                            _currentFilter),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _currentFilter[0]
                          .toUpperCase() +
                          _currentFilter.substring(1),
                      style: GoogleFonts.inter(
                          color: _filterColor(
                              _currentFilter),
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),

            // Space name at bottom of image
            Positioned(
              bottom: 12, left: 16, right: 16,
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(children: [
                    PhosphorIcon(
                      PhosphorIcons.mapPin(
                          PhosphorIconsStyle.bold),
                      color: Colors.white38,
                      size: 11,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(address,
                          style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 12),
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis),
                    ),
                  ]),
                ],
              ),
            ),
          ]),
        ),

        // ── Details ───────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [

              // Description
              if (desc.isNotEmpty) ...[
                Text(desc,
                    style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 13,
                        height: 1.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
              ],

              // Info chips
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  _infoChip(
                    PhosphorIcons.clock(
                        PhosphorIconsStyle.regular),
                    '${_trimTime(space['opening_time'])} – ${_trimTime(space['closing_time'])}',
                    const Color(0xFFDEFF6E),
                  ),
                  if (space['latitude'] != null)
                    _infoChip(
                      PhosphorIcons.mapPin(
                          PhosphorIconsStyle.regular),
                      '${(space['latitude'] as num).toStringAsFixed(4)}, '
                          '${(space['longitude'] as num).toStringAsFixed(4)}',
                      const Color(0xFF60A5FA),
                    ),
                ],
              ),

              // Amenities
              if ((space['amenities'] as List?)
                  ?.isNotEmpty ==
                  true) ...[
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: (space['amenities']
                    as List)
                        .take(6)
                        .map((a) => Container(
                      margin: const EdgeInsets
                          .only(right: 6),
                      padding:
                      const EdgeInsets
                          .symmetric(
                          horizontal: 10,
                          vertical: 4),
                      decoration:
                      BoxDecoration(
                        color: Colors.white
                            .withOpacity(0.06),
                        borderRadius:
                        BorderRadius
                            .circular(20),
                        border: Border.all(
                            color: Colors.white
                                .withOpacity(
                                0.08)),
                      ),
                      child: Text(
                          a.toString(),
                          style: GoogleFonts
                              .inter(
                              color: Colors
                                  .white54,
                              fontSize: 10,
                              fontWeight:
                              FontWeight
                                  .w500)),
                    ))
                        .toList(),
                  ),
                ),
              ],

              const SizedBox(height: 14),
              Divider(
                  color: Colors.white.withOpacity(0.07),
                  height: 1),
              const SizedBox(height: 12),

              // Admin info
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEFF6E)
                        .withOpacity(0.1),
                    borderRadius:
                    BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFDEFF6E)
                            .withOpacity(0.2)),
                  ),
                  child: Center(
                    child: Text(initials,
                        style: GoogleFonts.inter(
                            color: const Color(
                                0xFFDEFF6E),
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(adminName,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight:
                              FontWeight.w700)),
                      Text(adminEmail,
                          style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 11)),
                    ],
                  ),
                ),
                // Admin badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius:
                    BorderRadius.circular(6),
                  ),
                  child: Text('Space Admin',
                      style: GoogleFonts.inter(
                          color: Colors.white24,
                          fontSize: 9,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
            ],
          ),
        ),

        // ── Action buttons (pending only) ──────
        if (isPending) ...[
          Container(
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: Colors.white
                          .withOpacity(0.06))),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              // Reject
              Expanded(
                child: GestureDetector(
                  onTap: () => _rejectSpace(
                      space['id'],
                      space['admin_id']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444)
                          .withOpacity(0.08),
                      borderRadius:
                      BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFEF4444)
                              .withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        PhosphorIcon(
                          PhosphorIcons.x(
                              PhosphorIconsStyle.bold),
                          color: const Color(0xFFEF4444),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text('Reject',
                            style: GoogleFonts.inter(
                                color: const Color(
                                    0xFFEF4444),
                                fontSize: 13,
                                fontWeight:
                                FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Approve
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () => _approveSpace(
                      space['id'],
                      space['admin_id']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDEFF6E),
                      borderRadius:
                      BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFFDEFF6E)
                                .withOpacity(0.2),
                            blurRadius: 8),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        PhosphorIcon(
                          PhosphorIcons.check(
                              PhosphorIconsStyle.bold),
                          color: Colors.black,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text('Approve & Go Live',
                            style: GoogleFonts.inter(
                                color: Colors.black,
                                fontSize: 13,
                                fontWeight:
                                FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  // ── Helpers ───────────────────────────────────

  Widget _imgFallback() => Container(
    color: const Color(0xFFF97316).withOpacity(0.06),
    child: Center(
      child: PhosphorIcon(
        PhosphorIcons.buildings(
            PhosphorIconsStyle.regular),
        color: Colors.white12,
        size: 48,
      ),
    ),
  );

  Widget _infoChip(
      IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _trimTime(dynamic t) {
    if (t == null) return '—';
    final s = t.toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
  }
}