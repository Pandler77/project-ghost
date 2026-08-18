class EntitlementService {
  EntitlementService._();

  static final EntitlementService instance = EntitlementService._();

  bool _hasPremium = true;

  bool get hasPremium => _hasPremium;

  void setPremiumForTesting(bool value) {
    _hasPremium = value;
  }
}
