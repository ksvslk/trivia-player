import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:operation_veritas/extensions.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class MoneyController extends ChangeNotifier {
  final Logger _log = Logger('money_controller.dart');
  final String entitlementId = 'premium_entitlement';
  StoreProduct? _product; // Change this line

  String _cleanTitle(String title) {
    int index = title.indexOf('(');
    return index != -1 ? title.substring(0, index).trim() : title;
  }

  String? getProductFriendlyInfo() {
    return "${_cleanTitle(_product?.title ?? '...')} - ${_product?.priceString}/${_product?.subscriptionPeriod?.toFriendlyEnglish()}";
  }

  CustomerInfo? _customerInfo;

  MoneyController() {
    _queryCustomerInfo();
    _listenCustomerInfoUpdates();
    _querySubscriptionOption();
  }

  void _queryCustomerInfo() async {
    try {
      _customerInfo = await Purchases.getCustomerInfo();
      notifyListeners();
    } on PlatformException catch (e) {
      _log.log(Level.SEVERE, "Error getting customer info: $e");
    }
  }

  void _listenCustomerInfoUpdates() {
    Purchases.addCustomerInfoUpdateListener((info) {
      _customerInfo = info;
      notifyListeners();
    });
  }

  void _querySubscriptionOption() async {
    try {
      final products = await Purchases.getProducts(<String>[
        "com.indest.triviaplayer.premium",
      ]);
      if (products.isNotEmpty) {
        final product = products.first;
        _product = product; 
        _log.info("Product found: ${product.identifier}");
      }
    } catch (e) {
      _log.severe("Error getting products: $e");
    }
    notifyListeners();
  }

  bool isSubscribed() {
    if (_customerInfo?.entitlements.all[entitlementId]?.isActive == true) {
      return true;
    } else {
      return false;
    }
  }

  void purchaseSubscription() {
    if (_product != null) {
      Purchases.purchaseStoreProduct(_product!); // Change this line
    }
  }
}
