import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/space_model.dart';
import '../../models/tier_model.dart';
import '../../services/push_notification_sender.dart';
import 'tier_policy_screen.dart';

final ValueNotifier<int> bookingTabNotifier = ValueNotifier(0);

class BookingSheet extends StatefulWidget {
  final SpaceModel space;
  final TierModel tier;

  const BookingSheet({
    super.key,
    required this.space,
    required this.tier,
  });

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  final _supabase = Supabase.instance.client;

  DateTime?  _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int        _selectedDays = 1;
  bool       _isLoading = false;
  bool       _policyAcknowledged = false;

  bool get _isDaily => widget.tier.bookingType == 'daily';

  @override
  void initState() {
    super.initState();
    _selectedDays = widget.tier.minDuration > 0
        ? widget.tier.minDuration
        : 1;
  }

  //Helpers

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  String _getDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  double get _durationHours {
    if (_isDaily || _startTime == null || _endTime == null) return 0;
    final s = _startTime!.hour * 60 + _startTime!.minute;
    final e = _endTime!.hour * 60 + _endTime!.minute;
    return (e - s) / 60.0;
  }

  double get _estimatedTotal {
    if (_isDaily) return (widget.tier.pricePerDay ?? 0) * _selectedDays;
    if (_durationHours <= 0) return 0;
    return (widget.tier.pricePerHour ?? 0) * _durationHours;
  }

