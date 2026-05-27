import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    runApp(const HotspotApp());
  });
}

// ── BRAND COLORS & CONSTANTS ──
const Color kInk = Color(0xFF1A1C14);
const Color kVolt = Color(0xFFCBEA00);
const Color kAcc = Color(0xFF5B5BFF);
const Color kMuted = Color(0xFF8A8F80);
const Color kBg = Color(0xFFF2F3F0);
const double kMaxOverlayWidth = 600.0;

// ── GLOBAL STATE FOR TAB NAVIGATION ──
final ValueNotifier<int> currentTabNotifier = ValueNotifier(1); // Starts at Explore Tab

// ── DATA MODELS ──
class SpaceData {
  final String id, name, address, distance, type, status;
  final int price; // Base price for "Basic" tier
  final double rating;
  final int reviews;
  final LatLng location;
  final List<Color> gradient;
  final List<String> amenities;
  final bool hasValet;

  SpaceData({
    required this.id, required this.name, required this.address, required this.distance,
    required this.type, required this.status, required this.price, required this.rating,
    required this.reviews, required this.location, required this.gradient,
    required this.amenities, required this.hasValet,
  });
}

class BookingModel {
  String id;
  String spaceName;
  String type;
  String tier; // NEW: The tier they booked
  String duration;
  String date;
  String time;
  List<String> requests;
  String payment;
  String review;
  int totalAmount;
  String status; // "Pending", "Approved", "Cancelled", "Completed"

  BookingModel({
    required this.id, required this.spaceName, required this.type, required this.tier,
    required this.duration, required this.date, required this.time, required this.requests,
    required this.payment, required this.review, required this.totalAmount, required this.status,
  });
}

// ── GLOBAL BOOKINGS STATE ──
final ValueNotifier<List<BookingModel>> globalBookings = ValueNotifier([
  BookingModel(
      id: "init_1", spaceName: "The Dark Oak", type: "Board Room", tier: "VIP", duration: "3 Hours",
      date: "Tomorrow", time: "10:00 AM", requests: ["AC"], payment: "Visa ending in 4242",
      review: "", totalAmount: 1500, status: "Approved" // Will show QR Code
  ),
  BookingModel(
      id: "init_4", spaceName: "Ember Space", type: "Meeting Room", tier: "Basic", duration: "2 Hours",
      date: "Oct 20, 2023", time: "1:00 PM", requests: ["Projector"], payment: "Visa ending in 4242",
      review: "", totalAmount: 700, status: "Pending" // Awaiting Approval
  ),
  BookingModel(
      id: "init_2", spaceName: "Loft Collective", type: "Hot Desk", tier: "Pro", duration: "5 Hours",
      date: "Oct 12, 2023", time: "10:00 AM - 3:00 PM", requests: ["AC", "Coffee/Tea"], payment: "Visa ending in 4242",
      review: "★ 5.0 - Great environment, very quiet. Loved the free coffee!", totalAmount: 750, status: "Completed"
  ),
]);

// ── STATIC DATA ──
final List<SpaceData> sampleSpaces = [
  SpaceData(id: "1", name: "Barista Nugegoda", address: "Nugegoda, Sri Lanka", distance: "0.3 km", type: "Hot Desk", status: "Open now", price: 200, rating: 4.8, reviews: 179, location: const LatLng(6.8675, 79.9010), gradient: const [Color(0xFFC4D4E4), Color(0xFF9AB0C8)], amenities: ["Wi-Fi", "Coffee", "AC"], hasValet: false),
  SpaceData(id: "2", name: "The Dark Oak", address: "Beira Lake, Colombo", distance: "0.7 km", type: "Board Room", status: "Limited", price: 500, rating: 4.7, reviews: 94, location: const LatLng(6.8620, 79.8950), gradient: const [Color(0xFFB8CCD8), Color(0xFF8AAABF)], amenities: ["Wi-Fi", "Parking", "Printer", "AC"], hasValet: true),
  SpaceData(id: "3", name: "Loft Collective", address: "Colombo 03", distance: "1.1 km", type: "Hot Desk", status: "Open now", price: 150, rating: 4.6, reviews: 210, location: const LatLng(6.8710, 79.8930), gradient: const [Color(0xFFD4CFC8), Color(0xFFA09890)], amenities: ["Wi-Fi", "Coffee", "Parking"], hasValet: false),
  SpaceData(id: "4", name: "Ember Space", address: "Bambalapitiya", distance: "1.8 km", type: "Meeting Room", status: "2 Left", price: 350, rating: 4.9, reviews: 67, location: const LatLng(6.8850, 79.8540), gradient: const [Color(0xFFC8CEE8), Color(0xFF9AA0C8)], amenities: ["Wi-Fi", "AC", "Projector"], hasValet: true),
  SpaceData(id: "5", name: "Quiet Quarter", address: "Rajagiriya", distance: "3.2 km", type: "Hot Desk", status: "Open now", price: 180, rating: 5.0, reviews: 43, location: const LatLng(6.9040, 79.8980), gradient: const [Color(0xFFD8D8D8), Color(0xFFA0A0A0)], amenities: ["Wi-Fi", "Coffee", "Silent Zone"], hasValet: false),
];

// ── ROOT APP ──
class HotspotApp extends StatelessWidget {
  const HotspotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hotspot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Plus Jakarta Sans',
        scaffoldBackgroundColor: kBg,
        splashColor: kVolt.withOpacity(0.2),
        highlightColor: Colors.transparent,
      ),
      home: const MainNavigator(),
    );
  }
}

