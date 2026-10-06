import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:step_seoul_app/services/customer_home_service.dart';

final _variantSuffix = RegExp(
  r'_(m|f|u)_([0-9]+)_([0-9]+)$',
  caseSensitive: false,
);

String shoeFamilyPrefix(String shoeId) => shoeId.split('_').first;

String? shoeVariantGender(String shoeId) =>
    _variantSuffix.firstMatch(shoeId)?.group(1)?.toLowerCase();

String? shoeVariantSize(String shoeId) =>
    _variantSuffix.firstMatch(shoeId)?.group(2);

String? shoeColorCode(String shoeId) {
  final suffix = _variantSuffix.firstMatch(shoeId);
  final productId = suffix == null ? shoeId : shoeId.substring(0, suffix.start);
  final separator = productId.lastIndexOf('_');
  if (separator <= 0 || separator == productId.length - 1) return null;
  final code = productId.substring(separator + 1).toLowerCase();
  if (code.trim().isEmpty ||
      RegExp(r'^[0-9]+$').hasMatch(code) ||
      const {'m', 'f', 'u'}.contains(code)) {
    return null;
  }
  return code;
}

class ProductColorOption {
  const ProductColorOption({
    required this.code,
    required this.label,
    this.argb,
  });

  final String code;
  final String label;
  final int? argb;
}

const _knownColors = <String, ProductColorOption>{
  'black': ProductColorOption(code: 'black', label: '검정', argb: 0xFF000000),
  'white': ProductColorOption(code: 'white', label: '흰색', argb: 0xFFFFFFFF),
  'navy': ProductColorOption(code: 'navy', label: '남색', argb: 0xFF000080),
  'gray': ProductColorOption(code: 'gray', label: '회색', argb: 0xFF808080),
  'grey': ProductColorOption(code: 'grey', label: '회색', argb: 0xFF808080),
  'red': ProductColorOption(code: 'red', label: '빨강', argb: 0xFFFF0000),
  'blue': ProductColorOption(code: 'blue', label: '파랑', argb: 0xFF0000FF),
  'green': ProductColorOption(code: 'green', label: '초록', argb: 0xFF008000),
  'yellow': ProductColorOption(code: 'yellow', label: '노랑', argb: 0xFFFFFF00),
  'orange': ProductColorOption(code: 'orange', label: '주황', argb: 0xFFFFA500),
  'pink': ProductColorOption(code: 'pink', label: '분홍', argb: 0xFFFFC0CB),
  'purple': ProductColorOption(code: 'purple', label: '보라', argb: 0xFF800080),
  'brown': ProductColorOption(code: 'brown', label: '갈색', argb: 0xFF8B4513),
  'beige': ProductColorOption(code: 'beige', label: '베이지', argb: 0xFFF5F5DC),
};

List<ProductColorOption> productColorOptions(
  Iterable<CustomerShoe> variants,
  CustomerShoe selectedShoe,
) {
  final family = shoeFamilyPrefix(selectedShoe.id);
  final options = <String, ProductColorOption>{};
  for (final shoe in [selectedShoe, ...variants]) {
    if (shoeFamilyPrefix(shoe.id) != family) continue;
    final code = shoeColorCode(shoe.id);
    if (code == null) continue;
    options.putIfAbsent(
      code,
      () => _knownColors[code] ?? ProductColorOption(code: code, label: code),
    );
  }
  return options.values.toList();
}

CustomerShoe? shoeForColor(
  Iterable<CustomerShoe> variants,
  CustomerShoe selectedShoe,
  String code, {
  String? size,
}) {
  final family = shoeFamilyPrefix(selectedShoe.id);
  final gender = shoeVariantGender(selectedShoe.id);
  final requestedSize = size?.trim();
  final preferredSize = requestedSize?.isNotEmpty == true
      ? requestedSize
      : shoeVariantSize(selectedShoe.id);
  final requestedCode = code.toLowerCase();
  CustomerShoe? best;
  var bestRank = -1;
  for (final shoe in variants) {
    if (shoeFamilyPrefix(shoe.id) != family ||
        shoeColorCode(shoe.id) != requestedCode) {
      continue;
    }
    final sameGender = gender != null && shoeVariantGender(shoe.id) == gender;
    final sameSize =
        preferredSize != null && shoeVariantSize(shoe.id) == preferredSize;
    final rank =
        (sameGender && sameSize ? 4 : 0) +
        (sameGender ? 2 : 0) +
        (shoe.stock > 0 ? 1 : 0);
    if (rank > bestRank) {
      best = shoe;
      bestRank = rank;
    }
  }
  return best;
}

class ProductVariantService {
  ProductVariantService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<CustomerShoe>> loadVariants(CustomerShoe shoe) async {
    final family = shoeFamilyPrefix(shoe.id);
    if (family.isEmpty) {
      throw const ProductVariantException('상품 번호를 확인할 수 없습니다.');
    }
    final uri = Uri.parse(
      '$customerApiBaseUrl/shoe/search',
    ).replace(queryParameters: {'query': family});
    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw const ProductVariantException('상품 색상 정보를 불러오지 못했습니다.');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final records = decoded is Map<String, dynamic>
          ? decoded['result']
          : null;
      if (records is! List) {
        throw const ProductVariantException('상품 색상 정보의 형식이 올바르지 않습니다.');
      }
      final variants = <String, CustomerShoe>{};
      for (final record in records) {
        if (record is! Map<String, dynamic> ||
            record['shoe_id'] is! String ||
            (record['shoe_id'] as String).isEmpty) {
          throw const ProductVariantException('상품 색상 정보의 형식이 올바르지 않습니다.');
        }
        final variant = CustomerShoe.fromJson(record);
        if (shoeFamilyPrefix(variant.id) == family) {
          variants.putIfAbsent(variant.id, () => variant);
        }
      }
      variants.putIfAbsent(shoe.id, () => shoe);
      return variants.values.toList();
    } on ProductVariantException {
      rethrow;
    } on TimeoutException {
      throw const ProductVariantException('상품 색상 정보를 불러오는 시간이 초과되었습니다.');
    } on FormatException {
      throw const ProductVariantException('상품 색상 정보의 형식이 올바르지 않습니다.');
    } catch (_) {
      throw const ProductVariantException('상품 색상 정보를 불러오는 중 연결 오류가 발생했습니다.');
    }
  }

  void dispose() => _client.close();
}

class ProductVariantException implements Exception {
  const ProductVariantException(this.message);

  final String message;

  @override
  String toString() => message;
}
