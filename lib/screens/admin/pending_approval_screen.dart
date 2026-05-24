import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PendingApprovalScreen extends StatelessWidget {
  final Map<String, dynamic> space;

  const PendingApprovalScreen({super.key, required this.space});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Stack(children: [

        //Blurred fake dashboard shell
        SafeArea(
          bottom: false,
          child: Column(children: [
            //Fake hero
            Container(
              height: 200,
              color: const Color(0xFF1C1C1E),
              child: Center(
                  child: Icon(Icons.business_outlined,
                      color: Colors.white.withOpacity(0.04), size: 80)),
            ),
            //Fake tab bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                  )),
            ),
            const SizedBox(height: 20),
            //Fake cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                _fakeCard(height: 110),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _fakeCard(height: 80)),
                  const SizedBox(width: 12),
                  Expanded(child: _fakeCard(height: 80)),
                ]),
                const SizedBox(height: 12),
                _fakeCard(height: 70),
                const SizedBox(height: 12),
                _fakeCard(height: 70),
              ]),
            ),
          ]),
        ),

        //Blur layer
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
                color: const Color(0xFF111111).withOpacity(0.6)),
          ),
        ),

        //Pending card
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(28, 0, 28, bottomPad + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEFF6E).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFFDEFF6E).withOpacity(0.3),
                        width: 1.5),
                  ),
                  child: const Icon(Icons.hourglass_top_rounded,
                      color: Color(0xFFDEFF6E), size: 30),
                ),
                const SizedBox(height: 20),

                Text('Awaiting approval',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    )),
                const SizedBox(height: 8),
                Text(
                  'Your space is under review by the Hotspot team. '
                      'You\'ll receive a notification once it\'s approved '
                      'and your dashboard is unlocked.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 14,
                      height: 1.6),
                ),
                const SizedBox(height: 24),

                // Space details card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(children: [
                    _detailRow(
                      Icons.business_outlined,
                      space['name'] ?? '—',
                      Colors.white,
                    ),
                    const SizedBox(height: 12),
                    _detailRow(
                      Icons.location_on_outlined,
                      space['address'] ?? '—',
                      Colors.white54,
                    ),
                    const SizedBox(height: 12),
                    _detailRow(
                      Icons.pending_outlined,
                      'Submitted · Pending review',
                      const Color(0xFFF59E0B),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),

                // Check status
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEFF6E).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFDEFF6E).withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.notifications_outlined,
                        color: Color(0xFFDEFF6E), size: 15),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      'We\'ll notify you via the app once the team '
                          'has reviewed your submission.',
                      style: GoogleFonts.inter(
                          color: const Color(0xFFDEFF6E).withOpacity(0.8),
                          fontSize: 12,
                          height: 1.5),
                    )),
                  ]),
                ),
                const SizedBox(height: 24),

                // Sign out
                GestureDetector(
                  onTap: () =>
                      Supabase.instance.client.auth.signOut(),
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Center(
                      child: Text('Sign out',
                          style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _fakeCard({required double height}) => Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ));

  Widget _detailRow(IconData icon, String text, Color color) =>
      Row(children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 10),
        Expanded(child: Text(text,
            style: GoogleFonts.inter(color: color, fontSize: 13),
            overflow: TextOverflow.ellipsis)),
      ]);
}