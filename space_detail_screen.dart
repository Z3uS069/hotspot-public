import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import '../../models/space_model.dart';
import '../../models/tier_model.dart';
import '../../services/space_service.dart';
import 'booking_screen.dart';
import 'directions_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'enquiry_sheet.dart';
import 'subscription_sheet.dart';
import 'dart:async';

class SpaceDetailScreen extends StatefulWidget {
  final SpaceModel space;
  final String? initialTierId;

  const SpaceDetailScreen({
    super.key,
    required this.space,
    this.initialTierId,
  });

  @override
  State<SpaceDetailScreen> createState() =>
      _SpaceDetailScreenState();
}

class _SpaceDetailScreenState
    extends State<SpaceDetailScreen> {
  final SpaceService _spaceService = SpaceService();
  final _supabase = Supabase.instance.client;

  List<TierModel> _tiers = [];
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  bool _isLoadingReviews = true;
  bool _isMember = false;
  bool _isJoining = false;
  String? _selectedTierId;

// ── Enquiry carousel ──────────────────────────
  late PageController _enquiryPageCtrl;
  Timer? _enquiryTimer;
  int _enquiryPage = 0;

  @override
  void initState() {
    super.initState();
    _loadTiers();
    _checkMembership();
    _loadReviews();
    _enquiryPageCtrl = PageController();
  }

  // ── BACKEND (all unchanged) ───────────────────

  Future<void> _checkMembership() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final res = await _supabase
          .from('community_members')
          .select('id')
          .eq('user_id', userId)
          .eq('space_id', widget.space.id)
          .maybeSingle();
      if (mounted) setState(() => _isMember = res != null);
    } catch (_) {}
  }

  Future<void> _toggleMembership() async {
    setState(() => _isJoining = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      if (_isMember) {
        await _supabase
            .from('community_members')
            .delete()
            .eq('user_id', userId)
            .eq('space_id', widget.space.id);
        if (mounted) setState(() => _isMember = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Left community',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFF374151),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ));
        }
      } else {
        await _supabase.from('community_members').insert({
          'user_id': userId,
          'space_id': widget.space.id,
        });
        if (mounted) setState(() => _isMember = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Joined community! 🎉',
                style: GoogleFonts.inter(
                    color: Colors.black,
                    fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFFDEFF6E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ));
        }
      }
    } catch (e) {
      debugPrint('Toggle membership error: $e');
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  Future<void> _loadTiers() async {
    try {
      final tiers =
      await _spaceService.getTiersBySpace(widget.space.id);
      if (mounted) {
        setState(() {
          _tiers = tiers;
          _isLoading = false;
          if (widget.initialTierId != null) {
            _selectedTierId = widget.initialTierId;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadReviews() async {
    try {
      final res = await _supabase
          .from('reviews')
          .select('*, users(name, avatar_url)')
          .eq('space_id', widget.space.id)
          .order('created_at', ascending: false)
          .limit(10);
      if (mounted) {
        setState(() {
          _reviews = List<Map<String, dynamic>>.from(res);
          _isLoadingReviews = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  void _showGallery({int startIndex = 0}) {
    final allImages = [
      if (widget.space.imageUrl != null &&
          widget.space.imageUrl!.isNotEmpty)
        widget.space.imageUrl!,
      ...widget.space.galleryImages,
    ];
    if (allImages.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => _GalleryPopup(
        images: allImages,
        startIndex: startIndex.clamp(0, allImages.length - 1),
        spaceName: widget.space.name,
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final space = widget.space;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Column(children: [

        // ══ FIXED HERO ════════════════════════════
        SizedBox(
          height: 300,
          child: Stack(fit: StackFit.expand, children: [

            // Hero image
            space.imageUrl != null && space.imageUrl!.isNotEmpty
                ? GestureDetector(
              onTap: () => _showGallery(),
              child: Image.network(
                space.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _heroFallback(),
              ),
            )
                : _heroFallback(),

            // Gradient — bleeds into #111111
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x55000000),
                    Color(0x00000000),
                    Color(0xCC111111),
                    Color(0xFF111111),
                  ],
                  stops: [0.0, 0.25, 0.72, 1.0],
                ),
              ),
            ),

            // Back button + actions
            Positioned(
              top: topPad + 10,
              left: 14,
              right: 14,
              child: Row(children: [
                // Back
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
                const Spacer(),
                // Directions
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DirectionsScreen(
                        destinationLat: space.latitude,
                        destinationLng: space.longitude,
                        spaceName: space.name,
                        spaceAddress: space.address,
                      ),
                    ),
                  ),
                  child: Container(
                    width: 38, height: 38,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.directions_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                // Community join pill
                GestureDetector(
                  onTap: _isJoining ? null : _toggleMembership,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: _isMember
                          ? const Color(0xFFDEFF6E)
                          : Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isMember
                            ? Colors.transparent
                            : const Color(0xFFDEFF6E)
                            .withOpacity(0.6),
                      ),
                    ),
                    child: _isJoining
                        ? SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(
                        color: _isMember
                            ? Colors.black
                            : const Color(0xFFDEFF6E),
                        strokeWidth: 2,
                      ),
                    )
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isMember
                              ? Icons.groups_rounded
                              : Icons.groups_outlined,
                          color: _isMember
                              ? Colors.black
                              : const Color(0xFFDEFF6E),
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isMember ? 'Community Member' : 'Join Community',
                          style: GoogleFonts.inter(
                            color: _isMember
                                ? Colors.black
                                : const Color(0xFFDEFF6E),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),

            // Space name + rating + address + hours
            Positioned(
              bottom: 16,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating
                  Row(children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFBBF24), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      space.averageRating.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                    Text(' (${space.totalReviews} reviews)',
                        style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 12)),
                  ]),
                  const SizedBox(height: 4),

                  // Name
                  Text(
                    space.name,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Address
                  Row(children: [
                    const Icon(Icons.location_on_rounded,
                        color: Colors.white54, size: 13),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        space.address,
                        style: GoogleFonts.inter(
                            color: Colors.white60, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 3),

                  // Hours
                  Row(children: [
                    const Icon(Icons.access_time_rounded,
                        color: Colors.white54, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      '${space.openingTime ?? ''} – ${space.closingTime ?? ''}',
                      style: GoogleFonts.inter(
                          color: Colors.white60, fontSize: 12),
                    ),
                  ]),
                ],
              ),
            ),

            // Gallery badge
            if (space.galleryImages.isNotEmpty)
              Positioned(
                bottom: 16,
                right: 20,
                child: GestureDetector(
                  onTap: () => _showGallery(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library,
                            color: Colors.white, size: 13),
                        const SizedBox(width: 5),
                        Text(
                          '+${space.galleryImages.length} photos',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ]),
        ),

        // ══ SCROLLABLE CONTENT ════════════════════
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── About ──────────────────────────
                _sectionTitle('About'),
                const SizedBox(height: 8),
                Text(
                  space.description,
                  style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 14,
                      height: 1.6),
                ),
                const SizedBox(height: 28),

                // ── Amenities ──────────────────────
                _sectionTitle('Amenities'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: space.amenities.map((a) =>
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                              Colors.white.withOpacity(0.08)),
                        ),
                        child: Text(a,
                            style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 12)),
                      )).toList(),
                ),
                const SizedBox(height: 28),

                // ── Available Spaces (Tiers) ────────
                // ── Book Online tiers ───────────────
                _sectionTitle('Available Spaces'),
                const SizedBox(height: 4),
                Text('Book directly through the platform',
                    style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 12)),
                const SizedBox(height: 14),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFDEFF6E),
                        strokeWidth: 2),
                  )
                else ...[
                  // Bookable tiers
                  ...(_tiers
                      .where((t) => t.bookingType != 'contract')
                      .map((t) => _buildTierCard(t))),

                  // If none bookable
                  if (_tiers
                      .where((t) => t.bookingType != 'contract')
                      .isEmpty)
                    _emptyBox(Icons.chair_outlined,
                        'No bookable spaces yet'),
                ],

                // ── Contract / Enquiry tiers ────────
                if (_tiers.any(
                        (t) => t.bookingType == 'contract')) ...[
                  const SizedBox(height: 32),
                  _buildEnquirySection(),
                ],

                const SizedBox(height: 28),
                // ── Gallery ────────────────────────
                if (space.galleryImages.isNotEmpty) ...[
                  _sectionTitle('Gallery'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: space.galleryImages.length,
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () =>
                            _showGallery(startIndex: i + 1),
                        child: Container(
                          width: 110,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius:
                            BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white
                                    .withOpacity(0.08)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            space.galleryImages[i],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(
                                  color:
                                  Colors.white.withOpacity(0.05),
                                  child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.white24),
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // ── Reviews ────────────────────────
                Row(children: [
                  _sectionTitle('Reviews'),
                  const Spacer(),
                  // Average rating badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDEFF6E)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFDEFF6E)
                              .withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFBBF24), size: 13),
                      const SizedBox(width: 4),
                      Text(
                        space.averageRating.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700),
                      ),
                      Text(' · ${space.totalReviews}',
                          style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 12)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 14),

                if (_isLoadingReviews)
                  const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFDEFF6E),
                        strokeWidth: 2),
                  )
                else if (_reviews.isEmpty)
                  _emptyBox(Icons.rate_review_outlined,
                      'No reviews yet — be the first!')
                else
                  ..._reviews.map((r) => _buildReviewCard(r)),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ── Section title ─────────────────────────────

  Widget _sectionTitle(String title) => Text(
    title,
    style: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700),
  );

  Widget _emptyBox(IconData icon, String label) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.07)),
    ),
    child: Column(children: [
      Icon(icon, color: Colors.white24, size: 36),
      const SizedBox(height: 10),
      Text(label,
          style: GoogleFonts.inter(
              color: Colors.white38, fontSize: 14)),
    ]),
  );
  Widget _buildEnquirySection() {
    final contractTiers = _tiers
        .where((t) => t.bookingType == 'contract')
        .toList();

    // Start auto-scroll timer
    _enquiryTimer?.cancel();
    if (contractTiers.length > 1) {
      _enquiryTimer = Timer.periodic(
        const Duration(seconds: 3),
            (_) {
          if (!mounted) return;
          final next = (_enquiryPage + 1) %
              contractTiers.length;
          _enquiryPageCtrl.animateToPage(
            next,
            duration:
            const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(children: [
          Container(
            width: 3, height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFFF97316),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text('Private & Contract Spaces',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              Text(
                  'Tailored for teams — get in touch',
                  style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 11)),
            ],
          ),
        ]),
        const SizedBox(height: 14),

        // Full-width carousel
        StatefulBuilder(
          builder: (ctx, setS) => SizedBox(
            height: 280,
            child: Stack(children: [

              // PageView — full width cards
              PageView.builder(
                controller: _enquiryPageCtrl,
                itemCount: contractTiers.length,
                onPageChanged: (i) {
                  setState(() => _enquiryPage = i);
                  setS(() {});
                },
                itemBuilder: (_, i) =>
                    _buildContractCard(
                        contractTiers[i]),
              ),

              // Left arrow
              if (contractTiers.length > 1 &&
                  _enquiryPage > 0)
                Positioned(
                  left: 12,
                  top: 0, bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        _enquiryTimer?.cancel();
                        _enquiryPageCtrl
                            .previousPage(
                          duration: const Duration(
                              milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: Colors.black
                              .withOpacity(0.55),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white
                                  .withOpacity(0.2)),
                        ),
                        child: const Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                            size: 20),
                      ),
                    ),
                  ),
                ),

              // Right arrow
              if (contractTiers.length > 1 &&
                  _enquiryPage < contractTiers.length - 1)
                Positioned(
                  right: 12,
                  top: 0, bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        _enquiryTimer?.cancel();
                        _enquiryPageCtrl.nextPage(
                          duration: const Duration(
                              milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: Colors.black
                              .withOpacity(0.55),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white
                                  .withOpacity(0.2)),
                        ),
                        child: const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 20),
                      ),
                    ),
                  ),
                ),

              // Dot indicators
              if (contractTiers.length > 1)
                Positioned(
                  bottom: 12, left: 0, right: 0,
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: List.generate(
                      contractTiers.length,
                          (i) => AnimatedContainer(
                        duration: const Duration(
                            milliseconds: 250),
                        margin: const EdgeInsets
                            .symmetric(horizontal: 3),
                        width: _enquiryPage == i
                            ? 20
                            : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _enquiryPage == i
                              ? const Color(0xFFF97316)
                              : Colors.white
                              .withOpacity(0.3),
                          borderRadius:
                          BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),

        // Info notice
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF97316)
                .withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFFF97316)
                    .withOpacity(0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded,
                color: Color(0xFFF97316), size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Contract spaces involve a site tour, '
                    'legal documentation and custom pricing. '
                    'Submit an enquiry — team will reach '
                    'out within 24 hours.',
                style: GoogleFonts.inter(
                    color: const Color(0xFFF97316)
                        .withOpacity(0.85),
                    fontSize: 11,
                    height: 1.5),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildContractCard(TierModel tier) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFFF97316)
                  .withOpacity(0.25)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(fit: StackFit.expand, children: [

          // Background image
          tier.imageUrl != null &&
              tier.imageUrl!.isNotEmpty
              ? Image.network(tier.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _contractImgFallback())
              : _contractImgFallback(),

          // Bottom-to-top gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x00000000),
                  Color(0xCC1C1C1E),
                  Color(0xFF1C1C1E),
                ],
                stops: [0.0, 0.35, 0.65, 1.0],
              ),
            ),
          ),

          // Contract badge — top right
          Positioned(
            top: 14, right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF97316)
                    .withOpacity(0.9),
                borderRadius:
                BorderRadius.circular(20),
              ),
              child: Text('Contract',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
          ),

          // Content at bottom
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  20, 0, 20, 20),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(tier.name,
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4)),
                  const SizedBox(height: 4),
                  Text(tier.description,
                      style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 13,
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 14),

                  // Enquire button
                  GestureDetector(
                    onTap: () => _openTierFlow(tier),
                    child: Container(
                      width: double.infinity,
                      padding:
                      const EdgeInsets.symmetric(
                          vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius:
                        BorderRadius.circular(14),
                        border: Border.all(
                            color:
                            const Color(0xFFDEFF6E)
                                .withOpacity(0.4)),
                      ),
                      child: Center(
                        child: Text('Enquire Now',
                            style: GoogleFonts.inter(
                                color: const Color(
                                    0xFFDEFF6E),
                                fontSize: 14,
                                fontWeight:
                                FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _contractImgFallback() => Container(
    color: const Color(0xFFF97316).withOpacity(0.08),
    child: const Center(
      child: Icon(Icons.business_center_outlined,
          color: Color(0xFFF97316), size: 48),
    ),
  );

  // ── Tier card ─────────────────────────────────

  Widget _buildTierCard(TierModel tier) {
    final isAvailable = tier.availableSeats > 0;
    final double pct = tier.totalCapacity > 0
        ? tier.availableSeats / tier.totalCapacity
        : 0;
    final Color seatColor = pct > 0.5
        ? const Color(0xFF34D399)
        : pct > 0.2
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    return GestureDetector(
      onTap: isAvailable
          ? () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BookingSheet(space: widget.space, tier: tier),
      )
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: Colors.white.withOpacity(0.07)),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Left: image with right fade ──────
              SizedBox(
                width: 110,
                child: Stack(fit: StackFit.expand, children: [
                  tier.imageUrl != null &&
                      tier.imageUrl!.isNotEmpty
                      ? Image.network(tier.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _tierImgFallback())
                      : _tierImgFallback(),

                  // Fade into card bg
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Color(0xBB1C1C1E),
                          Color(0xFF1C1C1E),
                        ],
                        stops: [0.0, 0.45, 0.8, 1.0],
                      ),
                    ),
                  ),
                ]),
              ),

              // ── Right: full info column ──────────
              Expanded(
                child: Padding(
                  padding:
                  const EdgeInsets.fromLTRB(10, 14, 14, 0),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [

                      // Tier name
                      Text(
                        tier.name,
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Description
                      if (tier.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          tier.description,
                          style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 12,
                              height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 10),

                      // Tier detail chips: max hours, hourly, daily
                      // Booking type + pricing chips
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          _tierChip(
                            _bookingTypeLabel(
                                tier.bookingType),
                            _bookingTypeColor(
                                tier.bookingType),
                          ),
                          if (tier.bookingType ==
                              'hourly' &&
                              tier.pricePerHour != null)
                            _tierChip(
                              'LKR ${tier.pricePerHour!.toStringAsFixed(0)}/hr',
                              Colors.white54,
                            ),
                          if (tier.bookingType ==
                              'daily' &&
                              tier.pricePerDay != null)
                            _tierChip(
                              'LKR ${tier.pricePerDay!.toStringAsFixed(0)}/day',
                              Colors.white54,
                            ),
                          if (tier.bookingType ==
                              'monthly' &&
                              tier.pricePerMonth != null)
                            _tierChip(
                              'LKR ${tier.pricePerMonth!.toStringAsFixed(0)}/mo',
                              _bookingTypeColor(
                                  tier.bookingType),
                            ),
                          if (tier.bookingType ==
                              'annually' &&
                              tier.pricePerYear != null)
                            _tierChip(
                              'LKR ${tier.pricePerYear!.toStringAsFixed(0)}/yr',
                              _bookingTypeColor(
                                  tier.bookingType),
                            ),
                          if ((tier.bookingType ==
                              'monthly' ||
                              tier.bookingType ==
                                  'annually') &&
                              tier.minCommitment > 1)
                            _tierChip(
                              'Min ${tier.minCommitment}mo',
                              _bookingTypeColor(
                                  tier.bookingType),
                            ),
                          if (tier.bookingType ==
                              'contract')
                            _tierChip(
                              'Enquiry only',
                              _bookingTypeColor(
                                  tier.bookingType),
                            ),
                        ],
                      ),

                      const Spacer(),

                      // ── Divider ─────────────────
                      Divider(
                          color: Colors.white.withOpacity(0.07),
                          height: 1,
                          thickness: 1),

                      // ── Bottom: seats + book ────
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10),
                        child: Row(
                          children: [

                            // Seats indicator
                            Row(children: [
                              // Segmented seat dots
                              SizedBox(
                                width: 32,
                                height: 14,
                                child: Stack(
                                  children: List.generate(
                                    4,
                                        (i) {
                                      // How many dots to fill
                                      final filled = pct == 0
                                          ? 0
                                          : ((pct * 4).ceil()
                                          .clamp(0, 4));
                                      return Positioned(
                                        left: i * 9.0,
                                        child: Container(
                                          width: 7,
                                          height: 14,
                                          decoration:
                                          BoxDecoration(
                                            color: i < filled
                                                ? seatColor
                                                : Colors.white
                                                .withOpacity(
                                                0.12),
                                            borderRadius:
                                            BorderRadius
                                                .circular(3),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              RichText(
                                text: TextSpan(children: [
                                  TextSpan(
                                    text:
                                    '${tier.availableSeats}',
                                    style: GoogleFonts.inter(
                                        color: seatColor,
                                        fontSize: 13,
                                        fontWeight:
                                        FontWeight.w800),
                                  ),
                                  TextSpan(
                                    text:
                                    '/${tier.totalCapacity}',
                                    style: GoogleFonts.inter(
                                        color: Colors.white38,
                                        fontSize: 12,
                                        fontWeight:
                                        FontWeight.w500),
                                  ),
                                  TextSpan(
                                    text: ' left',
                                    style: GoogleFonts.inter(
                                        color: Colors.white30,
                                        fontSize: 11),
                                  ),
                                ]),
                              ),
                            ]),

                            const Spacer(),

                            // CTA — branches by booking type
                            GestureDetector(
                              onTap: (!isAvailable &&
                                  tier.bookingType !=
                                      'contract')
                                  ? null
                                  : () =>
                                  _openTierFlow(tier),
                              child: Container(
                                padding:
                                const EdgeInsets
                                    .symmetric(
                                    horizontal: 20,
                                    vertical: 9),
                                decoration: BoxDecoration(
                                  color: (!isAvailable &&
                                      tier.bookingType !=
                                          'contract')
                                      ? Colors.white
                                      .withOpacity(0.06)
                                      : tier.bookingType ==
                                      'contract'
                                      ? _bookingTypeColor(
                                      tier.bookingType)
                                      .withOpacity(
                                      0.15)
                                      : const Color(
                                      0xFFDEFF6E),
                                  borderRadius:
                                  BorderRadius.circular(
                                      20),
                                  border:
                                  tier.bookingType ==
                                      'contract'
                                      ? Border.all(
                                      color: _bookingTypeColor(
                                          tier.bookingType)
                                          .withOpacity(
                                          0.5))
                                      : null,
                                  boxShadow: isAvailable &&
                                      tier.bookingType !=
                                          'contract'
                                      ? [
                                    BoxShadow(
                                        color: const Color(
                                            0xFFDEFF6E)
                                            .withOpacity(
                                            0.2),
                                        blurRadius: 10)
                                  ]
                                      : null,
                                ),
                                child: Text(
                                  (!isAvailable &&
                                      tier.bookingType !=
                                          'contract')
                                      ? 'Full'
                                      : tier.bookingType ==
                                      'contract'
                                      ? 'Enquire'
                                      : (tier.bookingType ==
                                      'monthly' ||
                                      tier.bookingType ==
                                          'annually')
                                      ? 'Subscribe'
                                      : 'Book',
                                  style: GoogleFonts.inter(
                                    color: (!isAvailable &&
                                        tier.bookingType !=
                                            'contract')
                                        ? Colors.white24
                                        : tier.bookingType ==
                                        'contract'
                                        ? _bookingTypeColor(
                                        tier
                                            .bookingType)
                                        : Colors.black,
                                    fontSize: 12,
                                    fontWeight:
                                    FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _tierChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Text(label,
        style: GoogleFonts.inter(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600)),
  );

  // ── Review card ───────────────────────────────

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final user =
        review['users'] as Map<String, dynamic>? ?? {};
    final name = user['name'] as String? ?? 'Anonymous';
    final avatarUrl = user['avatar_url'] as String?;
    final rating = (review['rating'] as num?)?.toInt() ?? 5;
    final comment =
        review['comment'] as String? ?? '';
    final createdAt = review['created_at'] as String? ?? '';

    // Format date simply
    String dateStr = '';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      dateStr =
      '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {}

    // Initials fallback
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.isNotEmpty
        ? name[0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Reviewer + rating + date
          Row(children: [
            // Avatar
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFDEFF6E).withOpacity(0.15),
                border: Border.all(
                    color: const Color(0xFFDEFF6E)
                        .withOpacity(0.3)),
              ),
              child: ClipOval(
                child: avatarUrl != null &&
                    avatarUrl.isNotEmpty
                    ? Image.network(avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Center(
                          child: Text(initials,
                              style: GoogleFonts.inter(
                                  color: const Color(
                                      0xFFDEFF6E),
                                  fontSize: 12,
                                  fontWeight:
                                  FontWeight.w800)),
                        ))
                    : Center(
                  child: Text(initials,
                      style: GoogleFonts.inter(
                          color:
                          const Color(0xFFDEFF6E),
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Name + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  if (dateStr.isNotEmpty)
                    Text(dateStr,
                        style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 11)),
                ],
              ),
            ),

            // Star rating
            Row(
              children: List.generate(5, (i) => Icon(
                i < rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: const Color(0xFFFBBF24),
                size: 14,
              )),
            ),
          ]),

          // Comment
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comment,
              style: GoogleFonts.inter(
                  color: Colors.white60,
                  fontSize: 13,
                  height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  // ── Fallbacks ─────────────────────────────────

  Widget _heroFallback() => Container(
    color: const Color(0xFF1C1C1E),
    child: const Center(
      child: Icon(Icons.business_outlined,
          color: Colors.white12, size: 64),
    ),
  );

  Widget _tierImgFallback() => Container(
    color: Colors.white.withOpacity(0.05),
    child: const Center(
      child: Icon(Icons.chair_outlined,
          color: Colors.white24, size: 28),
    ),
  );
  void _openTierFlow(TierModel tier) {
    switch (tier.bookingType) {
      case 'monthly':
      case 'annually':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => SubscriptionSheet(
              space: widget.space, tier: tier),
        );
        break;
      case 'contract':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => EnquirySheet(
              space: widget.space, tier: tier),
        );
        break;
      default:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => BookingSheet(
              space: widget.space, tier: tier),
        );
    }
  }

  Color _bookingTypeColor(String type) {
    switch (type) {
      case 'daily':   return const Color(0xFF60A5FA);
      case 'monthly': return const Color(0xFFA78BFA);
      case 'annually':return const Color(0xFFFBBF24);
      case 'contract':return const Color(0xFFF97316);
      default:        return const Color(0xFFDEFF6E);
    }
  }

  String _bookingTypeLabel(String type) {
    switch (type) {
      case 'daily':   return 'Daily';
      case 'monthly': return 'Monthly';
      case 'annually':return 'Annual';
      case 'contract':return 'Contract';
      default:        return 'Hourly';
    }
  }
}

// ═══════════════════════════════════════════════
// GALLERY POPUP WITH BLUR
// ═══════════════════════════════════════════════

class _GalleryPopup extends StatefulWidget {
  final List<String> images;
  final int startIndex;
  final String spaceName;

  const _GalleryPopup({
    required this.images,
    required this.startIndex,
    required this.spaceName,
  });

  @override
  State<_GalleryPopup> createState() => _GalleryPopupState();
}

class _GalleryPopupState extends State<_GalleryPopup> {
  late PageController _pageCtrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.startIndex;
    _pageCtrl =
        PageController(initialPage: widget.startIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final topPad = MediaQuery.of(context).padding.top;

    return Stack(children: [

      // Blurred backdrop — tap to dismiss
      Positioned.fill(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
                color: Colors.black.withOpacity(0.78)),
          ),
        ),
      ),

      // Counter
      Positioned(
        top: topPad + 14,
        left: 0, right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withOpacity(0.15)),
            ),
            child: Text(
              '${_current + 1} / ${widget.images.length}',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),

      // Close button
      Positioned(
        top: topPad + 10,
        right: 16,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.2)),
            ),
            child: const Icon(Icons.close_rounded,
                color: Colors.white, size: 18),
          ),
        ),
      ),

      // Swipeable images
      Positioned.fill(
        child: PageView.builder(
          controller: _pageCtrl,
          itemCount: widget.images.length,
          onPageChanged: (i) =>
              setState(() => _current = i),
          itemBuilder: (_, i) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 90),
              child: GestureDetector(
                onTap: () {}, // don't dismiss on image tap
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: InteractiveViewer(
                    child: Image.network(
                      widget.images[i],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Container(
                            height: 260,
                            decoration: BoxDecoration(
                              color:
                              Colors.white.withOpacity(0.05),
                              borderRadius:
                              BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Icon(Icons.broken_image,
                                  color: Colors.white24,
                                  size: 48),
                            ),
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

      // Left arrow
      if (_current > 0)
        Positioned(
          left: 8, top: 0, bottom: 0,
          child: Center(
            child: GestureDetector(
              onTap: () => _pageCtrl.previousPage(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
        ),

      // Right arrow
      if (_current < widget.images.length - 1)
        Positioned(
          right: 8, top: 0, bottom: 0,
          child: Center(
            child: GestureDetector(
              onTap: () => _pageCtrl.nextPage(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
        ),

      // Dot indicators
      Positioned(
        bottom: bottomPad + 28,
        left: 0, right: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.images.length,
                (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin:
              const EdgeInsets.symmetric(horizontal: 3),
              width: _current == i ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _current == i
                    ? const Color(0xFFDEFF6E)
                    : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}