// ── STATEFUL NAVIGATOR ──
class MainNavigator extends StatelessWidget {
  const MainNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
        valueListenable: currentTabNotifier,
        builder: (context, currentIndex, child) {
          return Scaffold(
            extendBody: true,
            extendBodyBehindAppBar: true,
            drawer: const HotspotDrawer(),
            body: IndexedStack(
              index: currentIndex,
              children: const [
                MapTab(),
                ExploreTab(),
                MySpacesTab(), // RENAMED FROM BOOKINGSTAB
                ProfileTab(),
              ],
            ),
            bottomNavigationBar: SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: 1.0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: kMaxOverlayWidth),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 15),
                    child: FloatingNavBar(
                      currentIndex: currentIndex,
                      onTap: (index) => currentTabNotifier.value = index,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 1. MAP TAB
// ════════════════════════════════════════════════════════════════════════════
class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final MapController _mapController = MapController();
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _selectedIndex = 0;

  void _onMarkerTapped(int index) {
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    _centerMapOn(index);
  }

  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
    _centerMapOn(index);
  }

  void _centerMapOn(int index) {
    final loc = sampleSpaces[index].location;
    _mapController.move(LatLng(loc.latitude - 0.002, loc.longitude), 15.5);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(6.8649, 79.8997),
            initialZoom: 14.5,
            interactionOptions: InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          ),
          children: [
            TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png', subdomains: const ['a', 'b', 'c'], retinaMode: true),
            MarkerLayer(
              markers: [
                const Marker(point: LatLng(6.8649, 79.8997), width: 20, height: 20, child: UserLocationDot()),
                ...sampleSpaces.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final space = entry.value;
                  final isSelected = _selectedIndex == idx;
                  return Marker(point: space.location, width: 110, height: 50, child: GestureDetector(onTap: () => _onMarkerTapped(idx), child: isSelected ? SelectedMapPin(name: space.name) : UnselectedMapPin(price: space.price.toString())));
                }),
              ],
            ),
          ],
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: kMaxOverlayWidth), child: const Padding(padding: EdgeInsets.only(top: 10, left: 20, right: 20), child: TopSearchBar())),
          ),
        ),
        Positioned(
          bottom: 110, left: 0, right: 0, height: 200,
          child: PageView.builder(
            controller: _pageController, onPageChanged: _onPageChanged, itemCount: sampleSpaces.length,
            itemBuilder: (context, index) { return Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: GlassMapCard(space: sampleSpaces[index])); },
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 2. EXPLORE TAB
// ════════════════════════════════════════════════════════════════════════════
class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filteredSpaces = sampleSpaces.where((space) {
      return space.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          space.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          space.type.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kMaxOverlayWidth),
          child: ListView(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
            children: [
              const Text("Explore Spaces", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kInk)),
              const SizedBox(height: 15),
              Container(
                height: 50, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: const InputDecoration(hintText: "Search areas or spaces...", prefixIcon: Icon(Icons.search, color: kMuted), border: InputBorder.none),
                ),
              ),
              const SizedBox(height: 25),
              Text(_searchQuery.isEmpty ? "Top Rated Nearby" : "Search Results (${filteredSpaces.length})", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kInk)),
              const SizedBox(height: 15),
              if (filteredSpaces.isEmpty) const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: Text("No spaces found.", style: TextStyle(color: kMuted, fontWeight: FontWeight.bold)))),
              ...filteredSpaces.map((space) => LargeGlassSpaceCard(space: space)),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 3. MY SPACES TAB (Formerly BookingsTab)
