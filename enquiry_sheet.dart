import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/space_model.dart';
import '../../models/tier_model.dart';
import 'package:flutter/services.dart';

class EnquirySheet extends StatefulWidget {
  final SpaceModel space;
  final TierModel tier;

  const EnquirySheet({
    super.key,
    required this.space,
    required this.tier,
  });

  @override
  State<EnquirySheet> createState() =>
      _EnquirySheetState();
}

class _EnquirySheetState
    extends State<EnquirySheet> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _submitted = false;

  final _companyCtrl = TextEditingController();
  final _contactNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _requirementsCtrl = TextEditingController();
  int _teamSize = 1;
  DateTime? _preferredStart;

  @override
  void dispose() {
    _companyCtrl.dispose();
    _contactNameCtrl.dispose();
    _phoneCtrl.dispose();
    _requirementsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final userId =
          _supabase.auth.currentUser!.id;

      await _supabase.from('enquiries').insert({
        'user_id': userId,
        'space_id': widget.space.id,
        'tier_id': widget.tier.id,
        'company_name': _companyCtrl.text.trim(),
        'contact_name':
        _contactNameCtrl.text.trim(),
        'contact_phone': _phoneCtrl.text.trim(),
        'team_size': _teamSize,
        'requirements':
        _requirementsCtrl.text.trim(),
        'preferred_start_date':
        _preferredStart?.toIso8601String(),
        'status': 'pending',
      });

      // Notification to user
      await _supabase
          .from('notifications')
          .insert({
        'recipient_id': userId,
        'message':
        'Your enquiry for ${widget.tier.name} at ${widget.space.name} has been received. '
            'The team will reach out within 24 hours.',
      });

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submitted = true;
        });
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

  //BUILD

  @override
  Widget build(BuildContext context) {
    final bottomPad =
        MediaQuery.of(context).padding.bottom;

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
      child: _submitted
          ? _buildSuccess()
          : SingleChildScrollView(
        padding:
        const EdgeInsets.fromLTRB(
            24, 16, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              //Handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withOpacity(0.1),
                    borderRadius:
                    BorderRadius.circular(
                        2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              //Header
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(
                        0xFFF97316)
                        .withOpacity(0.12),
                    borderRadius:
                    BorderRadius.circular(
                        12),
                    border: Border.all(
                        color: const Color(
                            0xFFF97316)
                            .withOpacity(0.3)),
                  ),
                  child: const Icon(
                      Icons
                          .business_center_outlined,
                      color:
                      Color(0xFFF97316),
                      size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text('Enquire Now',
                          style:
                          GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight:
                            FontWeight.w800,
                            letterSpacing: -0.3,
                          )),
                      Text(
                          '${widget.tier.name} · ${widget.space.name}',
                          style:
                          GoogleFonts.inter(
                            color:
                            Colors.white38,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow
                              .ellipsis),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 6),

              // Information notice
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(
                    top: 12, bottom: 20),
                padding:
                const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316)
                      .withOpacity(0.07),
                  borderRadius:
                  BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(
                          0xFFF97316)
                          .withOpacity(0.2)),
                ),
                child: Text(
                  'This is an enquiry-based space. '
                      'Fill in your details and the team will '
                      'arrange a tour and discuss pricing within '
                      '24 hours.',
                  style: GoogleFonts.inter(
                      color: const Color(
                          0xFFF97316)
                          .withOpacity(0.9),
                      fontSize: 12,
                      height: 1.5),
                ),
              ),

              //Company name
              _label('Company / Organisation'),
              const SizedBox(height: 6),
              _field(
                ctrl: _companyCtrl,
                hint:
                'e.g. Acme Pvt Ltd',
                validator: (v) =>
                v == null || v.isEmpty
                    ? 'Required'
                    : null,
              ),
              const SizedBox(height: 14),

              // Contact name
              _label('Your Name'),
              const SizedBox(height: 6),
              _field(
                ctrl: _contactNameCtrl,
                hint: 'Full name',
                validator: (v) =>
                v == null || v.isEmpty
                    ? 'Required'
                    : null,
              ),
              const SizedBox(height: 14),

              //phone
              _label('Contact Number'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length != 10) return 'Must be exactly 10 digits';
                  return null;
                },
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '0771234567',
                  hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDEFF6E)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFEF4444)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),

              // Team size stepper
              _label('Team Size'),
              const SizedBox(height: 6),
              _buildTeamSizeStepper(),
              const SizedBox(height: 14),

              //Preferred start
              _label('Preferred Start Date'),
              const SizedBox(height: 6),
              _buildDatePicker(),
              const SizedBox(height: 14),

              //Requirements
              _label(
                  'Requirements & Notes'),
              const SizedBox(height: 6),
              _field(
                ctrl: _requirementsCtrl,
                hint:
                'Tell us about your team\'s needs, preferred setup, '
                    'any specific requirements...',
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              //Submit
              GestureDetector(
                onTap: _isSubmitting
                    ? null
                    : _submit,
                child: AnimatedContainer(
                  duration: const Duration(
                      milliseconds: 200),
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(
                      vertical: 15),
                  decoration: BoxDecoration(
                    color: _isSubmitting
                        ? const Color(0xFFDEFF6E)
                        .withOpacity(0.5)
                        : const Color(0xFFDEFF6E),
                    borderRadius:
                    BorderRadius.circular(14),
                    boxShadow: _isSubmitting
                        ? null
                        : [
                      BoxShadow(
                          color: const Color(
                              0xFFDEFF6E)
                              .withOpacity(
                              0.2),
                          blurRadius: 12),
                    ],
                  ),
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                      CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      'Submit Enquiry',
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
      ),
    );
  }

  //Success screen

  Widget _buildSuccess() {
    final bottomPad =
        MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 32, 24, bottomPad + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
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
                Icons.check_rounded,
                color: Color(0xFFDEFF6E),
                size: 32),
          ),
          const SizedBox(height: 20),

          Text('Enquiry Submitted!',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Text(
            'The team at ${widget.space.name} will '
                'reach out within 24 hours to arrange '
                'a tour and discuss your requirements.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 13,
                height: 1.5),
          ),
          const SizedBox(height: 28),

          // What happens next
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color:
                  Colors.white.withOpacity(0.07)),
            ),
            child: Column(children: [
              _nextStep('1', 'Team reviews your enquiry',
                  'Usually within a few hours'),
              _nextStep('2', 'Tour is arranged',
                  'A site visit at your convenience'),
              _nextStep('3', 'Pricing & terms discussed',
                  'Custom proposal based on your needs'),
            ]),
          ),

          const SizedBox(height: 24),

          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(
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
    );
  }

  Widget _nextStep(
      String number, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFFDEFF6E)
                .withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(number,
                style: GoogleFonts.inter(
                    color: const Color(0xFFDEFF6E),
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Text(sub,
                  style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 11)),
            ],
          ),
        ),
      ]),
    );
  }

  //Helpers

  Widget _buildTeamSizeStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: _teamSize > 1
              ? () =>
              setState(() => _teamSize--)
              : null,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color:
                  Colors.white.withOpacity(0.1)),
            ),
            child: Icon(Icons.remove,
                color: _teamSize > 1
                    ? Colors.white
                    : Colors.white24,
                size: 16),
          ),
        ),
        Expanded(
          child: Column(children: [
            Text('$_teamSize',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1),
                textAlign: TextAlign.center),
            Text(
                _teamSize == 1
                    ? 'person'
                    : 'people',
                style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 11),
                textAlign: TextAlign.center),
          ]),
        ),
        GestureDetector(
          onTap: () =>
              setState(() => _teamSize++),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFDEFF6E)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFDEFF6E)
                      .withOpacity(0.3)),
            ),
            child: const Icon(Icons.add,
                color: Color(0xFFDEFF6E), size: 16),
          ),
        ),
      ]),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now()
              .add(const Duration(days: 7)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now()
              .add(const Duration(days: 365)),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFDEFF6E),
                onPrimary: Colors.black,
                surface: Color(0xFF1C1C1E),
                onSurface: Colors.white,
              ),
              dialogBackgroundColor:
              const Color(0xFF111111),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          setState(
                  () => _preferredStart = picked);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _preferredStart != null
                ? const Color(0xFFDEFF6E)
                .withOpacity(0.4)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined,
              color: _preferredStart != null
                  ? const Color(0xFFDEFF6E)
                  : Colors.white38,
              size: 16),
          const SizedBox(width: 10),
          Text(
            _preferredStart != null
                ? '${_preferredStart!.day}/${_preferredStart!.month}/${_preferredStart!.year}'
                : 'Select preferred start date',
            style: GoogleFonts.inter(
              color: _preferredStart != null
                  ? Colors.white
                  : Colors.white38,
              fontSize: 14,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.inter(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2));

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    int maxLines = 1,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: type,
      validator: validator,
      style: GoogleFonts.inter(
          color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
            color: Colors.white24, fontSize: 13),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color(0xFFDEFF6E)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color(0xFFEF4444)),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
      ),
    );
  }
}