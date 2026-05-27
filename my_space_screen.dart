import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/space_model.dart';
import 'space_detail_screen.dart';

class MySpaceScreen extends StatefulWidget {
  const MySpaceScreen({super.key});

  @override
  State<MySpaceScreen> createState() => _MySpaceScreenState();
}

class _MySpaceScreenState extends State<MySpaceScreen> {
  final _supabase = Supabase.instance.client;
  final PageController _pageCtrl =
  PageController(viewportFraction: 1.0);

  List<Map<String, dynamic>> _communities = [];
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  bool _isPostsLoading = false;
  int _currentPage = 0;

  // ── BACKEND (all unchanged) ───────────────────

  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCommunities() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final res = await _supabase
          .from('community_members')
          .select('''
            *,
            spaces(
              id, name, address, image_url,
              average_rating, total_reviews,
              opening_time, closing_time
            )
          ''')
          .eq('user_id', userId)
          .order('joined_at', ascending: false);

      final communities = List<Map<String, dynamic>>.from(res);

      for (int i = 0; i < communities.length; i++) {
        final spaceId =
        communities[i]['spaces']['id'] as String;
        final countRes = await _supabase
            .from('community_members')
            .select('id')
            .eq('space_id', spaceId);
        final postRes = await _supabase
            .from('community_posts')
            .select('id')
            .eq('space_id', spaceId);
        communities[i]['member_count'] =
            (countRes as List).length;
        communities[i]['post_count'] =
            (postRes as List).length;
      }

      setState(() {
        _communities = communities;
        _isLoading = false;
      });