// ════════════════════════════════════════════════════════════════════════════
class MySpacesTab extends StatelessWidget {
  const MySpacesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kMaxOverlayWidth),
          child: ValueListenableBuilder<List<BookingModel>>(
              valueListenable: globalBookings,
              builder: (context, bookings, child) {

                // Only pull "Pending" and "Approved" spaces into the Active list.
                final activeSpaces = bookings.where((b) => b.status == "Pending" || b.status == "Approved").toList();
                final pastSpaces = bookings.where((b) => b.status == "Completed" || b.status == "Cancelled").toList();

                return ListView(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
                  children: [
                    const Text("My Spaces", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kInk)),
                    const SizedBox(height: 20),

                    const Text("Active & Pending", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kInk)),
                    const SizedBox(height: 10),

                    if (activeSpaces.isEmpty)
                      const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text("No active spaces right now.", style: TextStyle(color: kMuted)))),

                    ...activeSpaces.map((booking) => _buildActiveSpaceCard(context, booking)),

                    const SizedBox(height: 30),

                    const Text("Past Bookings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kInk)),
                    const SizedBox(height: 10),

                    ...pastSpaces.map((booking) => _buildPastBookingCard(context, booking)),
                  ],
                );
              }
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSpaceCard(BuildContext context, BookingModel booking) {
    bool isPending = booking.status == "Pending";

    Color badgeColor = isPending ? Colors.orangeAccent : Colors.green;
    Color badgeTextColor = isPending ? Colors.white : Colors.white;

    return GestureDetector(
      onTap: () => _showManageBookingModal(context, booking),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: kInk,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: kInk.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPending) const Icon(Icons.hourglass_top, color: Colors.white, size: 12),
                        if (!isPending) const Icon(Icons.check_circle, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(isPending ? "Awaiting Approval" : "Approved", style: TextStyle(color: badgeTextColor, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    )
                ),
                Text("LKR ${booking.totalAmount}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 15),
            Text(booking.spaceName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text("Tier: ${booking.tier} • ${booking.type}", style: const TextStyle(color: kVolt, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Row(children: [const Icon(Icons.calendar_month, color: kVolt, size: 16), const SizedBox(width: 8), Text("${booking.date}, ${booking.time}", style: const TextStyle(color: Colors.white, fontSize: 13))]),
                  const SizedBox(height: 8),
                  Row(children: [const Icon(Icons.timer, color: kVolt, size: 16), const SizedBox(width: 8), Text("Duration: ${booking.duration}", style: const TextStyle(color: Colors.white, fontSize: 13))]),
                ],
              ),
            ),

            // THE QR CODE BUTTON (Only visible if Approved!)
            if (!isPending) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kVolt,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))
                  ),
                  icon: const Icon(Icons.qr_code_2, color: kInk),
                  label: const Text("View Access QR", style: TextStyle(color: kInk, fontWeight: FontWeight.bold, fontSize: 15)),
                  onPressed: () => _showQRModal(context, booking),
                ),
              )
            ],

            if (isPending) ...[
              const SizedBox(height: 12),
              const Center(child: Text("We will notify you once your request is approved.", style: TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic)))
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildPastBookingCard(BuildContext context, BookingModel booking) {
    bool isCancelled = booking.status == "Cancelled";

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ReceiptScreen(
            name: booking.spaceName, type: booking.type, duration: booking.duration, tier: booking.tier,
            date: booking.date, time: booking.time, requests: booking.requests.isEmpty ? "None" : booking.requests.join(', '),
            payment: booking.payment, review: booking.review, total: "LKR ${booking.totalAmount}", status: booking.status
        )));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.history, color: kMuted, size: 20)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(booking.spaceName, style: const TextStyle(fontWeight: FontWeight.bold, color: kInk, fontSize: 15)), const SizedBox(height: 2), Text("${booking.tier} • ${booking.duration}", style: const TextStyle(color: kMuted, fontSize: 12))])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(booking.date, style: const TextStyle(fontWeight: FontWeight.bold, color: kInk, fontSize: 12)), const SizedBox(height: 4), Text(booking.status, style: TextStyle(color: isCancelled ? Colors.red : Colors.green, fontSize: 10, fontWeight: FontWeight.bold))])
          ],
        ),
      ),
    );
  }

  // ── THE QR CODE MODAL ──
  void _showQRModal(BuildContext context, BookingModel booking) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(30),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Your Access Pass", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kInk)),
              const SizedBox(height: 5),
              Text(booking.spaceName, style: const TextStyle(color: kMuted, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              // Dummy QR Code graphic
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    border: Border.all(color: kVolt, width: 4),
                    borderRadius: BorderRadius.circular(20)
                ),
                child: const Icon(Icons.qr_code_2, size: 180, color: kInk),
              ),

              const SizedBox(height: 30),
              const Text("Scan this at the front desk to enter.", textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 13)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kInk, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        )
    );
  }

  // ── MANAGE ACTIVE BOOKING MODAL ──
  void _showManageBookingModal(BuildContext context, BookingModel booking) {
    final List<String> availableRequests = ["AC", "Projector", "Whiteboard", "Extra Chairs", "Coffee/Tea"];
    List<String> tempRequests = List.from(booking.requests);
    String tempTime = booking.time;

    showModalBottomSheet(
        context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return Container(
                  padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))), const SizedBox(height: 20),
                      const Text("Manage Booking", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kInk)), const SizedBox(height: 24),

                      const Text("Date & Time", style: TextStyle(fontWeight: FontWeight.bold, color: kInk, fontSize: 14)), const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, color: kMuted, size: 20), const SizedBox(width: 12), Expanded(child: Text(tempTime, style: const TextStyle(fontWeight: FontWeight.bold, color: kInk))),
                            GestureDetector(
                              onTap: () async {
                                TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 10, minute: 0));
                                if (pickedTime != null) {
                                  String formattedTime = pickedTime.format(context);
                                  setModalState(() { tempTime = formattedTime; });
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Time updated! Remember to save changes."), backgroundColor: kInk));
                                }
                              },
                              child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]), child: const Icon(Icons.edit, color: kVolt, size: 16)),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text("Special Requests & Amenities", style: TextStyle(fontWeight: FontWeight.bold, color: kInk, fontSize: 14)), const SizedBox(height: 10),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: availableRequests.map((request) {
                          final isSelected = tempRequests.contains(request);
                          return GestureDetector(
                            onTap: () { setModalState(() { if (isSelected) { tempRequests.remove(request); } else { tempRequests.add(request); } }); },
                            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: isSelected ? kInk : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? kInk : Colors.black12)), child: Text(request, style: TextStyle(color: isSelected ? kVolt : kMuted, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 30),

                      // Hidden testing feature: Simulate approval if pending!
                      if (booking.status == "Pending") ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: const BorderSide(color: Colors.green), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                              icon: const Icon(Icons.admin_panel_settings, color: Colors.green, size: 16),
                              label: const Text("Admin: Force Approve", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                booking.status = "Approved";
                                globalBookings.value = List.from(globalBookings.value);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking Approved! QR Code generated."), backgroundColor: Colors.green));
                              }
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      Row(
                        children: [
                          Expanded(
                              child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Colors.redAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showCancelConfirmationDialog(context, booking);
                                  },
                                  child: const Text("Cancel Booking", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
                              )
                          ), const SizedBox(width: 12),
                          Expanded(
                              child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: kInk, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                                  onPressed: () {
                                    booking.time = tempTime;
                                    booking.requests = tempRequests;
                                    globalBookings.value = List.from(globalBookings.value);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking preferences saved!"), backgroundColor: kInk));
                                  },
                                  child: const Text("Save Changes", style: TextStyle(color: kVolt, fontWeight: FontWeight.bold))
                              )
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                );
              }
          );
        }
    );
  }

  void _showCancelConfirmationDialog(BuildContext context, BookingModel booking) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Cancel Booking?", style: TextStyle(color: kInk, fontWeight: FontWeight.w800)),
          content: const Text("Are you sure you want to cancel this request? This action cannot be undone.", style: TextStyle(color: kMuted, height: 1.4)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Keep Booking", style: TextStyle(color: kInk, fontWeight: FontWeight.bold))),
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  booking.status = "Cancelled";
                  globalBookings.value = List.from(globalBookings.value);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking cancelled. It has been moved to your History."), backgroundColor: kInk));
                },
                child: const Text("Yes, Cancel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            )
          ],
        )
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 4. PROFILE TAB
// ════════════════════════════════════════════════════════════════════════════
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String _fullName = "Wishvi Fernando";
  String _email = "wishvifernando410@gmail.com";
  String _phone = "+94 77 123 4567";
  bool _hasCustomPicture = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kMaxOverlayWidth),
          child: ListView(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 40, bottom: 120),
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildQuickActions(context),
              const SizedBox(height: 35),
              const Text("Personal Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kInk)),
              const SizedBox(height: 12),
              _buildInfoCard(),
              const SizedBox(height: 30),
              const Text("Settings & Preferences", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kInk)),
              const SizedBox(height: 12),
              _settingsTile(Icons.payment, "Payment Methods", onTap: () => _showPaymentMethodsModal(context)),
              _settingsTile(Icons.shield_outlined, "Privacy & Security"),
              _settingsTile(Icons.help_outline, "Help & Support"),
              const SizedBox(height: 20),
              _settingsTile(Icons.logout, "Log Out", isDestructive: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(width: 110, height: 110, decoration: BoxDecoration(color: _hasCustomPicture ? Colors.grey[200] : kVolt, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))], image: _hasCustomPicture ? const DecorationImage(image: NetworkImage("https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80"), fit: BoxFit.cover) : null), child: _hasCustomPicture ? null : Center(child: Text(_fullName.isNotEmpty ? _fullName.substring(0, 2).toUpperCase() : "WF", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: kInk)))),
            GestureDetector(onTap: () => _showImagePickerModal(), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kInk, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.camera_alt, color: Colors.white, size: 16))),
          ],
        ),
        const SizedBox(height: 15),
        Text(_fullName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kInk)),
        const SizedBox(height: 6),
        Text(_email, style: const TextStyle(fontSize: 14, color: kMuted, fontWeight: FontWeight.w500)),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: kVolt, width: 1.5)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.star, color: kInk, size: 14), SizedBox(width: 6), Text("Pro Member", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kInk))])),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionButton(context, Icons.notifications_none, "Alerts", badgeCount: 3),
        _actionButton(context, Icons.favorite_border, "Saved"),
        _actionButton(context, Icons.history, "History"),
      ],
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label, {int? badgeCount}) {
    return GestureDetector(
      onTap: () {
        if (label == "Alerts") Navigator.push(context, MaterialPageRoute(builder: (context) => const AlertsScreen()));
        else if (label == "Saved") Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedSpacesScreen()));
        else if (label == "History") Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryActivityScreen()));
      },
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(width: 65, height: 65, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]), child: Icon(icon, color: kInk, size: 28)),
              if (badgeCount != null) Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: Text(badgeCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kInk)),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(
        children: [
          _infoRow(Icons.person_outline, "Full Name", _fullName, (newValue) => setState(() => _fullName = newValue)),
          const Divider(height: 1, indent: 70, endIndent: 20, color: Colors.black12),
          _infoRow(Icons.email_outlined, "Email Address", _email, (newValue) => setState(() => _email = newValue)),
          const Divider(height: 1, indent: 70, endIndent: 20, color: Colors.black12),
          _infoRow(Icons.phone_outlined, "Contact Number", _phone, (newValue) => setState(() => _phone = newValue)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Function(String) onSave) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: kMuted, size: 22)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)), const SizedBox(height: 2), Text(value, style: const TextStyle(fontSize: 15, color: kInk, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)])),
          GestureDetector(onTap: () => _showEditDialog(label, value, onSave), child: Container(padding: const EdgeInsets.all(8), color: Colors.transparent, child: const Icon(Icons.edit, color: kVolt, size: 20))),
        ],
      ),
    );
  }

  void _showEditDialog(String label, String currentValue, Function(String) onSave) {
    TextEditingController controller = TextEditingController(text: currentValue);
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Edit $label", style: const TextStyle(color: kInk, fontWeight: FontWeight.w800)),
          content: TextField(controller: controller, cursorColor: kInk, decoration: InputDecoration(filled: true, fillColor: kBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kVolt, width: 2)))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: kMuted, fontWeight: FontWeight.bold))),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: kInk, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () { if (controller.text.trim().isNotEmpty) onSave(controller.text.trim()); Navigator.pop(context); }, child: const Text("Save", style: TextStyle(color: kVolt, fontWeight: FontWeight.bold)))
          ],
        )
    );
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
        context: context, backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))), padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))), const SizedBox(height: 20),
              const Text("Profile Picture", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kInk)), const SizedBox(height: 24),
              ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.camera_alt, color: kInk)), title: const Text("Take a photo", style: TextStyle(fontWeight: FontWeight.bold, color: kInk)), onTap: () { Navigator.pop(context); setState(() => _hasCustomPicture = true); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Camera opened! Photo updated."), backgroundColor: kInk)); }),
              ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.photo_library, color: kInk)), title: const Text("Choose from gallery", style: TextStyle(fontWeight: FontWeight.bold, color: kInk)), onTap: () { Navigator.pop(context); setState(() => _hasCustomPicture = true); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gallery opened! Photo updated."), backgroundColor: kInk)); }),
              ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.delete, color: Colors.red)), title: const Text("Remove current picture", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)), onTap: () { Navigator.pop(context); setState(() => _hasCustomPicture = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile picture removed"), backgroundColor: kInk)); }),
              const SizedBox(height: 10),
            ],
          ),
        )
    );
  }

  void _showPaymentMethodsModal(BuildContext context) {
    showModalBottomSheet(
        context: context, backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))), padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))), const SizedBox(height: 20),
              const Text("Payment Methods", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kInk)), const SizedBox(height: 24),
              _paymentOptionTile(Icons.credit_card, "Credit/Debit Card", "Ending in 4242"),
              _paymentOptionTile(Icons.account_balance_wallet, "PayPal", "wishvi@example.com"),
              _paymentOptionTile(Icons.money, "Cash", "Pay at location"),
              const SizedBox(height: 20),
              Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: kVolt.withOpacity(0.2), borderRadius: BorderRadius.circular(16), border: Border.all(color: kVolt)), child: const Center(child: Text("+ Add New Method", style: TextStyle(color: kInk, fontWeight: FontWeight.bold)))),
              const SizedBox(height: 20),
            ],
          ),
        )
    );
  }

  Widget _paymentOptionTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black.withOpacity(0.05))),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: kInk)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: kInk)), subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: kMuted)), trailing: const Icon(Icons.chevron_right, color: Colors.black26),
        onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$title selected"), backgroundColor: kInk)); },
      ),
    );
  }

  Widget _settingsTile(IconData icon, String title, {bool isDestructive = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
        child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4), leading: Icon(icon, color: isDestructive ? Colors.red : kInk), title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : kInk, fontWeight: FontWeight.bold, fontSize: 14)), trailing: isDestructive ? null : const Icon(Icons.chevron_right, color: Colors.black26)),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 5. HISTORY & ACTIVITY SCREEN
