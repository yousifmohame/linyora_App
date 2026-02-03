import 'dart:async';
import 'dart:ui'; // ضروري للتأثير الزجاجي
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:linyora_project/core/utils/event_bus.dart';
import '../../../models/top_user_model.dart';
import '../services/home_service.dart';
import '../../public_profiles/screens/model_profile_screen.dart';
import '../../public_profiles/screens/merchant_profile_screen.dart';

class TopUserCard extends StatefulWidget {
  final TopUserModel user;
  final bool isModel;

  const TopUserCard({super.key, required this.user, this.isModel = true});

  @override
  State<TopUserCard> createState() => _TopUserCardState();
}

class _TopUserCardState extends State<TopUserCard>
    with SingleTickerProviderStateMixin {
  late bool isFollowed;
  final HomeService _homeService = HomeService();
  StreamSubscription? _subscription;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    isFollowed = widget.user.isFollowed;

    _subscription = GlobalEventBus.stream.listen((event) {
      if (event.userId == widget.user.id) {
        if (mounted) {
          setState(() {
            isFollowed = event.isFollowed;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _toggleFollow() async {
    setState(() => _scale = 0.90);
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() => _scale = 1.0);

    final newStatus = !isFollowed;
    setState(() => isFollowed = newStatus);
    GlobalEventBus.sendEvent(widget.user.id, newStatus);

    final success = await _homeService.toggleFollow(widget.user.id);

    if (!success && mounted) {
      setState(() => isFollowed = !newStatus);
      GlobalEventBus.sendEvent(widget.user.id, !newStatus);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Connection error")));
    }
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                widget.isModel
                    ? ModelProfileScreen(modelId: widget.user.id.toString())
                    : MerchantProfileScreen(
                      merchantId: widget.user.id.toString(),
                    ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // الألوان بناءً على النوع
    final gradientColors =
        widget.isModel
            ? [const Color(0xFFC026D3), const Color(0xFF4F46E5)] // بنفسجي لأزرق
            : [const Color(0xFF2563EB), const Color(0xFF06B6D4)]; // أزرق لسماوي

    return GestureDetector(
      onTap: _navigateToProfile,
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Container(
          width: 160, // عرض أكبر قليلاً
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          // 1. الإطار الخارجي المتدرج (The Glowing Border)
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors:
                  isFollowed
                      ? [Colors.grey.shade300, Colors.grey.shade400]
                      : gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    isFollowed
                        ? Colors.black.withOpacity(0.05)
                        : gradientColors[0].withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(2.0), // سمك الإطار
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    // 2. الصورة الكاملة (Full Image Background)
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: widget.user.imageUrl,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              color: Colors.grey[100],
                              child: const Center(
                                child: Icon(Icons.image, color: Colors.grey),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.person),
                            ),
                      ),
                    ),

                    // 3. طبقة تظليل علوية للتقييم
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 4. شارة التقييم (Top Left)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${widget.user.rating}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 5. المعلومات السفلية (Glassmorphism Effect)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(22),
                          bottomRight: Radius.circular(22),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              border: Border(
                                top: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // الاسم
                                Text(
                                  widget.user.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // النوع
                                Text(
                                  widget.isModel
                                      ? "أشهر عارضه ✨"
                                      : "المتجر الرسمي ✓",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // زر المتابعة
                                SizedBox(
                                  height: 30,
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _toggleFollow,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          isFollowed
                                              ? Colors.white.withOpacity(0.2)
                                              : Colors.white,
                                      foregroundColor:
                                          isFollowed
                                              ? Colors.white
                                              : Colors.black,
                                      elevation: 0,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child:
                                        isFollowed
                                            ? const Text(
                                              "متابع",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                            : ShaderMask(
                                              shaderCallback:
                                                  (bounds) => LinearGradient(
                                                    colors: gradientColors,
                                                  ).createShader(bounds),
                                              child: const Text(
                                                "متابعة +",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
