import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:ui' as ui;

class DirectionsScreen extends StatefulWidget {
  final double destinationLat;
  final double destinationLng;
  final String spaceName;
  final String spaceAddress;

  const DirectionsScreen({
    super.key,
    required this.destinationLat,
    required this.destinationLng,
    required this.spaceName,
    required this.spaceAddress,
  });

  @override
  State<DirectionsScreen> createState() =>
      _DirectionsScreenState();
}

class _DirectionsScreenState
    extends State<DirectionsScreen> {
  final MapController _mapController = MapController();

  LatLng? _userLocation;
  List<LatLng> _routePoints = [];
  List<Map<String, dynamic>> _steps = [];

  bool _isLoading = true;
  bool _hasError = false;
  bool _showStepsList = false;

  String _distance = '';
  String _duration = '';
  String _statusMessage = 'Getting your location...';
  String _mode = 'driving';

  // BACKEND LOGIC

  @override
  void initState() {
    super.initState();
    _initDirections();
  }

  Future<void> _initDirections() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _routePoints = [];
      _steps = [];
      _statusMessage = 'Getting your location...';
    });
    await _getUserLocation();
    if (_userLocation != null) await _getRoute();
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission =
      await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final position =
      await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation =
            LatLng(position.latitude, position.longitude);
        _statusMessage = 'Finding route...';
      });
    } catch (_) {
      setState(() {
        _userLocation = const LatLng(6.9271, 79.8612);
        _statusMessage = 'Finding route...';
      });
    }
  }

  Future<void> _getRoute() async {
    try {
      setState(() => _statusMessage = 'Finding route...');

      final url =
          'https://router.project-osrm.org/route/v1/$_mode/'
          '${_userLocation!.longitude},${_userLocation!.latitude};'
          '${widget.destinationLng},${widget.destinationLat}'
          '?overview=full&geometries=geojson&steps=true';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final route = data['routes'][0];

        final coords =
        route['geometry']['coordinates'] as List;
        final points = coords
            .map((c) => LatLng(
          (c[1] as num).toDouble(),
          (c[0] as num).toDouble(),
        ))
            .toList();

        final distanceM = route['distance'] as num;

        final durationS = route['duration'] as num;
        final durationMin = (durationS / 60).ceil();

        String formattedDuration;
        if (durationMin >= 60) {
          final hrs = durationMin ~/ 60;
          final mins = durationMin % 60;
          formattedDuration =
          mins > 0 ? '${hrs}h ${mins}m' : '${hrs}h';
        } else {
          formattedDuration = '${durationMin} min';
        }

        final List<Map<String, dynamic>> steps = [];
        for (final leg in route['legs'] as List) {
          for (final step in leg['steps'] as List) {
            final maneuver =
            step['maneuver'] as Map<String, dynamic>;
            final instruction =
            _buildInstruction(maneuver, step);
            final dist =
            (step['distance'] as num).toDouble();
            final type =
                maneuver['type'] as String? ?? '';
            final modifier =
                maneuver['modifier'] as String? ?? '';
            steps.add({
              'instruction': instruction,
              'distance': dist,
              'type': type,
              'modifier': modifier,
            });
          }
        }

        setState(() {
          _routePoints = points;
          _distance =
          '${(distanceM / 1000).toStringAsFixed(1)} km';
          _duration = formattedDuration;
          _steps = steps;
          _isLoading = false;
          _statusMessage = '';
        });
        _fitMapToRoute();
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _statusMessage = 'Route not found';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _statusMessage = 'Could not load route';
      });
      debugPrint('Route error: $e');
    }
  }

  String _buildInstruction(
      Map<String, dynamic> maneuver,
      Map<String, dynamic> step) {
    final type = maneuver['type'] as String? ?? '';
    final modifier =
        maneuver['modifier'] as String? ?? '';
    final name = step['name'] as String? ?? '';
    final road = name.isNotEmpty ? ' onto $name' : '';

    switch (type) {
      case 'depart':
        return 'Head ${modifier.isNotEmpty ? modifier : 'forward'}$road';
      case 'arrive':
        return 'Arrive at ${widget.spaceName}';
      case 'turn':
        return 'Turn ${modifier.isNotEmpty ? modifier : 'right'}$road';
      case 'new name':
        return 'Continue$road';
      case 'merge':
        return 'Merge $modifier$road';
      case 'on ramp':
        return 'Take the ramp $modifier$road';
      case 'off ramp':
        return 'Take the exit $modifier$road';
      case 'fork':
        return 'Keep $modifier at the fork$road';
      case 'end of road':
        return 'Turn $modifier at the end of road$road';
      case 'roundabout':
      case 'rotary':
        final exit = maneuver['exit'] as int? ?? 1;
        return 'Take exit $exit at the roundabout$road';
      case 'continue':
        return 'Continue $modifier$road';
      default:
        return 'Continue$road';
    }
  }

  void _fitMapToRoute() {
    if (_routePoints.isEmpty || _userLocation == null)
      return;
    final destination = LatLng(
        widget.destinationLat, widget.destinationLng);
    final bounds = LatLngBounds.fromPoints(
        [_userLocation!, destination]);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(
            40, 120, 40, 300),
      ),
    );
  }

  String _formatStepDist(double meters) {
    if (meters >= 1000)
      return '${(meters / 1000).toStringAsFixed(1)} km';
    return '${meters.toInt()} m';
  }

  //BUILD

  @override
  Widget build(BuildContext context) {
    if (_showStepsList) return _buildStepsList();
    return _buildMapView();
  }

  // Map view

  Widget _buildMapView() {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final destination = LatLng(
        widget.destinationLat, widget.destinationLng);

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Stack(children: [

        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: destination,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all &
              ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
              'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.hotspot',
            ),
            if (_routePoints.isNotEmpty)
              PolylineLayer(polylines: [
                Polyline(
                  points: _routePoints,
                  strokeWidth: 10,
                  color: const Color(0xFF1A1C14)
                      .withOpacity(0.25),
                ),
                Polyline(
                  points: _routePoints,
                  strokeWidth: 5,
                  color: const Color(0xFFDEFF6E),
                ),
              ]),
            MarkerLayer(markers: [
              if (_userLocation != null)
                Marker(
                  point: _userLocation!,
                  width: 36, height: 36,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFDEFF6E),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF1A1C14),
                          width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDEFF6E)
                              .withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              Marker(
                point: destination,
                width: 140, height: 38,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1C14),
                    borderRadius:
                    BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFDEFF6E),
                        width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDEFF6E)
                            .withOpacity(0.2),
                        blurRadius: 10,
                      ),
                    ],
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
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          widget.spaceName,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight:
                              FontWeight.w700),
                          overflow:
                          TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ],
        ),

        Positioned(
          top: topPad + 12, left: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: _floatingBtn(
              child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ),

        // Mode toggle
        Positioned(
          top: topPad + 12, right: 16,
          child: _buildModeToggle(),
        ),

        // Loading
        if (_isLoading)
          Positioned(
            top: topPad + 12, left: 0, right: 0,
            child: Center(
                child: _buildLoadingPill()),
          ),

        // Recenter
        if (!_isLoading && _routePoints.isNotEmpty)
          Positioned(
            bottom: bottomPad + 240,
            right: 16,
            child: GestureDetector(
              onTap: _fitMapToRoute,
              child: _floatingBtn(
                child: SizedBox(
                  width: 18, height: 18,
                  child: CustomPaint(
                      painter: _RecenterPainter()),
                ),
              ),
            ),
          ),

        // Next step banner
        if (!_isLoading &&
            _routePoints.isNotEmpty &&
            _steps.isNotEmpty)
          Positioned(
            top: topPad + 70, left: 16, right: 16,
            child: _buildNextStepBanner(),
          ),

        // Bottom card
        if (!_isLoading && !_hasError)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomCard(bottomPad),
          ),

        // Error card
        if (!_isLoading && _hasError)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildErrorCard(bottomPad),
          ),
      ]),
    );
  }

  Widget _floatingBtn({required Widget child}) =>
      Container(
        width: 42, height: 42,
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
        child: Center(child: child),
      );

  // Mode toggle

  Widget _buildModeToggle() => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: const Color(0xFF1C1C1E),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
          color: Colors.white.withOpacity(0.08)),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10),
      ],
    ),
    child: Row(mainAxisSize: MainAxisSize.min,
        children: [
          _modeBtn('driving', 'Drive',
              _DrivingIcon(
                  color: _mode == 'driving'
                      ? Colors.black
                      : Colors.white.withOpacity(0.4))),
          _modeBtn('foot', 'Walk',
              _WalkingIcon(
                  color: _mode == 'foot'
                      ? Colors.black
                      : Colors.white.withOpacity(0.4))),
        ]),
  );

  Widget _modeBtn(
      String mode, String label, Widget icon) {
    final active = _mode == mode;
    return GestureDetector(
      onTap: () {
        if (_mode == mode) return;
        setState(() => _mode = mode);
        _initDirections();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFDEFF6E)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 16, height: 16, child: icon),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.inter(
                    color: active
                        ? Colors.black
                        : Colors.white38,
                    fontSize: 12,
                    fontWeight: active
                        ? FontWeight.w800
                        : FontWeight.w400)),
          ],
        ),
      ),
    );
  }

  //Next step banner

  Widget _buildNextStepBanner() {
    final step = _steps.first;
    final instruction = step['instruction'] as String;
    final dist = step['distance'] as double;
    final type = step['type'] as String;
    final modifier = step['modifier'] as String;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFDEFF6E)
                .withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12),
        ],
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFDEFF6E),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: SizedBox(
              width: 20, height: 20,
              child: _directionIcon(
                  type, modifier, Colors.black),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(instruction,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(_formatStepDist(dist),
                  style: GoogleFonts.inter(
                      color: const Color(0xFFDEFF6E),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ]),
    );
  }

  // Bottom card

  Widget _buildBottomCard(double bottomPad) =>
      Container(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, bottomPad + 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24)),
          border: Border(
              top: BorderSide(
                  color:
                  Colors.white.withOpacity(0.07))),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, -4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin:
                const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                    color:
                    Colors.white.withOpacity(0.1),
                    borderRadius:
                    BorderRadius.circular(2)),
              ),
            ),
            Text(widget.spaceName,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(widget.spaceAddress,
                style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 14),
            Container(
              padding:
              const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Expanded(
                    child: _statCell(
                        'DISTANCE', _distance)),
                Container(
                    width: 1, height: 28,
                    color:
                    Colors.white.withOpacity(0.08)),
                Expanded(
                    child:
                    _statCell('ETA', _duration)),
                Container(
                    width: 1, height: 28,
                    color:
                    Colors.white.withOpacity(0.08)),
                Expanded(
                    child: _statCell('MODE',
                        _mode == 'driving'
                            ? 'Drive'
                            : 'Walk')),
              ]),
            ),
            const SizedBox(height: 12),
            Row(children: [
              if (_steps.isNotEmpty) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(
                            () => _showStepsList = true),
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(
                          vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withOpacity(0.06),
                        borderRadius:
                        BorderRadius.circular(13),
                        border: Border.all(
                            color: Colors.white
                                .withOpacity(0.09)),
                      ),
                      child: Center(
                        child: Text('Steps',
                            style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight:
                                FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: _steps.isNotEmpty ? 2 : 1,
                child: GestureDetector(
                  onTap: _fitMapToRoute,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDEFF6E),
                      borderRadius:
                      BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                            color:
                            const Color(0xFFDEFF6E)
                                .withOpacity(0.2),
                            blurRadius: 10),
                      ],
                    ),
                    child: Center(
                      child: Text('Show Full Route',
                          style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 13,
                              fontWeight:
                              FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ]),
          ],
        ),
      );

  //Steps list

  Widget _buildStepsList() {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Column(children: [
        Container(
          color: const Color(0xFF111111),
          padding: EdgeInsets.fromLTRB(
              20, topPad + 12, 20, 14),
          child: Row(children: [
            GestureDetector(
              onTap: () => setState(
                      () => _showStepsList = false),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color:
                      Colors.white.withOpacity(0.1)),
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
                  Text('Turn-by-Turn Directions',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3)),
                  Text(
                      '$_distance · $_duration · '
                          '${_mode == 'driving' ? 'Driving' : 'Walking'}',
                      style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 12)),
                ],
              ),
            ),
          ]),
        ),

        // Summary strip
        Container(
          margin: const EdgeInsets.fromLTRB(
              20, 0, 20, 14),
          padding:
          const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Colors.white.withOpacity(0.07)),
          ),
          child: Row(children: [
            Expanded(
                child: _statCell(
                    'TO', widget.spaceName,
                    small: true)),
            Container(
                width: 1, height: 28,
                color: Colors.white.withOpacity(0.08)),
            Expanded(
                child:
                _statCell('DISTANCE', _distance)),
            Container(
                width: 1, height: 28,
                color: Colors.white.withOpacity(0.08)),
            Expanded(
                child: _statCell('ETA', _duration)),
          ]),
        ),

        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
                20, 0, 20, bottomPad + 24),
            itemCount: _steps.length,
            itemBuilder: (_, i) =>
                _buildStepRow(i, _steps[i]),
          ),
        ),
      ]),
    );
  }

  Widget _buildStepRow(
      int index, Map<String, dynamic> step) {
    final instruction = step['instruction'] as String;
    final dist = step['distance'] as double;
    final type = step['type'] as String;
    final modifier = step['modifier'] as String;
    final isLast = index == _steps.length - 1;
    final isFirst = index == 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isFirst || isLast
                  ? const Color(0xFFDEFF6E)
                  : const Color(0xFF1C1C1E),
              shape: BoxShape.circle,
              border: Border.all(
                color: isFirst || isLast
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.1),
              ),
            ),
            child: Center(
              child: SizedBox(
                width: 18, height: 18,
                child: _directionIcon(
                  type,
                  modifier,
                  isFirst || isLast
                      ? Colors.black
                      : Colors.white.withOpacity(0.6),
                ),
              ),
            ),
          ),
          if (!isLast)
            Container(
              width: 2, height: 44,
              margin: const EdgeInsets.symmetric(
                  vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ]),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
                top: 6, bottom: 16),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(instruction,
                    style: GoogleFonts.inter(
                        color: isFirst || isLast
                            ? Colors.white
                            : Colors.white70,
                        fontSize: 14,
                        fontWeight: isFirst || isLast
                            ? FontWeight.w700
                            : FontWeight.w500,
                        height: 1.3)),
                if (dist > 0) ...[
                  const SizedBox(height: 4),
                  Text(_formatStepDist(dist),
                      style: GoogleFonts.inter(
                          color: isFirst
                              ? const Color(0xFFDEFF6E)
                              : Colors.white38,
                          fontSize: 12,
                          fontWeight:
                          FontWeight.w600)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  //Error card

  Widget _buildErrorCard(double bottomPad) =>
      Container(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, bottomPad + 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24)),
          border: Border(
              top: BorderSide(
                  color:
                  Colors.white.withOpacity(0.07))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin:
                const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color:
                    Colors.white.withOpacity(0.1),
                    borderRadius:
                    BorderRadius.circular(2)),
              ),
            ),
            Container(
              width: 32, height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444)
                    .withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(_statusMessage,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
                'Check your connection and try again.',
                style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 13)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _initDirections,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 14),
                decoration: BoxDecoration(
                  color:
                  Colors.white.withOpacity(0.06),
                  borderRadius:
                  BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white
                          .withOpacity(0.09)),
                ),
                child: Center(
                  child: Text('Try Again',
                      style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight:
                          FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      );

  // Loading pill

  Widget _buildLoadingPill() => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF1C1C1E),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
          color: Colors.white.withOpacity(0.08)),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 14, height: 14,
          child: CircularProgressIndicator(
              color: Color(0xFFDEFF6E),
              strokeWidth: 2),
        ),
        const SizedBox(width: 10),
        Text(_statusMessage,
            style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ],
    ),
  );

  // Shared helpers

  Widget _statCell(String label, String value,
      {bool small = false}) =>
      Column(children: [
        Text(label,
            style: GoogleFonts.inter(
                color: Colors.white24,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.7)),
        const SizedBox(height: 3),
        Text(value,
            style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: small ? 11 : 14,
                fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ]);

  //Custom painted direction icon
  Widget _directionIcon(
      String type, String modifier, Color color) {
    switch (type) {
      case 'depart':
        return CustomPaint(
            painter: _ArrowUpPainter(color: color));
      case 'arrive':
        return CustomPaint(
            painter: _DestinationPainter(color: color));
      case 'turn':
        if (modifier.contains('sharp left'))
          return CustomPaint(
              painter: _ArrowSharpLeftPainter(
                  color: color));
        if (modifier.contains('sharp right'))
          return CustomPaint(
              painter: _ArrowSharpRightPainter(
                  color: color));
        if (modifier.contains('slight left'))
          return CustomPaint(
              painter: _ArrowSlightLeftPainter(
                  color: color));
        if (modifier.contains('slight right'))
          return CustomPaint(
              painter: _ArrowSlightRightPainter(
                  color: color));
        if (modifier.contains('left'))
          return CustomPaint(
              painter: _ArrowLeftPainter(color: color));
        return CustomPaint(
            painter: _ArrowRightPainter(color: color));
      case 'roundabout':
      case 'rotary':
        return CustomPaint(
            painter:
            _RoundaboutPainter(color: color));
      case 'fork':
        if (modifier.contains('left'))
          return CustomPaint(
              painter: _ArrowSlightLeftPainter(
                  color: color));
        return CustomPaint(
            painter: _ArrowSlightRightPainter(
                color: color));
      case 'merge':
      case 'on ramp':
      case 'off ramp':
        return CustomPaint(
            painter: _MergePainter(color: color));
      case 'end of road':
        if (modifier.contains('left'))
          return CustomPaint(
              painter: _ArrowLeftPainter(color: color));
        return CustomPaint(
            painter: _ArrowRightPainter(color: color));
      case 'arrive':
        return CustomPaint(
            painter:
            _DestinationPainter(color: color));
      default:
        return CustomPaint(
            painter: _ArrowUpPainter(color: color));
    }
  }
}