// ════════════════════════════════════════════════════════════════════════════
class HistoryActivityScreen extends StatelessWidget {
  const HistoryActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
            backgroundColor: Colors.white, elevation: 0, centerTitle: true, iconTheme: const IconThemeData(color: kInk),
            title: const Text("History & Activity", style: TextStyle(color: kInk, fontWeight: FontWeight.w800, fontSize: 18)),
            bottom: const TabBar(indicatorColor: kVolt, indicatorWeight: 4, labelColor: kInk, unselectedLabelColor: kMuted, labelStyle: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans', fontSize: 15), tabs: [Tab(text: "History"), Tab(text: "Activity")])
        ),
        body: TabBarView(children: [_buildHistoryTab(context), _buildActivityTab()]),
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    return ValueListenableBuilder<List<BookingModel>>(
        valueListenable: globalBookings,
        builder: (context, bookings, child) {
          final pastBookings = bookings.where((b) => b.status == "Completed" || b.status == "Cancelled").toList();

          if (pastBookings.isEmpty) {
            return const Center(child: Text("No history available.", style: TextStyle(color: kMuted, fontWeight: FontWeight.bold)));
          }

          return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: pastBookings.length,
              itemBuilder: (context, index) {
                return _historyCard(context, pastBookings[index]);
              }
          );
        }
    );
  }

  Widget _historyCard(BuildContext context, BookingModel booking) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ReceiptScreen(
                  name: booking.spaceName, type: booking.type, tier: booking.tier,
                  duration: booking.duration, date: booking.date, time: booking.time,
                  requests: booking.requests.isEmpty ? "None" : booking.requests.join(", "),
                  payment: booking.payment, review: booking.review, total: "LKR ${booking.totalAmount}", status: booking.status,
                )
            )
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Row(
          children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.history, color: kMuted)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(booking.spaceName, style: const TextStyle(fontWeight: FontWeight.bold, color: kInk, fontSize: 15)),
              const SizedBox(height: 2),
              Text("${booking.tier} • ${booking.duration}", style: const TextStyle(color: kMuted, fontSize: 12))
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text("LKR ${booking.totalAmount}", style: const TextStyle(fontWeight: FontWeight.w900, color: kInk)),
              const SizedBox(height: 4),
              Text(booking.status, style: TextStyle(color: booking.status == "Completed" ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold))
            ])
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text("Recent Activity", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kInk)), const SizedBox(height: 16),
        _activityRow(Icons.favorite, Colors.redAccent, "You saved Loft Collective to your favorites.", "2 hours ago"),
        _activityRow(Icons.star, Colors.orange, "You left a 5-star review for The Dark Oak.", "Yesterday"),
        _activityRow(Icons.payment, kVolt, "Added a new Visa card ending in 4242.", "3 days ago"),
        _activityRow(Icons.person, kAcc, "Updated your profile picture.", "Last week"),
        _activityRow(Icons.location_on, Colors.teal, "Explored spaces near Rajagiriya.", "Last week"),
      ],
    );
  }

  Widget _activityRow(IconData icon, Color iconColor, String text, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: iconColor.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: iconColor == kVolt ? kInk : iconColor, size: 20)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(text, style: const TextStyle(color: kInk, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4)), const SizedBox(height: 4), Text(time, style: const TextStyle(color: kMuted, fontSize: 11))])),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 6. ALERTS SCREEN
