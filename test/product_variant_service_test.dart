import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:step_seoul_app/services/customer_home_service.dart';
import 'package:step_seoul_app/services/product_variant_service.dart';

CustomerShoe _shoe(String id, {int stock = 3}) => CustomerShoe(
  id: id,
  name: '에어포스 블랙',
  category: '러닝',
  imageUrl: null,
  price: '10000',
  stock: stock,
);

http.Response _response(Object payload, {int status = 200}) =>
    http.Response.bytes(utf8.encode(jsonEncode(payload)), status);

void main() {
  final selected = _shoe('airforce_black_m_280_00');

  test('variant suffix parsing separates color, gender and size', () {
    expect(shoeFamilyPrefix(selected.id), 'airforce');
    expect(shoeColorCode(selected.id), 'black');
    expect(shoeVariantGender(selected.id), 'm');
    expect(shoeVariantSize(selected.id), '280');
    expect(shoeColorCode('airforce_WHITE_F_250_02'), 'white');
    expect(shoeVariantGender('airforce_WHITE_F_250_02'), 'f');
    expect(shoeColorCode('airforce_black'), 'black');
    expect(shoeVariantSize('airforce_black'), isNull);
  });

  test(
    'missing colors and malformed numeric IDs do not create color choices',
    () {
      for (final id in [
        '',
        'airforce',
        'airforce_',
        '_black',
        'airforce_m_280_00',
        'airforce_black_m_280',
        'airforce_280_m_black_00',
      ]) {
        expect(shoeColorCode(id), isNull, reason: id);
        expect(
          productColorOptions([_shoe(id)], _shoe(id)),
          isEmpty,
          reason: id,
        );
      }
    },
  );

  test('single known black SKU yields only the black option', () {
    final colors = productColorOptions([selected], selected);

    expect(colors, hasLength(1));
    expect(colors.single.code, 'black');
    expect(colors.single.label, '검정');
    expect(colors.single.argb, 0xFF000000);
    expect(shoeForColor([selected], selected, 'white'), isNull);
  });

  test('color choices deduplicate SKUs and keep selected color first', () {
    final colors = productColorOptions([
      _shoe('airforce_white_f_250_00'),
      _shoe('airforce_white_m_280_00'),
      _shoe('airforce_black_f_250_01'),
      _shoe('airforce_mint_m_280_00'),
      _shoe('airforce2_navy_m_280_00'),
      _shoe('dunk_red_m_280_00'),
    ], selected);

    expect(colors.map((option) => option.code), ['black', 'white', 'mint']);
    expect(colors.last.label, 'mint');
    expect(colors.last.argb, isNull);
  });

  test(
    'color selection returns the actual SKU for selected gender and size',
    () {
      final female = _shoe('airforce_white_f_280_00');
      final otherSize = _shoe('airforce_white_m_270_00');
      final exactUnavailable = _shoe('airforce_white_m_280_00', stock: 0);
      final exactAvailable = _shoe('airforce_white_m_280_01');
      final otherFamily = _shoe('airforce2_white_m_280_00');
      final variants = [
        otherFamily,
        female,
        otherSize,
        exactUnavailable,
        exactAvailable,
      ];

      expect(shoeForColor(variants, selected, 'white'), same(exactAvailable));
      expect(
        shoeForColor(variants, selected, 'white', size: '270'),
        same(otherSize),
      );
      expect(
        shoeForColor([female, otherSize], selected, 'white'),
        same(otherSize),
      );
      expect(shoeForColor([otherFamily], selected, 'white'), isNull);
    },
  );

  test(
    'selection uses stock and stable order when gender cannot be matched',
    () {
      final unavailable = _shoe('airforce_white_f_250_00', stock: 0);
      final available = _shoe('airforce_white_f_260_00');
      final anotherAvailable = _shoe('airforce_white_u_280_00');

      expect(
        shoeForColor(
          [unavailable, available, anotherAvailable],
          selected,
          'white',
        ),
        same(available),
      );
      expect(shoeForColor([unavailable], selected, 'white'), same(unavailable));
    },
  );

  test(
    'API broad search excludes prefix and brand false matches, deduplicates IDs',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/shoe/search');
        expect(request.url.queryParameters, {'query': 'airforce'});
        return _response({
          'result': [
            {'shoe_id': selected.id, 'shoe_name': '에어포스 블랙'},
            {'shoe_id': 'airforce_white_m_280_00', 'shoe_name': '에어포스 화이트'},
            {'shoe_id': 'airforce_white_m_280_00', 'shoe_name': '중복'},
            {'shoe_id': 'airforce2_navy_m_280_00', 'brand_name': 'airforce'},
            {'shoe_id': 'dunk_red_m_280_00', 'brand_name': 'airforce'},
          ],
        });
      });
      final service = ProductVariantService(client: client);
      addTearDown(service.dispose);

      final variants = await service.loadVariants(selected);

      expect(variants.map((shoe) => shoe.id), [
        selected.id,
        'airforce_white_m_280_00',
      ]);
      expect(variants.last.name, '에어포스 화이트');
      expect(
        productColorOptions(variants, selected).map((color) => color.code),
        ['black', 'white'],
      );
    },
  );

  test(
    'empty API result keeps the known current SKU without adding colors',
    () async {
      final service = ProductVariantService(
        client: MockClient((_) async => _response({'result': []})),
      );
      addTearDown(service.dispose);

      final variants = await service.loadVariants(selected);

      expect(variants.single, same(selected));
      expect(productColorOptions(variants, selected).single.code, 'black');
    },
  );

  test(
    'invalid API payloads fail clearly while known current color stays available',
    () async {
      for (final response in [
        _response({'result': 'invalid'}),
        _response({
          'result': [42],
        }),
        _response({
          'result': [
            {'shoe_id': null},
          ],
        }),
        http.Response('{invalid json', 200),
      ]) {
        final service = ProductVariantService(
          client: MockClient((_) async => response),
        );
        try {
          await expectLater(
            service.loadVariants(selected),
            throwsA(
              isA<ProductVariantException>().having(
                (error) => error.message,
                'message',
                contains('형식'),
              ),
            ),
          );
          expect(
            productColorOptions([selected], selected).single.code,
            'black',
          );
        } finally {
          service.dispose();
        }
      }
    },
  );

  test(
    'HTTP failure and transport failure produce Korean error messages',
    () async {
      for (final client in [
        MockClient(
          (_) async => _response({'error': 'unavailable'}, status: 503),
        ),
        MockClient((_) async => throw http.ClientException('offline')),
      ]) {
        final service = ProductVariantService(client: client);
        try {
          await expectLater(
            service.loadVariants(selected),
            throwsA(
              isA<ProductVariantException>().having(
                (error) => error.message,
                'message',
                contains('상품 색상 정보'),
              ),
            ),
          );
        } finally {
          service.dispose();
        }
      }
    },
  );
}
