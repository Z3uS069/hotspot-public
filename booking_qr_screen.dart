import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/qr_service.dart';

class BookingQRScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  const BookingQRScreen({super.key, required this.booking});

  @override
  State<BookingQRScreen> createState() => _BookingQRScreenState();
}

class _BookingQRScreenState extends State<BookingQRScreen> {
  final _supabase = Supabase.instance.client;
  String? _qrData;
  bool _isLoading = true;
  bool _isUsed = false;
  bool _isExpired = false;

  //BACKEND LOGIC

  @override
  void initState() {
    super.initState();
    _generateQR();
  }

  Future<void> _generateQR() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final booking = widget.booking;

      final bookingData = await _supabase
          .from('bookings')
          .select('qr_used, booking_date, status')
          .eq('id', booking['id'])
          .single();

      if (bookingData['qr_used'] == true) {
        setState(() {
          _isUsed = true;
          _isLoading = false;
        });
        return;
      }

      if (bookingData['status'] != 'confirmed') {
        setState(() => _isLoading = false);
        return;
      }

      final bookingDate = DateTime.parse(
          booking['booking_date'] ??
              DateTime.now().toIso8601String());

      final expiryTime =
      bookingDate.add(const Duration(hours: 24));
      if (DateTime.now().isAfter(expiryTime)) {
        setState(() {
          _isExpired = true;
          _isLoading = false;
        });
        return;
      }

      final qrData = QRService.generateQRData(
        bookingId: booking['id'],
        userId: userId,
        spaceId: booking['space_id'],
        tierId: booking['tier_id'],
        bookingDate: bookingDate,
      );

      setState(() {
        _qrData = qrData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('QR generation error: $e');
    }
  }

  //BUILD

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final space = (widget.booking['spaces']
    as Map<String, dynamic>?) ??
        {'name': 'Unknown Space', 'address': ''};
    final tier = (widget.booking['tiers']
    as Map<String, dynamic>?) ??
        {'name': 'Unknown Tier'};

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Column(children: [

        //Custom header
        Container(
          color: const Color(0xFF111111),
          padding: EdgeInsets.fromLTRB(
              20, topPad + 12, 20, 16),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.1)),
                ),
                child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text('Entry Pass',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3)),
                  Text(space['name'] ?? '',
                      style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 12)),
                ],
              ),
            ),
          ]),
        ),

        //Content
        Expanded(
          child: _isLoading
              ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFFDEFF6E),
                  strokeWidth: 2))
              : SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                24, 8, 24, 40),
            child: Column(children: [

              //Booking summary
              _buildSummaryCard(space, tier),
              const SizedBox(height: 28),

              //QR states
              if (_isUsed)
                _buildStateCard(
                  title: 'Already Used',
                  message:
                  'This pass has been scanned and is no longer valid.',
                  color: const Color(0xFFEF4444),
                )
              else if (_isExpired)
                _buildStateCard(
                  title: 'Pass Expired',
                  message:
                  'This entry pass expired 24 hours after your booking date.',
                  color: const Color(0xFFF59E0B),
                )
              else if (_qrData != null)
                  _buildQRCard()
                else
                  _buildStateCard(
                    title: 'Not Available',
                    message:
                    'Entry pass is only available for confirmed bookings.',
                    color: const Color(0xFFEF4444),
                  ),
            ]),
          ),
        ),
      ]),
    );
  }

  //Summary card

  Widget _buildSummaryCard(
      Map<String, dynamic> space,
      Map<String, dynamic> tier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(space['name'] ?? '',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Row(children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                      color: Color(0xFFDEFF6E),
                      shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text(tier['name'] ?? '',
                    style: GoogleFonts.inter(
                        color: const Color(0xFFDEFF6E),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ]),
            ],
          ),
        ),
        // Confirmed badge
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF34D399).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF34D399)
                    .withOpacity(0.3)),
          ),
          child: Text('Confirmed',
              style: GoogleFonts.inter(
                  color: const Color(0xFF34D399),
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  //QR card

  Widget _buildQRCard() {
    return Column(children: [

      //QR with lime border
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: const Color(0xFFDEFF6E).withOpacity(0.5),
              width: 1.5),
        ),
        child: Column(children: [

          // Header inside card
          Row(children: [
            Expanded(
              child: Text('Scan to enter',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDEFF6E)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFFDEFF6E)
                        .withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                        color: Color(0xFFDEFF6E),
                        shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text('Valid',
                      style: GoogleFonts.inter(
                          color: const Color(0xFFDEFF6E),
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // QR code
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: QrImageView(
                data: _qrData!,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF111111),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF111111),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Time strip
          Container(
            padding: const EdgeInsets.symmetric(
                vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Expanded(
                  child: _timeCell(
                    'DATE',
                    widget.booking['booking_date'] ?? '—',
                  )),
              Container(
                  width: 1, height: 32,
                  color: Colors.white.withOpacity(0.08)),
              Expanded(
                  child: _timeCell(
                    'START',
                    _trimTime(widget.booking['start_time']),
                  )),
              Container(
                  width: 1, height: 32,
                  color: Colors.white.withOpacity(0.08)),
              Expanded(
                  child: _timeCell(
                    'END',
                    _trimTime(widget.booking['end_time']),
                  )),
            ]),
          ),
        ]),
      ),

      const SizedBox(height: 20),

      // Instruction notice
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.white.withOpacity(0.07)),
        ),
        child: Text(
          'Show this pass to the space administrator on arrival. Valid for one scan only — expires 24 hours from your booking date.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 12,
              height: 1.5),
        ),
      ),
    ]);
  }

  //State card

  Widget _buildStateCard({
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(
                color: color.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              _isUsed ? '✕' : _isExpired ? '!' : '?',
              style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(title,
            style: GoogleFonts.inter(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 13,
                height: 1.5)),
      ]),
    );
  }

  //Helpers

  Widget _timeCell(String label, String value) =>
      Column(children: [
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
            textAlign: TextAlign.center),
      ]);

  String _trimTime(dynamic t) {
    if (t == null) return '—';
    final s = t.toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
  }
}