// ════════════════════════════════════════════════════════════════════════════
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, centerTitle: true, iconTheme: const IconThemeData(color: kInk), title: const Text("Alerts", style: TextStyle(color: kInk, fontWeight: FontWeight.w800, fontSize: 18))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _alertTile(Icons.check_circle, Colors.green, "Booking Approved", "Your VIP request for The Dark Oak was approved. Your QR is ready.", "1 hour ago"),
          _alertTile(Icons.hourglass_top, Colors.orange, "Awaiting Approval", "Your Basic request for Ember Space is under review.", "3 hours ago"),
          _alertTile(Icons.local_offer, Colors.blueAccent, "Special Offer", "Get 20% off on Board Rooms this week! Book now.", "5 hours ago"),
        ],
      ),
    );
  }

  Widget _alertTile(IconData icon, Color color, String title, String desc, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: kInk, fontSize: 15)), Text(time, style: const TextStyle(color: kMuted, fontSize: 11, fontWeight: FontWeight.w600))]), const SizedBox(height: 6), Text(desc, style: const TextStyle(color: kMuted, fontSize: 13, height: 1.4))])),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 7. SAVED SPACES SCREEN
// ════════════════════════════════════════════════════════════════════════════
class SavedSpacesScreen extends StatelessWidget {
  const SavedSpacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final savedSpaces = [sampleSpaces[2], sampleSpaces[4]];
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, centerTitle: true, iconTheme: const IconThemeData(color: kInk), title: const Text("Saved Spaces", style: TextStyle(color: kInk, fontWeight: FontWeight.w800, fontSize: 18))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("Your Favorites", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kInk)),
          const SizedBox(height: 16),
          ...savedSpaces.map((space) => LargeGlassSpaceCard(space: space)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 8. PAST BOOKING RECEIPT SCREEN
// ════════════════════════════════════════════════════════════════════════════
class ReceiptScreen extends StatelessWidget {
  final String name, type, tier, duration, date, time, requests, payment, review, total, status;

  const ReceiptScreen({
    super.key, required this.name, required this.type, required this.tier, required this.duration,
    required this.date, required this.time, required this.requests,
    required this.payment, required this.review, required this.total, required this.status
  });

  Future<void> _generateAndDownloadPdf(BuildContext context) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("HOTSPOT", style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)), pw.SizedBox(height: 10), pw.Text("Official Booking Receipt", style: const pw.TextStyle(fontSize: 20)), pw.Divider(thickness: 2), pw.SizedBox(height: 20),
                pw.Text("Status: $status", style: pw.TextStyle(fontSize: 14, color: status == "Cancelled" ? PdfColors.red : PdfColors.green)),
                pw.SizedBox(height: 10),
                _pdfRow("Space Name:", name), _pdfRow("Booking Type:", type), _pdfRow("Tier:", tier), _pdfRow("Date:", date), _pdfRow("Time:", time), _pdfRow("Duration:", duration), _pdfRow("Special Requests:", requests), _pdfRow("Payment Method:", payment),
                pw.SizedBox(height: 20), pw.Divider(), pw.SizedBox(height: 10),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("Total Paid:", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)), pw.Text(status == "Cancelled" ? "LKR 0" : total, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800))]),
                pw.SizedBox(height: 40), pw.Text("Thank you for using Hotspot!", style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
              ],
            ),
          );
        },
      ),
    );
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Hotspot_Receipt_$name.pdf');
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(padding: const pw.EdgeInsets.only(bottom: 10), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 14)), pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14))]));
  }

  @override
  Widget build(BuildContext context) {
    bool isCancelled = status == "Cancelled";

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, centerTitle: true, iconTheme: const IconThemeData(color: kInk), title: const Text("Booking Receipt", style: TextStyle(color: kInk, fontWeight: FontWeight.w800, fontSize: 18))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kMaxOverlayWidth),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Transaction Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kInk)),
                    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: isCancelled ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(status, style: TextStyle(color: isCancelled ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 12))
                    )
                  ]
              ),
              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))]),
                child: Column(
                  children: [
                    _receiptRow("Space Name", name), _receiptRow("Booking Type", type), _receiptRow("Tier", tier), _receiptRow("Date", date), _receiptRow("Time", time), _receiptRow("Duration", duration), _receiptRow("Special Requests", requests), _receiptRow("Payment Method", payment),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.black12)),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Paid", style: TextStyle(color: kInk, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(isCancelled ? "LKR 0" : total, style: TextStyle(color: isCancelled ? kMuted : kAcc, fontWeight: FontWeight.w900, fontSize: 20, decoration: isCancelled ? TextDecoration.lineThrough : TextDecoration.none))
                        ]
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              if (review.isNotEmpty && !isCancelled) ...[
                const Text("Your Review", style: TextStyle(fontWeight: FontWeight.bold, color: kInk, fontSize: 16)), const SizedBox(height: 10),
                Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)), child: Text(review, style: const TextStyle(color: kInk, fontSize: 14, height: 1.5))),
                const SizedBox(height: 40),
              ],

              if (!isCancelled) ...[
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: kInk, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        icon: const Icon(Icons.download, color: kVolt, size: 20),
                        label: const Text("Download PDF Receipt", style: TextStyle(color: kVolt, fontWeight: FontWeight.bold, fontSize: 15)),
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generating PDF..."), backgroundColor: kInk));
                          await _generateAndDownloadPdf(context);
                        }
                    )
                ),
                const SizedBox(height: 40),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kMuted, fontSize: 14, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: kInk, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 9. CREATE BOOKING BOTTOM SHEET (WITH TIER SELECTION)
