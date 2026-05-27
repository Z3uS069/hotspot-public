import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'directions_screen.dart';
import 'booking_qr_screen.dart';
import '../../services/invoice_service.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() =>
      _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String _currentFilter = 'pending';

  final List<String> _filters = [
    'pending',
    'confirmed',
    'completed',
    'cancelled',
  ];
  // ── Segment ───────────────────────────────────
  int _segment = 0; // 0=Bookings 1=Enquiries

  // ── Memberships ───────────────────────────────
  List<Map<String, dynamic>> _subs = [];
  bool _subsLoading = true;
  String _subStatus = 'pending';
  final _subStatuses = [
    'pending', 'active', 'expired', 'cancelled'
  ];

  // ── Enquiries ─────────────────────────────────
  List<Map<String, dynamic>> _enquiries = [];
  bool _enquiriesLoading = true;
  String _enquiryStatus = 'pending';
  final _enquiryStatuses = [
    'pending', 'tour_scheduled',
    'negotiating', 'converted', 'rejected',
  ];
  final _enquiryStatusLabels = {
    'pending': 'Pending',
    'tour_scheduled': 'Tour Scheduled',
    'negotiating': 'Negotiating',
    'converted': 'Converted',
    'rejected': 'Rejected',
  };

  // ── BACKEND (all unchanged) ───────────────────

  @override
  void initState() {
    super.initState();
    _loadBookings();
    _loadSubs();
    _loadEnquiries();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('bookings')
          .select(
          '*, spaces(name, address, image_url), tiers(name, booking_type, price_per_hour, price_per_day, price_per_month, price_per_year), users!bookings_user_id_fkey(name, email)')
          .eq('user_id', userId)
          .eq('status', _currentFilter)
          .order('created_at', ascending: false);
      setState(() {
        _bookings =
        List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('My bookings error: $e');
    }
  }
  Future<void> _loadSubs() async {
    setState(() => _subsLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final res = await _supabase
          .from('subscriptions')
          .select(
          '*, spaces(name, address, image_url), '
              'tiers(name, booking_type)')
          .eq('user_id', userId)
          .eq('status', _subStatus)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _subs =
          List<Map<String, dynamic>>.from(res);
          _subsLoading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() => _subsLoading = false);
      debugPrint('Subs load error: $e');
    }
  }

  Future<void> _loadEnquiries() async {
    setState(() => _enquiriesLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final res = await _supabase
          .from('enquiries')
          .select(
          '*, spaces(name, address, image_url), '
              'tiers(name)')
          .eq('user_id', userId)
          .eq('status', _enquiryStatus)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _enquiries =
          List<Map<String, dynamic>>.from(res);
          _enquiriesLoading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() => _enquiriesLoading = false);
      debugPrint('Enquiries load error: $e');
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    final reason = await _showCancelSheet();
    if (reason == null) return;
    try {
      await _supabase.from('bookings').update({
        'status': 'cancelled',
        'cancellation_reason': reason,
        'cancelled_at': DateTime.now().toIso8601String(),
        'cancelled_by': _supabase.auth.currentUser!.id,
      }).eq('id', bookingId);

      final booking =
      _bookings.firstWhere((b) => b['id'] == bookingId);
      final tier = await _supabase
          .from('tiers')
          .select('available_seats')
          .eq('id', booking['tier_id'])
          .single();

      await _supabase.from('tiers').update({
        'available_seats': (tier['available_seats'] as int) + 1,
      }).eq('id', booking['tier_id']);

      if (mounted) {
        _snack('Booking cancelled');
        _loadBookings();
      }
    } catch (e) {
      if (mounted) _snack('Cancellation failed: $e', isError: true);
    }
  }

  Future<void> _submitReview(
      Map<String, dynamic> booking) async {
    await _showReviewSheet(booking);
  }

  void _snack(String msg, {bool isError = false}) {
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

  // ── Cancel sheet ──────────────────────────────

  Future<String?> _showCancelSheet() async {
    final ctrl = TextEditingController();
    String? result;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),

              Text('Cancel Booking',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3)),
              const SizedBox(height: 4),
              Text(
                  'Let us know why you\'re cancelling.',
                  style: GoogleFonts.inter(
                      color: Colors.white38, fontSize: 13)),
              const SizedBox(height: 20),

              // Reason input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: ctrl,
                  style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 14),
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter your reason...',
                    hintStyle: GoogleFonts.inter(
                        color: Colors.white24, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
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
                        child: Text('Keep Booking',
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
                    onTap: () {
                      if (ctrl.text.trim().isEmpty) {
                        _snack('Please enter a reason',
                            isError: true);
                        return;
                      }
                      result = ctrl.text.trim();
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text('Cancel Booking',
                            style: GoogleFonts.inter(
                                color: Colors.white,
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
      ),
    );

    return result;
  }

  // ── Review sheet ──────────────────────────────

  Future<void> _showReviewSheet(
      Map<String, dynamic> booking) async {
    int selectedRating = 5;
    final commentCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),

              Text('Leave a Review',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3)),
              const SizedBox(height: 4),
              Text(
                  (booking['spaces']
                  as Map<String, dynamic>?)?['name'] ??
                      '',
                  style: GoogleFonts.inter(
                      color: Colors.white38, fontSize: 13)),
              const SizedBox(height: 24),

              // Star rating
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    final filled = i < selectedRating;
                    return GestureDetector(
                      onTap: () =>
                          setS(() => selectedRating = i + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6),
                        child: AnimatedContainer(
                          duration:
                          const Duration(milliseconds: 150),
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: filled
                                ? const Color(0xFFDEFF6E)
                                : Colors.white.withOpacity(0.06),
                            borderRadius:
                            BorderRadius.circular(12),
                            border: Border.all(
                              color: filled
                                  ? Colors.transparent
                                  : Colors.white
                                  .withOpacity(0.1),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: GoogleFonts.inter(
                                color: filled
                                    ? Colors.black
                                    : Colors.white24,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _ratingLabel(selectedRating),
                  style: GoogleFonts.inter(
                      color: const Color(0xFFDEFF6E),
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 20),

              // Comment input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: commentCtrl,
                  style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 14),
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Share your experience...',
                    hintStyle: GoogleFonts.inter(
                        color: Colors.white24, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
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
                        child: Text('Skip',
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
                  flex: 2,
                  child: GestureDetector(
                    onTap: () async {
                      try {
                        final userId =
                            _supabase.auth.currentUser!.id;
                        await _supabase.from('reviews').insert({
                          'user_id': userId,
                          'space_id': booking['space_id'],
                          'booking_id': booking['id'],
                          'rating': selectedRating,
                          'comment': commentCtrl.text.trim(),
                        });

                        final reviews = await _supabase
                            .from('reviews')
                            .select('rating')
                            .eq('space_id', booking['space_id']);
                        final ratings = (reviews as List)
                            .map((r) => r['rating'] as int)
                            .toList();
                        final avg =
                            ratings.reduce((a, b) => a + b) /
                                ratings.length;
                        await _supabase.from('spaces').update({
                          'average_rating':
                          avg.toStringAsFixed(1),
                          'total_reviews': ratings.length,
                        }).eq('id', booking['space_id']);

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          _snack('Review submitted — thank you!');
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          _snack('Error: $e', isError: true);
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDEFF6E),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFFDEFF6E)
                                  .withOpacity(0.2),
                              blurRadius: 12),
                        ],
                      ),
                      child: Center(
                        child: Text('Submit Review',
                            style: GoogleFonts.inter(
                                color: Colors.black,
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
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Great';
      case 5: return 'Excellent';
      default: return '';
    }
  }

  // ── BUILD ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Column(children: [

        // ── Header ────────────────────────────────
        Container(
          color: const Color(0xFF111111),
          padding: EdgeInsets.fromLTRB(
              20, topPad + 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Bookings',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
              Text('Track and manage your reservations',
                  style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 13)),
              const SizedBox(height: 16),

              // ── Top segment: Bookings / Memberships / Enquiries
              _buildTopSegment(),
              const SizedBox(height: 12),

              // ── Status filter pills per segment
              _buildStatusPills(),
            ],
          ),
        ),

        // ── Content ───────────────────────────────
        // ── Content ───────────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _loadBookings();
              _loadSubs();
              _loadEnquiries();
            },
            color: const Color(0xFFDEFF6E),
            backgroundColor: const Color(0xFF1C1C1E),
            child: _buildCurrentSegmentContent(),
          ),
        ),
      ]),
    );
  }

  // ── Segmented control ─────────────────────────

  // ── Top segment control ───────────────────────

  Widget _buildTopSegment() {
    final labels = ['Bookings', 'Enquiries'];
    final colors = [
      const Color(0xFFDEFF6E),
      const Color(0xFFF97316),
    ];

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: labels.asMap().entries.map((e) {
          final i = e.key;
          final active = _segment == i;
          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  setState(() => _segment = i),
              child: AnimatedContainer(
                duration: const Duration(
                    milliseconds: 200),
                decoration: BoxDecoration(
                  color: active
                      ? colors[i]
                      : Colors.transparent,
                  borderRadius:
                  BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(e.value,
                      style: GoogleFonts.inter(
                        color: active
                            ? Colors.black
                            : Colors.white38,
                        fontSize: 12,
                        fontWeight: active
                            ? FontWeight.w700
                            : FontWeight.w500,
                      )),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Status pills per segment ──────────────────

  Widget _buildStatusPills() {
    // Segment 0 (Bookings) — session status pills at top
    // Memberships has its own inline pills
    if (_segment == 0) {
      return _pillRow(
        statuses: _filters,
        current: _currentFilter,
        activeColor: const Color(0xFFDEFF6E),
        activeTextColor: Colors.black,
        onTap: (s) {
          setState(() => _currentFilter = s);
          _loadBookings();
        },
        labelOf: (s) =>
        s[0].toUpperCase() + s.substring(1),
      );
    }
    // Segment 1 (Enquiries)
    return _pillRow(
      statuses: _enquiryStatuses,
      current: _enquiryStatus,
      activeColor: const Color(0xFFF97316),
      activeTextColor: Colors.white,
      onTap: (s) {
        setState(() => _enquiryStatus = s);
        _loadEnquiries();
      },
      labelOf: (s) => _enquiryStatusLabels[s] ?? s,
    );
  }

  Widget _pillRow({
    required List<String> statuses,
    required String current,
    required Color activeColor,
    required Color activeTextColor,
    required void Function(String) onTap,
    required String Function(String) labelOf,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses.map((s) {
          final active = current == s;
          return GestureDetector(
            onTap: () => onTap(s),
            child: AnimatedContainer(
              duration: const Duration(
                  milliseconds: 200),
              margin:
              const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? activeColor
                    : Colors.white.withOpacity(0.06),
                borderRadius:
                BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.08),
                ),
              ),
              child: Text(
                labelOf(s),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: active
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: active
                      ? activeTextColor
                      : Colors.white38,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Content per segment ───────────────────────

  Widget _buildCurrentSegmentContent() {
    if (_segment == 0)
      return _buildUnifiedBookingsContent();
    return _buildEnquiriesList();
  }

  Widget _buildUnifiedBookingsContent() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [

        // ── Sessions section ─────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                20, 8, 20, 12),
            child: Row(children: [
              Container(
                width: 3, height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFDEFF6E),
                  borderRadius:
                  BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text('Sessions',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(
                  '${_bookings.length} ${_currentFilter}',
                  style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 12)),
            ]),
          ),
        ),

        if (_isLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFDEFF6E),
                    strokeWidth: 2),
              ),
            ),
          )
        else if (_bookings.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  20, 0, 20, 20),
              child: _buildSegmentEmpty(
                'No $_currentFilter sessions',
                'Your session bookings will appear here.',
                Icons.calendar_today_outlined,
                const Color(0xFFDEFF6E),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                padding: const EdgeInsets.fromLTRB(
                    20, 0, 20, 0),
                child: _buildBookingCard(
                    _bookings[i]),
              ),
              childCount: _bookings.length,
            ),
          ),

        // ── Divider ──────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                20, 16, 20, 20),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Divider(
                    color: Colors.white
                        .withOpacity(0.07),
                    height: 1),
                const SizedBox(height: 16),

                // ── Memberships header + inline filter
                Row(children: [
                  Container(
                    width: 3, height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFA78BFA),
                      borderRadius:
                      BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Memberships',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 10),

                // Compact membership status pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _subStatuses.map((s) {
                      final active = _subStatus == s;
                      return GestureDetector(
                        onTap: () {
                          setState(
                                  () => _subStatus = s);
                          _loadSubs();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(
                              milliseconds: 180),
                          margin: const EdgeInsets
                              .only(right: 6),
                          padding: const EdgeInsets
                              .symmetric(
                              horizontal: 12,
                              vertical: 6),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(
                                0xFFA78BFA)
                                : Colors.white
                                .withOpacity(0.05),
                            borderRadius:
                            BorderRadius.circular(
                                20),
                            border: Border.all(
                                color: active
                                    ? Colors.transparent
                                    : Colors.white
                                    .withOpacity(
                                    0.08)),
                          ),
                          child: Text(
                            s[0].toUpperCase() +
                                s.substring(1),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: active
                                  ? Colors.black
                                  : Colors.white38,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Memberships list ─────────────────
        if (_subsLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFA78BFA),
                    strokeWidth: 2),
              ),
            ),
          )
        else if (_subs.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  20, 0, 20, 20),
              child: _buildSegmentEmpty(
                'No $_subStatus memberships',
                'Your memberships will appear here.',
                Icons.card_membership_rounded,
                const Color(0xFFA78BFA),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                padding: const EdgeInsets.fromLTRB(
                    20, 0, 20, 0),
                child: _buildSubCard(_subs[i]),
              ),
              childCount: _subs.length,
            ),
          ),

        // Bottom padding
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.of(context)
                .padding
                .bottom +
                100,
          ),
        ),
      ],
    );
  }

  Widget _buildSubCard(
      Map<String, dynamic> sub) {
    final space =
        sub['spaces'] as Map<String, dynamic>? ?? {};
    final tier =
        sub['tiers'] as Map<String, dynamic>? ?? {};
    final status =
        sub['status'] as String? ?? 'pending';
    final spaceName =
        space['name'] as String? ?? 'Unknown Space';
    final tierName =
        tier['name'] as String? ?? '';
    final months =
        sub['months_committed'] as int? ?? 1;
    final total =
        (sub['total_price'] as num?)?.toDouble() ?? 0;
    final startDate = sub['start_date'] as String?;
    final endDate = sub['end_date'] as String?;
    final imageUrl = space['image_url'] as String?;

    final Color statusColor;
    switch (status) {
      case 'active':
        statusColor = const Color(0xFF34D399);
        break;
      case 'expired':
        statusColor = const Color(0xFFEF4444);
        break;
      case 'cancelled':
        statusColor = const Color(0xFF6B7280);
        break;
      default:
        statusColor = const Color(0xFFFBBF24);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withOpacity(0.07)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [

        // Hero image
        SizedBox(
          height: 130,
          width: double.infinity,
          child: Stack(
              fit: StackFit.expand,
              children: [
                imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _memberImgFallback())
                    : _memberImgFallback(),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),
                        Color(0xBB1C1C1E),
                        Color(0xFF1C1C1E),
                      ],
                      stops: [0.4, 0.78, 1.0],
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
                      color:
                      Colors.black.withOpacity(0.55),
                      borderRadius:
                      BorderRadius.circular(20),
                      border: Border.all(
                          color: statusColor
                              .withOpacity(0.4)),
                    ),
                    child: Text(
                      status[0].toUpperCase() +
                          status.substring(1),
                      style: GoogleFonts.inter(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                // Space + tier name
                Positioned(
                  bottom: 12, left: 14, right: 14,
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(spaceName,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (tierName.isNotEmpty)
                        Text(tierName,
                            style: GoogleFonts.inter(
                                color: const Color(
                                    0xFFA78BFA),
                                fontSize: 12,
                                fontWeight:
                                FontWeight.w600)),
                    ],
                  ),
                ),
              ]),
        ),

        // Details strip
        Padding(
          padding: const EdgeInsets.fromLTRB(
              16, 12, 16, 14),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: _infoCell(
                    'DURATION',
                    '$months month${months > 1 ? 's' : ''}'),
              ),
              Container(
                  width: 1, height: 32,
                  color:
                  Colors.white.withOpacity(0.07)),
              Expanded(
                  child: _infoCell(
                      'START',
                      _formatDate(startDate))),
              Container(
                  width: 1, height: 32,
                  color:
                  Colors.white.withOpacity(0.07)),
              Expanded(
                  child: _infoCell(
                      'END', _formatDate(endDate))),
            ]),
            const SizedBox(height: 12),

            // Total paid
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFA78BFA)
                    .withOpacity(0.07),
                borderRadius:
                BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFA78BFA)
                        .withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Paid',
                      style: GoogleFonts.inter(
                          color: const Color(0xFFA78BFA)
                              .withOpacity(0.7),
                          fontSize: 12)),
                  Text(
                      'LKR ${total.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                          color: const Color(
                              0xFFA78BFA),
                          fontSize: 15,
                          fontWeight:
                          FontWeight.w800)),
                ],
              ),
            ),

            // Pending notice
            if (status == 'pending') ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24)
                      .withOpacity(0.07),
                  borderRadius:
                  BorderRadius.circular(11),
                  border: Border.all(
                      color: const Color(0xFFFBBF24)
                          .withOpacity(0.2)),
                ),
                child: Text(
                  'Awaiting admin activation. '
                      'You\'ll be notified once your '
                      'membership is active.',
                  style: GoogleFonts.inter(
                      color: const Color(0xFFFBBF24),
                      fontSize: 12,
                      height: 1.4),
                ),
              ),
            ],

            // Expired notice
            if (status == 'expired') ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444)
                      .withOpacity(0.07),
                  borderRadius:
                  BorderRadius.circular(11),
                  border: Border.all(
                      color: const Color(0xFFEF4444)
                          .withOpacity(0.2)),
                ),
                child: Text(
                  'Your membership has expired. '
                      'Contact the space to renew.',
                  style: GoogleFonts.inter(
                      color: const Color(0xFFEF4444),
                      fontSize: 12,
                      height: 1.4),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _memberImgFallback() => Container(
    color: const Color(0xFFA78BFA)
        .withOpacity(0.08),
    child: const Center(
      child: Icon(Icons.card_membership_rounded,
          color: Color(0xFFA78BFA), size: 36),
    ),
  );
  Widget _buildEnquiriesList() {
    if (_enquiriesLoading) {
      return const Center(
          child: CircularProgressIndicator(
              color: Color(0xFFF97316),
              strokeWidth: 2));
    }
    if (_enquiries.isEmpty) {
      return _buildSegmentEmpty(
        'No ${_enquiryStatusLabels[_enquiryStatus]?.toLowerCase()} enquiries',
        'Your enquiries for private and contract '
            'spaces will appear here.',
        Icons.mail_outline_rounded,
        const Color(0xFFF97316),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
          20, 8, 20, 100),
      itemCount: _enquiries.length,
      itemBuilder: (_, i) =>
          _buildEnquiryCard(_enquiries[i]),
    );
  }

  Widget _buildEnquiryCard(
      Map<String, dynamic> enquiry) {
    final space = enquiry['spaces']
    as Map<String, dynamic>? ??
        {};
    final tier = enquiry['tiers']
    as Map<String, dynamic>? ??
        {};
    final status =
        enquiry['status'] as String? ?? 'pending';
    final spaceName =
        space['name'] as String? ?? 'Unknown Space';
    final tierName = tier['name'] as String? ?? '';
    final company =
        enquiry['company_name'] as String? ?? '—';
    final teamSize =
        enquiry['team_size'] as int? ?? 0;
    final preferred =
    enquiry['preferred_start_date'] as String?;
    final imageUrl = space['image_url'] as String?;

    final Color statusColor;
    switch (status) {
      case 'tour_scheduled':
        statusColor = const Color(0xFF60A5FA);
        break;
      case 'negotiating':
        statusColor = const Color(0xFFFBBF24);
        break;
      case 'converted':
        statusColor = const Color(0xFFDEFF6E);
        break;
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        break;
      default:
        statusColor = const Color(0xFFF97316);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withOpacity(0.07)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [

        // Hero
        SizedBox(
          height: 130,
          width: double.infinity,
          child: Stack(
              fit: StackFit.expand,
              children: [
                imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _enquiryImgFallback())
                    : _enquiryImgFallback(),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),
                        Color(0xBB1C1C1E),
                        Color(0xFF1C1C1E),
                      ],
                      stops: [0.4, 0.78, 1.0],
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
                      color:
                      Colors.black.withOpacity(0.55),
                      borderRadius:
                      BorderRadius.circular(20),
                      border: Border.all(
                          color: statusColor
                              .withOpacity(0.4)),
                    ),
                    child: Text(
                      _enquiryStatusLabels[status] ??
                          status,
                      style: GoogleFonts.inter(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                // Space + tier
                Positioned(
                  bottom: 12, left: 14, right: 14,
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(spaceName,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (tierName.isNotEmpty)
                        Text(tierName,
                            style: GoogleFonts.inter(
                                color: const Color(
                                    0xFFF97316),
                                fontSize: 12,
                                fontWeight:
                                FontWeight.w600)),
                    ],
                  ),
                ),
              ]),
        ),

        // Info
        Padding(
          padding: const EdgeInsets.fromLTRB(
              16, 12, 16, 14),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: _infoCell(
                    'COMPANY', company),
              ),
              Container(
                  width: 1, height: 32,
                  color:
                  Colors.white.withOpacity(0.07)),
              Expanded(
                child: _infoCell(
                    'TEAM', '$teamSize people'),
              ),
              if (preferred != null) ...[
                Container(
                    width: 1, height: 32,
                    color: Colors.white
                        .withOpacity(0.07)),
                Expanded(
                  child: _infoCell('PREFERRED',
                      _formatDate(preferred)),
                ),
              ],
            ]),
            const SizedBox(height: 12),

            // Pipeline status bar
            _buildMiniPipeline(status),
          ]),
        ),
      ]),
    );
  }

  Widget _buildMiniPipeline(String status) {
    final stages = [
      'pending',
      'tour_scheduled',
      'negotiating',
      'converted',
    ];
    final labels = {
      'pending': 'Pending',
      'tour_scheduled': 'Tour',
      'negotiating': 'Negotiating',
      'converted': 'Converted',
    };
    final currentIdx = stages.indexOf(status);
    final isRejected = status == 'rejected';

    if (isRejected) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444)
              .withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFFEF4444)
                  .withOpacity(0.25)),
        ),
        child: Text(
          'This enquiry was not taken forward.',
          style: GoogleFonts.inter(
              color: const Color(0xFFEF4444),
              fontSize: 12),
        ),
      );
    }

    return Row(
      children: stages.asMap().entries.map((e) {
        final i = e.key;
        final s = e.value;
        final isActive = i <= currentIdx;
        final isLast = i == stages.length - 1;
        return Expanded(
          child: Row(children: [
            Expanded(
              child: Column(children: [
                AnimatedContainer(
                  duration: const Duration(
                      milliseconds: 200),
                  height: 3,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFF97316)
                        : Colors.white
                        .withOpacity(0.12),
                    borderRadius:
                    BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 5),
                Text(labels[s] ?? s,
                    style: GoogleFonts.inter(
                        color: isActive
                            ? const Color(0xFFF97316)
                            : Colors.white24,
                        fontSize: 8,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w400),
                    textAlign: TextAlign.center),
              ]),
            ),
            if (!isLast)
              const SizedBox(width: 3),
          ]),
        );
      }).toList(),
    );
  }

  Widget _enquiryImgFallback() => Container(
    color: const Color(0xFFF97316)
        .withOpacity(0.08),
    child: const Center(
      child: Icon(
          Icons.business_center_outlined,
          color: Color(0xFFF97316), size: 36),
    ),
  );
  // ── Empty state ───────────────────────────────

  Widget _buildEmpty() {
    final messages = {
      'pending': (
      'Nothing pending',
      'Your booking requests will show here'
      ),
      'confirmed': (
      'No confirmed bookings',
      'Approved bookings will appear here'
      ),
      'completed': (
      'No past bookings',
      'Completed visits will show here'
      ),
      'cancelled': (
      'No cancelled bookings',
      'Any cancelled bookings live here'
      ),
    };
    final msg = messages[_currentFilter]!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status accent line
            Container(
              width: 32, height: 3,
              decoration: BoxDecoration(
                color: _statusColor(_currentFilter)
                    .withOpacity(0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              msg.$1,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3),
            ),
            const SizedBox(height: 8),
            Text(
              msg.$2,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 14,
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ── Booking card ──────────────────────────────

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final space =
        booking['spaces'] as Map<String, dynamic>? ?? {};
    final tier =
        booking['tiers'] as Map<String, dynamic>? ?? {};
    final status = booking['status'] as String? ?? 'pending';
    final price =
        (booking['total_price'] as num?)?.toDouble() ?? 0;
    final imageUrl = space['image_url'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withOpacity(0.07)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Full bleed hero image ─────────────
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(fit: StackFit.expand, children: [

              // Image
              imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _imgFallback())
                  : _imgFallback(),

              // Gradient bleed into card bg
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

              // Status badge — top right
              Positioned(
                top: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color:
                    Colors.black.withOpacity(0.55),
                    borderRadius:
                    BorderRadius.circular(20),
                    border: Border.all(
                        color: _statusColor(status)
                            .withOpacity(0.4)),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: GoogleFonts.inter(
                        color: _statusColor(status),
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              // Space name + tier overlaid at bottom
              Positioned(
                bottom: 12, left: 14, right: 14,
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      space['name'] ?? 'Unknown Space',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tier['name'] ?? '',
                      style: GoogleFonts.inter(
                          color: const Color(0xFFDEFF6E),
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ]),
          ),

          // ── Info section ──────────────────────
          Padding(
            padding:
            const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Date + time row
                Row(children: [
                  Expanded(
                    child: _infoCell(
                      'DATE',
                      booking['booking_date'] ?? '—',
                    ),
                  ),
                  Container(
                      width: 1, height: 32,
                      color: Colors.white.withOpacity(0.07)),
                  Expanded(
                    child: _infoCell(
                      'TIME',
                      '${_trimTime(booking['start_time'])} – ${_trimTime(booking['end_time'])}',
                    ),
                  ),
                  if (price > 0) ...[
                    Container(
                        width: 1, height: 32,
                        color: Colors.white.withOpacity(0.07)),
                    Expanded(
                      child: _infoCell(
                        'TOTAL',
                        'LKR ${price.toStringAsFixed(0)}',
                      ),
                    ),
                  ],
                ]),

                const SizedBox(height: 14),
                Divider(
                    color: Colors.white.withOpacity(0.07),
                    height: 1),

                // ── Action buttons ────────────────
                _buildActions(booking, status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCell(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(
        horizontal: 8, vertical: 4),
    child: Column(children: [
      Text(label,
          style: GoogleFonts.inter(
              color: Colors.white24,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7)),
      const SizedBox(height: 4),
      Text(value,
          style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    ]),
  );

  Widget _buildActions(
      Map<String, dynamic> booking, String status) {
    if (status == 'confirmed') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(children: [
          // QR button — lime
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      BookingQRScreen(booking: booking)),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFFDEFF6E),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFFDEFF6E)
                          .withOpacity(0.2),
                      blurRadius: 10),
                ],
              ),
              child: Center(
                child: Text('Show Entry QR Code',
                    style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // ✅ Invoice button — separate widget
          GestureDetector(
            onTap: () async {
              try {
                await InvoiceService.downloadInvoice(
                  booking: booking,
                  space: booking['spaces']
                  as Map<String, dynamic>? ??
                      {},
                  tier: booking['tiers']
                  as Map<String, dynamic>? ??
                      {},
                  user: booking['users']
                  as Map<String, dynamic>? ??
                      {},
                );
              } catch (e) {
                _snack(
                    'Could not generate invoice: $e',
                    isError: true);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                    color:
                    Colors.white.withOpacity(0.1)),
              ),
              child: Center(
                child: Text('Download Invoice',
                    style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            // Directions — ghost
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  try {
                    final spaceData = await _supabase
                        .from('spaces')
                        .select(
                        'latitude, longitude, name, address')
                        .eq('id', booking['space_id'])
                        .single();
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DirectionsScreen(
                            destinationLat:
                            (spaceData['latitude'] as num)
                                .toDouble(),
                            destinationLng:
                            (spaceData['longitude'] as num)
                                .toDouble(),
                            spaceName: spaceData['name'],
                            spaceAddress:
                            spaceData['address'],
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('Direction error: $e');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 13),
                  decoration: BoxDecoration(
                    color:
                    Colors.white.withOpacity(0.06),
                    borderRadius:
                    BorderRadius.circular(13),
                    border: Border.all(
                        color: Colors.white
                            .withOpacity(0.08)),
                  ),
                  child: Center(
                    child: Text('Directions',
                        style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight:
                            FontWeight.w600)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Cancel — red ghost
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    _cancelBooking(booking['id']),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444)
                        .withOpacity(0.08),
                    borderRadius:
                    BorderRadius.circular(13),
                    border: Border.all(
                        color: const Color(0xFFEF4444)
                            .withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text('Cancel',
                        style: GoogleFonts.inter(
                            color:
                            const Color(0xFFEF4444),
                            fontSize: 13,
                            fontWeight:
                            FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ]),
        ]),
      );
    }

    if (status == 'pending') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(children: [
          // Awaiting notice
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
              const Color(0xFFFBBF24).withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFFBBF24)
                      .withOpacity(0.2)),
            ),
            child: Text(
              'Awaiting approval from the space admin. '
                  'You\'ll be notified once confirmed.',
              style: GoogleFonts.inter(
                  color: const Color(0xFFFBBF24),
                  fontSize: 12,
                  height: 1.4),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _cancelBooking(booking['id']),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444)
                    .withOpacity(0.08),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                    color: const Color(0xFFEF4444)
                        .withOpacity(0.3)),
              ),
              child: Center(
                child: Text('Cancel Booking',
                    style: GoogleFonts.inter(
                        color: const Color(0xFFEF4444),
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ]),
      );
    }

    if (status == 'completed' &&
        booking['cancellation_reason'] == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: GestureDetector(
          onTap: () => _submitReview(booking),
          child: Container(
            width: double.infinity,
            padding:
            const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFDEFF6E)
                  .withOpacity(0.08),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                  color: const Color(0xFFDEFF6E)
                      .withOpacity(0.3)),
            ),
            child: Center(
              child: Text('Rate Your Experience',
                  style: GoogleFonts.inter(
                      color: const Color(0xFFDEFF6E),
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      );
    }

    // Cancelled / completed with reason — no actions
    return const SizedBox(height: 12);
  }

  // ── Helpers ───────────────────────────────────

  String _trimTime(dynamic t) {
    if (t == null) return '—';
    final s = t.toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed': return const Color(0xFF34D399);
      case 'cancelled': return const Color(0xFFEF4444);
      case 'completed': return const Color(0xFFDEFF6E);
      default: return const Color(0xFFFBBF24);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed': return 'Confirmed';
      case 'cancelled': return 'Cancelled';
      case 'completed': return 'Completed';
      default: return 'Pending';
    }
  }

  Widget _imgFallback() => Container(
    color: Colors.white.withOpacity(0.04),
  );
  Widget _buildSegmentEmpty(
      String title,
      String subtitle,
      IconData icon,
      Color color,
      ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 40, vertical: 60),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius:
                BorderRadius.circular(20),
                border: Border.all(
                    color: color.withOpacity(0.2)),
              ),
              child: Icon(icon,
                  color: color.withOpacity(0.6),
                  size: 28),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 13,
                    height: 1.5)),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return '—';
    try {
      final dt = DateTime.parse(date);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '—';
    }
  }
}
