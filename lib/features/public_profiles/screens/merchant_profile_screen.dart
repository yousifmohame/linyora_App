import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/widgets/optimized_image.dart';
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_merchant == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("المتجر غير موجود")),
      );
    }

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
                  // Avatar & Verification
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
                                              : '?', // حرف بديل في حال كان الاسم فارغاً
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
                        // Action Buttons
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
                                _merchant!.isFollowedByMe ? "أتابعه" : "متابعة",
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.share),
                              style: IconButton.styleFrom(
                                side: const BorderSide(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Store Info
                  Text(
                    _merchant!.storeName.isNotEmpty
                        ? _merchant!.storeName
                        : "تاجر",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Badges
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildBadge(Icons.verified, "تاجر معتمد", Colors.blue),
                      _buildBadge(
                        Icons.star,
                        "تقييم ${_merchant!.rating}",
                        Colors.orange,
                      ),
                      _buildBadge(
                        Icons.local_shipping,
                        "توصيل سريع",
                        Colors.green,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Stats Grid
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
                        _buildStat("متابع", _merchant!.followersCount),
                        _buildVerticalDivider(),
                        _buildStat("يتابع", _merchant!.followingCount),
                        _buildVerticalDivider(),
                        _buildStat("منتجات", _merchant!.postsCount),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bio
                  if (_merchant!.bio != null && _merchant!.bio!.isNotEmpty)
                    Text(
                      _merchant!.bio!,
                      style: TextStyle(color: Colors.grey[700], height: 1.5),
                    ),

                  const SizedBox(height: 16),

                  // Location
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
                  const Text(
                    "المنتجات",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Products Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver:
                _merchant!.products.isEmpty
                    ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(child: Text("لا توجد منتجات")),
                      ),
                    )
                    : SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio:
                                0.55, // تعديل النسبة لتناسب الكروت
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return ProductCard(product: _merchant!.products[index]);
                      }, childCount: _merchant!.products.length),
                    ),
          ),

          // مسافة سفلية إضافية
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