// ════════════════════════════════════════════════════════════════════════════
class CreateBookingSheet extends StatefulWidget {
  final SpaceData space;
  const CreateBookingSheet({super.key, required this.space});

  @override
  State<CreateBookingSheet> createState() => _CreateBookingSheetState();
}

class _CreateBookingSheetState extends State<CreateBookingSheet> {
  String _selectedTier = "Basic"; // Basic, Pro, VIP
  double _durationHours = 1.0;
  bool _wantsValet = false;
  String _coffeePref = "None";

  final int _valetPrice = 500;
  final int _coffeePrice = 350;

  int get _calculateTotal {
    // Tiers act as price multipliers
    double tierMultiplier = 1.0;
    if (_selectedTier == "Pro") tierMultiplier = 1.5;
    if (_selectedTier == "VIP") tierMultiplier = 2.5;

    double basePrice = (widget.space.price * tierMultiplier) * _durationHours;
    int extras = (_wantsValet ? _valetPrice : 0) + (_coffeePref != "None" ? _coffeePrice : 0);
    return basePrice.toInt() + extras;
  }

  void _requestBooking() {
    List<String> finalRequests = [];
    if (_wantsValet) finalRequests.add("Valet Parking");
    if (_coffeePref != "None") finalRequests.add("Coffee: $_coffeePref");

    final newBooking = BookingModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      spaceName: widget.space.name,
      type: widget.space.type,
      tier: _selectedTier,
      duration: "${_durationHours.toStringAsFixed(1)} Hours",
      date: "Today",
      time: "Right Now",
      requests: finalRequests,
      payment: "Visa ending in 4242",
      review: "",
      totalAmount: _calculateTotal,
      status: "Pending", // Sent to AWAITING APPROVAL!
    );

