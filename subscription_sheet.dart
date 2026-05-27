import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/space_model.dart';
import '../../models/tier_model.dart';
import 'tier_policy_screen.dart';

class SubscriptionSheet extends StatefulWidget {
  final SpaceModel space;
  final TierModel tier;

  const SubscriptionSheet({
    super.key,
    required this.space,
    required this.tier,
  });

  @override
  State<SubscriptionSheet> createState() =>
      _SubscriptionSheetState();
}

class _SubscriptionSheetState
    extends State<SubscriptionSheet> {
  final _supabase = Supabase.instance.client;
  bool _isSubmitting = false;
  bool _policyAcknowledged = false;
  late int _months;

  @override
  void initState() {
    super.initState();
    // Start at minimum commitment
    _months = widget.tier.minCommitment > 0
        ? widget.tier.minCommitment
        : 1;
  }

  // ── Price calculation ─────────────────────────

  double get _pricePerUnit {
    if (widget.tier.bookingType == 'annually') {
      return widget.tier.pricePerYear ?? 0;
    }
    return widget.tier.pricePerMonth ?? 0;
  }

  double get _totalPrice =>
      _pricePerUnit * _months;

  String get _unitLabel =>
      widget.tier.bookingType == 'annually'
          ? 'year'
          : 'month';

  bool get _hasPolicy =>
      widget.tier.policies.isNotEmpty;

  // ── Submit ────────────────────────────────────

  Future<void> _submit() async {
    if (_hasPolicy && !_policyAcknowledged) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Please read and accept the policy first',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId =
          _supabase.auth.currentUser!.id;

      await _supabase.from('subscriptions').insert({
        'user_id': userId,
        'space_id': widget.space.id,
        'tier_id': widget.tier.id,
        'months_committed': _months,
        'total_price': _totalPrice,
        'status': 'pending',
      });

      // Notification
      await _supabase
          .from('notifications')
          .insert({
        'recipient_id': userId,
        'message':
        'Your membership request for ${widget.tier.name} '
            'at ${widget.space.name} has been submitted. '
            'The admin will review and activate it shortly.',
      });

      if (mounted) {
        Navigator.pop(context);
        _showSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
            backgroundColor:
            const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showSuccess() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SuccessSheet(
          space: widget.space, tier: widget.tier),
    );
  }

  // ── BUILD ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPad =
        MediaQuery.of(context).padding.bottom;
    final typeColor =
    widget.tier.bookingType == 'annually'
        ? const Color(0xFFFBBF24)
        : const Color(0xFFA78BFA);

    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context)
              .viewInsets
              .bottom +
              bottomPad),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            24, 16, 24, 24),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color:
                  Colors.white.withOpacity(0.1),
                  borderRadius:
                  BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Header ───────────────────────────
            Row(children: [
              // Tier image thumbnail
              ClipRRect(
                borderRadius:
                BorderRadius.circular(12),
                child: SizedBox(
                  width: 48, height: 48,
                  child: widget.tier.imageUrl !=
                      null &&
                      widget.tier.imageUrl!
                          .isNotEmpty
                      ? Image.network(
                    widget.tier.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) =>
                        _imgFallback(
                            typeColor),
                  )
                      : _imgFallback(typeColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(widget.tier.name,
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight:
                            FontWeight.w800,
                            letterSpacing: -0.3)),
                    Text(widget.space.name,
                        style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 12)),
                  ],
                ),
              ),
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.12),
                  borderRadius:
                  BorderRadius.circular(20),
                  border: Border.all(
                      color:
                      typeColor.withOpacity(0.3)),
                ),
                child: Text(
                  widget.tier.bookingType ==
                      'annually'
                      ? 'Annual'
                      : 'Monthly',
                  style: GoogleFonts.inter(
                      color: typeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ]),

            const SizedBox(height: 24),

            // ── Month selector ───────────────────
            _sectionLabel(
                widget.tier.bookingType == 'annually'
                    ? 'Number of Years'
                    : 'Number of Months'),
            const SizedBox(height: 4),
            Text(
              'Minimum commitment: ${widget.tier.minCommitment} '
                  '${_unitLabel}${widget.tier.minCommitment > 1 ? 's' : ''}',
              style: GoogleFonts.inter(
                  color: typeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),

            // Stepper
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius:
                BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white
                        .withOpacity(0.08)),
              ),
              child: Row(children: [
                // Minus
                GestureDetector(
                  onTap: _months >
                      widget.tier.minCommitment
                      ? () =>
                      setState(() => _months--)
                      : null,
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withOpacity(0.06),
                      borderRadius:
                      BorderRadius.circular(11),
                      border: Border.all(
                          color: Colors.white
                              .withOpacity(0.1)),
                    ),
                    child: Icon(Icons.remove,
                        color: _months >
                            widget.tier
                                .minCommitment
                            ? Colors.white
                            : Colors.white24,
                        size: 18),
                  ),
                ),

                // Count display
                Expanded(
                  child: Column(children: [
                    Text('$_months',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight:
                            FontWeight.w800,
                            height: 1),
                        textAlign: TextAlign.center),
                    Text(
                        '$_unitLabel${_months > 1 ? 's' : ''}',
                        style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 12),
                        textAlign: TextAlign.center),
                  ]),
                ),

                // Plus
                GestureDetector(
                  onTap: () =>
                      setState(() => _months++),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.12),
                      borderRadius:
                      BorderRadius.circular(11),
                      border: Border.all(
                          color: typeColor
                              .withOpacity(0.3)),
                    ),
                    child: Icon(Icons.add,
                        color: typeColor, size: 18),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 20),

            // ── Price breakdown ──────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.06),
                borderRadius:
                BorderRadius.circular(16),
                border: Border.all(
                    color: typeColor.withOpacity(0.2)),
              ),
              child: Column(children: [
                _priceRow(
                  'Rate',
                  'LKR ${_pricePerUnit.toStringAsFixed(0)} / $_unitLabel',
                  Colors.white54,
                ),
                const SizedBox(height: 8),
                _priceRow(
                  'Duration',
                  '$_months $_unitLabel${_months > 1 ? 's' : ''}',
                  Colors.white54,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10),
                  child: Divider(
                      color: Colors.white
                          .withOpacity(0.08),
                      height: 1),
                ),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight:
                            FontWeight.w700)),
                    Text(
                      'LKR ${_totalPrice.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                          color: typeColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5),
                    ),
                  ],
                ),
              ]),
            ),

            // ── Policy acknowledge ───────────────
            if (_hasPolicy) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TierPolicyScreen(
                      tierName: widget.tier.name,
                      policies: widget.tier.policies
                          .map((k, v) =>
                          MapEntry(k, v.toString())),
                      previewMode: false,
                      onAcknowledged: () => setState(
                              () =>
                          _policyAcknowledged =
                          true),
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _policyAcknowledged
                        ? const Color(0xFFDEFF6E)
                        .withOpacity(0.07)
                        : Colors.white.withOpacity(0.04),
                    borderRadius:
                    BorderRadius.circular(14),
                    border: Border.all(
                      color: _policyAcknowledged
                          ? const Color(0xFFDEFF6E)
                          .withOpacity(0.35)
                          : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Row(children: [
                    AnimatedContainer(
                      duration: const Duration(
                          milliseconds: 180),
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: _policyAcknowledged
                            ? const Color(0xFFDEFF6E)
                            : Colors.transparent,
                        borderRadius:
                        BorderRadius.circular(6),
                        border: Border.all(
                          color: _policyAcknowledged
                              ? Colors.transparent
                              : Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: _policyAcknowledged
                          ? const Icon(
                          Icons.check_rounded,
                          color: Colors.black,
                          size: 14)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            _policyAcknowledged
                                ? 'Policy accepted'
                                : 'Read & accept membership policy',
                            style: GoogleFonts.inter(
                                color: _policyAcknowledged
                                    ? const Color(
                                    0xFFDEFF6E)
                                    : Colors.white70,
                                fontSize: 13,
                                fontWeight:
                                FontWeight.w600),
                          ),
                          if (!_policyAcknowledged)
                            Text(
                                'Tap to read the full policy',
                                style: GoogleFonts.inter(
                                    color: Colors.white38,
                                    fontSize: 11)),
                        ],
                      ),
                    ),
                    if (!_policyAcknowledged)
                      const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white24,
                          size: 18),
                  ]),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Notice ───────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius:
                BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white
                        .withOpacity(0.06)),
              ),
              child: Text(
                'Your membership will be activated once '
                    'the space admin approves your request. '
                    'Start and end dates are set from the '
                    'approval date.',
                style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 11,
                    height: 1.5),
              ),
            ),

            const SizedBox(height: 20),

            // ── Submit button ────────────────────
            GestureDetector(
              onTap: (_isSubmitting ||
                  (_hasPolicy &&
                      !_policyAcknowledged))
                  ? null
                  : _submit,
              child: AnimatedContainer(
                duration:
                const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 15),
                decoration: BoxDecoration(
                  color: (_isSubmitting ||
                      (_hasPolicy &&
                          !_policyAcknowledged))
                      ? const Color(0xFFDEFF6E)
                      .withOpacity(0.4)
                      : const Color(0xFFDEFF6E),
                  borderRadius:
                  BorderRadius.circular(14),
                  boxShadow: (_isSubmitting ||
                      (_hasPolicy &&
                          !_policyAcknowledged))
                      ? null
                      : [
                    BoxShadow(
                        color: const Color(
                            0xFFDEFF6E)
                            .withOpacity(0.2),
                        blurRadius: 12),
                  ],
                ),
                child: Center(
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 18, height: 18,
                    child:
                    CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    (_hasPolicy &&
                        !_policyAcknowledged)
                        ? 'Accept policy to continue'
                        : 'Request Membership',
                    style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight:
                        FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────

  Widget _priceRow(
      String label, String value, Color color) =>
      Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  color: color, fontSize: 12)),
          Text(value,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      );

  Widget _sectionLabel(String label) => Text(label,
      style: GoogleFonts.inter(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2));

  Widget _imgFallback(Color color) => Container(
    color: color.withOpacity(0.1),
    child: Center(
      child: Icon(Icons.chair_outlined,
          color: color, size: 20),
    ),
  );
}

