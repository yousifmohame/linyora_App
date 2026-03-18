import 'package:flutter/material.dart';
import 'package:linyora_project/features/subscriptions/services/subscription_service.dart';
import 'package:provider/provider.dart';

// ✅ 1. استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

import 'package:linyora_project/features/auth/providers/auth_provider.dart';
import 'package:linyora_project/models/subscription_plan_model.dart';
import 'package:linyora_project/features/subscriptions/screens/payment_Services.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  final SubscriptionService _dataService = SubscriptionService();
  final PaymentService _paymentService = PaymentService();

  List<SubscriptionPlan> _plans = [];
  bool _isLoading = true;
  int? _selectedPlanId;

  final Color _activeColor = const Color(0xFF10B981);
  final Color _primaryColor = const Color(0xFFF43F5E);
  final Color _darkText = const Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    try {
      final plans = await _dataService.getPlans();
      if (mounted) {
        setState(() {
          _plans = plans;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ تمرير l10n لمعالجة رسائل الخطأ من الـ PaymentService
  Future<void> _handleSubscribe(int planId, AppLocalizations l10n) async {
    setState(() => _selectedPlanId = planId);

    try {
      await _paymentService.subscribeToPlan(
        context: context,
        planId: planId,
        paymentMethodId: null,
        l10n: l10n, // ✅ تمريرها
        onSuccess: () async {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.confirmingSubscriptionMsg), // ✅ مترجم
              duration: const Duration(seconds: 2),
            ),
          );

          await Future.delayed(const Duration(seconds: 2));

          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          await authProvider.refreshUser();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.subscriptionActivatedSuccessMsg), // ✅ مترجم
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );

            Navigator.of(context).pop();
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.operationFailedMsg}$e'), // ✅ مترجم
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _selectedPlanId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    final user = Provider.of<AuthProvider>(context).user;
    final subscription = user?.subscription;

    int? currentPlanId;
    if (subscription != null && subscription.status == 'active') {
      currentPlanId = subscription.planId;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          l10n.subscriptionPlansTitle, // ✅ مترجم
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: _primaryColor))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      l10n.discoverPerfectPackage, // ✅ مترجم
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.packageFeaturesSubtitle, // ✅ مترجم
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _plans.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 24),
                      itemBuilder: (context, index) {
                        final plan = _plans[index];
                        final bool isMyPlan =
                            (currentPlanId != null && plan.id == currentPlanId);
                        return _buildProfessionalCard(
                          plan,
                          isMyPlan,
                          l10n,
                        ); // ✅ تمرير l10n
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfessionalCard(
    SubscriptionPlan plan,
    bool isMyPlan,
    AppLocalizations l10n,
  ) {
    final bool isProcessing = _selectedPlanId == plan.id;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isMyPlan ? Border.all(color: _activeColor, width: 2) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color:
                      isMyPlan
                          ? _activeColor.withOpacity(0.05)
                          : Colors.transparent,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _darkText,
                          ),
                        ),
                        if (isMyPlan)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              l10n.yourCurrentPackage, // ✅ مترجم
                              style: TextStyle(
                                fontSize: 12,
                                color: _activeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              plan.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "${plan.price.toInt()}",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: _darkText,
                            ),
                          ),
                          TextSpan(
                            text: " ${l10n.currencySAR}", // ✅ عملة مترجمة
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _darkText,
                            ),
                          ),
                          TextSpan(
                            text: l10n.perMonth, // ✅ مترجم
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    ...plan.features.map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: isMyPlan ? _activeColor : _primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            (isMyPlan || _selectedPlanId != null)
                                ? null
                                : () => _handleSubscribe(
                                  plan.id,
                                  l10n,
                                ), // ✅ تمرير l10n
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isMyPlan ? Colors.grey[200] : _primaryColor,
                          foregroundColor:
                              isMyPlan ? Colors.grey : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor:
                              isMyPlan
                                  ? Colors.green.shade50
                                  : Colors.grey[300],
                          disabledForegroundColor:
                              isMyPlan ? Colors.green : Colors.grey[600],
                        ),
                        child:
                            isProcessing
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(
                                  isMyPlan
                                      ? l10n.currentlySubscribedBtn
                                      : l10n.subscribeNowBtn, // ✅ مترجم
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isMyPlan && plan.price > 0 && plan.price < 500)
          Positioned(
            top: -12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  l10n.mostRequestedBadge, // ✅ مترجم
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
