import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:linyora_project/features/models/requests/models/agreement_request_model.dart';
import 'package:linyora_project/features/models/requests/services/agreement_service.dart';
import '../../screens/model_nav.dart'; // افترض وجود هذا الملف

class ModelRequestsScreen extends StatefulWidget {
  const ModelRequestsScreen({Key? key}) : super(key: key);

  @override
  State<ModelRequestsScreen> createState() => _ModelRequestsScreenState();
}

class _ModelRequestsScreenState extends State<ModelRequestsScreen> {
  final AgreementService _service = AgreementService();

  List<AgreementRequest> _requests = [];
  List<AgreementRequest> _filteredRequests = [];
  bool _isLoading = true;

  // Filters
  String _statusFilter = 'all';
  String _searchTerm = '';
  final TextEditingController _searchController = TextEditingController();

  // Colors Palette
  final Color _roseColor = const Color(0xFFE11D48);
  final Color _purpleColor = const Color(0xFF9333EA);

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getRequests();
      if (mounted) {
        setState(() {
          _requests = data;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredRequests =
          _requests.where((req) {
            final matchesStatus =
                _statusFilter == 'all' || req.status == _statusFilter;
            final matchesSearch =
                req.merchantName.toLowerCase().contains(
                  _searchTerm.toLowerCase(),
                ) ||
                req.productName.toLowerCase().contains(
                  _searchTerm.toLowerCase(),
                );
            return matchesStatus && matchesSearch;
          }).toList();
    });
  }

  // --- Actions ---