// CUSTOM DIRECTION ICON PAINTERS

// Shared stroke setup
Paint _iconPaint(Color color) => Paint()
  ..color = color
  ..strokeWidth = 1.8
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..style = PaintingStyle.stroke;

// Arrow UP (straight / depart / continue)
class _ArrowUpPainter extends CustomPainter {
  final Color color;
  const _ArrowUpPainter({required this.color});
  @override
  void paint(Canvas canvas, Size s) {
    final p = _iconPaint(color);
    final cx = s.width / 2;
    // Shaft
    canvas.drawLine(
        Offset(cx, s.height * 0.85),
        Offset(cx, s.height * 0.2), p);
    // Arrow head
    final path = ui.Path()
      ..moveTo(cx - s.width * 0.28, s.height * 0.42)
      ..lineTo(cx, s.height * 0.12)
      ..lineTo(cx + s.width * 0.28, s.height * 0.42);
    canvas.drawPath(path, p);
  }
  @override bool shouldRepaint(covariant _ArrowUpPainter o) => o.color != color;
}

//Arrow lrft
class _ArrowLeftPainter extends CustomPainter {
  final Color color;
  const _ArrowLeftPainter({required this.color});
  @override
  void paint(Canvas canvas, Size s) {
    final p = _iconPaint(color);
    final cy = s.height / 2;
    // Up shaft
    canvas.drawLine(
        Offset(s.width * 0.65, s.height * 0.85),
        Offset(s.width * 0.65, cy), p);
    // Horizontal
    canvas.drawLine(
        Offset(s.width * 0.65, cy),
        Offset(s.width * 0.22, cy), p);
    // Head
    final path = ui.Path()
      ..moveTo(s.width * 0.44, cy - s.height * 0.22)
      ..lineTo(s.width * 0.12, cy)
      ..lineTo(s.width * 0.44, cy + s.height * 0.22);
    canvas.drawPath(path, p);
  }
  @override bool shouldRepaint(covariant _ArrowLeftPainter o) => o.color != color;
}