// ── Success sheet ─────────────────────────────────

class _SuccessSheet extends StatelessWidget {
  final SpaceModel space;
  final TierModel tier;

  const _SuccessSheet(
      {required this.space, required this.tier});

  @override
  Widget build(BuildContext context) {
    final bottomPad =
        MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 32, 24, bottomPad + 32),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
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
          const SizedBox(height: 32),

          // Icon
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFDEFF6E)
                  .withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFFDEFF6E)
                      .withOpacity(0.3)),
            ),
            child: const Icon(
                Icons.card_membership_rounded,
                color: Color(0xFFDEFF6E),
                size: 30),
          ),
          const SizedBox(height: 20),

          Text('Membership Requested!',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Text(
            'Your request for ${tier.name} at '
                '${space.name} has been submitted. '
                'The admin will review and activate '
                'your membership shortly.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 13,
                height: 1.5),
          ),
          const SizedBox(height: 28),

          // Status strip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color:
                  Colors.white.withOpacity(0.07)),
            ),
            child: Row(children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFBBF24),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pending admin approval — '
                      'you\'ll be notified once activated',
                  style: GoogleFonts.inter(
                      color: const Color(0xFFFBBF24),
                      fontSize: 12,
                      height: 1.4),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius:
                BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white
                        .withOpacity(0.08)),
              ),
              child: Center(
                child: Text('Done',
                    style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}