    globalBookings.value = [newBooking, ...globalBookings.value];
    Navigator.pop(context);
    currentTabNotifier.value = 2; // Jump to "My Spaces"
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking requested! Awaiting approval from the host."), backgroundColor: Colors.orange));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Book ${widget.space.name}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kInk)), const SizedBox(height: 4), Text(widget.space.type, style: const TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.bold))])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: kVolt.withOpacity(0.3), borderRadius: BorderRadius.circular(8)), child: Text("Base LKR ${widget.space.price}/hr", style: const TextStyle(color: kInk, fontWeight: FontWeight.bold, fontSize: 12)))
            ],
          ),
          const SizedBox(height: 24),

          // TIER SELECTION
          const Text("Select Tier", style: TextStyle(fontWeight: FontWeight.bold, color: kInk, fontSize: 14)), const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _tierChip("Basic", 1.0),
              _tierChip("Pro", 1.5),
              _tierChip("VIP", 2.5),
            ],
          ),
          const SizedBox(height: 24),

          const Text("Timeline (Duration)", style: TextStyle(fontWeight: FontWeight.bold, color: kInk, fontSize: 14)), const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(onTap: () { if (_durationHours > 0.5) setState(() => _durationHours -= 0.5); }, child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]), child: const Icon(Icons.remove, color: kInk))),
                Text("${_durationHours.toStringAsFixed(1)} Hours", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kInk)),
                GestureDetector(onTap: () { if (_durationHours < 12.0) setState(() => _durationHours += 0.5); }, child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]), child: const Icon(Icons.add, color: kInk))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text("Add-ons & Preferences", style: TextStyle(fontWeight: FontWeight.bold, color: kInk, fontSize: 14)), const SizedBox(height: 12),
          if (widget.space.hasValet) Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(border: Border.all(color: _wantsValet ? kAcc : Colors.black12), borderRadius: BorderRadius.circular(16), color: _wantsValet ? kAcc.withOpacity(0.05) : Colors.transparent), child: SwitchListTile(activeColor: kAcc, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), title: const Text("Valet Parking", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kInk)), subtitle: Text("+ LKR $_valetPrice flat fee", style: const TextStyle(fontSize: 12, color: kMuted)), secondary: const Icon(Icons.local_parking, color: kMuted), value: _wantsValet, onChanged: (val) => setState(() => _wantsValet = val))) else Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(16)), child: const Row(children: [Icon(Icons.local_parking, color: Colors.black26), SizedBox(width: 12), Text("Valet parking is not available here.", style: TextStyle(color: Colors.black38, fontSize: 13, fontWeight: FontWeight.w500))])),
          const Text("Coffee Request (+ LKR 350)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kMuted)), const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_coffeeChip("None", "❌"), _coffeeChip("Black", "☕"), _coffeeChip("Latte", "🥛"), _coffeeChip("Cap", "☁️")]),
          const SizedBox(height: 30), const Divider(height: 1, color: Colors.black12), const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Total Estimate", style: TextStyle(fontSize: 12, color: kMuted)), Text("LKR ${_calculateTotal.toString()}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kInk))])),
              Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: kInk, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), onPressed: _requestBooking, child: const Text("Request Booking", style: TextStyle(color: kVolt, fontWeight: FontWeight.bold)))),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _tierChip(String tierName, double multiplier) {
    bool isSelected = _selectedTier == tierName;
    return GestureDetector(
      onTap: () => setState(() => _selectedTier = tierName),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
            color: isSelected ? kAcc : Colors.white,
            border: Border.all(color: isSelected ? kAcc : Colors.black12),
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected ? [BoxShadow(color: kAcc.withOpacity(0.3), blurRadius: 8)] : []
        ),
        child: Column(
          children: [
            Text(tierName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : kInk)),
            const SizedBox(height: 4),
            Text("x$multiplier Rate", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white70 : kMuted)),
          ],
        ),
      ),
    );
  }

  Widget _coffeeChip(String type, String icon) {
    bool isSelected = _coffeePref == type;
    return GestureDetector(
      onTap: () => setState(() => _coffeePref = type),
      child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: isSelected ? kInk : Colors.white, border: Border.all(color: isSelected ? kInk : Colors.black12), borderRadius: BorderRadius.circular(14), boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)] : []), child: Column(children: [Text(icon, style: const TextStyle(fontSize: 18)), const SizedBox(height: 4), Text(type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? kVolt : kMuted))])),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SHARED UI COMPONENTS (GLASSMORPHISM, CARDS, PINS)