// Arrow right
class _ArrowRightPainter extends CustomPainter {
  final Color color;
  const _ArrowRightPainter({required this.color});
  @override
  void paint(Canvas canvas, Size s) {
    final p = _iconPaint(color);
    final cy = s.height / 2;
    canvas.drawLine(
        Offset(s.width * 0.35, s.height * 0.85),
        Offset(s.width * 0.35, cy), p);
    canvas.drawLine(
        Offset(s.width * 0.35, cy),
        Offset(s.width * 0.78, cy), p);
    final path = ui.Path()
      ..moveTo(s.width * 0.56, cy - s.height * 0.22)
      ..lineTo(s.width * 0.88, cy)
      ..lineTo(s.width * 0.56, cy + s.height * 0.22);
    canvas.drawPath(path, p);
  }
  @override bool shouldRepaint(covariant _ArrowRightPainter o) => o.color != color;
}

// slight left
class _ArrowSlightLeftPainter extends CustomPainter {
  final Color color;
  const _ArrowSlightLeftPainter({required this.color});
  @override
  void paint(Canvas canvas, Size s) {
    final p = _iconPaint(color);
    // Shaft from bottom-centre
    canvas.drawLine(
        Offset(s.width * 0.55, s.height * 0.88),
        Offset(s.width * 0.55, s.height * 0.55), p);
    // Slight diagonal to upper-left
    canvas.drawLine(
        Offset(s.width * 0.55, s.height * 0.55),
        Offset(s.width * 0.25, s.height * 0.18), p);
    // Head
    final path = ui.Path()
      ..moveTo(s.width * 0.12, s.height * 0.36)
      ..lineTo(s.width * 0.18, s.height * 0.10)
      ..lineTo(s.width * 0.42, s.height * 0.25);
    canvas.drawPath(path, p);
  }
  @override bool shouldRepaint(covariant _ArrowSlightLeftPainter o) => o.color != color;
}

