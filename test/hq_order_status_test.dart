import 'package:flutter_test/flutter_test.dart';
import 'package:step_seoul_app/hq/hq_view_data.dart';

void main() {
  final order = {
    'purchase_id': 'o1',
    'shoe_shoe_id': 's1',
    'payment_id': 'p1',
    'user_user_id': 'u1',
    'store_store_id': 'st1',
  };

  test('new order defaults to awaiting dispatch and unreceived', () {
    final db = HqViewData({});
    expect(db.deliveryStatus(order), '출고 대기중');
    expect(db.receiveStatus(order), '미수령');
  });

  test(
    'linked shipment uses actual status and normalizes pickup preparation',
    () {
      final shipment = {
        'purchase_purchase_id': 'o1',
        'shoe_shoe_id': 's1',
        'store_store_id': 'st1',
        'delivery_status': 'Preparing pickup',
      };
      final db = HqViewData({
        'shipment': [shipment],
      });
      expect(db.deliveryStatus(order), '출고 대기중');
      shipment['delivery_status'] = '배송중';
      expect(db.deliveryStatus(order), '배송중');
      shipment['purchase_purchase_id'] = 'other';
      expect(db.deliveryStatus(order), '출고 대기중');
    },
  );

  test('receipt requires matching payment customer and store', () {
    final receipt = {
      'receive_payment_id': 'p1',
      'user_user_id': 'u1',
      'store_store_id': 'st1',
      'receive_status': '수령완료',
    };
    final db = HqViewData({
      'receive': [receipt],
    });
    expect(db.receiveStatus(order), '수령완료');
    receipt['user_user_id'] = 'other';
    expect(db.receiveStatus(order), '미수령');
  });
}
