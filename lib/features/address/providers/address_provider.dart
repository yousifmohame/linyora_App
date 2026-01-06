import 'package:flutter/material.dart';
import '../../../models/checkout_models.dart';
import '../services/address_service.dart';

class AddressProvider extends ChangeNotifier {
  final AddressService _service = AddressService();
  List<AddressModel> _addresses = [];
  bool _isLoading = false;

  List<AddressModel> get addresses => _addresses;
  bool get isLoading => _isLoading;

  Future<void> fetchAddresses() async {
    _isLoading = true;
    notifyListeners();
    try {
      _addresses = await _service.getAddresses();
    } catch (e) {
      print(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addAddress(Map<String, dynamic> data) async {
    try {
      final newAddress = await _service.addAddress(data);
      _addresses.add(newAddress);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAddress(int id, Map<String, dynamic> data) async {
    try {
      final updated = await _service.updateAddress(id, data);
      final index = _addresses.indexWhere((element) => element.id == id);
      if (index != -1) {
        _addresses[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAddress(int id) async {
    // حذف تفاؤلي (Optimistic Delete)
    final existing = _addresses.firstWhere((e) => e.id == id);
    _addresses.removeWhere((element) => element.id == id);
    notifyListeners();

    try {
      await _service.deleteAddress(id);
    } catch (e) {
      _addresses.add(existing); // إعادة العنصر في حال الفشل
      notifyListeners();
      rethrow;
    }
  }
}