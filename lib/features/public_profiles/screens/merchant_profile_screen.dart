import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/widgets/optimized_image.dart';
import 'package:share_plus/share_plus.dart';

// ✅ 1. استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

import '../../../features/shared/widgets/product_card.dart';
import '../../../models/public_profile_models.dart';
import '../services/public_profile_service.dart';

class MerchantProfileScreen extends StatefulWidget {
  final String merchantId;

  const MerchantProfileScreen({Key? key, required this.merchantId})
    : super(key: key);

  @override
  State<MerchantProfileScreen> createState() => _MerchantProfileScreenState();
}

class _MerchantProfileScreenState extends State<MerchantProfileScreen> {
  final PublicProfileService _service = PublicProfileService();
  PublicMerchantProfile? _merchant;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _service.getMerchantProfile(widget.merchantId);
      if (mounted) {
        setState(() {
          _merchant = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFollow() async {
    if (_merchant == null) return;
    setState(() {
      _merchant!.isFollowedByMe = !_merchant!.isFollowedByMe;
    });
    try {
      await _service.toggleFollow(_merchant!.id, !_merchant!.isFollowedByMe);
    } catch (e) {
      setState(() {
        _merchant!.isFollowedByMe = !_merchant!.isFollowedByMe;
      });
    }
  }

  // ✅ تمرير l10n للترجمة
  void _shareProfile(AppLocalizations l10n) {
    if (_merchant == null) return;
    final String profileUrl = "https://linyora.com/store/${_merchant!.id}";
    final String shareText =
        "${l10n.shareStoreIntro}${_merchant!.storeName}${l10n.shareStoreMid}$profileUrl";
    Share.share(
      shareText,
      subject: "${_merchant!.storeName} ${l10n.shareStoreSubject}",
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_merchant == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.storeNotFound)), // ✅ مترجم
      );
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 4 : 2);
    double childAspectRatio = screenWidth > 600 ? 0.55 : 0.55;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background:
                  _merchant!.coverUrl != null && _merchant!.coverUrl!.isNotEmpty
                      ? CachedNetworkImage(
                        imageUrl: _merchant!.coverUrl!,
                        fit: BoxFit.cover,
                        errorWidget:
                            (context, url, error) =>
                                Container(color: Colors.grey[300]),
                      )
                      : Container(color: Colors.grey[300]),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.translate(
                    offset: const Offset(0, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.grey[200],
                                backgroundImage:
                                    _merchant!.profilePictureUrl != null &&
                                            _merchant!
                                                .profilePictureUrl!
                                                .isNotEmpty
                                        ? CachedNetworkImageProvider(
                                          _merchant!.profilePictureUrl!,
                                        )
                                        : null,
                                child:
                                    (_merchant!.profilePictureUrl == null ||
                                            _merchant!
                                                .profilePictureUrl!
                                                .isEmpty)
                                        ? Text(
                                          _merchant!.storeName.isNotEmpty
                                              ? _merchant!.storeName[0]
                                                  .toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                        : null,
                              ),
                            ),
                            const Positioned(
                              bottom: 5,
                              right: 5,
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.blue,
                                child: Icon(
                                  Icons.store,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: _handleFollow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _merchant!.isFollowedByMe
                                        ? Colors.grey[200]
                                        : const Color(0xFFF105C6),
                                foregroundColor:
                                    _merchant!.isFollowedByMe
                                        ? Colors.black
                                        : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                _merchant!.isFollowedByMe
                                    ? l10n.followingBtn
                                    : l10n.followBtn, // ✅ مترجم
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: IconButton(
                                onPressed:
                                    () =>
                                        _shareProfile(l10n), // ✅ تمرير الترجمة
                                icon: const Icon(
                                  Icons.share_outlined,
                                  size: 20,
                                ),
                                color: Colors.black87,
                                tooltip: l10n.shareStoreTooltip, // ✅ مترجم
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Text(
                    _merchant!.storeName.isNotEmpty
                        ? _merchant!.storeName
                        : l10n.defaultMerchantName, // ✅ مترجم
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    children: [
                      _buildBadge(
                        Icons.verified,
                        l10n.verifiedMerchantBadge,
                        Colors.blue,
                      ), // ✅ مترجم
                      _buildBadge(
                        Icons.star,
                        "${l10n.ratingBadge} ${_merchant!.rating}",
                        Colors.orange,
                      ), // ✅ مترجم
                      _buildBadge(
                        Icons.local_shipping,
                        l10n.fastDeliveryBadge,
                        Colors.green,
                      ), // ✅ مترجم
                    ],
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStat(
                          l10n.followersStat,
                          _merchant!.followersCount,
                        ), // ✅ مترجم
                        _buildVerticalDivider(),
                        _buildStat(
                          l10n.followingStat,
                          _merchant!.followingCount,
                        ), // ✅ مترجم
                        _buildVerticalDivider(),
                        _buildStat(
                          l10n.productsStat,
                          _merchant!.postsCount,
                        ), // ✅ مترجم
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_merchant!.bio != null && _merchant!.bio!.isNotEmpty)
                    Text(
                      _merchant!.bio!,
                      style: TextStyle(color: Colors.grey[700], height: 1.5),
                    ),

                  const SizedBox(height: 16),

                  if (_merchant!.location != null &&
                      _merchant!.location!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _merchant!.location!,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),

                  const SizedBox(height: 1),
                  Text(
                    l10n.productsHeader, // ✅ مترجم
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver:
                _merchant!.products.isEmpty
                    ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(l10n.noProductsAvailable),
                        ), // ✅ مترجم
                      ),
                    )
                    : SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: childAspectRatio,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return ProductCard(product: _merchant!.products[index]);
                      }, childCount: _merchant!.products.length),
                    ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int value) {
    return Column(
      children: [
        Text(
          "$value",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 20, width: 1, color: Colors.grey[300]);
  }
}
