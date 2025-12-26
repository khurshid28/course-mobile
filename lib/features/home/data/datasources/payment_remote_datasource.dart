import '../../../../core/network/dio_client.dart';

class PaymentRemoteDataSource {
  final DioClient _dioClient;

  PaymentRemoteDataSource(this._dioClient);

  Future<List<dynamic>> getPaymentHistory() async {
    try {
      final response = await _dioClient.get('/payments/history');
      return response.data as List<dynamic>;
    } catch (e) {
      print('Error getting payment history: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createPayment({
    required int courseId,
    required double amount,
    required String method,
    String? promoCode,
  }) async {
    try {
      final data = {'courseId': courseId, 'amount': amount, 'method': method};
      if (promoCode != null && promoCode.isNotEmpty) {
        data['promoCode'] = promoCode;
      }
      final response = await _dioClient.post('/payments', data: data);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('Error creating payment: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> topupBalance({
    required double amount,
    required String method,
  }) async {
    try {
      final response = await _dioClient.post(
        '/payments/topup',
        data: {'amount': amount, 'method': method},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('Error topping up balance: $e');
      rethrow;
    }
  }

  Future<double> getBalance() async {
    try {
      final response = await _dioClient.get('/payments/balance');
      final balance = response.data['balance'];
      if (balance is String) {
        return double.parse(balance);
      }
      return (balance as num).toDouble();
    } catch (e) {
      print('Error getting balance: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> validatePromoCode(
    String code,
    int courseId,
  ) async {
    try {
      final response = await _dioClient.post(
        '/payments/promo/validate',
        data: {'code': code, 'courseId': courseId},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('Error validating promo code: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getUserUsedPromoCodes() async {
    try {
      final response = await _dioClient.get('/payments/promo/used');
      return response.data as List<dynamic>;
    } catch (e) {
      print('Error getting used promo codes: $e');
      rethrow;
    }
  }
}
