import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class MoneyController extends ChangeNotifier {
  final Logger _log = Logger('money_controller.dart');
  final String entitlementId = 'premium_entitlement';
  SubscriptionOption? subscriptionOption;

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
      _log.log(Level.WARNING, "Error getting customer info: $e");
    }
  }

  void _listenCustomerInfoUpdates() {
    Purchases.addCustomerInfoUpdateListener((info) {
      _customerInfo = info;
       _log.info(Level.INFO, "_customerInfo: $_customerInfo");
      notifyListeners();
    });
  }

  void _querySubscriptionOption() async {
    final products = await Purchases.getProducts(
        <String>["com.indest.triviaplayer.premium"]);
    subscriptionOption = products.first.subscriptionOptions?.first;
    _log.info(Level.INFO, "subscriptionOption: $subscriptionOption");
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
    if (subscriptionOption != null) {
      Purchases.purchaseSubscriptionOption(subscriptionOption!);
    }
  }
}