// ── Slight RIGHT ───────────────────────────────
class _ArrowSlightRightPainter extends CustomPainter {
  final Color color;
  const _ArrowSlightRightPainter({required this.color});
  @override
  void paint(Canvas canvas, Size s) {
    final p = _iconPaint(color);
    canvas.drawLine(
        Offset(s.width * 0.45, s.height * 0.88),
        Offset(s.width * 0.45, s.height * 0.55), p);
    canvas.drawLine(
        Offset(s.width * 0.45, s.height * 0.55),
        Offset(s.width * 0.75, s.height * 0.18), p);
    final path = ui.Path()
      ..moveTo(s.width * 0.88, s.height * 0.36)
      ..lineTo(s.width * 0.82, s.height * 0.10)
      ..lineTo(s.width * 0.58, s.height * 0.25);
    canvas.drawPath(path, p);
  }
  @override bool shouldRepaint(covariant _ArrowSlightRightPainter o) => o.color != color;
}

// ── Sharp LEFT ─────────────────────────────────
class _ArrowSharpLeftPainter extends CustomPainter {
  final Color color;
  const _ArrowSharpLeftPainter({required this.color});
  @override
  void paint(Canvas canvas, Size s) {
    final p = _iconPaint(color);
    final cy = s.height * 0.55;
    // Up
    canvas.drawLine(
        Offset(s.width * 0.6, s.height * 0.88),
        Offset(s.width * 0.6, cy), p);
    // Sharp left then up again
    canvas.drawLine(
        Offset(s.width * 0.6, cy),
        Offset(s.width * 0.3, cy), p);
    canvas.drawLine(
        Offset(s.width * 0.3, cy),
        Offset(s.width * 0.3, s.height * 0.15), p);
    final path = ui.Path()
      ..moveTo(s.width * 0.10, s.height * 0.35)
      ..lineTo(s.width * 0.30, s.height * 0.08)
      ..lineTo(s.width * 0.50, s.height * 0.35);
    canvas.drawPath(path, p);
  }
  @override bool shouldRepaint(covariant _ArrowSharpLeftPainter o) => o.color != color;
}

