import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ✅ 1. استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

import '../models/wallet_model.dart';
import '../services/wallet_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  final WalletService _service = WalletService();
  late TabController _tabController;

  WalletData? _wallet;
  List<WalletTransaction> _transactions = [];

  bool _isLoading = true;
  bool _isSubmitting = false;
  final TextEditingController _amountController = TextEditingController();

  double get _displayAvailableBalance =>
      (_wallet?.balance ?? 0) > 0 ? (_wallet?.balance ?? 0) : 0.0;

  double get _displayTotalDebt {
    double rawBalance = _wallet?.balance ?? 0;
    double outstanding = _wallet?.outstandingDebt ?? 0;
    return outstanding + (rawBalance < 0 ? rawBalance.abs() : 0);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final walletData = await _service.getWalletData();
      final transactionsData = await _service.getTransactions();

      if (mounted) {
        setState(() {
          _wallet = walletData;
          _transactions = transactionsData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ تمرير l10n لمعالجة رسائل الخطأ
  Future<void> _handlePayoutRequest(AppLocalizations l10n) async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (amount <= 0) {
      _showSnackBar(l10n.enterValidAmountMsg, isError: true); // ✅ مترجم
      return;
    }
    if (amount > _displayAvailableBalance) {
      _showSnackBar(l10n.insufficientBalanceMsg, isError: true); // ✅ مترجم
      return;
    }
    if (amount < 50) {
      _showSnackBar(
        "${l10n.minPayoutMsg}${l10n.currencySAR}",
        isError: true,
      ); // ✅ مترجم ومدمج
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final message = await _service.requestPayout(amount);
      _showSnackBar(message, isError: false);
      _amountController.clear();
      Navigator.pop(context);
      _fetchData();
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ✅ تمرير l10n للترجمة الديناميكية للأنواع
  String _translateType(String type, AppLocalizations l10n) {
    switch (type) {
      case 'sale_earning':
        return l10n.saleEarningType; // ✅
      case 'shipping_earning':
        return l10n.shippingEarningType; // ✅
      case 'cod_commission_deduction':
        return l10n.codCommissionDeductionType; // ✅
      case 'commission_deduction':
        return l10n.commissionDeductionType; // ✅
      case 'payout':
        return l10n.payoutType; // ✅
      case 'agreement_income':
        return l10n.agreementIncomeType; // ✅
      case 'adjustment':
        return l10n.adjustmentType; // ✅
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          l10n.walletTitle, // ✅ مترجم
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchData,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _fetchData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildStatsGrid(l10n), // ✅ تمرير l10n

                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _displayAvailableBalance >= 50
                                    ? () =>
                                        _showPayoutSheet(l10n) // ✅ تمرير l10n
                                    : null,
                            icon: const Icon(Icons.account_balance_wallet),
                            label: Text(l10n.requestPayoutBtn), // ✅ مترجم
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9333EA),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor: Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildTransactionsSection(l10n), // ✅ تمرير l10n
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildStatsGrid(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: l10n.availableToWithdrawLabel, // ✅ مترجم
                  value: _displayAvailableBalance,
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  subtext: l10n.readyToTransferLabel, // ✅ مترجم
                  l10n: l10n,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: l10n.debtsLabel, // ✅ مترجم
                  value: _displayTotalDebt,
                  icon: Icons.warning_amber_rounded,
                  color: _displayTotalDebt > 0 ? Colors.red : Colors.grey,
                  subtext:
                      _displayTotalDebt > 0
                          ? l10n.autoDeductedLabel
                          : l10n.noDebtsLabel, // ✅ مترجم
                  isDebt: true,
                  l10n: l10n,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: l10n.pendingSettlementLabel, // ✅ مترجم
                  value: _wallet?.pendingBalance ?? 0,
                  icon: Icons.access_time,
                  color: Colors.orange,
                  subtext:
                      "${_wallet?.pendingTransactionsCount ?? 0} ${l10n.operationsLabel}", // ✅ مترجم
                  l10n: l10n,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: l10n.totalProfitsLabel, // ✅ مترجم
                  value: _wallet?.totalEarnings ?? 0,
                  icon: Icons.trending_up,
                  color: Colors.blue,
                  subtext: l10n.historicalLabel, // ✅ مترجم
                  l10n: l10n,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
    required String subtext,
    bool isDebt = false,
    required AppLocalizations l10n, // ✅ إضافة l10n
  }) {
    // اختيار اللغة للتنسيق بناءً على اختيار المستخدم لتنسيق الأرقام
    String langCode = Localizations.localeOf(context).languageCode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(top: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "${NumberFormat('#,##0.00', langCode).format(value)} ${l10n.currencySAR}", // ✅ تنسيق وعملة
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDebt && value > 0 ? Colors.red : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: TextStyle(color: Colors.grey[400], fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection(AppLocalizations l10n) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF9333EA),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF9333EA),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: [
              Tab(text: l10n.allTab), // ✅ مترجم
              Tab(text: l10n.depositTab), // ✅ مترجم
              Tab(text: l10n.deductionTab), // ✅ مترجم
              Tab(text: l10n.withdrawTab), // ✅ مترجم
            ],
          ),
          SizedBox(
            height: 500,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionList('all', l10n), // ✅ تمرير l10n
                _buildTransactionList('earnings', l10n),
                _buildTransactionList('deductions', l10n),
                _buildTransactionList('payouts', l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(String filterType, AppLocalizations l10n) {
    final filteredList =
        _transactions.where((t) {
          if (filterType == 'all') return true;
          if (filterType == 'earnings') return t.amount > 0;
          if (filterType == 'deductions')
            return t.amount < 0 && t.type != 'payout';
          if (filterType == 'payouts') return t.type == 'payout';
          return true;
        }).toList();

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(
              l10n.noOperationsMsg,
              style: const TextStyle(color: Colors.grey),
            ), // ✅ مترجم
          ],
        ),
      );
    }

    String langCode = Localizations.localeOf(context).languageCode;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredList.length,
      separatorBuilder: (c, i) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final trans = filteredList[index];
        final isPositive = trans.amount > 0;
        final isPayout = trans.type == 'payout';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      isPayout
                          ? Colors.blue.shade50
                          : (isPositive
                              ? Colors.green.shade50
                              : Colors.red.shade50),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPayout
                      ? Icons.arrow_outward
                      : (isPositive ? Icons.arrow_downward : Icons.remove),
                  color:
                      isPayout
                          ? Colors.blue
                          : (isPositive ? Colors.green : Colors.red),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _translateType(trans.type, l10n), // ✅ تمرير l10n
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trans.description,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          DateFormat(
                            'yyyy-MM-dd',
                            langCode,
                          ).format(DateTime.parse(trans.createdAt)),
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 10,
                          ),
                        ),
                        if (trans.referenceId != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "#${trans.referenceId}",
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${isPositive ? '+' : ''}${trans.amount} ${l10n.currencySAR}", // ✅ عملة مترجمة
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color:
                          isPositive
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusChip(trans.status, l10n), // ✅ تمرير l10n
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status, AppLocalizations l10n) {
    Color color;
    String text;
    switch (status) {
      case 'cleared':
        color = Colors.green;
        text = l10n.completedStatus; // ✅ مترجم
        break;
      case 'pending':
        color = Colors.orange;
        text = l10n.pendingStatus; // ✅ مترجم
        break;
      case 'processing':
        color = Colors.blue;
        text = l10n.processingStatus; // ✅ مترجم
        break;
      case 'cancelled':
        color = Colors.red;
        text = l10n.cancelledStatus; // ✅ مترجم
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showPayoutSheet(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.payoutRequestTitle, // ✅ مترجم
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${l10n.availableBalanceLabel}$_displayAvailableBalance ${l10n.currencySAR}", // ✅ ديناميكي ومترجم
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n.requestedAmountLabel, // ✅ مترجم
                    suffixText: l10n.currencySAR, // ✅ مترجم
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _isSubmitting
                            ? null
                            : () => _handlePayoutRequest(l10n), // ✅ تمرير l10n
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9333EA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child:
                        _isSubmitting
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                            : Text(l10n.confirmWithdrawalBtn), // ✅ مترجم
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }
}
