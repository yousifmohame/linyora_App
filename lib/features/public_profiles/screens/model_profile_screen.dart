import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:linyora_project/features/reels/screens/model_reels_viewer.dart';
import 'package:linyora_project/features/shared/widgets/full_screen_image_viewer.dart';
import 'package:url_launcher/url_launcher.dart';

// ✅ استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

import '../../../models/public_profile_models.dart';
import '../services/public_profile_service.dart';
import 'package:share_plus/share_plus.dart';

class ModelProfileScreen extends StatefulWidget {
  final String modelId;

  const ModelProfileScreen({Key? key, required this.modelId}) : super(key: key);

  @override
  State<ModelProfileScreen> createState() => _ModelProfileScreenState();
}

class _ModelProfileScreenState extends State<ModelProfileScreen>
    with SingleTickerProviderStateMixin {
  final PublicProfileService _service = PublicProfileService();
  PublicModelProfile? _modelData;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _service.getModelProfile(widget.modelId);
      setState(() {
        _modelData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFollow() async {
    if (_modelData == null) return;
    final newState = !_modelData!.profile.isFollowedByMe;

    setState(() {
      _modelData!.profile.isFollowedByMe = newState;
    });

    try {
      await _service.toggleFollow(_modelData!.profile.id, !newState);
    } catch (e) {
      setState(() {
        _modelData!.profile.isFollowedByMe = !newState;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_modelData == null)
      return Scaffold(body: Center(child: Text(l10n.userNotFound))); // ✅ مترجم

    final profile = _modelData!.profile;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background:
                    profile.coverUrl != null
                        ? CachedNetworkImage(
                          imageUrl: profile.coverUrl!,
                          fit: BoxFit.cover,
                        )
                        : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFF3E5F5), Color(0xFFFCE4EC)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Transform.translate(
                      offset: const Offset(0, 0),
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage:
                                  profile.profilePictureUrl != null
                                      ? CachedNetworkImageProvider(
                                        profile.profilePictureUrl!,
                                      )
                                      : null,
                              child:
                                  profile.profilePictureUrl == null
                                      ? Text(
                                        profile.name.isNotEmpty
                                            ? profile.name[0]
                                            : 'U',
                                        style: const TextStyle(fontSize: 30),
                                      )
                                      : null,
                            ),
                          ),
                          if (profile.isVerified)
                            const Positioned(
                              bottom: 5,
                              right: 5,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.blue,
                                child: Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        profile.roleName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          l10n.followersStat,
                          "${profile.stats.followers + profile.followersCount}",
                        ), // ✅ مترجم
                        _buildStatItem(
                          l10n.reelsTab,
                          "${_modelData!.reels.length}",
                        ), // ✅ مترجم
                        _buildStatItem(
                          l10n.servicesTab,
                          "${_modelData!.services.length + _modelData!.offers.length}",
                        ), // ✅ مترجم
                      ],
                    ),

                    const SizedBox(height: 20),

                    if (profile.bio != null)
                      Text(
                        profile.bio!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700], height: 1.5),
                      ),

                    const SizedBox(height: 20),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (profile.socialLinks.instagram != null &&
                              profile.socialLinks.instagram!.isNotEmpty)
                            _buildSocialBtn(
                              FontAwesomeIcons.instagram,
                              const Color(0xFFC13584),
                              profile.socialLinks.instagram!,
                            ),

                          if (profile.socialLinks.twitter != null &&
                              profile.socialLinks.twitter!.isNotEmpty)
                            _buildSocialBtn(
                              FontAwesomeIcons.xTwitter,
                              Colors.black,
                              profile.socialLinks.twitter!,
                            ),

                          if (profile.socialLinks.tiktok != null &&
                              profile.socialLinks.tiktok!.isNotEmpty)
                            _buildSocialBtn(
                              FontAwesomeIcons.tiktok,
                              Colors.black,
                              profile.socialLinks.tiktok!,
                            ),

                          if (profile.socialLinks.snapchat != null &&
                              profile.socialLinks.snapchat!.isNotEmpty)
                            _buildSocialBtn(
                              FontAwesomeIcons.snapchat,
                              const Color(0xFFFFFC00),
                              profile.socialLinks.snapchat!,
                              iconColor: Colors.black,
                            ),

                          if (profile.socialLinks.youtube != null &&
                              profile.socialLinks.youtube!.isNotEmpty)
                            _buildSocialBtn(
                              FontAwesomeIcons.youtube,
                              const Color(0xFFFF0000),
                              profile.socialLinks.youtube!,
                            ),

                          if (profile.socialLinks.facebook != null &&
                              profile.socialLinks.facebook!.isNotEmpty)
                            _buildSocialBtn(
                              FontAwesomeIcons.facebook,
                              const Color(0xFF1877F2),
                              profile.socialLinks.facebook!,
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleFollow,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  profile.isFollowedByMe
                                      ? Colors.grey[200]
                                      : const Color(0xFFF105C6),
                              foregroundColor:
                                  profile.isFollowedByMe
                                      ? Colors.black
                                      : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              profile.isFollowedByMe
                                  ? l10n.unfollowBtn
                                  : l10n.followBtn, // ✅ مترجم
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.share_outlined),
                            onPressed: () {
                              final String profileUrl =
                                  "https://linyora.com/profile/${profile.id}";
                              final String shareText =
                                  "${l10n.shareProfileIntro}${profile.name}${l10n.shareProfileMid}$profileUrl"; // ✅ مترجم
                              Share.share(
                                shareText,
                                subject:
                                    "${profile.name} ${l10n.shareProfileSubject}",
                              ); // ✅ مترجم
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFFF105C6),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFFF105C6),
                  tabs: [
                    Tab(
                      text: l10n.portfolioTab,
                      icon: const Icon(Icons.grid_on),
                    ), // ✅ مترجم
                    Tab(
                      text: l10n.reelsTab,
                      icon: const Icon(Icons.video_collection),
                    ), // ✅ مترجم
                    Tab(
                      text: l10n.servicesTab,
                      icon: const Icon(Icons.shopping_bag),
                    ), // ✅ مترجم
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPortfolioGrid(profile.portfolio, l10n), // ✅ تمرير l10n
            _buildReelsGrid(l10n), // ✅ تمرير l10n
            _buildServicesList(l10n), // ✅ تمرير l10n
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildSocialBtn(
    IconData icon,
    Color bgColor,
    String url, {
    Color iconColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(url)),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: bgColor.withOpacity(0.3),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: FaIcon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }

  Widget _buildPortfolioGrid(List<String> images, AppLocalizations l10n) {
    if (images.isEmpty) return Center(child: Text(l10n.noImagesMsg)); // ✅ مترجم
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => FullScreenImageViewer(
                      images: images,
                      initialIndex: index,
                    ),
              ),
            );
          },
          child: Hero(
            tag: 'portfolio_$index',
            child: CachedNetworkImage(
              imageUrl: images[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[200]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReelsGrid(AppLocalizations l10n) {
    if (_modelData!.reels.isEmpty)
      return Center(child: Text(l10n.noReelsMsg)); // ✅ مترجم

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 9 / 16,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _modelData!.reels.length,
      itemBuilder: (context, index) {
        final reel = _modelData!.reels[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ModelReelsViewer(
                      reels: _modelData!.reels,
                      initialIndex: index,
                    ),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              reel.thumbnailUrl != null
                  ? CachedNetworkImage(
                    imageUrl: reel.thumbnailUrl!,
                    fit: BoxFit.cover,
                  )
                  : Container(color: Colors.black),
              const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServicesList(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._modelData!.services.map(
          (s) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                s.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(s.description, maxLines: 2),
              trailing: Text(
                "${s.startingPrice} ${l10n.currencySAR}", // ✅ عملة مترجمة
                style: const TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        ..._modelData!.offers.map(
          (o) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: Colors.purple[50],
            child: ListTile(
              title: Text(
                o.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(o.description),
              trailing: Text(
                "${o.price} ${l10n.currencySAR}", // ✅ عملة مترجمة
                style: const TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