// ── Sharp RIGHT ────────────────────────────────
class _ArrowSharpRightPainter extends CustomPainter {
  final Color color;
  const _ArrowSharpRightPainter({required this.color});
  @override
  void paint(Canvas canvas, Size s) {
    final p = _iconPaint(color);
    final cy = s.height * 0.55;
    canvas.drawLine(
        Offset(s.width * 0.4, s.height * 0.88),
        Offset(s.width * 0.4, cy), p);
    canvas.drawLine(
        Offset(s.width * 0.4, cy),
        Offset(s.width * 0.7, cy), p);
    canvas.drawLine(
        Offset(s.width * 0.7, cy),
        Offset(s.width * 0.7, s.height * 0.15), p);
    final path = ui.Path()
      ..moveTo(s.width * 0.50, s.height * 0.35)
      ..lineTo(s.width * 0.70, s.height * 0.08)
      ..lineTo(s.width * 0.90, s.height * 0.35);
    canvas.drawPath(path, p);
  }
  @override bool shouldRepaint(covariant _ArrowSharpRightPainter o) => o.color != color;
}

// ── Roundabout ─────────────────────────────────
class _RoundaboutPainter extends CustomPainter {
  final Color color;
  const _RoundaboutPainter({required this.color});
  @override
  void paint(Canvas canvas, Size s) {
    final p = _iconPaint(color)..strokeWidth = 1.6;
    final cx = s.width / 2;
    final cy = s.height / 2;
    final r = s.width * 0.30;
    // Circle
    canvas.drawCircle(Offset(cx, cy), r, p);
    // Entry arrow from bottom
    canvas.drawLine(
        Offset(cx, s.height * 0.92),
        Offset(cx, cy + r), p);
    // Exit arrow upward-right
    canvas.drawLine(
        Offset(cx + r * 0.7, cy - r * 0.7),
        Offset(s.width * 0.88, s.height * 0.12), p);
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final head = ui.Path()
      ..moveTo(s.width * 0.68, s.height * 0.22)
      ..lineTo(s.width * 0.88, s.height * 0.12)
      ..lineTo(s.width * 0.80, s.height * 0.34);
    canvas.drawPath(head, arrowPaint);
  }
  @override bool shouldRepaint(covariant _RoundaboutPainter o) => o.color != color;
}