  //Pickers

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFDEFF6E),
            onPrimary: Colors.black,
            surface: Color(0xFF1C1C1E),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFDEFF6E),
            onPrimary: Colors.black,
            surface: Color(0xFF1C1C1E),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startTime = picked;
        else _endTime = picked;
      });
    }
  }

  //Policy sheet

  void _showPolicySheet() {
    if (widget.tier.policies.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TierPolicyScreen(
            tierName: widget.tier.name,
            policies: widget.tier.policies,
            previewMode: false,
            onAcknowledged: () =>
                setState(() => _policyAcknowledged = true),
          ),
        ),
      );
      return;
    }

    // Generic fallback
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
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
            Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFFBBF24).withOpacity(0.3)),
                ),
                child: const Icon(Icons.policy_outlined,
                    color: Color(0xFFFBBF24), size: 18),
              ),
              const SizedBox(width: 12),
              Text('Cancellation Policy',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 20),
            ...[
              _policyItem('24+ hours before', 'Full refund — no questions asked.'),
              _policyItem('12–24 hours before', '50% refund issued to your account.'),
              _policyItem('Under 12 hours', 'No refund. Booking is non-refundable.'),
              _policyItem('No-show', 'Booking is forfeited. No refund issued.'),
            ],
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24).withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFFFBBF24).withOpacity(0.2)),
              ),
              child: Text(
                'All cancellations must be submitted through the app. '
                    'Refunds are processed within 5–7 business days.',
                style: GoogleFonts.inter(
                    color: const Color(0xFFFBBF24),
                    fontSize: 12,
                    height: 1.5),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.08)),
                ),
                child: Center(
                  child: Text('Close',
                      style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _policyItem(String timing, String detail) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6, height: 6,
          margin: const EdgeInsets.only(top: 5),
          decoration: const BoxDecoration(
              color: Color(0xFFDEFF6E), shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(timing,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(detail,
                  style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 12,
                      height: 1.4)),
            ],
          ),
        ),
      ],
    ),
  );

  //Confirm booking

  Future<void> _confirmBooking() async {
    if (_selectedDate == null) {
      _snack('Please select a date', isError: true);
      return;
    }
    if (!_policyAcknowledged) {
      _snack('Please acknowledge the cancellation policy', isError: true);
      return;
    }

    if (_isDaily) {
      final minDays = widget.tier.minDuration > 0 ? widget.tier.minDuration : 1;
      if (_selectedDays < minDays) {
        _snack(
          'Minimum booking for ${widget.tier.name} is '
              '$minDays day${minDays > 1 ? 's' : ''}.',
          isError: true,
        );
        return;
      }
    } else {
      if (_startTime == null || _endTime == null) {
        _snack('Please select start and end time', isError: true);
        return;
      }
      final startMin = _startTime!.hour * 60 + _startTime!.minute;
      final endMin   = _endTime!.hour * 60 + _endTime!.minute;
      if (endMin <= startMin) {
        _snack('End time must be after start time', isError: true);
        return;
      }
      final durationHrs = (endMin - startMin) / 60.0;
      final minHrs = widget.tier.minDuration > 0 ? widget.tier.minDuration : 1;
      if (durationHrs < minHrs) {
        _snack(
          'Minimum booking for ${widget.tier.name} is '
              '$minHrs hour${minHrs > 1 ? 's' : ''}.',
          isError: true,
        );
        return;
      }

      final spaceHours = await _supabase
          .from('space_hours')
          .select()
          .eq('space_id', widget.space.id)
          .eq('day_of_week', _getDayName(_selectedDate!))
          .maybeSingle();

      if (spaceHours != null) {
        final isAm = _startTime!.hour < 12;
        final slotOpen = isAm
            ? (spaceHours['am_open'] as bool? ?? true)
            : (spaceHours['pm_open'] as bool? ?? true);
        if (!slotOpen) {
          _snack('This space is closed at your selected time.', isError: true);
          return;
        }
      }
    }

    setState(() => _isLoading = true);
    try {
      final userId     = _supabase.auth.currentUser!.id;
      final totalPrice = _estimatedTotal;

      final bookingResponse = await _supabase
          .from('bookings')
          .insert({
        'user_id':      userId,
        'space_id':     widget.space.id,
        'tier_id':      widget.tier.id,
        'booking_date': _selectedDate!.toIso8601String().split('T')[0],
        'start_time':   _isDaily ? '08:00:00' : _formatTime(_startTime!),
        'end_time':     _isDaily ? '08:00:00' : _formatTime(_endTime!),
        'status':       'pending',
        'total_price':  totalPrice,
        if (_isDaily) 'days_booked': _selectedDays,
      })
          .select('id')
          .single();

      await _supabase.from('notifications').insert({
        'recipient_id': widget.space.adminId,
        'booking_id':   bookingResponse['id'],
        'message':
        'New booking request for ${widget.tier.name} '
            'at ${widget.space.name} — '
            'LKR ${totalPrice.toStringAsFixed(0)}',
      });

      if (widget.space.adminId != null) {
        await PushNotificationSender.newBookingRequest(
          adminId:  widget.space.adminId!,
          userName: _supabase.auth.currentUser?.email ?? 'A user',
          tierName: widget.tier.name,
          date:     _selectedDate!.toIso8601String().split('T')[0],
        );
      }

      if (mounted) _showSuccessDialog(totalPrice);
    } catch (e) {
      if (mounted) _snack('Booking failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.inter(
              color: isError ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600)),
      backgroundColor:
      isError ? const Color(0xFFEF4444) : const Color(0xFFDEFF6E),
      behavior: SnackBarBehavior.floating,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSuccessDialog(double totalPrice) {
    final dateLabel = _selectedDate != null
        ? '${_selectedDate!.day}/${_selectedDate!.month}'
        : '—';

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFDEFF6E).withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFDEFF6E).withOpacity(0.3),
                      width: 2),
                ),
                child: const Icon(Icons.check_rounded,
                    color: Color(0xFFDEFF6E), size: 36),
              ),
              const SizedBox(height: 20),
              Text('Booking Submitted!',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3)),
              const SizedBox(height: 8),
              Text(
                'Pending confirmation from the space admin.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: Colors.white38, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
              if (totalPrice > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEFF6E).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFDEFF6E).withOpacity(0.25)),
                  ),
                  child: Column(children: [
                    Text('Estimated Total',
                        style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      'LKR ${totalPrice.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                          color: const Color(0xFFDEFF6E),
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5),
                    ),
                  ]),
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Expanded(
                      child: _summaryCell('SPACE', widget.space.name)),
                  Container(width: 1, height: 28,
                      color: Colors.white.withOpacity(0.07)),
                  Expanded(
                      child: _summaryCell('TIER', widget.tier.name)),
                  Container(width: 1, height: 28,
                      color: Colors.white.withOpacity(0.07)),
                  Expanded(child: _summaryCell('DATE', dateLabel)),
                ]),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  bookingTabNotifier.value = 2;
                  Navigator.of(context)
                      .popUntil((route) => route.isFirst);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEFF6E),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFDEFF6E).withOpacity(0.2),
                          blurRadius: 12),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long_rounded,
                          color: Colors.black, size: 18),
                      const SizedBox(width: 8),
                      Text('View My Bookings',
                          style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCell(String label, String value) => Column(
    children: [
      Text(label,
          style: GoogleFonts.inter(
              color: Colors.white24,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6)),
      const SizedBox(height: 4),
      Text(value,
          style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    ],
  );

  // BUILD

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomScrollView(
          controller: ctrl,
          slivers: [

            SliverToBoxAdapter(child: _buildHero()),

            SliverPadding(
              padding:
              EdgeInsets.fromLTRB(20, 20, 20, bottomPad + 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  _buildSummaryCard(),
                  const SizedBox(height: 24),

                  _sectionLabel('Select Date'),
                  const SizedBox(height: 10),
                  _buildDatePicker(),
                  const SizedBox(height: 20),

                  if (_isDaily) ...[
                    _sectionLabel('Number of Days'),
                    const SizedBox(height: 10),
                    _buildDaysStepper(),
                  ] else ...[
                    _sectionLabel('Select Time'),
                    const SizedBox(height: 10),
                    _buildTimePickers(),
                    if (_durationHours != 0) ...[
                      const SizedBox(height: 12),
                      _buildDurationPreview(),
                    ],
                  ],

                  const SizedBox(height: 24),
                  _buildPolicyRow(),
                  const SizedBox(height: 12),
                  _buildAcknowledgeRow(),
                  const SizedBox(height: 28),
                  _buildConfirmButton(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Hero

  Widget _buildHero() {
    final space = widget.space;
    return SizedBox(
      height: 220,
      child: Stack(fit: StackFit.expand, children: [

        widget.tier.imageUrl != null && widget.tier.imageUrl!.isNotEmpty
            ? Image.network(widget.tier.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _heroFallback())
            : space.imageUrl != null && space.imageUrl!.isNotEmpty
            ? Image.network(space.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _heroFallback())
            : _heroFallback(),

        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x44000000), Color(0x00000000),
                Color(0xCC111111), Color(0xFF111111),
              ],
              stops: [0.0, 0.2, 0.72, 1.0],
            ),
          ),
        ),

        Positioned(
          top: 12, left: 0, right: 0,
          child: Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
        ),

        Positioned(
          top: 10, right: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ),

        Positioned(
          bottom: 16, left: 20, right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                      color: Color(0xFFDEFF6E),
                      shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(widget.tier.name,
                    style: GoogleFonts.inter(
                        color: const Color(0xFFDEFF6E),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              Text(space.name,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _heroFallback() => Container(
    color: const Color(0xFF1C1C1E),
    child: const Center(
      child: Icon(Icons.business_outlined,
          color: Colors.white12, size: 56),
    ),
  );

  //Summary card

  Widget _buildSummaryCard() {
    final tier = widget.tier;
    final double pct = tier.totalCapacity > 0
        ? tier.availableSeats / tier.totalCapacity
        : 0;
    final Color seatColor = pct > 0.5
        ? const Color(0xFF34D399)
        : pct > 0.2
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.space.name,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(tier.name,
              style: GoogleFonts.inter(
                  color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withOpacity(0.06), height: 1),
          const SizedBox(height: 14),

          _summaryRow(
            icon: Icons.chair_outlined,
            label: 'Seats',
            child: _buildSeatBar(
                tier.availableSeats, tier.totalCapacity, seatColor, pct),
          ),
          const SizedBox(height: 12),

          _summaryRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            child: Text(
              _selectedDate != null
                  ? '${_selectedDate!.day} / ${_selectedDate!.month} / ${_selectedDate!.year}  ·  ${_getDayName(_selectedDate!)}'
                  : 'Not selected',
              style: GoogleFonts.inter(
                  color: _selectedDate != null
                      ? Colors.white
                      : Colors.white24,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),

          if (_isDaily)
            _summaryRow(
              icon: Icons.date_range_rounded,
              label: 'Days',
              child: Text(
                '$_selectedDays day${_selectedDays > 1 ? 's' : ''}',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            )
          else
            _summaryRow(
              icon: Icons.access_time_rounded,
              label: 'Time',
              child: Text(
                (_startTime != null && _endTime != null)
                    ? '${_startTime!.format(context)}  →  ${_endTime!.format(context)}'
                    : 'Not selected',
                style: GoogleFonts.inter(
                    color: (_startTime != null && _endTime != null)
                        ? Colors.white
                        : Colors.white24,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryRow({
    required IconData icon,
    required String label,
    required Widget child,
  }) =>
      Row(children: [
        Icon(icon, color: Colors.white24, size: 15),
        const SizedBox(width: 8),
        Text(label,
            style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(width: 12),
        Expanded(child: child),
      ]);

  Widget _buildSeatBar(
      int available, int total, Color seatColor, double pct) {
    const segments = 4;
    final filled =
    pct == 0 ? 0 : ((pct * segments).ceil().clamp(0, segments));
    return Row(children: [
      SizedBox(
        width: 38, height: 14,
        child: Stack(
          children: List.generate(segments, (i) => Positioned(
            left: i * 10.0,
            child: Container(
              width: 8, height: 14,
              decoration: BoxDecoration(
                color: i < filled
                    ? seatColor
                    : Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          )),
        ),
      ),
      const SizedBox(width: 8),
      RichText(
        text: TextSpan(children: [
          TextSpan(
            text: '$available',
            style: GoogleFonts.inter(
                color: seatColor,
                fontSize: 13,
                fontWeight: FontWeight.w800),
          ),
          TextSpan(
            text: '/$total',
            style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
          TextSpan(
            text: ' available',
            style: GoogleFonts.inter(
                color: Colors.white30, fontSize: 11),
          ),
        ]),
      ),
    ]);
  }

  //Section label

  Widget _sectionLabel(String text) => Text(
    text,
    style: GoogleFonts.inter(
        color: Colors.white54,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4),
  );

  //Date picker

  Widget _buildDatePicker() {
    final filled = _selectedDate != null;
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled
                ? const Color(0xFFDEFF6E).withOpacity(0.4)
                : Colors.white.withOpacity(0.07),
          ),
        ),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: filled
                  ? const Color(0xFFDEFF6E).withOpacity(0.12)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.calendar_today_rounded,
                color: filled
                    ? const Color(0xFFDEFF6E)
                    : Colors.white38,
                size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date',
                    style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  filled
                      ? '${_selectedDate!.day} / ${_selectedDate!.month} / ${_selectedDate!.year}  ·  ${_getDayName(_selectedDate!)}'
                      : 'Choose a date',
                  style: GoogleFonts.inter(
                      color: filled ? Colors.white : Colors.white24,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.2), size: 18),
        ]),
      ),
    );
  }

  //Time pickers (hourly)

  Widget _buildTimePickers() => Row(children: [
    Expanded(child: _timePill('Start', _startTime, true)),
    const SizedBox(width: 8),
    Container(
      width: 26, height: 26,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.arrow_forward_rounded,
          color: Colors.white24, size: 13),
    ),
    const SizedBox(width: 8),
    Expanded(child: _timePill('End', _endTime, false)),
  ]);

  Widget _timePill(String label, TimeOfDay? time, bool isStart) {
    final filled = time != null;
    return GestureDetector(
      onTap: () => _pickTime(isStart),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled
                ? const Color(0xFFDEFF6E).withOpacity(0.4)
                : Colors.white.withOpacity(0.07),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(
              filled ? time!.format(context) : '--:--',
              style: GoogleFonts.inter(
                  color: filled ? Colors.white : Colors.white24,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5),
            ),
          ],
        ),
      ),
    );
  }

  //Duration preview (hourly)

  Widget _buildDurationPreview() {
    final hrs   = _durationHours;
    final total = _estimatedTotal;
    final minHrs =
    widget.tier.minDuration > 0 ? widget.tier.minDuration : 1;
    final isValid = hrs >= minHrs;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isValid
            ? const Color(0xFFDEFF6E).withOpacity(0.06)
            : const Color(0xFFEF4444).withOpacity(0.06),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isValid
              ? const Color(0xFFDEFF6E).withOpacity(0.25)
              : const Color(0xFFEF4444).withOpacity(0.25),
        ),
      ),
      child: Row(children: [
        Icon(
          isValid
              ? Icons.check_circle_outline_rounded
              : Icons.warning_amber_rounded,
          color: isValid
              ? const Color(0xFFDEFF6E)
              : const Color(0xFFEF4444),
          size: 17,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            isValid
                ? '${hrs.toStringAsFixed(1)} hours selected'
                : 'Minimum ${minHrs}h required — currently ${hrs.toStringAsFixed(1)}h',
            style: GoogleFonts.inter(
                color: isValid
                    ? const Color(0xFFDEFF6E)
                    : const Color(0xFFEF4444),
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ),
        if (isValid && total > 0)
          Text(
            'LKR ${total.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3),
          ),
      ]),
    );
  }

  //Days stepper (daily)

  Widget _buildDaysStepper() {
    final minDays =
    widget.tier.minDuration > 0 ? widget.tier.minDuration : 1;
    final total = _estimatedTotal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFDEFF6E).withOpacity(0.3)),
      ),
      child: Column(children: [

        Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFDEFF6E).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: const Color(0xFFDEFF6E).withOpacity(0.2)),
          ),
          child: Text(
            'Minimum $minDays day${minDays > 1 ? 's' : ''} required for ${widget.tier.name}',
            style: GoogleFonts.inter(
                color: const Color(0xFFDEFF6E),
                fontSize: 12,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),

        Row(children: [
          GestureDetector(
            onTap: _selectedDays > minDays
                ? () => setState(() => _selectedDays--)
                : null,
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(13),
                border:
                Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Icon(Icons.remove,
                  color: _selectedDays > minDays
                      ? Colors.white
                      : Colors.white24,
                  size: 20),
            ),
          ),

          Expanded(
            child: Column(children: [
              Text(
                '$_selectedDays',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    height: 1),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'day${_selectedDays > 1 ? 's' : ''}',
                style: GoogleFonts.inter(
                    color: Colors.white38, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ]),
          ),

          GestureDetector(
            onTap: () => setState(() => _selectedDays++),
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFDEFF6E).withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                    color: const Color(0xFFDEFF6E).withOpacity(0.3)),
              ),
              child: const Icon(Icons.add,
                  color: Color(0xFFDEFF6E), size: 20),
            ),
          ),
        ]),

        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
            border:
            Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LKR ${(widget.tier.pricePerDay ?? 0).toStringAsFixed(0)}/day × $_selectedDays',
                style: GoogleFonts.inter(
                    color: Colors.white38, fontSize: 13),
              ),
              Text(
                'LKR ${total.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                    color: const Color(0xFFDEFF6E),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  //Policy row
  Widget _buildPolicyRow() {
    return GestureDetector(
      onTap: _showPolicySheet,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(14),
          border:
          Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFBBF24).withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.policy_outlined,
                color: Color(0xFFFBBF24), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    widget.tier.policies.isNotEmpty
                        ? 'Booking Policy'
                        : 'Cancellation Policy',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Tap to read before booking',
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: Colors.white24, size: 18),
        ]),
      ),
    );
  }

  Widget _buildAcknowledgeRow() {
    return GestureDetector(
      onTap: () =>
          setState(() => _policyAcknowledged = !_policyAcknowledged),
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: _policyAcknowledged
                ? const Color(0xFFDEFF6E)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _policyAcknowledged
                  ? Colors.transparent
                  : Colors.white.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: _policyAcknowledged
              ? const Icon(Icons.check_rounded,
              color: Colors.black, size: 14)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'I have read and agree to the cancellation policy',
            style: GoogleFonts.inter(
                color: Colors.white60, fontSize: 13),
          ),
        ),
      ]),
    );
  }

  //Confirm button

  Widget _buildConfirmButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _confirmBooking,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _isLoading
              ? const Color(0xFFDEFF6E).withOpacity(0.5)
              : const Color(0xFFDEFF6E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isLoading
              ? null
              : [
            BoxShadow(
                color: const Color(0xFFDEFF6E).withOpacity(0.2),
                blurRadius: 16),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(
                  color: Colors.black, strokeWidth: 2.5))
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bolt_rounded,
                  color: Colors.black, size: 20),
              const SizedBox(width: 6),
              Text('Confirm Booking',
                  style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}