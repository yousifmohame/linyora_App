import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ✅ 1. استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

import '../models/merchant_agreement_model.dart';
import '../services/merchant_agreements_service.dart';

class MerchantAgreementsScreen extends StatefulWidget {
  const MerchantAgreementsScreen({Key? key}) : super(key: key);

  @override
  State<MerchantAgreementsScreen> createState() => _MerchantAgreementsScreenState();
}

class _MerchantAgreementsScreenState extends State<MerchantAgreementsScreen> {
  final MerchantAgreementsService _service = MerchantAgreementsService();
  
  List<MerchantAgreement> _agreements = [];
  List<MerchantAgreement> _filteredAgreements = [];
  bool _isLoading = true;
  String _searchTerm = "";
  int? _processingId; 

  final Color rose50 = const Color(0xFFFFF1F2);
  final Color rose100 = const Color(0xFFFFE4E6);
  final Color rose500 = const Color(0xFFF43F5E);
  final Color rose700 = const Color(0xFFBE123C);
  final Color pink600 = const Color(0xFFDB2777);

  @override
  void initState() {
    super.initState();
    _fetchAgreements();
  }

  Future<void> _fetchAgreements() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getMyAgreements();
      setState(() {
        _agreements = data;
        _filterAgreements();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if(mounted){
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.failedToFetchDataMsg}: $e')), // ✅ مترجم
        );
      }
    }
  }

  void _filterAgreements() {
    if (_searchTerm.isEmpty) {
      _filteredAgreements = _agreements;
    } else {
      _filteredAgreements = _agreements.where((a) =>
        a.modelName.toLowerCase().contains(_searchTerm.toLowerCase()) ||
        a.packageTitle.toLowerCase().contains(_searchTerm.toLowerCase())
      ).toList();
    }
  }

  // ✅ تمرير l10n
  Future<void> _handleComplete(int id, AppLocalizations l10n) async {
    setState(() => _processingId = id);
    try {
      await _service.completeAgreement(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.receiptConfirmedSuccessMsg), backgroundColor: Colors.green), // ✅ مترجم
      );
      _fetchAgreements(); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorOccurredMsg} $e'), backgroundColor: Colors.red), // ✅ مترجم
      );
    } finally {
      setState(() => _processingId = null);
    }
  }

  // ✅ تمرير l10n للـ Dialog
  void _openReviewDialog(MerchantAgreement agreement, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => _ReviewDialog(
        agreement: agreement,
        l10n: l10n, // ✅ تمرير الترجمة
        onSubmit: (rating, comment) async {
          Navigator.pop(context);
          setState(() => _processingId = agreement.id);
          try {
            await _service.reviewAgreement(agreement.id, rating, comment);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.ratingSentSuccessMsg), backgroundColor: Colors.green), // ✅ مترجم
            );
            _fetchAgreements();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${l10n.errorOccurredMsg} $e'), backgroundColor: Colors.red), // ✅ مترجم
            );
          } finally {
            setState(() => _processingId = null);
          }
        },
      ),
    );
  }

  Map<String, dynamic> get _stats {
    return {
      'total': _agreements.length,
      'pending': _agreements.where((a) => a.status == 'pending').length,
      'accepted': _agreements.where((a) => a.status == 'accepted').length,
      'in_progress': _agreements.where((a) => a.status == 'in_progress').length,
      'delivered': _agreements.where((a) => a.status == 'delivered').length,
      'completed': _agreements.where((a) => a.status == 'completed').length,
      'totalValue': _agreements.fold(0.0, (sum, a) => sum + a.tierPrice),
    };
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [rose50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: rose500))
              : RefreshIndicator(
                  color: rose500,
                  onRefresh: _fetchAgreements,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeader(l10n)), // ✅ تمرير l10n
                      
                      SliverToBoxAdapter(child: _buildStatsGrid(l10n)), // ✅ تمرير l10n

                      SliverToBoxAdapter(child: _buildSearchBar(l10n)), // ✅ تمرير l10n

                      _filteredAgreements.isEmpty 
                        ? SliverToBoxAdapter(child: _buildEmptyState(l10n)) // ✅ تمرير l10n
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildAgreementCard(_filteredAgreements[index], l10n), // ✅ تمرير l10n
                              childCount: _filteredAgreements.length,
                            ),
                          ),
                      
                      const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                child: Icon(Icons.handshake, color: rose500, size: 30),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(colors: [rose500, pink600]).createShader(bounds),
            child: Text(
              l10n.myAgreementsTitle, // ✅ مترجم
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            l10n.manageCollabRequestsDesc, // ✅ مترجم
            style: TextStyle(color: rose700, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AppLocalizations l10n) {
    final stats = _stats;
    String langCode = Localizations.localeOf(context).languageCode;
    final currencyFormat = NumberFormat.currency(locale: langCode, symbol: l10n.currencySAR, decimalDigits: 0);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatCard(l10n.all, stats['total'].toString(), rose500, rose50), // ✅ مترجم
          _buildStatCard(l10n.pending, stats['pending'].toString(), Colors.amber, Colors.amber.shade50), // ✅ مترجم
          _buildStatCard(l10n.statusAccepted, stats['accepted'].toString(), Colors.blue, Colors.blue.shade50), // ✅ مترجم
          _buildStatCard(l10n.statusInProgress, stats['in_progress'].toString(), Colors.purple, Colors.purple.shade50), // ✅ مترجم
          _buildStatCard(l10n.statusDelivered, stats['delivered'].toString(), Colors.orange, Colors.orange.shade50), // ✅ مترجم
          _buildStatCard(l10n.completed, stats['completed'].toString(), Colors.green, Colors.green.shade50), // ✅ مترجم
          _buildStatCard(l10n.grandTotalLabel, currencyFormat.format(stats['totalValue']), pink600, rose100, width: 140), // ✅ مترجم
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, Color bg, {double width = 100}) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 5)],
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)), textAlign: TextAlign.center, maxLines: 1),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: TextField(
          onChanged: (val) {
            _searchTerm = val;
            setState(_filterAgreements);
          },
          decoration: InputDecoration(
            hintText: l10n.searchModelOrPackageHint, // ✅ مترجم
            prefixIcon: Icon(Icons.search, color: rose500.withOpacity(0.5)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildAgreementCard(MerchantAgreement agreement, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: rose100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: rose500.withOpacity(0.1),
                    child: Icon(Icons.person, color: rose500, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(agreement.modelName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(agreement.packageTitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              _buildStatusBadge(agreement.status, l10n), // ✅ تمرير l10n
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${agreement.tierPrice.toInt()} ${l10n.currencySAR}", // ✅ عملة
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: rose500),
              ),
              _buildActionButtons(agreement, l10n), // ✅ تمرير l10n
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, AppLocalizations l10n) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'pending': color = Colors.amber; text = l10n.pending; icon = Icons.hourglass_empty; break; // ✅ مترجم
      case 'accepted': color = Colors.blue; text = l10n.statusAccepted; icon = Icons.check_circle_outline; break; // ✅ مترجم
      case 'in_progress': color = Colors.purple; text = l10n.statusInProgress; icon = Icons.bolt; break; // ✅ مترجم
      case 'delivered': color = Colors.orange; text = l10n.statusDelivered; icon = Icons.inventory_2_outlined; break; // ✅ مترجم
      case 'completed': color = Colors.green; text = l10n.completed; icon = Icons.check_circle; break; // ✅ مترجم
      case 'rejected': color = Colors.red; text = l10n.statusRejected; icon = Icons.cancel_outlined; break; // ✅ مترجم
      default: color = Colors.grey; text = status; icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(MerchantAgreement agreement, AppLocalizations l10n) {
    if (_processingId == agreement.id) {
      return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (agreement.status == 'delivered') {
      return ElevatedButton.icon(
        onPressed: () => _handleComplete(agreement.id, l10n), // ✅ تمرير l10n
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        icon: const Icon(Icons.check_circle, size: 16),
        label: Text(l10n.confirmReceiptBtn), // ✅ مترجم
      );
    }

    if (agreement.status == 'completed') {
      if (agreement.hasMerchantReviewed) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.green, size: 14),
              const SizedBox(width: 4),
              Text(l10n.reviewedBadge, style: const TextStyle(color: Colors.green, fontSize: 12)), // ✅ مترجم
            ],
          ),
        );
      } else {
        return OutlinedButton.icon(
          onPressed: () => _openReviewDialog(agreement, l10n), // ✅ تمرير l10n
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.amber.shade800,
            side: BorderSide(color: Colors.amber.shade200),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.star_outline, size: 16),
          label: Text(l10n.addReviewBtn), // ✅ مترجم
        );
      }
    }

    return TextButton(
      onPressed: () {}, 
      child: Text(l10n.viewDetailsBtn, style: const TextStyle(color: Colors.grey)), // ✅ مترجم
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.inbox, size: 60, color: rose100),
            const SizedBox(height: 10),
            Text(l10n.noAgreementsMsg, style: TextStyle(color: rose500.withOpacity(0.5))), // ✅ مترجم
          ],
        ),
      ),
    );
  }
}

// --- Review Dialog Widget ---
class _ReviewDialog extends StatefulWidget {
  final MerchantAgreement agreement;
  final Function(int, String) onSubmit;
  final AppLocalizations l10n; // ✅ إضافة l10n لتمريره للويدجت الفرعي

  const _ReviewDialog({Key? key, required this.agreement, required this.onSubmit, required this.l10n}) : super(key: key);

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 40),
          const SizedBox(height: 10),
          Text(widget.l10n.rateYourExperienceTitle, style: const TextStyle(fontWeight: FontWeight.bold)), // ✅ مترجم
          Text("${widget.l10n.withModelPrefix}${widget.agreement.modelName}", style: const TextStyle(fontSize: 12, color: Colors.grey)), // ✅ مترجم ومدمج
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 30,
                ),
                onPressed: () => setState(() => _rating = index + 1),
              );
            }),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: widget.l10n.writeCommentHint, // ✅ مترجم
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.l10n.cancelBtn, style: const TextStyle(color: Colors.grey))), // ✅ مترجم
        ElevatedButton(
          onPressed: _rating == 0 ? null : () => widget.onSubmit(_rating, _commentController.text),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text(widget.l10n.confirmRatingBtn), // ✅ مترجم
        ),
      ],
    );
  }
}