// ── Merge / Ramp ────────────────────────────────
class _MergePainter extends CustomPainter {
  final Color color;
  const _MergePainter({required this.color});
  @override
  void paint(Canvas canvas, Size s) {
    final p = _iconPaint(color);
    final cx = s.width / 2;
    // Two lines converging upward
    canvas.drawLine(
        Offset(s.width * 0.25, s.height * 0.88),
        Offset(cx, s.height * 0.45), p);
    canvas.drawLine(
        Offset(s.width * 0.75, s.height * 0.88),
        Offset(cx, s.height * 0.45), p);
    // Single shaft up
    canvas.drawLine(
        Offset(cx, s.height * 0.45),
        Offset(cx, s.height * 0.18), p);
    // Head
    final path = ui.Path()
      ..moveTo(cx - s.width * 0.24, s.height * 0.38)
      ..lineTo(cx, s.height * 0.10)
      ..lineTo(cx + s.width * 0.24, s.height * 0.38);
    canvas.drawPath(path, p);
  }
  @override bool shouldRepaint(covariant _MergePainter o) => o.color != color;
}

// ── Destination pin ────────────────────────────
class _DestinationPainter extends CustomPainter {
  final Color color;
  const _DestinationPainter({required this.color});
  @override
  void paint(Canvas canvas, Size s) {
    final p = _iconPaint(color);
    final cx = s.width / 2;
    final r = s.width * 0.32;
    // Pin circle
    canvas.drawCircle(Offset(cx, r + s.height * 0.06),
        r, p);
    // Pin tail
    final path = ui.Path()
      ..moveTo(cx - r * 0.5,
          r * 1.6 + s.height * 0.06)
      ..quadraticBezierTo(
          cx, s.height * 0.94, cx, s.height * 0.94)
      ..quadraticBezierTo(
          cx,
          s.height * 0.94,
          cx + r * 0.5,
          r * 1.6 + s.height * 0.06);
    canvas.drawPath(path, p);
    // Inner dot
    canvas.drawCircle(
        Offset(cx, r + s.height * 0.06),
        r * 0.32,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill);
  }
  @override bool shouldRepaint(covariant _DestinationPainter o) => o.color != color;
}