      if (communities.isNotEmpty) {
        _loadPosts(communities[0]['spaces']['id']);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Load communities error: $e');
    }
  }

  Future<void> _loadPosts(String spaceId) async {
    setState(() => _isPostsLoading = true);
    try {
      final res = await _supabase
          .from('community_posts')
          .select()
          .eq('space_id', spaceId)
          .order('created_at', ascending: false);
      setState(() {
        _posts = List<Map<String, dynamic>>.from(res);
        _isPostsLoading = false;
      });
    } catch (e) {
      setState(() => _isPostsLoading = false);
    }
  }

  Future<void> _leaveSpace(String spaceId) async {
    final confirmed = await _showLeaveSheet();
    if (confirmed != true) return;
    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase
          .from('community_members')
          .delete()
          .eq('user_id', userId)
          .eq('space_id', spaceId);
      _loadCommunities();
      if (mounted) _snack('Left community');
    } catch (e) {
      debugPrint('Leave error: $e');
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.inter(
              color: isError ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600)),
      backgroundColor: isError
          ? const Color(0xFFEF4444)
          : const Color(0xFFDEFF6E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<bool?> _showLeaveSheet() async {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding:
        const EdgeInsets.fromLTRB(24, 16, 24, 40),
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
            const SizedBox(height: 20),
            Text('Leave Community?',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3)),
            const SizedBox(height: 6),
            Text(
                'You will no longer receive posts or '
                    'updates from this space.',
                style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 13,
                    height: 1.5)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      Navigator.pop(context, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    decoration: BoxDecoration(
                      color:
                      Colors.white.withOpacity(0.06),
                      borderRadius:
                      BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white
                              .withOpacity(0.08)),
                    ),
                    child: Center(
                      child: Text('Stay',
                          style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight:
                              FontWeight.w600)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      Navigator.pop(context, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444)
                          .withOpacity(0.12),
                      borderRadius:
                      BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFEF4444)
                              .withOpacity(0.4)),
                    ),
                    child: Center(
                      child: Text('Leave',
                          style: GoogleFonts.inter(
                              color:
                              const Color(0xFFEF4444),
                              fontSize: 14,
                              fontWeight:
                              FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _navigateToSpace(Map<String, dynamic> space) {
    final spaceModel = SpaceModel(
      id: space['id'],
      name: space['name'] ?? '',
      description: '',
      address: space['address'] ?? '',
      latitude: 0,
      longitude: 0,
      amenities: [],
      operatingDays: [],
      openingTime: space['opening_time'],
      closingTime: space['closing_time'],
      isActive: true,
      isVerified: true,
      averageRating:
      (space['average_rating'] as num?)?.toDouble() ?? 0,
      totalReviews: space['total_reviews'] as int? ?? 0,
      imageUrl: space['image_url'],
      galleryImages: [],
    );
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => SpaceDetailScreen(space: spaceModel)),
    );
  }

  // ── BUILD ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(
              color: Color(0xFFDEFF6E), strokeWidth: 2))
          : _communities.isEmpty
          ? _buildEmpty(topPad)
          : RefreshIndicator(
        onRefresh: _loadCommunities,
        color: const Color(0xFFDEFF6E),
        backgroundColor: const Color(0xFF1C1C1E),
        child: CustomScrollView(
          slivers: [

            // ── Header ──────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    20, topPad + 16, 20, 20),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text('My Spaces',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight:
                                FontWeight.w800,
                                letterSpacing: -0.5)),
                        Text(
                            '${_communities.length} communit${_communities.length == 1 ? 'y' : 'ies'} joined',
                            style: GoogleFonts.inter(
                                color: Colors.white38,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ]),
              ),
            ),

            // ── Deck of cards ────────────
            SliverToBoxAdapter(
              child: Column(children: [
                _buildDeck(),
                const SizedBox(height: 12),

                // Dot indicators
                if (_communities.length > 1)
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: List.generate(
                      _communities.length,
                          (i) => AnimatedContainer(
                        duration: const Duration(
                            milliseconds: 220),
                        margin:
                        const EdgeInsets.symmetric(
                            horizontal: 3),
                        width: _currentPage == i
                            ? 22
                            : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? const Color(0xFFDEFF6E)
                              : Colors.white
                              .withOpacity(0.2),
                          borderRadius:
                          BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // ✅ Lime Book button
                if (_communities.isNotEmpty)
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(
                        horizontal: 20),
                    child: _buildBookButton(),
                  ),

                const SizedBox(height: 28),

                // Community feed header
                Padding(
                  padding:
                  const EdgeInsets.symmetric(
                      horizontal: 20),
                  child: Row(children: [
                    Text('Community Feed',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight:
                            FontWeight.w700)),
                    const Spacer(),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withOpacity(0.06),
                        borderRadius:
                        BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white
                                .withOpacity(0.08)),
                      ),
                      child: Text(
                          '${_posts.length} post${_posts.length == 1 ? '' : 's'}',
                          style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 11,
                              fontWeight:
                              FontWeight.w600)),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
              ]),
            ),

            // ── Posts ────────────────────
            if (_isPostsLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                        color: Color(0xFFDEFF6E),
                        strokeWidth: 2),
                  ),
                ),
              )
            else if (_posts.isEmpty)
              SliverToBoxAdapter(
                  child: _buildNoPosts())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                    padding:
                    const EdgeInsets.fromLTRB(
                        20, 0, 20, 12),
                    child: _buildPostCard(_posts[i]),
                  ),
                  childCount: _posts.length,
                ),
              ),

            const SliverToBoxAdapter(
                child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ── Deck of cards ─────────────────────────────

  Widget _buildDeck() {
    final remaining =
        _communities.length - _currentPage - 1;

    return SizedBox(
      height: 300,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [

          // ── Ghost card 3 (furthest back) ──────
          if (remaining >= 2)
            Positioned(
              top: 20,
              left: 36,
              right: 36,
              child: Container(
                height: 260,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.05)),
                ),
                clipBehavior: Clip.antiAlias,
                child: BackdropFilter(
                  filter:
                  ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),
            ),

          // ── Ghost card 2 (one behind) ─────────
          if (remaining >= 1)
            Positioned(
              top: 10,
              left: 20,
              right: 20,
              child: Container(
                height: 268,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.08)),
                ),
                clipBehavior: Clip.antiAlias,
                child: BackdropFilter(
                  filter:
                  ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
            ),

          // ── Actual PageView (front) ───────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SizedBox(
              height: 278,
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _communities.length,
                onPageChanged: (i) {
                  setState(() => _currentPage = i);
                  _loadPosts(
                      _communities[i]['spaces']['id']);
                },
                itemBuilder: (_, i) =>
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20),
                      child: _buildCommunityCard(
                          _communities[i]),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Community card ────────────────────────────

  Widget _buildCommunityCard(
      Map<String, dynamic> community) {
    final space =
    community['spaces'] as Map<String, dynamic>;
    final memberCount =
        community['member_count'] as int? ?? 0;
    final postCount =
        community['post_count'] as int? ?? 0;
    final rating =
        (space['average_rating'] as num?)?.toDouble() ?? 0;
    final imageUrl = space['image_url'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: Colors.white.withOpacity(0.07)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(fit: StackFit.expand, children: [

        // Hero image
        imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _imgFallback())
            : _imgFallback(),

        // Gradient bleed
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x33000000),
                Color(0x00000000),
                Color(0xCC1C1C1E),
                Color(0xFF1C1C1E),
              ],
              stops: [0.0, 0.2, 0.68, 1.0],
            ),
          ),
        ),

        // Leave pill — top right
        Positioned(
          top: 12, right: 12,
          child: GestureDetector(
            onTap: () =>
                _leaveSpace(space['id'] as String),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                    Colors.black.withOpacity(0.35),
                    borderRadius:
                    BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white
                            .withOpacity(0.18)),
                  ),
                  child: Text('Leave',
                      style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ),

        // Bottom: name + stats
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                16, 0, 16, 14),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(space['name'] ?? '',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),

                // ✅ Instagram-style stat blocks
                Row(children: [
                  _statBlock(
                    _formatCount(memberCount),
                    'Members',
                  ),
                  _statDivider(),
                  _statBlock(
                    '$postCount',
                    'Posts',
                  ),
                  _statDivider(),
                  _statBlock(
                    rating.toStringAsFixed(1),
                    'Rating',
                    isRating: true,
                  ),
                ]),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _statBlock(String value, String label,
      {bool isRating = false}) {
    return Expanded(
      child: Column(
        children: [
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: value,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5),
              ),
              if (isRating)
                TextSpan(
                  text: ' ★',
                  style: GoogleFonts.inter(
                      color: const Color(0xFFFBBF24),
                      fontSize: 13),
                ),
            ]),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(
    width: 1,
    height: 32,
    color: Colors.white.withOpacity(0.12),
  );

  String _formatCount(int n) {
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    } else if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}k';
    }
    return '$n';
  }

  // ── Lime book button ──────────────────────────

  Widget _buildBookButton() {
    if (_communities.isEmpty) return const SizedBox();
    final space = _communities[_currentPage]['spaces']
    as Map<String, dynamic>;

    return GestureDetector(
      onTap: () => _navigateToSpace(space),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFDEFF6E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color:
                const Color(0xFFDEFF6E).withOpacity(0.2),
                blurRadius: 16),
          ],
        ),
        child: Center(
          child: Text(
            'Book at ${space['name'] ?? ''}',
            style: GoogleFonts.inter(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2),
          ),
        ),
      ),
    );
  }

  // ── Post card ─────────────────────────────────

  Widget _buildPostCard(Map<String, dynamic> post) {
    final isEvent = post['type'] == 'event';
    final hasImage = post['image_url'] != null &&
        (post['image_url'] as String).isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: Colors.white.withOpacity(0.07)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post image
          if (hasImage)
            Image.network(
              post['image_url'],
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
              const SizedBox(),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [

                // Type badge + date row
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isEvent
                          ? const Color(0xFFDEFF6E)
                          .withOpacity(0.1)
                          : Colors.white.withOpacity(0.06),
                      borderRadius:
                      BorderRadius.circular(20),
                      border: Border.all(
                        color: isEvent
                            ? const Color(0xFFDEFF6E)
                            .withOpacity(0.35)
                            : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Text(
                      isEvent ? 'Event' : 'Announcement',
                      style: GoogleFonts.inter(
                          color: isEvent
                              ? const Color(0xFFDEFF6E)
                              : Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(
                        post['created_at'] as String),
                    style: GoogleFonts.inter(
                        color: Colors.white24,
                        fontSize: 11),
                  ),
                ]),
                const SizedBox(height: 10),

                // Title
                Text(post['title'] ?? '',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const SizedBox(height: 6),

                // Body
                Text(post['body'] ?? '',
                    style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 13,
                        height: 1.5)),

                // Event date/time pill
                if (isEvent &&
                    post['event_date'] != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDEFF6E)
                          .withOpacity(0.07),
                      borderRadius:
                      BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFDEFF6E)
                              .withOpacity(0.25)),
                    ),
                    child: Row(children: [
                      Text(post['event_date'] ?? '',
                          style: GoogleFonts.inter(
                              color:
                              const Color(0xFFDEFF6E),
                              fontSize: 12,
                              fontWeight:
                              FontWeight.w600)),
                      if (post['event_time'] != null) ...[
                        Text('  ·  ',
                            style: GoogleFonts.inter(
                                color: Colors.white24,
                                fontSize: 12)),
                        Text(
                          post['event_time']
                              .toString()
                              .substring(0, 5),
                          style: GoogleFonts.inter(
                              color:
                              const Color(0xFFDEFF6E),
                              fontSize: 12,
                              fontWeight:
                              FontWeight.w600),
                        ),
                      ],
                    ]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty / no posts ──────────────────────────

  Widget _buildEmpty(double topPad) {
    return Column(children: [
      SizedBox(height: topPad + 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('My Spaces',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
        ),
      ),
      Expanded(
        child: Center(
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32, height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEFF6E)
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text('No communities yet',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3)),
                const SizedBox(height: 8),
                Text(
                    'Join a space community from\nthe Explore tab',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 14,
                        height: 1.5)),
              ],
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildNoPosts() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(children: [
          Container(
            width: 32, height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text('No posts yet',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
              'The space admin hasn\'t posted anything yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 13,
                  height: 1.4)),
        ]),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  Widget _imgFallback() => Container(
    color: Colors.white.withOpacity(0.04),
  );
}