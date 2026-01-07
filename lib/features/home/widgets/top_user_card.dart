import 'dart:async'; // 1. إضافة مكتبة async
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

  // 2. متغير للاشتراك في الأحداث
  StreamSubscription? _subscription;

  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    isFollowed = widget.user.isFollowed;

    // 3. الاشتراك في الاستماع للتغييرات العامة
    _subscription = GlobalEventBus.stream.listen((event) {
      // إذا كان الحدث يخص هذا المستخدم تحديداً
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
    // 4. إلغاء الاشتراك عند إغلاق الويتجت لمنع تسريب الذاكرة
    _subscription?.cancel();
    super.dispose();
  }

  void _toggleFollow() async {
    setState(() => _scale = 0.95);
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() => _scale = 1.0);

    final newStatus = !isFollowed;

    // تحديث الواجهة محلياً
    setState(() => isFollowed = newStatus);

    // 5. إرسال خبر لباقي التطبيق بأن الحالة تغيرت
    GlobalEventBus.sendEvent(widget.user.id, newStatus);

    final success = await _homeService.toggleFollow(widget.user.id);

    if (!success && mounted) {
      // تراجع في حال الفشل
      setState(() => isFollowed = !newStatus);
      // إرسال خبر التراجع لباقي التطبيق
      GlobalEventBus.sendEvent(widget.user.id, !newStatus);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("تعذر تحديث الحالة، تحقق من الانترنت"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _navigateToProfile() {
    if (widget.isModel) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  ModelProfileScreen(modelId: widget.user.id.toString()),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  MerchantProfileScreen(merchantId: widget.user.id.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (باقي كود التصميم كما هو تماماً بدون تغيير)
    return Container(
      width: 130,
      margin: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToProfile,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.purpleAccent.shade100,
                            Colors.blueAccent.shade100,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.grey[100],
                          backgroundImage: CachedNetworkImageProvider(
                            widget.user.imageUrl,
                          ),
                          onBackgroundImageError:
                              (_, __) => const Icon(Icons.person),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 12,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              "${widget.user.rating}",
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isModel ? "Top Model ✨" : "Official Store ✓",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                AnimatedScale(
                  scale: _scale,
                  duration: const Duration(milliseconds: 100),
                  child: SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isFollowed ? Colors.white : Colors.black,
                        foregroundColor:
                            isFollowed ? Colors.black : Colors.white,
                        elevation: isFollowed ? 0 : 2,
                        side:
                            isFollowed
                                ? BorderSide(color: Colors.grey.shade300)
                                : BorderSide.none,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          isFollowed
                              ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.check, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    "يتابع",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                              : const Text(
                                "متابعة",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
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
    );
  }
}
