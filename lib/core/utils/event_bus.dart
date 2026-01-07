import 'dart:async';

// الحدث الذي سنرسله
class UserFollowEvent {
  final int userId;
  final bool isFollowed;

  UserFollowEvent({required this.userId, required this.isFollowed});
}

// محطة البث
class GlobalEventBus {
  // نستخدم broadcast ليتمكن أكثر من مستمع (Listener) من استقبال الحدث
  static final StreamController<UserFollowEvent> _controller = 
      StreamController<UserFollowEvent>.broadcast();

  static Stream<UserFollowEvent> get stream => _controller.stream;

  static void sendEvent(int userId, bool isFollowed) {
    _controller.add(UserFollowEvent(userId: userId, isFollowed: isFollowed));
  }
}