  Future<void> _handleAction(
    Future Function() action,
    String successMessage,
  ) async {
    try {
      // ✅ 1. تحسين عرض Loading Dialog لتجنب الشاشة السوداء
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => Center(
              // Center مهم لتوسط الشاشة
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, // خلفية بيضاء للمربع
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min, // لتصغير الحجم
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      "جاري المعالجة...",
                      style: TextStyle(
                        decoration: TextDecoration.none,
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      );

      await action();

      // ✅ 2. التأكد من إغلاق الـ Dialog فقط إذا كانت الشاشة لا تزال موجودة
      if (mounted) {
        Navigator.pop(context); // إغلاق Loading
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
        _fetchRequests(); // تحديث القائمة
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // إغلاق Loading عند الخطأ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("حدث خطأ: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showRejectDialog(AgreementRequest req) {
    String reason = '';
    String selectedReason = 'busy'; // default

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber),
                    SizedBox(width: 8),
                    Text("رفض الطلب"),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "لماذا تريدين رفض طلب ${req.merchantName}؟",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedReason,
                      items: const [
                        DropdownMenuItem(
                          value: 'busy',
                          child: Text("مشغول حالياً"),
                        ),
                        DropdownMenuItem(
                          value: 'budget',
                          child: Text("الميزانية غير مناسبة"),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text("سبب آخر"),
                        ),
                      ],
                      onChanged: (val) => setState(() => selectedReason = val!),
                      decoration: _inputDecoration("السبب"),
                    ),
                    if (selectedReason == 'other') ...[
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (val) => reason = val,
                        decoration: _inputDecoration("اكتب السبب هنا..."),
                        maxLines: 2,
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("إلغاء"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _handleAction(
                        () => _service.respondToRequest(
                          req.id,
                          'rejected',
                          reason:
                              selectedReason == 'other'
                                  ? reason
                                  : selectedReason,
                        ),
                        "تم رفض الطلب",
                      );
                    },
                    child: const Text(
                      "تأكيد الرفض",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  // --- UI Components ---

  @override
  Widget build(BuildContext context) {
    final stats = {
      'total': _requests.length,
      'pending': _requests.where((r) => r.status == 'pending').length,
      'in_progress': _requests.where((r) => r.status == 'in_progress').length,
      'delivered': _requests.where((r) => r.status == 'delivered').length,
      'completed': _requests.where((r) => r.status == 'completed').length,
    };

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.pink.shade50.withOpacity(0.3),
                  Colors.purple.shade50.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -50,
            right: -50,
            child: _buildBlurBlob(Colors.pink.shade200),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildBlurBlob(Colors.purple.shade200),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),

                // Stats
                SizedBox(
                  height: 80,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildStatCard("الكل", stats['total']!, Colors.pink),
                      _buildStatCard(
                        "قيد الانتظار",
                        stats['pending']!,
                        Colors.amber,
                      ),
                      _buildStatCard(
                        "جاري التنفيذ",
                        stats['in_progress']!,
                        Colors.purple,
                      ),
                      _buildStatCard(
                        "تم التسليم",
                        stats['delivered']!,
                        Colors.yellow.shade700,
                      ),
                      _buildStatCard(
                        "مكتمل",
                        stats['completed']!,
                        Colors.green,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Filters
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            _searchTerm = val;
                            _applyFilters();
                          },
                          decoration: _inputDecoration(
                            "بحث عن تاجر أو منتج",
                            icon: Icons.search,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _statusFilter,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'all',
                                    child: Text("جميع الحالات"),
                                  ),
                                  DropdownMenuItem(
                                    value: 'pending',
                                    child: Text("قيد الانتظار"),
                                  ),
                                  DropdownMenuItem(
                                    value: 'in_progress',
                                    child: Text("جاري التنفيذ"),
                                  ),
                                  DropdownMenuItem(
                                    value: 'completed',
                                    child: Text("مكتمل"),
                                  ),
                                ],
                                onChanged: (val) {
                                  _statusFilter = val!;
                                  _applyFilters();
                                },
                                decoration: _inputDecoration(
                                  "تصفية بالحالة",
                                  icon: Icons.filter_list,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.purple,
                              ),
                              onPressed: () {
                                setState(() {
                                  _statusFilter = 'all';
                                  _searchTerm = '';
                                  _searchController.clear();
                                  _applyFilters();
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // List
                Expanded(
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredRequests.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredRequests.length,
                            itemBuilder:
                                (context, index) =>
                                    _buildRequestCard(_filteredRequests[index]),
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.handshake, color: _roseColor),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: Colors.pink.shade300,
                  ),
                ],
              ),
              const SizedBox(width: 40), // Spacer
            ],
          ),
          const SizedBox(height: 10),
          ShaderMask(
            shaderCallback:
                (bounds) => LinearGradient(
                  colors: [_roseColor, _purpleColor],
                ).createShader(bounds),
            child: const Text(
              "طلبات الاتفاقيات",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const Text(
            "إدارة طلبات التعاون مع التجار",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(AgreementRequest req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          // Header Gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_roseColor, _purpleColor]),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.merchantName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (req.merchantLocation != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 10,
                                color: Colors.white70,
                              ),
                              Text(
                                req.merchantLocation!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
                _buildStatusBadge(req.status),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Info Boxes
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoBox(
                        Icons.inventory_2,
                        "الباقة",
                        req.packageTitle,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoBox(
                        Icons.shopping_bag,
                        "المنتج",
                        req.productName,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Details Grid
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDetailItem(
                        Icons.attach_money,
                        "${req.tierPrice} ر.س",
                        Colors.green,
                      ),
                      _buildDetailItem(
                        Icons.access_time,
                        "${req.deliveryDays} أيام",
                        Colors.amber,
                      ),
                      _buildDetailItem(
                        Icons.rate_review,
                        "${req.revisions} تعديل",
                        Colors.blue,
                      ),
                    ],
                  ),
                ),

                if (req.features.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade50.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.pink.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "المميزات:",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _roseColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...req.features
                            .take(3)
                            .map(
                              (f) => Row(
                                children: [
                                  const Icon(
                                    Icons.check,
                                    size: 12,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    f,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _roseColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Actions
                _buildActionButtons(req),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AgreementRequest req) {
    if (req.status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 16),
              label: const Text("قبول"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed:
                  () => _handleAction(
                    () => _service.respondToRequest(req.id, 'accepted'),
                    "تم قبول الطلب",
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.close, size: 16),
              label: const Text("رفض"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              onPressed: () => _showRejectDialog(req),
            ),
          ),
        ],
      );
    } else if (req.status == 'accepted') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow, size: 16),
          label: const Text("بدء التنفيذ"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          onPressed:
              () => _handleAction(
                () => _service.startRequest(req.id),
                "تم بدء المشروع",
              ),
        ),
      );
    } else if (req.status == 'in_progress') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text("تسليم العمل"),
          style: ElevatedButton.styleFrom(
            backgroundColor: _purpleColor,
            foregroundColor: Colors.white,
          ),
          onPressed:
              () => _handleAction(
                () => _service.deliverRequest(req.id),
                "تم تسليم العمل",
              ),
        ),
      );
    } else if (req.status == 'delivered') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          "في انتظار موافقة التاجر",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.amber.shade900,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return const SizedBox();
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'pending':
        color = Colors.amber;
        text = "قيد الانتظار";
        icon = Icons.access_time;
        break;
      case 'accepted':
        color = Colors.blue;
        text = "مقبول";
        icon = Icons.check_circle;
        break;
      case 'in_progress':
        color = Colors.purple;
        text = "جاري التنفيذ";
        icon = Icons.bolt;
        break;
      case 'delivered':
        color = Colors.orange;
        text = "تم التسليم";
        icon = Icons.local_shipping;
        break;
      case 'completed':
        color = Colors.green;
        text = "مكتمل";
        icon = Icons.task_alt;
        break;
      case 'rejected':
        color = Colors.red;
        text = "مرفوض";
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        text = status;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.handshake_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "لا توجد طلبات",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            "لم تصلك أي طلبات تعاون حتى الآن",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _purpleColor),
      ),
    );
  }

  Widget _buildBlurBlob(Color color) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
