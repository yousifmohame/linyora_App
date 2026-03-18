import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:linyora_project/features/models/offers/models/offer_models.dart';
import 'package:linyora_project/features/models/offers/screens/model_offer_form_screen.dart';

// ✅ 1. استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

import '../services/offers_service.dart';
import '../../screens/model_nav.dart';

class ModelOffersScreen extends StatefulWidget {
  const ModelOffersScreen({Key? key}) : super(key: key);

  @override
  State<ModelOffersScreen> createState() => _ModelOffersScreenState();
}

class _ModelOffersScreenState extends State<ModelOffersScreen> {
  final OffersService _service = OffersService();
  List<ServicePackage> _packages = [];
  bool _isLoading = true;

  final Color _roseColor = const Color(0xFFE11D48);
  final Color _purpleColor = const Color(0xFF9333EA);

  @override
  void initState() {
    super.initState();
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getOffers();
      if (mounted) {
        setState(() {
          _packages = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ تمرير l10n
  Future<void> _toggleStatus(ServicePackage pkg, AppLocalizations l10n) async {
    try {
      final newStatus = pkg.status == 'active' ? 'paused' : 'active';
      setState(() => pkg.status = newStatus);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${l10n.statusChangedToMsg}${newStatus == 'active' ? l10n.activeStatus : l10n.pausedStatus}", // ✅ مترجم
          ),
        ),
      );
    } catch (e) {
      _fetchOffers();
    }
  }

  // ✅ تمرير l10n
  Future<void> _deleteOffer(int id, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.deleteOfferTitle), // ✅ مترجم
            content: Text(l10n.deleteOfferConfirmMsg), // ✅ مترجم
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancelBtn), // ✅ مترجم
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  l10n.delete,
                  style: const TextStyle(color: Colors.white),
                ), // ✅ مترجم
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _service.deleteOffer(id);
        _fetchOffers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.deletedSuccessfullyMsg)), // ✅ مترجم
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.deletionFailedMsg)), // ✅ مترجم
        );
      }
    }
  }

  void _openForm({ServicePackage? package}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModelOfferFormScreen(packageToEdit: package),
      ),
    ).then((val) {
      if (val == true) _fetchOffers();
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
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

          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _fetchOffers,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.pink.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${_packages.length}${l10n.activeOffersCount}", // ✅ مترجم
                            style: TextStyle(
                              color: _roseColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _openForm(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _purpleColor,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: Text(l10n.addNewOfferBtn), // ✅ مترجم
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (_packages.isEmpty)
                      _buildEmptyState(l10n) // ✅ تمرير l10n
                    else
                      ..._packages
                          .map((pkg) => _buildOfferCard(pkg, l10n))
                          .toList(), // ✅ تمرير l10n

                    const SizedBox(height: 50),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 50),
          Icon(
            Icons.inventory_2_outlined,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noOffersCurrentlyMsg, // ✅ مترجم
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            l10n.startAddingPackagesMsg, // ✅ مترجم
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(ServicePackage pkg, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_roseColor, _purpleColor]),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            pkg.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildBadge(
                            pkg.status == 'active'
                                ? l10n.activeStatus
                                : l10n.pausedStatus, // ✅ مترجم
                            Colors.white.withOpacity(0.2),
                            Colors.white,
                          ),
                          if (pkg.category != null)
                            _buildBadge(
                              pkg.category!,
                              Colors.white.withOpacity(0.2),
                              Colors.white,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _openForm(package: pkg),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed:
                          () => _deleteOffer(pkg.id, l10n), // ✅ تمرير l10n
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pkg.description != null && pkg.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      pkg.description!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),

                Column(
                  children:
                      pkg.tiers
                          .map((tier) => _buildTierItem(tier, l10n))
                          .toList(), // ✅ تمرير l10n
                ),

                const Divider(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: () => _toggleStatus(pkg, l10n), // ✅ تمرير l10n
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color:
                              pkg.status == 'active'
                                  ? Colors.red.shade200
                                  : Colors.green.shade200,
                        ),
                        foregroundColor:
                            pkg.status == 'active' ? Colors.red : Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        pkg.status == 'active'
                            ? l10n.disableOfferBtn
                            : l10n.enableOfferBtn, // ✅ مترجم
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    _buildBadge(
                      pkg.status == 'active'
                          ? l10n.visibleToClientsBadge
                          : l10n.hiddenBadge, // ✅ مترجم
                      pkg.status == 'active'
                          ? Colors.green.shade50
                          : Colors.amber.shade50,
                      pkg.status == 'active'
                          ? Colors.green
                          : Colors.amber.shade800,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierItem(PackageTier tier, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tier.tierName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                "${tier.price.toStringAsFixed(0)} ${l10n.currencySAR}", // ✅ عملة مترجمة
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _roseColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...tier.features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 14, color: Colors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      f,
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIconText(
                Icons.access_time,
                "${tier.deliveryDays} ${l10n.daysLabel}",
              ), // ✅ مترجم
              _buildIconText(
                Icons.loop,
                tier.revisions == -1
                    ? l10n.infiniteRevisions
                    : "${tier.revisions}${l10n.revisionsCount}", // ✅ مترجم
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
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
