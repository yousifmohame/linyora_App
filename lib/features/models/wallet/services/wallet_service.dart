import 'package:dio/dio.dart';
import 'package:linyora_project/core/api/api_client.dart';
import 'package:linyora_project/features/models/wallet/models/wallet_models.dart';


class WalletService {
  final ApiClient _apiClient = ApiClient();

  Future<ModelWallet> getWallet() async {
    final response = await _apiClient.get('/wallet/model/my-wallet');
    return ModelWallet.fromJson(response.data);
  }

  Future<List<Transaction>> getTransactions() async {
    final response = await _apiClient.get('/wallet/model/transactions');
    return (response.data as List).map((e) => Transaction.fromJson(e)).toList();
  }

  Future<void> requestPayout(double amount) async {
    await _apiClient.post('/wallet/model/request-payout', data: {'amount': amount});
  }
}