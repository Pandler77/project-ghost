import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class EntitlementService extends ChangeNotifier {
  EntitlementService._();

  static final EntitlementService instance = EntitlementService._();

  static const String premiumEntitlementId = 'modose_premium';

  bool _hasPremium = false;
  bool _isLoading = true;

  bool get hasPremium => _hasPremium;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final customerInfo = await Purchases.getCustomerInfo();

      _updateFromCustomerInfo(customerInfo);

      Purchases.addCustomerInfoUpdateListener(_updateFromCustomerInfo);
    } catch (error) {
      debugPrint('Could not load RevenueCat entitlement: $error');

      _hasPremium = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();

      _updateFromCustomerInfo(customerInfo);
    } catch (error) {
      debugPrint('Could not refresh RevenueCat entitlement: $error');
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();

      _updateFromCustomerInfo(customerInfo);

      return _hasPremium;
    } catch (error) {
      debugPrint('Could not restore purchases: $error');
      rethrow;
    }
  }

  void _updateFromCustomerInfo(CustomerInfo customerInfo) {
    final newValue = customerInfo.entitlements.active.containsKey(
      premiumEntitlementId,
    );

    if (_hasPremium == newValue) {
      return;
    }

    _hasPremium = newValue;
    notifyListeners();
  }

  void setPremiumForTesting(bool value) {
    assert(() {
      _hasPremium = value;
      notifyListeners();
      return true;
    }());
  }
}
