import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/space_model.dart';
import '../../services/space_service.dart';
import 'space_detail_screen.dart';
import 'directions_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final PageController _carouselCtrl =
  PageController(viewportFraction: 0.88);
  final SpaceService _spaceService = SpaceService();
  final TextEditingController _searchCtrl = TextEditingController();

  LatLng _currentLocation = const LatLng(6.9271, 79.8612);
  List<SpaceModel> _spaces = [];
  List<SpaceModel> _filteredSpaces = [];
  List<SpaceModel> _sortedByDistance = [];
  SpaceModel? _selectedSpace;
  bool _isLoading = true;
  int _carouselIndex = 0;

  //Filter state
  List<String> _selectedAmenities = [];
  double _minRating = 0;
  double _maxDistance = 50;
  double _maxPrice = 5000;
  List<String> _selectedDays = [];
  bool _filtersActive = false;

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
    _getCurrentLocation();
    _loadSpaces();
    _searchCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _carouselCtrl.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission =
      await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() => _currentLocation =
              LatLng(position.latitude, position.longitude));
          _mapController.move(_currentLocation, 14.0);
          _rebuildSorted();
        }
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _loadSpaces() async {
    try {
      final spaces = await _spaceService.getActiveSpaces();
      if (mounted) {
        setState(() {
          _spaces = spaces;
          _filteredSpaces = spaces;
          _isLoading = false;
        });
        _rebuildSorted();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _rebuildSorted() {
    final sorted = List<SpaceModel>.from(_filteredSpaces);
    sorted.sort((a, b) {
      final dA = const Distance().as(LengthUnit.Kilometer,
          _currentLocation, LatLng(a.latitude, a.longitude));
      final dB = const Distance().as(LengthUnit.Kilometer,
          _currentLocation, LatLng(b.latitude, b.longitude));
      return dA.compareTo(dB);
    });
    setState(() {
      _sortedByDistance = sorted;
      if (sorted.isNotEmpty && _selectedSpace == null) {
        _selectedSpace = sorted[0];
      }
    });
  }

  void _applyFilters() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filteredSpaces = _spaces.where((space) {
        final matchesSearch = query.isEmpty ||
            space.name.toLowerCase().contains(query) ||
            space.address.toLowerCase().contains(query);
        final matchesRating = space.averageRating >= _minRating;
        final matchesAmenities = _selectedAmenities.isEmpty ||
            _selectedAmenities
                .every((a) => space.amenities.contains(a));
        final distKm = const Distance().as(LengthUnit.Kilometer,
            _currentLocation,
            LatLng(space.latitude, space.longitude));
        final matchesDist = distKm <= _maxDistance;
        final matchesDays = _selectedDays.isEmpty ||
            _selectedDays.any((d) => space.operatingDays.contains(d));
        return matchesSearch && matchesRating &&
            matchesAmenities && matchesDist && matchesDays;
      }).toList();

      _filtersActive = _selectedAmenities.isNotEmpty ||
          _minRating > 0 || _maxDistance < 50 ||
          _maxPrice < 5000 || _selectedDays.isNotEmpty;
    });
    _rebuildSorted();
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

  double _distanceTo(SpaceModel s) => const Distance().as(
      LengthUnit.Kilometer, _currentLocation,
      LatLng(s.latitude, s.longitude));

  String _distStr(SpaceModel s) {
    final d = _distanceTo(s);
    return d < 1
        ? '${(d * 1000).toInt()}m away'
        : '${d.toStringAsFixed(1)}km away';
  }

  void _onPinTapped(SpaceModel space) {
    final idx = _sortedByDistance.indexWhere((s) => s.id == space.id);
    setState(() {
      _selectedSpace = space;
      if (idx >= 0) _carouselIndex = idx;
    });
    if (idx >= 0) {
      _carouselCtrl.animateToPage(idx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
    }
    _mapController.move(
        LatLng(space.latitude - 0.003, space.longitude), 15.2);
  }

  void _onCarouselChanged(int index) {
    if (index >= _sortedByDistance.length) return;
    final space = _sortedByDistance[index];
    setState(() {
      _carouselIndex = index;
      _selectedSpace = space;
    });
    _mapController.move(
        LatLng(space.latitude - 0.003, space.longitude), 15.2);
  }

  void _openDetail(SpaceModel space) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SpaceDetailSheet(
          space: space, distStr: _distStr(space)),
    );
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
                      _slider(ctx, tempRating, 0, 5, 10,
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
                      _slider(ctx, tempDistance, 1, 50, 49,
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
                          Text(
                              'LKR ${tempPrice.toInt()}/hr',
                              style: GoogleFonts.inter(
                                  color: const Color(0xFFDEFF6E),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      _slider(ctx, tempPrice, 100, 5000, 49,
                          const Color(0xFFDEFF6E),
                              (v) => setS(() => tempPrice = v)),
                    ])),
                const SizedBox(height: 12),

                _fsec('Operating Days',
                    Icons.calendar_today,
                    const Color(0xFFF59E0B),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allDays.map((d) {
                        final sel = tempDays.contains(d);
                        return GestureDetector(
                          onTap: () => setS(() => sel
                              ? tempDays.remove(d)
                              : tempDays.add(d)),
                          child: AnimatedContainer(
                            duration:
                            const Duration(milliseconds: 180),
                            padding:
                            const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7),
                            decoration: BoxDecoration(
                              color: sel
                                  ? const Color(0xFFF59E0B)
                                  : Colors.white
                                  .withOpacity(0.06),
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
                      spacing: 8,
                      runSpacing: 8,
                      children: _allAmenities.map((a) {
                        final sel = tempAmenities.contains(a);
                        return GestureDetector(
                          onTap: () => setS(() => sel
                              ? tempAmenities.remove(a)
                              : tempAmenities.add(a)),
                          child: AnimatedContainer(
                            duration:
                            const Duration(milliseconds: 180),
                            padding:
                            const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6),
                            decoration: BoxDecoration(
                              color: sel
                                  ? const Color(0xFFDEFF6E)
                                  .withOpacity(0.12)
                                  : Colors.white
                                  .withOpacity(0.05),
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
                                            ? const Color(
                                            0xFFDEFF6E)
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

  Widget _fsec(String title, IconData icon, Color color,
      {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
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

  Widget _slider(BuildContext ctx, double value, double min,
      double max, int div, Color color, ValueChanged<double> cb) {
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

  //BUILD

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      extendBodyBehindAppBar: true,
      body: Stack(children: [

        //Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation,
            initialZoom: 14.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all &
              ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            // CartoDB light tiles
            TileLayer(
              urlTemplate:
              'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.hotspot',
            ),
            // User location dot
            MarkerLayer(markers: [
              Marker(
                point: _currentLocation,
                width: 56,
                height: 56,
                child: const _CurrentLocationPin(),
              ),
            ]),
            MarkerLayer(
              markers: _filteredSpaces.map((space) {
                final isSel =
                    _selectedSpace?.id == space.id;
                return Marker(
                  point: LatLng(
                      space.latitude, space.longitude),
                  width: 64,
                  height: 64,
                  child: GestureDetector(
                    onTap: () => _onPinTapped(space),
                    child: _SpacePin(
                      imageUrl: space.imageUrl,
                      isSelected: isSel,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        //Top search bar
        Positioned(
          top: topPad + 12,
          left: 16,
          right: 16,
          child: _buildSearchBar(),
        ),

        //Active filter chip
        if (_filtersActive)
          Positioned(
            top: topPad + 76,
            left: 16,
            child: GestureDetector(
              onTap: _clearFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDEFF6E),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFDEFF6E)
                            .withOpacity(0.35),
                        blurRadius: 8),
                  ],
                ),
                child: Row(children: [
                  const Icon(Icons.filter_list,
                      color: Colors.black, size: 13),
                  const SizedBox(width: 4),
                  Text('Filters active · Clear',
                      style: GoogleFonts.inter(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),

        //My location
        Positioned(
          bottom: bottomPad + 200,
          right: 16,
          child: GestureDetector(
            onTap: _getCurrentLocation,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10),
                ],
              ),
              child: const Icon(
                  Icons.my_location_rounded,
                  color: Color(0xFFDEFF6E),
                  size: 18),
            ),
          ),
        ),

        //Bottom carousel
        if (!_isLoading && _sortedByDistance.isNotEmpty)
          Positioned(
            bottom: bottomPad + 16,
            left: 0,
            right: 0,
            height: 158,
            child: PageView.builder(
              controller: _carouselCtrl,
              onPageChanged: _onCarouselChanged,
              itemCount: _sortedByDistance.length,
              itemBuilder: (_, i) {
                final space = _sortedByDistance[i];
                final isSel = _selectedSpace?.id == space.id;
                return Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6),
                  child:
                  _buildCarouselCard(space, isSel),
                );
              },
            ),
          ),

        //Empty state
        if (!_isLoading && _filteredSpaces.isEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white.withOpacity(0.08)),
              ),
              child: Text('No spaces match your filters',
                  style: GoogleFonts.inter(
                      color: Colors.white54, fontSize: 14)),
            ),
          ),

        //Loading
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(
                color: Color(0xFFDEFF6E),
                strokeWidth: 2),
          ),
      ]),
    );
  }

  //Search bar

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E).withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        border:
        Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 16),
        ],
      ),
      child: Row(children: [
        const SizedBox(width: 16),
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
        Container(
            width: 1,
            height: 22,
            color: Colors.white.withOpacity(0.1)),
        GestureDetector(
          onTap: _showFilterSheet,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _filtersActive
                  ? const Color(0xFFDEFF6E).withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(16)),
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

  //Carousel card

  Widget _buildCarouselCard(SpaceModel space, bool isSel) {
    return GestureDetector(
      onTap: () => _openDetail(space),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSel
                ? const Color(0xFFDEFF6E).withOpacity(0.55)
                : Colors.white.withOpacity(0.06),
            width: isSel ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSel
                  ? const Color(0xFFDEFF6E).withOpacity(0.12)
                  : Colors.black.withOpacity(0.4),
              blurRadius: isSel ? 22 : 10,
              spreadRadius: isSel ? 1 : 0,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(fit: StackFit.expand, children: [

          // Full bleed image
          space.imageUrl != null && space.imageUrl!.isNotEmpty
              ? Image.network(space.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _imgFallback())
              : _imgFallback(),

          // Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x22000000), // very light at top
                  Color(0x00000000), // transparent mid
                  Color(0xBB111111), // heavy near bottom
                  Color(0xFF111111), // full #111 at bottom
                ],
                stops: [0.0, 0.2, 0.65, 1.0],
              ),
            ),
          ),

          // ── Info overlaid on gradient ─────────
          Positioned(
            bottom: 12,
            left: 14,
            right: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(space.name,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFBBF24), size: 11),
                        const SizedBox(width: 3),
                        Text(space.averageRating.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                                color: Colors.white60,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                        Text(' (${space.totalReviews})',
                            style: GoogleFonts.inter(
                                color: Colors.white30,
                                fontSize: 10)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Distance badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEFF6E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    const Icon(Icons.near_me_rounded,
                        color: Colors.black, size: 10),
                    const SizedBox(width: 4),
                    Text(_distStr(space),
                        style: GoogleFonts.inter(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ]),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
  Widget _imgFallback() => Container(
    color: Colors.white.withOpacity(0.05),
    child: const Center(
      child: Icon(Icons.business_outlined,
          color: Colors.white24, size: 32),
    ),
  );
}
// ═══════════════════════════════════════════════
// PULSING PIN WIDGET
// ═══════════════════════════════════════════════

class _SpacePin extends StatefulWidget {
  final String? imageUrl;
  final bool isSelected;

  const _SpacePin({
    required this.imageUrl,
    required this.isSelected,
  });

  @override
  State<_SpacePin> createState() =>
      _SpacePinState();
}

class _SpacePinState extends State<_SpacePin>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _pulse = CurvedAnimation(
        parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [

        // ── Pulse ring (selected only) ─────────
        if (widget.isSelected)
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: 46 + 22 * _pulse.value,
              height: 46 + 22 * _pulse.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFDEFF6E)
                      .withOpacity(
                      (1 - _pulse.value) * 0.55),
                  width: 1.5,
                ),
              ),
            ),
          ),

        // ── Outer glow ring (selected only) ───
        if (widget.isSelected)
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDEFF6E)
                      .withOpacity(0.35),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),

        // ── Image circle ───────────────────────
        Container(
          width: widget.isSelected ? 50 : 44,
          height: widget.isSelected ? 50 : 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isSelected
                  ? const Color(0xFFDEFF6E)
                  : Colors.white.withOpacity(0.55),
              width: widget.isSelected ? 2.5 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? const Color(0xFFDEFF6E)
                    .withOpacity(0.4)
                    : Colors.black.withOpacity(0.35),
                blurRadius:
                widget.isSelected ? 14 : 6,
                spreadRadius:
                widget.isSelected ? 1 : 0,
              ),
            ],
          ),
          child: ClipOval(
            child: widget.imageUrl != null &&
                widget.imageUrl!.isNotEmpty
                ? Image.network(
              widget.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) =>
                  _fallback(),
            )
                : _fallback(),
          ),
        ),
      ],
    );
  }

  Widget _fallback() => Container(
    color: const Color(0xFF1C1C1E),
    child: const Icon(
      Icons.business_outlined,
      color: Color(0xFFDEFF6E),
      size: 20,
    ),
  );
}

