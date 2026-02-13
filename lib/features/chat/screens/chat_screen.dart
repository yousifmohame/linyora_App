import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:linyora_project/features/auth/services/auth_service.dart';

import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

// ==========================================
// 🎨 Constants & Theme (Blue Identity)
// ==========================================
const Color kPrimaryBlue = Color(0xFF2563EB); // Royal Blue
const Color kLightBlue = Color(0xFFEFF6FF); // Very Light Blue Background
const Color kAccentBlue = Color(0xFF3B82F6); // Buttons
const Color kChatBackground = Color(0xFFF1F5F9); // Slate 100
const Color kMyBubbleColor = Color(0xFF2563EB);
const Color kOtherBubbleColor = Colors.white;
const Color kTextColor = Color(0xFF1E293B);

// ==========================================
// 1. شاشة قائمة المحادثات (Main List)
// ==========================================
class ChatListScreen extends StatefulWidget {
  final int currentUserId;
  final int? initialActiveConversationId;

  const ChatListScreen({
    Key? key,
    required this.currentUserId,
    this.initialActiveConversationId,
  }) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with WidgetsBindingObserver {
  final ChatService _chatService = ChatService();
  late IO.Socket _socket;

  List<Conversation> _conversations = [];
  bool _isLoading = true;
  bool _isSocketConnected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSocket();

    // التعامل الذكي مع الفتح المباشر لمحادثة
    _fetchConversations().then((_) {
      if (widget.initialActiveConversationId != null &&
          _conversations.isNotEmpty) {
        try {
          final convo = _conversations.firstWhere(
            (c) => c.id == widget.initialActiveConversationId,
          );
          _openChat(convo);
        } catch (e) {
          // إذا لم نجد المحادثة (ربما جديدة)، يمكن تجاهل الأمر أو فتح الأولى
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_socket.connected) _socket.disconnect();
    _socket.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_socket.connected) _socket.connect();
      _fetchConversations();
    }
  }

  // --- Socket Logic ---
  void _initSocket() async {
    const String socketUrl = 'https://linyora.cloud/';
    String? token = await AuthService.instance.getToken();
    if (token == null) return;

    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .enableForceNew()
          .setReconnectionDelay(1000)
          .setReconnectionAttempts(9999)
          .build(),
    );

    _socket.connect();

    _socket.onConnect((_) {
      if (mounted) setState(() => _isSocketConnected = true);
      _socket.emit('authenticate', token);
    });

    _socket.onDisconnect((_) {
      if (mounted) setState(() => _isSocketConnected = false);
    });

    _socket.on(
      'userOnline',
      (data) => _updateUserStatus(int.parse(data['userId'].toString()), true),
    );
    _socket.on(
      'userOffline',
      (data) => _updateUserStatus(
        int.parse(data['userId'].toString()),
        false,
        data['last_seen'],
      ),
    );

    _socket.on('newMessage', (data) {
      final newMsg = Message.fromJson(data);
      _updateConversationList(newMsg);
    });
  }

  void _updateUserStatus(int userId, bool isOnline, [String? lastSeen]) {
    if (!mounted) return;
    setState(() {
      final index = _conversations.indexWhere((c) => c.participantId == userId);
      if (index != -1) {
        _conversations[index].isOnline = isOnline;
        if (lastSeen != null) _conversations[index].lastSeen = lastSeen;
      }
    });
  }

  void _updateConversationList(Message msg) {
    if (!mounted) return;
    setState(() {
      final index = _conversations.indexWhere(
        (c) => c.id == msg.conversationId,
      );
      if (index != -1) {
        var convo = _conversations[index];
        convo.lastMessage = msg.body ?? 'مرفق 📎';
        convo.unreadCount += 1;
        _conversations.removeAt(index);
        _conversations.insert(0, convo);
      } else {
        _fetchConversations();
      }
    });
  }

