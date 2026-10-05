import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/coupon.dart';
import 'api_config.dart';
import 'authenticated_http_client.dart' as http;

class CouponsApiException implements Exception {
  const CouponsApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class CouponsService {
  CouponsService();

  final String _baseUrl = ApiConfig.baseUrl + ApiConfig.couponsPath;

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  dynamic _decode(http.Response response) {
    final dynamic data = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map
          ? (data['error'] ?? data['message'] ?? 'Error en Cupones API').toString()
          : 'Error en Cupones API';
      throw CouponsApiException(message, response.statusCode);
    }
    return data;
  }

  List<CouponGift> _giftsFromResponse(dynamic data) {
    final dynamic gifts = data is List
        ? data
        : data is Map
        ? (data['regalos'] ?? data['items'] ?? const [])
        : const [];
    return (gifts as List)
        .whereType<Map>()
        .map((gift) => CouponGift.fromJson(Map<String, dynamic>.from(gift)))
        .toList();
  }

  Future<List<CouponGift>> getGifts() async {
    debugPrint('🔵 [CouponsService] getGifts: GET iniciado');
    final response = await http.get(_uri('/regalos'), headers: _headers);
    debugPrint('⚪️ [CouponsService] getGifts: respuesta HTTP ${response.statusCode}');
    final gifts = _giftsFromResponse(_decode(response));
    debugPrint('🟢 [CouponsService] getGifts: parseados ${gifts.length} regalos');
    return gifts;
  }

  Future<void> createCoupon(List<CouponGift> gifts) async {
    debugPrint('🔵 [CouponsService] createCoupon: POST iniciado');
    final response = await http.post(
      _uri(''),
      headers: _headers,
      body: jsonEncode({'regalos': gifts.map((gift) => gift.toJson()).toList()}),
    );
    debugPrint('⚪️ [CouponsService] createCoupon: respuesta HTTP ${response.statusCode}');
    _decode(response);
    debugPrint('🟢 [CouponsService] createCoupon: completado');
  }

  Future<void> addGift(CouponGift gift) async {
    debugPrint('🔵 [CouponsService] addGift: POST iniciado');
    final response = await http.post(
      _uri('/regalos'),
      headers: _headers,
      body: jsonEncode(gift.toJson()),
    );
    debugPrint('⚪️ [CouponsService] addGift: respuesta HTTP ${response.statusCode}');
    _decode(response);
    debugPrint('🟢 [CouponsService] addGift: completado');
  }

  Future<void> updateGift(String originalName, CouponGift gift) async {
    debugPrint('🔵 [CouponsService] updateGift: PUT iniciado');
    final response = await http.put(
      _uri('/regalos/${Uri.encodeComponent(originalName)}'),
      headers: _headers,
      body: jsonEncode(gift.toJson()),
    );
    debugPrint('⚪️ [CouponsService] updateGift: respuesta HTTP ${response.statusCode}');
    _decode(response);
    debugPrint('🟢 [CouponsService] updateGift: completado');
  }

  Future<void> setRedeemed(String name, bool redeemed) async {
    debugPrint('🔵 [CouponsService] setRedeemed: PATCH iniciado');
    final response = await http.patch(
      _uri('/regalos/${Uri.encodeComponent(name)}/canjear'),
      headers: _headers,
      body: jsonEncode({'canjeado': redeemed}),
    );
    debugPrint('⚪️ [CouponsService] setRedeemed: respuesta HTTP ${response.statusCode}');
    _decode(response);
    debugPrint('🟢 [CouponsService] setRedeemed: completado');
  }

  Future<void> deleteGift(String name) async {
    debugPrint('🔵 [CouponsService] deleteGift: DELETE iniciado');
    final response = await http.delete(
      _uri('/regalos/${Uri.encodeComponent(name)}'),
      headers: _headers,
    );
    debugPrint('⚪️ [CouponsService] deleteGift: respuesta HTTP ${response.statusCode}');
    _decode(response);
    debugPrint('🟢 [CouponsService] deleteGift: completado');
  }

  Future<void> deleteCoupon() async {
    debugPrint('🔵 [CouponsService] deleteCoupon: DELETE iniciado');
    final response = await http.delete(_uri(''), headers: _headers);
    debugPrint('⚪️ [CouponsService] deleteCoupon: respuesta HTTP ${response.statusCode}');
    _decode(response);
    debugPrint('🟢 [CouponsService] deleteCoupon: completado');
  }
}