// ── Recenter icon ──────────────────────────────
class _RecenterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = const Color(0xFFDEFF6E)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final cx = s.width / 2;
    final cy = s.height / 2;
    final r = s.width * 0.32;
    canvas.drawCircle(Offset(cx, cy), r, p);
    // Cross lines outside circle
    canvas.drawLine(Offset(cx, 0), Offset(cx, cy - r), p);
    canvas.drawLine(Offset(cx, cy + r), Offset(cx, s.height), p);
    canvas.drawLine(Offset(0, cy), Offset(cx - r, cy), p);
    canvas.drawLine(Offset(cx + r, cy), Offset(s.width, cy), p);
    // Centre dot
    canvas.drawCircle(Offset(cx, cy), 2.0,
        Paint()
          ..color = const Color(0xFFDEFF6E)
          ..style = PaintingStyle.fill);
  }
  @override bool shouldRepaint(_) => false;
}

// ── Driving icon (for mode toggle) ────────────
class _DrivingIcon extends StatelessWidget {
  final Color color;
  const _DrivingIcon({required this.color});
  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: _DrivingPainter(color: color));
}

class _DrivingPainter extends CustomPainter {
  final Color color;
  const _DrivingPainter({required this.color});
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    // Car body
    final body = ui.Path()
      ..moveTo(s.width * 0.08, s.height * 0.62)
      ..lineTo(s.width * 0.08, s.height * 0.72)
      ..lineTo(s.width * 0.92, s.height * 0.72)
      ..lineTo(s.width * 0.92, s.height * 0.62)
      ..lineTo(s.width * 0.78, s.height * 0.62)
      ..lineTo(s.width * 0.65, s.height * 0.35)
      ..lineTo(s.width * 0.35, s.height * 0.35)
      ..lineTo(s.width * 0.22, s.height * 0.62)
      ..close();
    canvas.drawPath(body, p);
    // Wheels
    canvas.drawCircle(
        Offset(s.width * 0.25, s.height * 0.76),
        s.width * 0.10, p);
    canvas.drawCircle(
        Offset(s.width * 0.75, s.height * 0.76),
        s.width * 0.10, p);
    // Window
    final win = ui.Path()
      ..moveTo(s.width * 0.37, s.height * 0.38)
      ..lineTo(s.width * 0.28, s.height * 0.58)
      ..lineTo(s.width * 0.72, s.height * 0.58)
      ..lineTo(s.width * 0.63, s.height * 0.38)
      ..close();
    canvas.drawPath(win, p);
  }
  @override bool shouldRepaint(covariant _DrivingPainter o) => o.color != color;
}

