import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class VideoCacheUtils {
  static final DefaultCacheManager _cacheManager = DefaultCacheManager();

  // هذه الدالة هي القلب النابض: تجلب الملف من الكاش أو تحمله إذا لم يكن موجوداً
  static Future<File> getCachedVideoFile(String videoUrl) async {
    final fileInfo = await _cacheManager.getFileFromCache(videoUrl);
    if (fileInfo != null) {
      return fileInfo.file;
    } else {
      // تحميل وتخزين
      return await _cacheManager.getSingleFile(videoUrl);
    }
  }
}