import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/space_model.dart';
import '../../services/space_service.dart';
import 'space_detail_screen.dart';
import '../../models/tier_model.dart';
import 'enquiry_sheet.dart';
import 'subscription_sheet.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final SpaceService _spaceService = SpaceService();
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  List<SpaceModel> _spaces = [];
  List<SpaceModel> _filteredSpaces = [];
  bool _isLoading = true;
  LatLng _currentLocation = const LatLng(6.9271, 79.8612);

  //Filter state
  List<String> _selectedAmenities = [];
  double _minRating = 0;
  double _maxDistance = 50;
  double _maxPrice = 5000;
  List<String> _selectedDays = [];
  bool _filtersActive = false;
  String _sortBy = 'distance';

  final List<String> _allAmenities = [
    'WiFi', 'Parking', 'Coffee', 'Printer',
    'Meeting Rooms', 'Phone Booths', 'Lockers',
    'Reception', '24/7 Access', 'Cafeteria',
    'Projector', 'Whiteboard', 'Air Conditioning',
  ];

  final List<String> _allDays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  //BACKEND LOGIC

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _loadSpaces();
    _searchCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLocation() async {
    try {
      LocationPermission permission =
      await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition();
        setState(() => _currentLocation =
            LatLng(pos.latitude, pos.longitude));
        _applyFilters();
      }
    } catch (_) {}
  }

  Future<void> _loadSpaces() async {
    setState(() => _isLoading = true);
    try {
      final spaces = await _spaceService.getActiveSpaces();
      setState(() {
        _spaces = spaces;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double _getDistance(SpaceModel space) {
    return const Distance().as(
      LengthUnit.Kilometer,
      _currentLocation,
      LatLng(space.latitude, space.longitude),
    );
  }

  void _applyFilters() {
    final query = _searchCtrl.text.toLowerCase().trim();
    List<SpaceModel> filtered = _spaces.where((space) {
      final matchesSearch = query.isEmpty ||
          space.name.toLowerCase().contains(query) ||
          space.address.toLowerCase().contains(query);
      final matchesRating = space.averageRating >= _minRating;
      final matchesAmenities = _selectedAmenities.isEmpty ||
          _selectedAmenities.every((a) => space.amenities.contains(a));
      final dist = _getDistance(space);
      final matchesDistance = dist <= _maxDistance;
      final matchesDays = _selectedDays.isEmpty ||
          _selectedDays.any((d) => space.operatingDays.contains(d));
      final matchesPrice = space.minPricePerHour == null ||
          space.minPricePerHour! <= _maxPrice;
      return matchesSearch && matchesRating &&
          matchesAmenities && matchesDistance && matchesDays && matchesPrice;
    }).toList();

    switch (_sortBy) {
      case 'distance':
        filtered.sort((a, b) =>
            _getDistance(a).compareTo(_getDistance(b)));
        break;
      case 'rating':
        filtered.sort((a, b) =>
            b.averageRating.compareTo(a.averageRating));
        break;
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    setState(() {
      _filteredSpaces = filtered;
      _filtersActive = _selectedAmenities.isNotEmpty ||
          _minRating > 0 ||
          _maxDistance < 50 ||
          _maxPrice < 5000 ||
          _selectedDays.isNotEmpty;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedAmenities = [];
      _minRating = 0;
      _maxDistance = 50;
      _maxPrice = 5000;
      _selectedDays = [];
      _filtersActive = false;
    });
    _applyFilters();
  }

  void _showFilterSheet() {
    List<String> tempAmenities = List.from(_selectedAmenities);
    double tempRating = _minRating;
    double tempDistance = _maxDistance;
    double tempPrice = _maxPrice;
    List<String> tempDays = List.from(_selectedDays);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.88,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, sc) => SingleChildScrollView(
            controller: sc,
            padding: const EdgeInsets.all(20),
            child: Column(
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filter Spaces',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                    GestureDetector(
                      onTap: () => setS(() {
                        tempAmenities = [];
                        tempRating = 0;
                        tempDistance = 50;
                        tempPrice = 5000;
                        tempDays = [];
                      }),
                      child: Text('Reset all',
                          style: GoogleFonts.inter(
                              color: const Color(0xFFDEFF6E),
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _fsec('Minimum Rating', Icons.star,
                    const Color(0xFFFBBF24),
                    child: Column(children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              tempRating == 0
                                  ? 'Any rating'
                                  : '${tempRating.toStringAsFixed(1)}+ ★',
                              style: GoogleFonts.inter(
                                  color: Colors.white54,
                                  fontSize: 13)),
                          Text(
                              '${tempRating.toStringAsFixed(1)} / 5.0',
                              style: GoogleFonts.inter(
                                  color: const Color(0xFFFBBF24),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      _buildSlider(ctx, tempRating, 0, 5, 10,
                          const Color(0xFFFBBF24),
                              (v) => setS(() => tempRating = v)),
                    ])),
                const SizedBox(height: 12),

                _fsec('Maximum Distance', Icons.near_me,
                    const Color(0xFF34D399),
                    child: Column(children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              'Within ${tempDistance.toInt()} km',
                              style: GoogleFonts.inter(
                                  color: Colors.white54,
                                  fontSize: 13)),
                          Text('${tempDistance.toInt()} km',
                              style: GoogleFonts.inter(
                                  color: const Color(0xFF34D399),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      _buildSlider(ctx, tempDistance, 1, 50, 49,
                          const Color(0xFF34D399),
                              (v) => setS(() => tempDistance = v)),
                    ])),
                const SizedBox(height: 12),

                _fsec('Max Price / Hour',
                    Icons.payments_outlined,
                    const Color(0xFFDEFF6E),
                    child: Column(children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              'Up to LKR ${tempPrice.toInt()}',
                              style: GoogleFonts.inter(
                                  color: Colors.white54,
                                  fontSize: 13)),
                          Text('LKR ${tempPrice.toInt()}/hr',
                              style: GoogleFonts.inter(
                                  color: const Color(0xFFDEFF6E),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      _buildSlider(ctx, tempPrice, 100, 5000, 49,
                          const Color(0xFFDEFF6E),
                              (v) => setS(() => tempPrice = v)),
                    ])),
                const SizedBox(height: 12),

                _fsec('Operating Days',
                    Icons.calendar_today,
                    const Color(0xFFF59E0B),
                    child: Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _allDays.map((d) {
                        final sel = tempDays.contains(d);
                        return GestureDetector(
                          onTap: () => setS(() => sel
                              ? tempDays.remove(d)
                              : tempDays.add(d)),
                          child: AnimatedContainer(
                            duration: const Duration(
                                milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: sel
                                  ? const Color(0xFFF59E0B)
                                  : Colors.white.withOpacity(0.06),
                              borderRadius:
                              BorderRadius.circular(8),
                              border: Border.all(
                                  color: sel
                                      ? Colors.transparent
                                      : Colors.white
                                      .withOpacity(0.1)),
                            ),
                            child: Text(d,
                                style: GoogleFonts.inter(
                                    color: sel
                                        ? Colors.black
                                        : Colors.white54,
                                    fontSize: 12,
                                    fontWeight: sel
                                        ? FontWeight.w700
                                        : FontWeight.w400)),
                          ),
                        );
                      }).toList(),
                    )),
                const SizedBox(height: 12),

                _fsec('Amenities',
                    Icons.check_circle_outline,
                    const Color(0xFFDEFF6E),
                    child: Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _allAmenities.map((a) {
                        final sel = tempAmenities.contains(a);
                        return GestureDetector(
                          onTap: () => setS(() => sel
                              ? tempAmenities.remove(a)
                              : tempAmenities.add(a)),
                          child: AnimatedContainer(
                            duration: const Duration(
                                milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: sel
                                  ? const Color(0xFFDEFF6E)
                                  .withOpacity(0.12)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius:
                              BorderRadius.circular(8),
                              border: Border.all(
                                  color: sel
                                      ? const Color(0xFFDEFF6E)
                                      .withOpacity(0.4)
                                      : Colors.white
                                      .withOpacity(0.1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (sel) ...[
                                  const Icon(Icons.check,
                                      color: Color(0xFFDEFF6E),
                                      size: 11),
                                  const SizedBox(width: 4),
                                ],
                                Text(a,
                                    style: GoogleFonts.inter(
                                        color: sel
                                            ? const Color(0xFFDEFF6E)
                                            : Colors.white38,
                                        fontSize: 12,
                                        fontWeight: sel
                                            ? FontWeight.w600
                                            : FontWeight.w400)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    )),
                const SizedBox(height: 28),

                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAmenities = tempAmenities;
                      _minRating = tempRating;
                      _maxDistance = tempDistance;
                      _maxPrice = tempPrice;
                      _selectedDays = tempDays;
                    });
                    _applyFilters();
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDEFF6E),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        'Show ${_filteredSpaces.length} Spaces',
                        style: GoogleFonts.inter(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: 15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //BUILD

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Column(children: [

        //Header
        Container(
          padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 16),
          color: const Color(0xFF111111),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row and sorting
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Explore',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5)),
                      Text('Find your perfect workspace',
                          style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 13)),
                    ],
                  ),
                ),
                // Sort button
                _buildSortButton(),
              ]),
              const SizedBox(height: 16),

              // Search bar
              _buildSearchBar(),
            ],
          ),
        ),

        //Active filter pill
        if (_filtersActive)
          Container(
            color: const Color(0xFF111111),
            padding:
            const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Row(children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    if (_minRating > 0)
                      _activePill(
                          '${_minRating.toStringAsFixed(1)}+ ★'),
                    if (_maxDistance < 50)
                      _activePill(
                          '≤ ${_maxDistance.toInt()} km'),
                    if (_maxPrice < 5000)
                      _activePill(
                          '≤ LKR ${_maxPrice.toInt()}'),
                    ..._selectedDays
                        .map((d) => _activePill(d)),
                    ..._selectedAmenities
                        .map((a) => _activePill(a)),
                  ]),
                ),
              ),
              GestureDetector(
                onTap: _clearFilters,
                child: Text('Clear',
                    style: GoogleFonts.inter(
                        color: const Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ),

        //Results meta row
        Padding(
          padding:
          const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(children: [
            Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(
                  color: Color(0xFFDEFF6E),
                  shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              '${_filteredSpaces.length} space${_filteredSpaces.length == 1 ? '' : 's'} found',
              style: GoogleFonts.inter(
                  color: Colors.white38, fontSize: 12),
            ),
            const Spacer(),
            Text(
              _sortBy == 'distance'
                  ? 'Nearest first'
                  : _sortBy == 'rating'
                  ? 'Highest rated'
                  : 'Name A–Z',
              style: GoogleFonts.inter(
                  color: const Color(0xFFDEFF6E),
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ]),
        ),

        //Space list
        Expanded(
          child: _isLoading
              ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFFDEFF6E),
                  strokeWidth: 2))
              : _filteredSpaces.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
            onRefresh: _loadSpaces,
            color: const Color(0xFFDEFF6E),
            backgroundColor:
            const Color(0xFF1C1C1E),
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(
                  20, 0, 20, 100),
              itemCount: _filteredSpaces.length,
              itemBuilder: (_, i) =>
                  _buildSpaceCard(
                      _filteredSpaces[i]),
            ),
          ),
        ),
      ]),
    );
  }
