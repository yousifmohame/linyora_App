import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final int? initialActiveConversationId;
  final int currentUserId;

  const ChatScreen({
    Key? key,
    this.initialActiveConversationId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  late IO.Socket _socket;

  List<Conversation> _conversations = [];
  Conversation? _activeConversation;
  List<Message> _messages = [];

  bool _isLoadingConversations = true;
  bool _isLoadingMessages = false;
  bool _isUploading = false;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final Color roseColor = const Color(0xFFE11D48);
  final Color purpleColor = const Color(0xFF9333EA);

  @override
  void initState() {
    super.initState();
    _initSocket();
    _fetchConversations();
  }

  @override
  void dispose() {
    _socket.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- Socket Logic ---
  void _initSocket() {
    // استبدل هذا بالرابط الحقيقي للسوكيت الخاص بك
    _socket = IO.io('YOUR_SOCKET_URL', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    _socket.connect();

    _socket.on('newMessage', (data) {
      if (mounted) {
        final newMessage = Message.fromJson(data);
        _handleNewMessageSocket(newMessage);
      }
    });

    _socket.on('messagesRead', (data) {
      if (_activeConversation?.id == data['conversationId']) {
        setState(() {
          for (var msg in _messages) msg.isRead = true;
        });
      }
    });
  }

  void _handleNewMessageSocket(Message newMessage) {
    setState(() {
      // تحديث آخر رسالة في القائمة
      final index = _conversations.indexWhere(
        (c) => c.id == newMessage.conversationId,
      );
      if (index != -1) {
        _conversations[index].lastMessage = newMessage.body ?? 'مرفق';
        if (_activeConversation?.id != newMessage.conversationId) {
          _conversations[index].unreadCount += 1;
        }
        final convo = _conversations.removeAt(index);
        _conversations.insert(0, convo);
      }
      // إضافة الرسالة إذا كانت المحادثة مفتوحة
      if (_activeConversation?.id == newMessage.conversationId) {
        _messages.add(newMessage);
        _scrollToBottom();
        _socket.emit('markAsRead', {
          'conversationId': newMessage.conversationId,
        });
      }
    });
  }

  // --- Service Calls ---
  Future<void> _fetchConversations() async {
    final convos = await _chatService.getConversations();
    if (mounted) {
      setState(() {
        _conversations = convos;
        _isLoadingConversations = false;
      });

      // منطق فتح المحادثة التلقائي (Active Loader)
      if (widget.initialActiveConversationId != null && convos.isNotEmpty) {
        final target = convos.firstWhere(
          (c) => c.id == widget.initialActiveConversationId,
          orElse: () => convos.first,
        );
        _selectConversation(target);
      }
    }
  }

  Future<void> _fetchMessages(int conversationId) async {
    setState(() => _isLoadingMessages = true);
    final msgs = await _chatService.getMessages(conversationId);
    if (mounted) {
      setState(() {
        _messages = msgs;
        _isLoadingMessages = false;
      });
      _scrollToBottom();
      _socket.emit('markAsRead', {'conversationId': conversationId});
    }
  }

  Future<void> _sendMessage({
    String? body,
    String? attachmentUrl,
    String? type,
  }) async {
    if ((body == null || body.trim().isEmpty) && attachmentUrl == null) return;
    if (_activeConversation == null) return;

    // Optimistic Update (إضافة وهمية للسرعة)
    final tempMsg = Message(
      id: DateTime.now().millisecondsSinceEpoch,
      conversationId: _activeConversation!.id,
      senderId: widget.currentUserId,
      body: body,
      attachmentUrl: attachmentUrl,
      attachmentType: type,
      isRead: false,
      createdAt: DateTime.now().toIso8601String(),
    );

    setState(() {
      _messages.add(tempMsg);
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      await _chatService.sendMessage(
        receiverId: _activeConversation!.participantId,
        body: body,
        attachmentUrl: attachmentUrl,
        attachmentType: type,
      );
    } catch (e) {
      setState(() => _messages.remove(tempMsg)); // تراجع عند الخطأ
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فشل الإرسال')));
    }
  }

  Future<void> _handleFileUpload(String source) async {
    File? file;
    String attachmentType = 'file'; // النوع الافتراضي

    try {
      if (source == 'image') {
        // 1. اختيار صورة من المعرض
        final picked = await ImagePicker().pickImage(
          source: ImageSource.gallery,
        );
        if (picked != null) {
          file = File(picked.path);
          attachmentType = 'image';
        }
      } else {
        // 2. اختيار ملف (PDF, Doc, أو حتى صورة من الملفات)
        final result = await FilePicker.platform.pickFiles(
          type: FileType.any, // السماح بجميع أنواع الملفات
        );

        if (result != null && result.files.single.path != null) {
          file = File(result.files.single.path!);

          // فحص ذكي: هل الملف المختار هو صورة؟
          String path = file.path.toLowerCase();
          if (path.endsWith('.jpg') ||
              path.endsWith('.jpeg') ||
              path.endsWith('.png') ||
              path.endsWith('.gif') ||
              path.endsWith('.webp')) {
            attachmentType = 'image';
          } else {
            attachmentType = 'file';
          }
        }
      }

      // 3. عملية الرفع
      if (file != null) {
        setState(() => _isUploading = true);

        // استدعاء السيرفس لرفع الملف
        final result = await _chatService.uploadAttachment(file);

        setState(() => _isUploading = false);

        if (result != null) {
          // إرسال الرسالة مع الرابط والنوع
          _sendMessage(
            attachmentUrl: result['attachment_url'],
            // نفضل النوع القادم من السيرفر، وإلا نستخدم النوع الذي اكتشفناه محلياً
            type: result['attachment_type'] ?? attachmentType,
          );
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء اختيار الملف: $e')));
    }
  }

  void _selectConversation(Conversation convo) {
    setState(() {
      _activeConversation = convo;
      // تصفير العداد محلياً
      final index = _conversations.indexOf(convo);
      if (index != -1) _conversations[index].unreadCount = 0;
    });
    _fetchMessages(convo.id);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- UI Building ---
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF1F2), Color(0xFFFAF5FF)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar:
            _activeConversation != null &&
                    MediaQuery.of(context).size.width < 800
                ? null // إخفاء الـ Appbar الافتراضي عند فتح الشات في الموبايل واستخدام الهيدر المخصص
                : AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: ShaderMask(
                    shaderCallback:
                        (bounds) => LinearGradient(
                          colors: [roseColor, purpleColor],
                        ).createShader(bounds),
                    child: const Text(
                      "الرسائل",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  iconTheme: const IconThemeData(color: Colors.black),
                ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              // Tablet/Desktop Split View
              return Row(
                children: [
                  SizedBox(width: 350, child: _buildConversationsList()),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child:
                        _activeConversation == null
                            ? _buildEmptyState()
                            : _buildChatWindow(),
                  ),
                ],
              );
            } else {
              // Mobile View
              return _activeConversation == null
                  ? _buildConversationsList()
                  : WillPopScope(
                    onWillPop: () async {
                      setState(() => _activeConversation = null);
                      return false;
                    },
                    child: SafeArea(child: _buildChatWindow(isMobile: true)),
                  );
            }
          },
        ),
      ),
    );
  }

  // ... (Widgets: _buildConversationsList, _buildChatWindow, etc.)
  // سأضع الـ Widgets هنا بشكل مختصر لضمان عمل الملف

  Widget _buildConversationsList() {
    return Card(
      margin: const EdgeInsets.all(8),
      color: Colors.white.withOpacity(0.9),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child:
          _isLoadingConversations
              ? Center(child: CircularProgressIndicator(color: roseColor))
              : _conversations.isEmpty
              ? const Center(child: Text("لا توجد محادثات"))
              : ListView.builder(
                itemCount: _conversations.length,
                itemBuilder: (ctx, i) {
                  final convo = _conversations[i];
                  final isActive = _activeConversation?.id == convo.id;
                  return ListTile(
                    onTap: () => _selectConversation(convo),
                    tileColor: isActive ? roseColor.withOpacity(0.05) : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: CircleAvatar(
                      backgroundImage:
                          convo.participantAvatar != null
                              ? CachedNetworkImageProvider(
                                convo.participantAvatar!,
                              )
                              : null,
                      child:
                          convo.participantAvatar == null
                              ? Text(convo.participantName?[0] ?? "?")
                              : null,
                    ),
                    title: Text(convo.participantName ?? "مستخدم"),
                    subtitle: Text(convo.lastMessage ?? "", maxLines: 1),
                    trailing:
                        convo.unreadCount > 0
                            ? CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.red,
                              child: Text(
                                "${convo.unreadCount}",
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            )
                            : null,
                  );
                },
              ),
    );
  }

  // --- Widgets: Chat Window ---
  Widget _buildChatWindow({bool isMobile = false}) {
    return Card(
      margin: const EdgeInsets.all(8),
      color: Colors.white.withOpacity(0.95),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // 1. Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black12)),
            ),
            child: Row(
              children: [
                if (isMobile)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _activeConversation = null),
                  ),
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      _activeConversation!.participantAvatar != null
                          ? CachedNetworkImageProvider(
                            _activeConversation!.participantAvatar!,
                          )
                          : null,
                  child:
                      _activeConversation!.participantAvatar == null
                          ? Text(
                            _activeConversation!.participantName?[0] ?? "?",
                          )
                          : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _activeConversation!.participantName ?? "",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                _activeConversation!.isOnline
                                    ? Colors.green
                                    : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _activeConversation!.isOnline
                              ? "متصل الآن"
                              : "غير متصل",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Messages List
          Expanded(
            child:
                _isLoadingMessages
                    ? Center(
                      child: CircularProgressIndicator(color: purpleColor),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (ctx, i) {
                        final msg = _messages[i];
                        final isMe = msg.senderId == widget.currentUserId;
                        return _buildMessageBubble(msg, isMe);
                      },
                    ),
          ),

          // 3. Input Area
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image_outlined, color: Colors.grey),
                  onPressed: () => _handleFileUpload('image'),
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.grey),
                  onPressed: () => _handleFileUpload('file'),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "اكتب رسالة...",
                      hintStyle: const TextStyle(fontSize: 14),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _sendMessage(body: _messageController.text),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [roseColor, purpleColor],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child:
                        _isUploading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- دالة تصميم الفقاعة (Message Bubble) ---
  Widget _buildMessageBubble(Message msg, bool isMe) {
    // تحديد شكل الحواف بناءً على المرسل
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
      bottomRight: isMe ? Radius.zero : const Radius.circular(16),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient:
              isMe ? LinearGradient(colors: [roseColor, purpleColor]) : null,
          color: isMe ? null : Colors.white,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0), // Padding صغير للحاوية
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. عرض الصورة أو الملف
              if (msg.attachmentUrl != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _buildAttachmentView(msg, isMe),
                ),

              // 2. عرض النص
              if (msg.body != null && msg.body!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    msg.body!,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                ),

              // 3. الوقت وحالة القراءة
              Padding(
                padding: const EdgeInsets.only(right: 8, left: 8, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat(
                        'hh:mm a',
                      ).format(DateTime.parse(msg.createdAt)),
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe ? Colors.white70 : Colors.grey,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        msg.isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color:
                            msg.isRead ? Colors.blue.shade100 : Colors.white70,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- دالة مساعدة لعرض المرفقات ---
  Widget _buildAttachmentView(Message msg, bool isMe) {
    // إذا كان المرفق صورة
    if (msg.attachmentType == 'image') {
      return GestureDetector(
        onTap: () {
          // فتح الصورة بحجم كامل عند الضغط عليها
          showDialog(
            context: context,
            builder:
                (_) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: InteractiveViewer(
                    child: CachedNetworkImage(imageUrl: msg.attachmentUrl!),
                  ),
                ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: msg.attachmentUrl!,
            placeholder:
                (context, url) => Container(
                  height: 150,
                  width: 200,
                  color: Colors.black12,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            fit: BoxFit.cover,
            width: double.infinity, // تأخذ عرض الفقاعة
          ),
        ),
      );
    }
    // إذا كان المرفق ملف آخر
    else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file,
              color: isMe ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                "ملف مرفق",
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildEmptyState() => Center(
    child: Text("اختر محادثة", style: TextStyle(color: Colors.grey.shade400)),
  );
}