// ═══════════════════════════════════════════════
// SPACE DETAIL BOTTOM SHEET
// ═══════════════════════════════════════════════

class _SpaceDetailSheet extends StatelessWidget {
  final SpaceModel space;
  final String distStr;

  const _SpaceDetailSheet({
    required this.space,
    required this.distStr,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // ── Hero image (full bleed top half) ──
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24)),
            child: SizedBox(
              height: 210,
              width: double.infinity,
              child: Stack(fit: StackFit.expand, children: [

                // Image
                space.imageUrl != null &&
                    space.imageUrl!.isNotEmpty
                    ? Image.network(space.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _heroFallback())
                    : _heroFallback(),

                // Gradient overlay
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),
                        Color(0x44000000),
                        Color(0xCC1C1C1E), // heavy at 70%
                        Color(0xFF1C1C1E),
                      ],
                      stops: [0.0, 0.25, 0.7, 1.0],
                    ),
                  ),
                ),

                // Drag handle at top
                Positioned(
                  top: 10, left: 0, right: 0,
                  child: Center(
                    child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                          color: Colors.white
                              .withOpacity(0.35),
                          borderRadius:
                          BorderRadius.circular(2)),
                    ),
                  ),
                ),

                // Name + rating overlaid on image
                Positioned(
                  bottom: 14,
                  left: 18,
                  right: 18,
                  child: Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            // Rating
                            Row(children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFBBF24),
                                  size: 13),
                              const SizedBox(width: 3),
                              Text(
                                  space.averageRating
                                      .toStringAsFixed(1),
                                  style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight:
                                      FontWeight.w600)),
                              Text(
                                  ' (${space.totalReviews})',
                                  style: GoogleFonts.inter(
                                      color: Colors.white38,
                                      fontSize: 11)),
                            ]),
                            const SizedBox(height: 3),
                            Text(space.name,
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight:
                                    FontWeight.w800,
                                    letterSpacing: -0.4),
                                maxLines: 1,
                                overflow:
                                TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      // Distance badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDEFF6E),
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                        child: Row(children: [
                          const Icon(Icons.near_me_rounded,
                              color: Colors.black, size: 11),
                          const SizedBox(width: 4),
                          Text(distStr,
                              style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight:
                                  FontWeight.w800)),
                        ]),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),

          // ── Info section ───────────────────────
          Padding(
            padding:
            const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Column(children: [

              // Address + hours row
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
                const Icon(Icons.access_time_rounded,
                    color: Colors.white38, size: 13),
                const SizedBox(width: 4),
                Text(
                    '${space.openingTime} – ${space.closingTime}',
                    style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 12)),
              ]),

              // Amenities
              if (space.amenities.isNotEmpty) ...[
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: space.amenities
                        .take(7)
                        .map((a) => Container(
                      margin: const EdgeInsets.only(
                          right: 6),
                      padding:
                      const EdgeInsets.symmetric(
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
                                .withOpacity(0.08)),
                      ),
                      child: Text(a,
                          style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 10,
                              fontWeight:
                              FontWeight.w500)),
                    ))
                        .toList(),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ── 3 Action buttons ─────────────────
              Row(children: [

                // Directions
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DirectionsScreen(
                              destinationLat:
                              space.latitude,
                              destinationLng:
                              space.longitude,
                              spaceName: space.name,
                              spaceAddress: space.address,
                            ),
                          ));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      decoration: BoxDecoration(
                        color:
                        Colors.white.withOpacity(0.07),
                        borderRadius:
                        BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white
                                .withOpacity(0.1)),
                      ),
                      child: Column(children: [
                        const Icon(
                            Icons.directions_rounded,
                            color: Colors.white70,
                            size: 20),
                        const SizedBox(height: 5),
                        Text('Directions',
                            style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight:
                                FontWeight.w600)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Book Space — lime CTA
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SpaceDetailScreen(
                                    space: space),
                          ));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDEFF6E),
                        borderRadius:
                        BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFFDEFF6E)
                                  .withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 1),
                        ],
                      ),
                      child: Column(children: [
                        const Icon(Icons.bolt_rounded,
                            color: Colors.black, size: 20),
                        const SizedBox(height: 5),
                        Text('Book Space',
                            style: GoogleFonts.inter(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight:
                                FontWeight.w800)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // View Space
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SpaceDetailScreen(
                                    space: space),
                          ));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      decoration: BoxDecoration(
                        color:
                        Colors.white.withOpacity(0.07),
                        borderRadius:
                        BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white
                                .withOpacity(0.1)),
                      ),
                      child: Column(children: [
                        const Icon(
                            Icons.visibility_outlined,
                            color: Colors.white70,
                            size: 20),
                        const SizedBox(height: 5),
                        Text('View Space',
                            style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight:
                                FontWeight.w600)),
                      ]),
                    ),
                  ),
                ),
              ]),

              SizedBox(height: bottomPad + 18),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _heroFallback() => Container(
    color: const Color(0xFF1C1C1E),
    child: const Center(
      child: Icon(Icons.business_outlined,
          color: Colors.white12, size: 56),
    ),
  );
}
class _CurrentLocationPin extends StatefulWidget {
  const _CurrentLocationPin();

  @override
  State<_CurrentLocationPin> createState() =>
      _CurrentLocationPinState();
}

class _CurrentLocationPinState
    extends State<_CurrentLocationPin>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _pulse = CurvedAnimation(
        parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [

        // ── Outer pulse ring ──────────────────
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Container(
            width: 18 + 34 * _pulse.value,
            height: 18 + 34 * _pulse.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFDEFF6E)
                    .withOpacity(
                    (1 - _pulse.value) * 0.4),
                width: 1.5,
              ),
            ),
          ),
        ),

        // ── Middle pulse ring ─────────────────
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Container(
            width: 18 + 18 * _pulse.value,
            height: 18 + 18 * _pulse.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFDEFF6E)
                  .withOpacity(
                  (1 - _pulse.value) * 0.1),
            ),
          ),
        ),

        //Core dot
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFDEFF6E),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDEFF6E)
                    .withOpacity(0.6),
                blurRadius: 12,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: const Color(0xFFDEFF6E)
                    .withOpacity(0.2),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}