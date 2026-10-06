import 'package:step_seoul_app/services/customer_home_service.dart';
import 'package:step_seoul_app/view/customer/checkout_payment.dart';

class CheckoutArguments {
  const CheckoutArguments({
    required this.items,
    this.store,
    this.clearCart = false,
  });

  final List<CheckoutLineItem> items;
  final CustomerStore? store;
  final bool clearCart;
}

class BranchListArguments {
  const BranchListArguments({required this.stores, this.selectedStoreId});

  final List<CustomerStore> stores;
  final String? selectedStoreId;
}