// ── Walking icon (for mode toggle) ────────────
class _WalkingIcon extends StatelessWidget {
  final Color color;
  const _WalkingIcon({required this.color});
  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: _WalkingPainter(color: color));
}

class _WalkingPainter extends CustomPainter {
  final Color color;
  const _WalkingPainter({required this.color});
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    // Head
    canvas.drawCircle(
        Offset(s.width * 0.55, s.height * 0.14),
        s.width * 0.12,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill);
    // Body
    canvas.drawLine(
        Offset(s.width * 0.55, s.height * 0.26),
        Offset(s.width * 0.48, s.height * 0.58), p);
    // Left arm
    canvas.drawLine(
        Offset(s.width * 0.55, s.height * 0.38),
        Offset(s.width * 0.22, s.height * 0.48), p);
    // Right arm
    canvas.drawLine(
        Offset(s.width * 0.52, s.height * 0.42),
        Offset(s.width * 0.72, s.height * 0.52), p);
    // Left leg
    canvas.drawLine(
        Offset(s.width * 0.48, s.height * 0.58),
        Offset(s.width * 0.28, s.height * 0.88), p);
    // Right leg
    canvas.drawLine(
        Offset(s.width * 0.48, s.height * 0.58),
        Offset(s.width * 0.68, s.height * 0.82), p);
  }
  @override bool shouldRepaint(covariant _WalkingPainter o) => o.color != color;
}