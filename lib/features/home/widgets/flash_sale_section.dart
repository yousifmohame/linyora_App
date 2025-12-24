import 'package:flutter/material.dart';
import '../services/flash_sale_service.dart';
import '../../../models/flash_sale_model.dart';
import 'flash_sale_timer.dart';
import 'flash_product_card.dart';

class FlashSaleSection extends StatefulWidget {
  const FlashSaleSection({super.key});

  @override
  State<FlashSaleSection> createState() => _FlashSaleSectionState();
}

class _FlashSaleSectionState extends State<FlashSaleSection> {
  final FlashSaleService _service = FlashSaleService();
  List<FlashSaleCampaign> _campaigns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCampaigns();
  }

  Future<void> _fetchCampaigns() async {
    final campaigns = await _service.getActiveFlashSales();
    if (mounted) {
      setState(() {
        _campaigns = campaigns;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _campaigns.isEmpty) return const SizedBox.shrink();

    return Column(
      children: _campaigns.map((campaign) {
        if (campaign.products.isEmpty) return const SizedBox.shrink();
        
        return Container(
          margin: const EdgeInsets.only(bottom: 24, top: 12),
          padding: const EdgeInsets.symmetric(vertical: 16),
          // خلفية متدرجة خفيفة كما في الموقع
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade50,
                Colors.pink.shade50,
                Colors.orange.shade50,
              ],
            ),
          ),
          child: Column(
            children: [
              // 1. رأس القسم (العنوان + المؤقت)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flash_on, color: Colors.orange, size: 28),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              campaign.title,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              "ينتهي خلال",
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    FlashSaleTimer(endTime: campaign.endTime),
                  ],
                ),
              ),

              // 2. قائمة المنتجات
              SizedBox(
                height: 250, // ارتفاع مناسب للبطاقة
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: campaign.products.length,
                  itemExtent: 172,
                  itemBuilder: (context, index) {
                    return FlashProductCard(product: campaign.products[index]);
                  },
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}