  Future<void> _fetchConversations() async {
    try {
      final convos = await _chatService.getConversations();
      if (mounted) {
        setState(() {
          _conversations = convos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openChat(Conversation convo) async {
    setState(() {
      final index = _conversations.indexOf(convo);
      if (index != -1) _conversations[index].unreadCount = 0;
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ChatDetailScreen(
              conversation: convo,
              currentUserId: widget.currentUserId,
              socket: _socket,
            ),
      ),
    );
    _fetchConversations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "المحادثات",
          style: TextStyle(
            color: kTextColor,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            fontFamily: 'Cairo', // يفضل استخدام خط عربي
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color:
                      _isSocketConnected
                          ? Colors.greenAccent[700]
                          : Colors.redAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isSocketConnected ? Colors.green : Colors.red)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: kPrimaryBlue),
              )
              : _conversations.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: _conversations.length,
                separatorBuilder:
                    (c, i) => const Padding(
                      padding: EdgeInsets.only(left: 80, right: 20),
                      child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ),
                itemBuilder:
                    (context, index) =>
                        _buildConversationTile(_conversations[index]),
              ),
    );
  }

  Widget _buildConversationTile(Conversation convo) {
    return InkWell(
      onTap: () => _openChat(convo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Avatar
            Hero(
              tag: 'avatar_${convo.participantId}',
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: kLightBlue,
                      backgroundImage:
                          convo.participantAvatar != null
                              ? CachedNetworkImageProvider(
                                convo.participantAvatar!,
                              )
                              : null,
                      child:
                          convo.participantAvatar == null
                              ? Text(
                                convo.participantName?[0] ?? "?",
                                style: const TextStyle(
                                  color: kPrimaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                              : null,
                    ),
                  ),
                  if (convo.isOnline)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E), // Bright Green
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    convo.participantName ?? "مستخدم",
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    convo.lastMessage ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          convo.unreadCount > 0 ? kTextColor : Colors.grey[500],
                      fontWeight:
                          convo.unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Time & Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (convo.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: kPrimaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "${convo.unreadCount}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kLightBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 40,
              color: kPrimaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "ابدأ محادثة جديدة",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. شاشة المحادثة (Details) - The Blue UX
// ==========================================
class ChatDetailScreen extends StatefulWidget {
  final Conversation conversation;
  final int currentUserId;
  final IO.Socket socket;

  const ChatDetailScreen({
    Key? key,
    required this.conversation,
    required this.currentUserId,
    required this.socket,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = []; // Reverse Order

  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
    _fetchMessages();
  }

  @override
  void dispose() {
    widget.socket.off('newMessage');
    widget.socket.off('userOnline');
    widget.socket.off('userOffline');
    widget.socket.off('messagesRead');
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupSocketListeners() {
    widget.socket.on('newMessage', (data) {
      if (!mounted) return;
      final msg = Message.fromJson(data);
      if (msg.conversationId == widget.conversation.id) {
        setState(() => _messages.insert(0, msg));
        // ✅ تشغيل النزول الذكي إذا كان المستخدم يرى آخر رسالة
        if (_scrollController.hasClients && _scrollController.offset < 100) {
          _scrollToBottom(isImage: msg.attachmentUrl != null);
        }
        widget.socket.emit('markAsRead', {
          'conversationId': widget.conversation.id,
        });
      }
    });

    widget.socket.on('userOnline', (data) {
      if (!mounted) return;
      if (int.parse(data['userId'].toString()) ==
          widget.conversation.participantId) {
        setState(() => widget.conversation.isOnline = true);
      }
    });

    widget.socket.on('userOffline', (data) {
      if (!mounted) return;
      if (int.parse(data['userId'].toString()) ==
          widget.conversation.participantId) {
        setState(() {
          widget.conversation.isOnline = false;
          widget.conversation.lastSeen = data['last_seen'];
        });
      }
    });

    widget.socket.on('messagesRead', (data) {
      if (data['conversationId'] == widget.conversation.id && mounted) {
        setState(() {
          for (var msg in _messages) msg.isRead = true;
        });
      }
    });
  }

  Future<void> _fetchMessages() async {
    try {
      final msgs = await _chatService.getMessages(widget.conversation.id);
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(msgs.reversed.toList());
          _isLoading = false;
        });
        widget.socket.emit('markAsRead', {
          'conversationId': widget.conversation.id,
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ الدالة السحرية للنزول السلس
  void _scrollToBottom({bool isImage = false}) {
    if (!_scrollController.hasClients) return;
    // لأن القائمة معكوسة، النزول للأسفل يعني الذهاب إلى offset 0
    // ولكن في بعض الحالات نريد التأكد من العرض
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // للقائمة المعكوسة (reverse: true)، الـ bottom هو 0.0
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  Future<void> _sendMessage({
    String? body,
    String? attachmentUrl,
    String? type,
  }) async {
    if ((body == null || body.trim().isEmpty) && attachmentUrl == null) return;

    final tempMsg = Message(
      id: DateTime.now().millisecondsSinceEpoch,
      conversationId: widget.conversation.id,
      senderId: widget.currentUserId,
      body: body,
      attachmentUrl: attachmentUrl,
      attachmentType: type,
      isRead: false,
      createdAt: DateTime.now().toIso8601String(),
    );

    setState(() {
      _messages.insert(0, tempMsg);
      _messageController.clear();
    });

    // ✅ النزول دائماً عند الإرسال
    _scrollToBottom(isImage: attachmentUrl != null);

    try {
      await _chatService.sendMessage(
        receiverId: widget.conversation.participantId,
        body: body,
        attachmentUrl: attachmentUrl,
        attachmentType: type,
      );
    } catch (e) {
      setState(() => _messages.remove(tempMsg));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فشل الإرسال')));
    }
  }

  Future<void> _handleAttachment(String type) async {
    File? file;
    String attachmentType = type == 'image' ? 'image' : 'file';

    try {
      if (type == 'image') {
        final picked = await ImagePicker().pickImage(
          source: ImageSource.gallery,
        );
        if (picked != null) file = File(picked.path);
      } else {
        final result = await FilePicker.platform.pickFiles();
        if (result != null) file = File(result.files.single.path!);
      }

      if (file != null) {
        setState(() => _isUploading = true);
        final res = await _chatService.uploadAttachment(file);
        setState(() => _isUploading = false);
        if (res != null) {
          _sendMessage(
            attachmentUrl: res['attachment_url'],
            type: res['attachment_type'] ?? attachmentType,
          );
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
    }
  }

  String _formatLastSeen(String? lastSeen) {
    if (lastSeen == null) return "غير متصل";
    try {
      final date = DateTime.parse(lastSeen).toLocal();
      return "آخر ظهور ${DateFormat('hh:mm a').format(date)}";
    } catch (e) {
      return "غير متصل";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kChatBackground, // خلفية رمادية فاتحة جداً
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: kTextColor,
        leadingWidth: 40,
        titleSpacing: 0,
        title: Row(
          children: [
            Hero(
              tag: 'avatar_${widget.conversation.participantId}',
              child: CircleAvatar(
                radius: 20,
                backgroundColor: kLightBlue,
                backgroundImage:
                    widget.conversation.participantAvatar != null
                        ? CachedNetworkImageProvider(
                          widget.conversation.participantAvatar!,
                        )
                        : null,
                child:
                    widget.conversation.participantAvatar == null
                        ? const Icon(
                          Icons.person,
                          size: 20,
                          color: kPrimaryBlue,
                        )
                        : null,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversation.participantName ?? "مستخدم",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.conversation.isOnline
                      ? "متصل الآن"
                      : _formatLastSeen(widget.conversation.lastSeen),
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        widget.conversation.isOnline
                            ? Colors.green
                            : Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: kPrimaryBlue),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined, color: kPrimaryBlue),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Messages Area
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: kPrimaryBlue),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      reverse: true, // ✅ القائمة تبدأ من الأسفل
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isMe = msg.senderId == widget.currentUserId;
                        // فحص لتجميع الرسائل المتتالية (تقليل المسافات)
                        final bool isNextSame =
                            index > 0 &&
                            _messages[index - 1].senderId == msg.senderId;
                        return _buildBlueBubble(msg, isMe, isNextSame);
                      },
                    ),
          ),

          // 2. Modern Input Area
          _buildBlueInputArea(),
        ],
      ),
    );
  }

  // 💎 The Blue Bubble Design
  Widget _buildBlueBubble(Message msg, bool isMe, bool isNextSame) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: isNextSame ? 4 : 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? kPrimaryBlue : kOtherBubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (msg.attachmentUrl != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: msg.attachmentUrl!,
                      placeholder:
                          (c, u) => Container(
                            height: 150,
                            width: 200,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      // ✅ عند تحميل الصورة، اطلب النزول للأسفل إذا لزم الأمر
                      imageBuilder: (ctx, provider) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients &&
                              _scrollController.offset < 50) {
                            _scrollToBottom(isImage: true);
                          }
                        });
                        return Image(image: provider, fit: BoxFit.cover);
                      },
                      errorWidget: (c, u, e) => const Icon(Icons.error),
                    ),
                  ),
                ),
              if (msg.body != null && msg.body!.isNotEmpty)
                Text(
                  msg.body!,
                  style: TextStyle(
                    color: isMe ? Colors.white : kTextColor,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    DateFormat(
                      'hh:mm a',
                    ).format(DateTime.parse(msg.createdAt).toLocal()),
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          isMe
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey[500],
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      msg.isRead ? Icons.done_all_rounded : Icons.check_rounded,
                      size: 14,
                      color:
                          msg.isRead
                              ? Colors.white
                              : Colors.white.withOpacity(0.6),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 💎 Modern Input
  Widget _buildBlueInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        30,
      ), // Extra bottom padding for iOS home bar
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.emoji_emotions_outlined,
                      color: Colors.grey[500],
                    ),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 5,
                      style: const TextStyle(color: kTextColor),
                      decoration: InputDecoration(
                        hintText: "اكتب رسالة...",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.attach_file_rounded,
                      color: Colors.grey[500],
                    ),
                    onPressed: () => _handleAttachment('file'),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.grey[500],
                    ),
                    onPressed: () => _handleAttachment('image'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendMessage(body: _messageController.text),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kPrimaryBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryBlue.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child:
                  _isUploading
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