// ════════════════════════════════════════════════════════════════════════════

class GlassMapCard extends StatelessWidget {
  final SpaceData space;
  const GlassMapCard({super.key, required this.space});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(space.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kInk), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Text("${space.address} • ${space.distance}", style: const TextStyle(fontSize: 11, color: kMuted))])),
                  Row(children: [const Icon(Icons.star, color: Colors.orange, size: 14), const SizedBox(width: 4), Text(space.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text(" (${space.reviews})", style: const TextStyle(color: kMuted, fontSize: 10))]),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _glassChip(space.status, color: space.status == "Open now" ? Colors.green : Colors.orange), const SizedBox(width: 6),
                  _glassChip("8am - 8pm", color: kMuted), const SizedBox(width: 6),
                  Expanded(child: _glassChip(space.amenities.take(2).join(" • "), color: kMuted)),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(width: 60, height: 50, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: space.gradient))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Starting from", style: TextStyle(fontSize: 9, color: kMuted)), Text("LKR ${space.price}/hr", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kAcc))])),
                  Row(children: [_actionButton(Icons.directions, "Directions", false), const SizedBox(width: 6), _actionButton(Icons.arrow_forward, "View", true)])
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassChip(String text, {required Color color}) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white)), child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis));
  }

  Widget _actionButton(IconData icon, String label, bool isPrimary) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: isPrimary ? kAcc : Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(12), border: Border.all(color: isPrimary ? kAcc : Colors.white)), child: Row(children: [Icon(icon, size: 12, color: isPrimary ? Colors.white : kInk), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isPrimary ? Colors.white : kInk))]));
  }
}

class LargeGlassSpaceCard extends StatelessWidget {
  final SpaceData space;
  const LargeGlassSpaceCard({super.key, required this.space});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(colors: space.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))]),
      child: Stack(
        children: [
          Positioned.fill(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.7)])))),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2)))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(space.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: kVolt, borderRadius: BorderRadius.circular(12)), child: Text("LKR ${space.price}/hr", style: const TextStyle(color: kInk, fontSize: 11, fontWeight: FontWeight.w900)))]),
                      const SizedBox(height: 6), Text("${space.type} • ${space.amenities.join(' • ')}", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)), const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.3))), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.directions, color: Colors.white, size: 14), SizedBox(width: 6), Text("Directions", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))]))),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                                    builder: (context) => CreateBookingSheet(space: space)
                                );
                              },
                              child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: kAcc, borderRadius: BorderRadius.circular(12)), child: const Center(child: Text("Book Space", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UnselectedMapPin extends StatelessWidget {
  final String price;
  const UnselectedMapPin({super.key, required this.price});
  @override
  Widget build(BuildContext context) {
    return Column(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))]), child: Text("LKR $price", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: kInk)))]);
  }
}

class SelectedMapPin extends StatelessWidget {
  final String name;
  const SelectedMapPin({super.key, required this.name});
  @override
  Widget build(BuildContext context) {
    return Column(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: kAcc, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: kAcc.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))]), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), const SizedBox(width: 6), Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.white))]))]);
  }
}

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  const FloatingNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70, padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: kInk, borderRadius: BorderRadius.circular(35), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.map_rounded, "Map", 0), _navItem(Icons.search, "Explore", 1),
          _navItem(Icons.meeting_room, "My Spaces", 2), _navItem(Icons.person, "Profile", 3), // Renamed & changed icon!
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index), behavior: HitTestBehavior.opaque,
      child: SizedBox(width: 60, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: isActive ? kVolt : Colors.white54, size: 26), const SizedBox(height: 4), Text(label, style: TextStyle(color: isActive ? kVolt : Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))])),
    );
  }
}

class TopSearchBar extends StatelessWidget {
  const TopSearchBar({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15), height: 55, decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20)]),
      child: Row(children: [IconButton(onPressed: () => Scaffold.of(context).openDrawer(), icon: const Icon(Icons.menu, color: kInk)), const Expanded(child: Text("Where to work?", style: TextStyle(color: Colors.grey, fontSize: 16))), const VerticalDivider(indent: 15, endIndent: 15, color: Colors.black12), const Icon(Icons.tune, color: kInk)]),
    );
  }
}

class UserLocationDot extends StatelessWidget {
  const UserLocationDot({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(decoration: BoxDecoration(color: const Color(0xFF5B5BFF), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)]));
  }
}

class HotspotDrawer extends StatelessWidget {
  const HotspotDrawer({super.key});
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const UserAccountsDrawerHeader(decoration: BoxDecoration(color: kInk), currentAccountPicture: CircleAvatar(backgroundColor: kVolt, child: Text("WF", style: TextStyle(color: kInk, fontWeight: FontWeight.bold))), accountName: Text("Wishvi Fernando", style: TextStyle(fontWeight: FontWeight.bold)), accountEmail: Text("wishvifernando410@gmail.com", style: TextStyle(color: Colors.white54))),
          const ListTile(leading: Icon(Icons.map), title: Text("Map")), const ListTile(leading: Icon(Icons.meeting_room), title: Text("My Spaces")),
          const Spacer(), const ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text("Log out", style: TextStyle(color: Colors.red))), const SizedBox(height: 20),
        ],
      ),
    );
  }
}