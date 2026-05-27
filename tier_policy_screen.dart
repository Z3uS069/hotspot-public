import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TierPolicyScreen extends StatefulWidget {
  final String tierName;
  final Map<String, dynamic> policies;
  final bool previewMode;
  final VoidCallback? onAcknowledged;

  const TierPolicyScreen({
    super.key,
    required this.tierName,
    required this.policies,
    this.previewMode = false,
    this.onAcknowledged,
  });

  @override
  State<TierPolicyScreen> createState() =>
      _TierPolicyScreenState();
}

class _TierPolicyScreenState
    extends State<TierPolicyScreen> {
  bool _acknowledged = false;
  final ScrollController _scrollCtrl =
  ScrollController();
  bool _hasScrolledToBottom = false;

  // Maps key → display label
  static const _labels = {
    'cancellation': 'Cancellation Policy',
    'notice_period': 'Notice Period',
    'refund': 'Refund Policy',
    'deposit': 'Deposit & Payment Terms',
    'access': 'Access & Hours',
    'guest': 'Guest Policy',
    'additional': 'Additional Terms',
  };

  // Ordered keys
  static const _order = [
    'cancellation',
    'notice_period',
    'refund',
    'deposit',
    'access',
    'guest',
    'additional',
  ];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 40) {
      if (!_hasScrolledToBottom) {
        setState(() => _hasScrolledToBottom = true);
      }
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  List<MapEntry<String, String>> get _sections {
    return _order
        .where((k) =>
    widget.policies.containsKey(k) &&
        widget.policies[k] != null &&
        (widget.policies[k] as String)
            .isNotEmpty)
        .map((k) => MapEntry(
        k, widget.policies[k] as String))
        .toList();
  }

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
              20, topPad + 14, 20, 14),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(children: [
                GestureDetector(
                  onTap: () =>
                      Navigator.pop(context),
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
                    child: const Icon(
                        Icons
                            .arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 15),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.previewMode
                            ? 'Policy Preview'
                            : 'Membership Policy',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight:
                            FontWeight.w800,
                            letterSpacing: -0.3),
                      ),
                      Text(widget.tierName,
                          style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 12)),
                    ],
                  ),
                ),
                if (widget.previewMode)
                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24)
                          .withOpacity(0.12),
                      borderRadius:
                      BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(
                              0xFFFBBF24)
                              .withOpacity(0.3)),
                    ),
                    child: Text('Preview',
                        style: GoogleFonts.inter(
                            color: const Color(
                                0xFFFBBF24),
                            fontSize: 10,
                            fontWeight:
                            FontWeight.w700)),
                  ),
              ]),

              // Scroll hint — only for real mode
              if (!widget.previewMode &&
                  !_hasScrolledToBottom) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEFF6E)
                        .withOpacity(0.07),
                    borderRadius:
                    BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFDEFF6E)
                            .withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    const Icon(
                        Icons.arrow_downward_rounded,
                        color: Color(0xFFDEFF6E),
                        size: 13),
                    const SizedBox(width: 7),
                    Text(
                      'Scroll to read the full policy before confirming',
                      style: GoogleFonts.inter(
                          color: const Color(
                              0xFFDEFF6E),
                          fontSize: 11,
                          height: 1.3),
                    ),
                  ]),
                ),
              ],
            ],
          ),
        ),

        Divider(
            height: 1,
            color: Colors.white.withOpacity(0.06)),

        // ── Policy content ────────────────────
        Expanded(
          child: ListView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(
                20, 20, 20, 20),
            children: [
              // Document header
              Container(
                padding: const EdgeInsets.all(18),
                margin:
                const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius:
                  BorderRadius.circular(18),
                  border: Border.all(
                      color: Colors.white
                          .withOpacity(0.07)),
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: const Color(
                              0xFFDEFF6E)
                              .withOpacity(0.1),
                          borderRadius:
                          BorderRadius.circular(
                              10),
                          border: Border.all(
                              color: const Color(
                                  0xFFDEFF6E)
                                  .withOpacity(0.3)),
                        ),
                        child: const Icon(
                            Icons
                                .description_outlined,
                            color: Color(0xFFDEFF6E),
                            size: 17),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Membership Agreement',
                                style:
                                GoogleFonts.inter(
                                    color: Colors
                                        .white,
                                    fontSize: 14,
                                    fontWeight:
                                    FontWeight
                                        .w700)),
                            Text(widget.tierName,
                                style:
                                GoogleFonts.inter(
                                    color: Colors
                                        .white38,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Divider(
                        height: 1,
                        color: Colors.white
                            .withOpacity(0.06)),
                    const SizedBox(height: 12),
                    Text(
                      'This document outlines the terms and conditions '
                          'of your membership for the ${widget.tierName} tier. '
                          'Please read each section carefully before confirming.',
                      style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 12,
                          height: 1.6),
                    ),
                  ],
                ),
              ),

              // Policy sections
              ..._sections.asMap().entries.map(
                    (entry) {
                  final i = entry.key;
                  final section = entry.value;
                  final label =
                      _labels[section.key] ??
                          section.key;
                  final isLast =
                      i == _sections.length - 1;

                  return Padding(
                    padding: EdgeInsets.only(
                        bottom: isLast ? 0 : 14),
                    child: _buildPolicySection(
                        i + 1, label, section.value),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Effective date notice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white
                      .withOpacity(0.03),
                  borderRadius:
                  BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white
                          .withOpacity(0.06)),
                ),
                child: Text(
                  'These terms apply from the date your membership is activated. '
                      'The space operator reserves the right to update this policy '
                      'with reasonable notice.',
                  style: GoogleFonts.inter(
                      color: Colors.white24,
                      fontSize: 11,
                      height: 1.5),
                ),
              ),
            ],
          ),
        ),

        // ── Bottom: acknowledge + confirm ──────
        if (!widget.previewMode)
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, bottomPad + 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              border: Border(
                  top: BorderSide(
                      color: Colors.white
                          .withOpacity(0.07))),
              boxShadow: [
                BoxShadow(
                    color:
                    Colors.black.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, -4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Acknowledge checkbox
                GestureDetector(
                  onTap: () => setState(
                          () => _acknowledged =
                      !_acknowledged),
                  child: Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(
                            milliseconds: 180),
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: _acknowledged
                              ? const Color(
                              0xFFDEFF6E)
                              : Colors.transparent,
                          borderRadius:
                          BorderRadius.circular(
                              6),
                          border: Border.all(
                            color: _acknowledged
                                ? Colors.transparent
                                : Colors.white
                                .withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: _acknowledged
                            ? const Icon(
                            Icons.check_rounded,
                            color: Colors.black,
                            size: 14)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'I have read and understood the membership policy for ${widget.tierName} and agree to the terms outlined above.',
                          style: GoogleFonts.inter(
                              color: Colors.white60,
                              fontSize: 12,
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Confirm button
                GestureDetector(
                  onTap: _acknowledged
                      ? () {
                    Navigator.pop(context);
                    widget.onAcknowledged
                        ?.call();
                  }
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(
                        milliseconds: 200),
                    width: double.infinity,
                    padding:
                    const EdgeInsets.symmetric(
                        vertical: 15),
                    decoration: BoxDecoration(
                      color: _acknowledged
                          ? const Color(0xFFDEFF6E)
                          : Colors.white
                          .withOpacity(0.06),
                      borderRadius:
                      BorderRadius.circular(14),
                      boxShadow: _acknowledged
                          ? [
                        BoxShadow(
                            color: const Color(
                                0xFFDEFF6E)
                                .withOpacity(
                                0.2),
                            blurRadius: 12),
                      ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        _acknowledged
                            ? 'I Agree — Continue'
                            : 'Read the policy to continue',
                        style: GoogleFonts.inter(
                            color: _acknowledged
                                ? Colors.black
                                : Colors.white24,
                            fontSize: 14,
                            fontWeight:
                            FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ]),
    );
  }

  Widget _buildPolicySection(
      int number, String label, String content) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.fromLTRB(
                16, 12, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: Colors.white
                          .withOpacity(0.06))),
            ),
            child: Row(children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFDEFF6E)
                      .withOpacity(0.1),
                  borderRadius:
                  BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text('$number',
                      style: GoogleFonts.inter(
                          color:
                          const Color(0xFFDEFF6E),
                          fontSize: 11,
                          fontWeight:
                          FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 10),
              Text(label,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ]),
          ),

          // Section content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: GoogleFonts.inter(
                  color: Colors.white60,
                  fontSize: 13,
                  height: 1.7),
            ),
          ),
        ],
      ),
    );
  }
}