//tier quick-book sheet

  Future<void> _showTierSheet(SpaceModel space) async {
    // Show sheet immediately with a loading state
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TierBookSheet(space: space),
    );
  }
  //Header widgets

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(children: [
        const SizedBox(width: 14),
        const Icon(Icons.search_rounded,
            color: Colors.white38, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Search spaces or areas...',
              hintStyle: GoogleFonts.inter(
                  color: Colors.white38, fontSize: 14),
            ),
          ),
        ),
        if (_searchCtrl.text.isNotEmpty)
          GestureDetector(
            onTap: () {
              _searchCtrl.clear();
              _applyFilters();
            },
            child: const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.close_rounded,
                  color: Colors.white38, size: 18),
            ),
          ),
        Container(
            width: 1,
            height: 22,
            color: Colors.white.withOpacity(0.08)),
        GestureDetector(
          onTap: _showFilterSheet,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _filtersActive
                  ? const Color(0xFFDEFF6E).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(14)),
            ),
            child: Icon(Icons.tune_rounded,
                color: _filtersActive
                    ? const Color(0xFFDEFF6E)
                    : Colors.white54,
                size: 18),
          ),
        ),
      ]),
    );
  }

  Widget _buildSortButton() {
    return GestureDetector(
      onTap: () => _showSortSheet(),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(children: [
          const Icon(Icons.swap_vert_rounded,
              color: Colors.white54, size: 16),
          const SizedBox(width: 6),
          Text(
            _sortBy == 'distance'
                ? 'Nearest'
                : _sortBy == 'rating'
                ? 'Rating'
                : 'Name',
            style: GoogleFonts.inter(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ]),
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 16),
            Text('Sort by',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _sortOption('distance',
                Icons.near_me_rounded, 'Nearest first'),
            _sortOption('rating',
                Icons.star_rounded, 'Highest rated'),
            _sortOption('name',
                Icons.sort_by_alpha_rounded, 'Name A–Z'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sortOption(
      String val, IconData icon, String label) {
    final selected = _sortBy == val;
    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = val);
        _applyFilters();
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFDEFF6E).withOpacity(0.08)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFFDEFF6E).withOpacity(0.4)
                : Colors.white.withOpacity(0.07),
          ),
        ),
        child: Row(children: [
          Icon(icon,
              color: selected
                  ? const Color(0xFFDEFF6E)
                  : Colors.white38,
              size: 18),
          const SizedBox(width: 12),
          Text(label,
              style: GoogleFonts.inter(
                  color: selected
                      ? const Color(0xFFDEFF6E)
                      : Colors.white70,
                  fontSize: 14,
                  fontWeight: selected
                      ? FontWeight.w700
                      : FontWeight.w400)),
          const Spacer(),
          if (selected)
            const Icon(Icons.check_rounded,
                color: Color(0xFFDEFF6E), size: 16),
        ]),
      ),
    );
  }

  Widget _activePill(String label) => Container(
    margin: const EdgeInsets.only(right: 6),
    padding: const EdgeInsets.symmetric(
        horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFDEFF6E).withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
          color:
          const Color(0xFFDEFF6E).withOpacity(0.3)),
    ),
    child: Text(label,
        style: GoogleFonts.inter(
            color: const Color(0xFFDEFF6E),
            fontSize: 11,
            fontWeight: FontWeight.w600)),
  );

  //Filter sheet helper widgets

  Widget _fsec(String title, IconData icon, Color color,
      {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border:
        Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 8),
            Text(title,
                style: GoogleFonts.inter(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildSlider(BuildContext ctx, double value,
      double min, double max, int div, Color color,
      ValueChanged<double> cb) {
    return SliderTheme(
      data: SliderTheme.of(ctx).copyWith(
        activeTrackColor: color,
        inactiveTrackColor: Colors.white.withOpacity(0.1),
        thumbColor: color,
        overlayColor: color.withOpacity(0.2),
      ),
      child: Slider(
          value: value,
          min: min,
          max: max,
          divisions: div,
          onChanged: cb),
    );
  }

  //Space card

  Widget _buildSpaceCard(SpaceModel space) {
    final distKm = _getDistance(space);
    final distStr = distKm < 1
        ? '${(distKm * 1000).toInt()}m away'
        : '${distKm.toStringAsFixed(1)}km away';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => SpaceDetailScreen(space: space)),
      ),
      child: Container(
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

            //hero image
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(fit: StackFit.expand, children: [
                // Image
                space.imageUrl != null &&
                    space.imageUrl!.isNotEmpty
                    ? Image.network(space.imageUrl!,
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
                        Color(0xAA1C1C1E),
                        Color(0xFF1C1C1E),
                      ],
                      stops: [0.0, 0.45, 0.78, 1.0],
                    ),
                  ),
                ),

                // Rating badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius:
                      BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white
                              .withOpacity(0.15)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFBBF24),
                          size: 12),
                      const SizedBox(width: 3),
                      Text(
                          space.averageRating
                              .toStringAsFixed(1),
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                      Text(' (${space.totalReviews})',
                          style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 10)),
                    ]),
                  ),
                ),

                // Name overlay
                Positioned(
                  bottom: 10,
                  left: 14,
                  right: 14,
                  child: Text(space.name,
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),

            //Info section
            Padding(
              padding:
              const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Address, distance
                  Row(children: [
                    const Icon(Icons.location_on_rounded,
                        color: Colors.white38, size: 13),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(space.address,
                          style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDEFF6E)
                            .withOpacity(0.1),
                        borderRadius:
                        BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFDEFF6E)
                                .withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.near_me_rounded,
                            color: Color(0xFFDEFF6E),
                            size: 10),
                        const SizedBox(width: 3),
                        Text(distStr,
                            style: GoogleFonts.inter(
                                color:
                                const Color(0xFFDEFF6E),
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ]),

                  const SizedBox(height: 8),

                  // Hours
                  Row(children: [
                    const Icon(Icons.access_time_rounded,
                        color: Colors.white24, size: 12),
                    const SizedBox(width: 5),
                    Text(
                        '${space.openingTime ?? ''} – ${space.closingTime ?? ''}',
                        style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 11)),
                  ]),

                  // Amenity chips
                  if (space.amenities.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: space.amenities
                            .take(5)
                            .map((a) => Container(
                          margin: const EdgeInsets
                              .only(right: 6),
                          padding: const EdgeInsets
                              .symmetric(
                              horizontal: 10,
                              vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withOpacity(0.06),
                            borderRadius:
                            BorderRadius.circular(
                                20),
                            border: Border.all(
                                color: Colors.white
                                    .withOpacity(
                                    0.08)),
                          ),
                          child: Text(a,
                              style: GoogleFonts.inter(
                                  color:
                                  Colors.white54,
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


                  Row(children: [
                    // View button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  SpaceDetailScreen(space: space)),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 13),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.visibility_outlined,
                                  color: Colors.white70, size: 15),
                              const SizedBox(width: 6),
                              Text('View',
                                  style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Book button
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () => _showTierSheet(space),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDEFF6E),
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: [
                              BoxShadow(
                                  color: const Color(0xFFDEFF6E)
                                      .withOpacity(0.25),
                                  blurRadius: 10,
                                  spreadRadius: 0),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Book',
                                  style: GoogleFonts.inter(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Shared helpers

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withOpacity(0.07)),
            ),
            child: const Icon(Icons.search_off_rounded,
                color: Colors.white24, size: 32),
          ),
          const SizedBox(height: 16),
          Text('No spaces found',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Try adjusting your filters',
              style: GoogleFonts.inter(
                  color: Colors.white38, fontSize: 13)),
          if (_filtersActive) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _clearFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDEFF6E),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text('Clear filters',
                    style: GoogleFonts.inter(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _imgFallback() => Container(
    color: Colors.white.withOpacity(0.04),
    child: const Center(
      child: Icon(Icons.business_outlined,
          color: Colors.white12, size: 40),
    ),
  );
}

// TIER QUICK-BOOK

class _TierBookSheet extends StatefulWidget {
  final SpaceModel space;
  const _TierBookSheet({required this.space});

  @override
  State<_TierBookSheet> createState() => _TierBookSheetState();
}

class _TierBookSheetState extends State<_TierBookSheet> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _tiers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTiers();
  }

  Future<void> _loadTiers() async {
    try {
      final res = await _supabase
          .from('tiers')
          .select()
          .eq('space_id', widget.space.id)
          .eq('is_active', true)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _tiers = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load tiers';
          _isLoading = false;
        });
      }
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2)
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [

          //Handle and header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Choose a Tier',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3)),
                      const SizedBox(height: 3),
                      Text(widget.space.name,
                          style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 13)),
                    ],
                  ),
                ),
                // Close button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.08)),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white38, size: 16),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Divider(color: Colors.white.withOpacity(0.07),
                  height: 1),
            ]),
          ),

          //Tier list
          Expanded(
            child: _isLoading
                ? const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFDEFF6E),
                    strokeWidth: 2))
                : _error != null
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.white24, size: 40),
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 14)),
                ],
              ),
            )
                : _tiers.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withOpacity(0.04),
                      borderRadius:
                      BorderRadius.circular(16),
                    ),
                    child: const Icon(
                        Icons.chair_outlined,
                        color: Colors.white24,
                        size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text('No tiers available',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight:
                          FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                      'Check back later or view the space',
                      style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 13)),
                ],
              ),
            )
                : CustomScrollView(
              controller: ctrl,
              slivers: [
                //Bookable tiers
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 12, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (_, i) {
                        final bookable = _tiers
                            .where((t) =>
                        t['booking_type'] !=
                            'contract')
                            .toList();
                        if (bookable.isEmpty && i == 0) {
                          return Padding(
                            padding:
                            const EdgeInsets.only(
                                bottom: 12),
                            child: Text(
                              'No bookable tiers available',
                              style: GoogleFonts.inter(
                                  color: Colors.white38,
                                  fontSize: 13),
                            ),
                          );
                        }
                        if (i >= bookable.length)
                          return null;
                        return _buildTierCard(
                            bookable[i]);
                      },
                      childCount: () {
                        final bookable = _tiers
                            .where((t) =>
                        t['booking_type'] !=
                            'contract')
                            .toList();
                        return bookable.isEmpty
                            ? 1
                            : bookable.length;
                      }(),
                    ),
                  ),
                ),

                //Contract tiers
                if (_tiers.any((t) =>
                t['booking_type'] == 'contract')) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          20, 20, 20, 10),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Divider(
                              color: Colors.white
                                  .withOpacity(0.07),
                              height: 1),
                          const SizedBox(height: 16),
                          Text(
                            'Private & Contract Spaces',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight:
                                FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Submit an enquiry — team will reach out',
                            style: GoogleFonts.inter(
                                color: Colors.white38,
                                fontSize: 11),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 160,
                            child: ListView.builder(
                              scrollDirection:
                              Axis.horizontal,
                              itemCount: _tiers
                                  .where((t) =>
                              t['booking_type'] ==
                                  'contract')
                                  .length,
                              itemBuilder: (_, i) {
                                final contracts = _tiers
                                    .where((t) =>
                                t['booking_type'] ==
                                    'contract')
                                    .toList();
                                final t = contracts[i];
                                return _buildContractMiniCard(
                                    t, context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                SliverToBoxAdapter(
                  child: SizedBox(
                      height: bottomPad + 16),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTierCard(Map<String, dynamic> tier) {
    final name = tier['name'] as String? ?? 'Tier';
    final desc = tier['description'] as String? ?? '';
    final bookingType =
        tier['booking_type'] as String? ?? 'hourly';
    final priceHr =
    (tier['price_per_hour'] as num?)?.toDouble();
    final priceDay =
    (tier['price_per_day'] as num?)?.toDouble();
    final priceMonth =
    (tier['price_per_month'] as num?)?.toDouble();
    final priceYear =
    (tier['price_per_year'] as num?)?.toDouble();
    final minCommit =
        tier['min_commitment'] as int? ?? 1;
    final available =
        tier['available_seats'] as int? ?? 0;
    final total = tier['total_capacity'] as int? ?? 0;
    final imageUrl = tier['image_url'] as String?;
    final pct = total > 0 ? available / total : 0.0;
    final isContract = bookingType == 'contract';
    final typeColor = _typeColor(bookingType);

    //Seat color
    Color seatColor;
    if (pct > 0.5) {
      seatColor = const Color(0xFF34D399);
    } else if (pct > 0.2) {
      seatColor = const Color(0xFFF59E0B);
    } else {
      seatColor = const Color(0xFFEF4444);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(children: [

        //image + info
        SizedBox(
          height: 110,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18)),
                child: SizedBox(
                  width: 100,
                  child: imageUrl != null &&
                      imageUrl.isNotEmpty
                      ? Image.network(imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _tierImgFallback())
                      : _tierImgFallback(),
                ),
              ),

              // Right info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      12, 12, 12, 10),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(desc,
                            style: GoogleFonts.inter(
                                color: Colors.white38,
                                fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                      const Spacer(),
                      // Info chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          // Booking type badge
                          _infoChip(
                            Icons.label_outline,
                            _typeLabel(bookingType),
                            typeColor,
                          ),
                          // Seats
                          if (!isContract)
                            _infoChip(
                              Icons.chair_outlined,
                              '$available/$total slots',
                              seatColor,
                            ),
                          // Commitment for subscriptions
                          if (bookingType == 'monthly' ||
                              bookingType == 'annually')
                            _infoChip(
                              Icons.calendar_month,
                              'Min ${minCommit}mo',
                              typeColor,
                            ),
                          // Min hours for session types
                          if (tier['booking_type'] == 'hourly' ||
                              tier['booking_type'] == 'daily') ...[
                            _infoChip(
                              Icons.timer_outlined,
                              'Min ${tier['min_duration'] ?? 1}'
                                  '${tier['booking_type'] == 'daily' ? 'd' : 'h'}',
                              const Color(0xFFDEFF6E),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Divider
        Divider(
            color: Colors.white.withOpacity(0.07),
            height: 1),

        // Pricing, Book
        Padding(
          padding: const EdgeInsets.fromLTRB(
              12, 10, 12, 12),
          child: Row(children: [
            // Pricing display
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  if (bookingType == 'hourly' &&
                      priceHr != null)
                    Row(children: [
                      Text(
                          'LKR ${priceHr.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3)),
                      Text(' / hr',
                          style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 11)),
                    ]),
                  if (bookingType == 'daily' &&
                      priceDay != null)
                    Row(children: [
                      Text(
                          'LKR ${priceDay.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3)),
                      Text(' / day',
                          style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 11)),
                    ]),
                  if (bookingType == 'monthly' &&
                      priceMonth != null)
                    Row(children: [
                      Text(
                          'LKR ${priceMonth.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                              color: typeColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3)),
                      Text(' / mo',
                          style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 11)),
                    ]),
                  if (bookingType == 'annually' &&
                      priceYear != null)
                    Row(children: [
                      Text(
                          'LKR ${priceYear.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                              color: typeColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3)),
                      Text(' / yr',
                          style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 11)),
                    ]),
                  if (isContract)
                    Text('Pricing on enquiry',
                        style: GoogleFonts.inter(
                            color: typeColor,
                            fontSize: 13,
                            fontWeight:
                            FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // CTA button
            GestureDetector(
              onTap: (!isContract && available <= 0)
                  ? null
                  : () {
                Navigator.pop(context);
                _openTierFlow(
                    context, tier, bookingType);
              },
              child: AnimatedContainer(
                duration:
                const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 11),
                decoration: BoxDecoration(
                  color: (!isContract && available <= 0)
                      ? Colors.white.withOpacity(0.06)
                      : isContract
                      ? typeColor.withOpacity(0.15)
                      : const Color(0xFFDEFF6E),
                  borderRadius:
                  BorderRadius.circular(12),
                  border: isContract
                      ? Border.all(
                      color:
                      typeColor.withOpacity(0.5))
                      : null,
                  boxShadow:
                  (!isContract && available > 0)
                      ? [
                    BoxShadow(
                        color: const Color(
                            0xFFDEFF6E)
                            .withOpacity(0.25),
                        blurRadius: 8)
                  ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      (!isContract && available <= 0)
                          ? Icons.block_rounded
                          : isContract
                          ? Icons.mail_outline_rounded
                          : (bookingType == 'monthly' ||
                          bookingType ==
                              'annually')
                          ? Icons
                          .card_membership_rounded
                          : Icons.bolt_rounded,
                      color: (!isContract &&
                          available <= 0)
                          ? Colors.white24
                          : isContract
                          ? typeColor
                          : Colors.black,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      (!isContract && available <= 0)
                          ? 'Full'
                          : isContract
                          ? 'Enquire'
                          : (bookingType ==
                          'monthly' ||
                          bookingType ==
                              'annually')
                          ? 'Subscribe'
                          : 'Book',
                      style: GoogleFonts.inter(
                          color: (!isContract &&
                              available <= 0)
                              ? Colors.white24
                              : isContract
                              ? typeColor
                              : Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _tierImgFallback() => Container(
    color: Colors.white.withOpacity(0.04),
    child: const Center(
      child: Icon(Icons.chair_outlined,
          color: Colors.white12, size: 24),
    ),
  );
  void _openTierFlow(BuildContext context,
      Map<String, dynamic> tier, String bookingType) {
    final space = widget.space;
    Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Convert raw map to TierModel for the sheets
      final tierModel = TierModel.fromJson(tier);
      switch (bookingType) {
        case 'monthly':
        case 'annually':
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => SubscriptionSheet(
                space: space, tier: tierModel),
          );
          break;
        case 'contract':
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => EnquirySheet(
                space: space, tier: tierModel),
          );
          break;
        default:
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => SpaceDetailScreen(
              space: space,
              initialTierId: tier['id'] as String?,
            ),
          );
      }
    });
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'daily':
        return const Color(0xFF60A5FA);
      case 'monthly':
        return const Color(0xFFA78BFA);
      case 'annually':
        return const Color(0xFFFBBF24);
      case 'contract':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFFDEFF6E);
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'daily': return 'Daily';
      case 'monthly': return 'Monthly';
      case 'annually': return 'Annual';
      case 'contract': return 'Contract';
      default: return 'Hourly';
    }
  }
  Widget _buildContractMiniCard(
      Map<String, dynamic> tier, BuildContext context) {
    final name = tier['name'] as String? ?? '';
    final desc = tier['description'] as String? ?? '';
    final imageUrl = tier['image_url'] as String?;

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color:
            const Color(0xFFF97316).withOpacity(0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        // Image
        SizedBox(
          height: 72,
          child: Stack(fit: StackFit.expand, children: [
            imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(
                      color: const Color(0xFFF97316)
                          .withOpacity(0.08),
                      child: const Center(
                        child: Icon(
                            Icons
                                .business_center_outlined,
                            color: Color(0xFFF97316),
                            size: 22),
                      ),
                    ))
                : Container(
              color: const Color(0xFFF97316)
                  .withOpacity(0.08),
              child: const Center(
                child: Icon(
                    Icons.business_center_outlined,
                    color: Color(0xFFF97316),
                    size: 22),
              ),
            ),
            Container(color: Colors.black.withOpacity(0.3)),
          ]),
        ),

        // Info, button
        Expanded(
          child: Padding(
            padding:
            const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(desc,
                    style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 10,
                        height: 1.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const Spacer(),
                GestureDetector(
                  onTap: () => _openTierFlow(
                      context, tier, 'contract'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius:
                      BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFFDEFF6E)
                              .withOpacity(0.35)),
                    ),
                    child: Center(
                      child: Text('Enquire',
                          style: GoogleFonts.inter(
                              color:
                              const Color(0xFFDEFF6E),
                              fontSize: 11,
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
    );
  }
}