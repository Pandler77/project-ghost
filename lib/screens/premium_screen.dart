import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/services.dart';

import '../services/app_data_service.dart';
import '../services/entitlement_service.dart';
import '../services/usage_analytics_service.dart';
import '../theme/app_theme.dart';
import '../theme/arctic_icons.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({required this.dataService, super.key});

  final AppDataService dataService;

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  Offering? _offering;

  bool _isLoading = true;
  bool _isPurchasing = false;
  bool _isRestoring = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    UsageAnalyticsService.instance.track(
      UsageAnalyticsEvent.premiumScreenViewed,
      properties: {'premium_active': widget.dataService.hasPremium},
    );

    EntitlementService.instance.addListener(_handleEntitlementChanged);

    _loadOffering();
  }

  @override
  void dispose() {
    EntitlementService.instance.removeListener(_handleEntitlementChanged);
    super.dispose();
  }

  void _handleEntitlementChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _loadOffering() async {
    try {
      final offerings = await Purchases.getOfferings();

      if (!mounted) {
        return;
      }

      setState(() {
        _offering = offerings.current;
        _isLoading = false;

        if (_offering == null) {
          _errorMessage = 'Subscription options are currently unavailable.';
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load subscription options.';
      });
    }
  }

  Future<void> _purchasePackage(Package package) async {
    if (_isPurchasing || _isRestoring) {
      return;
    }

    setState(() {
      _isPurchasing = true;
      _errorMessage = null;
    });

    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));

      final hasPremium = result.customerInfo.entitlements.active.containsKey(
        EntitlementService.premiumEntitlementId,
      );

      await EntitlementService.instance.refresh();

      if (!mounted) {
        return;
      }

      setState(() {
        _isPurchasing = false;
      });

      if (hasPremium) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('MODOSE Premium is now active.')),
        );
      } else {
        setState(() {
          _errorMessage =
              'The purchase completed, but Premium access could not be verified.';
        });
      }
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }

      final errorCode = PurchasesErrorHelper.getErrorCode(error);

      setState(() {
        _isPurchasing = false;
      });

      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return;
      }

      setState(() {
        _errorMessage = 'The purchase could not be completed.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isPurchasing = false;
        _errorMessage = 'The purchase could not be completed.';
      });
    }
  }

  Future<void> _restorePurchases() async {
    if (_isRestoring || _isPurchasing) {
      return;
    }

    setState(() {
      _isRestoring = true;
      _errorMessage = null;
    });

    try {
      final restored = await EntitlementService.instance.restorePurchases();

      if (!mounted) {
        return;
      }

      setState(() {
        _isRestoring = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            restored
                ? 'MODOSE Premium restored.'
                : 'No active MODOSE Premium subscription was found.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isRestoring = false;
        _errorMessage = 'Could not restore purchases.';
      });
    }
  }

  Package? _packageForType(PackageType type) {
    final packages = _offering?.availablePackages;

    if (packages == null) {
      return null;
    }

    for (final package in packages) {
      if (package.packageType == type) {
        return package;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasPremium = widget.dataService.hasPremium;

    final monthlyPackage = _packageForType(PackageType.monthly);
    final annualPackage = _packageForType(PackageType.annual);

    return Scaffold(
      appBar: AppBar(title: const Text('MODOSE Premium')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            40,
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hasPremium
                      ? [
                          const Color(0xFFE3AA22).withValues(alpha: 0.20),
                          const Color(0xFFE3AA22).withValues(alpha: 0.07),
                        ]
                      : [
                          colors.primary.withValues(alpha: 0.18),
                          colors.primary.withValues(alpha: 0.06),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: hasPremium
                      ? const Color(0xFFE3AA22).withValues(alpha: 0.70)
                      : colors.primary.withValues(alpha: 0.45),
                  width: hasPremium ? 1.5 : 1.25,
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 82,
                    height: 82,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          hasPremium ? const Color(0xFFE3AA22) : colors.primary,
                          BlendMode.srcIn,
                        ),
                        child: Image.asset(
                          'assets/branding/modose_premium_mark.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    hasPremium
                        ? 'MODOSE Premium is active'
                        : 'Unlock the full MODOSE experience',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: hasPremium
                          ? const Color(0xFFB77A00)
                          : colors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    hasPremium
                        ? 'You have access to all current premium features.'
                        : 'Track without limits, manage supplies, use multiple profiles, and unlock deeper insights.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTypography.body,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            const Text(
              'Included with Premium',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            const _PremiumFeatureCard(
              icon: ArcticIcons.all_inclusive,
              title: 'Unlimited dose logging',
              description:
                  'Continue tracking after the first 10 free completed doses.',
            ),

            const SizedBox(height: AppSpacing.sm),

            const _PremiumFeatureCard(
              icon: ArcticIcons.inventory_2_outlined,
              title: 'MODOSE Supply™',
              description:
                  'Track inventory, remaining doses, open containers, low stock, vendors, and reorder timing.',
            ),

            const SizedBox(height: AppSpacing.sm),

            const _PremiumFeatureCard(
              icon: ArcticIcons.people_outline,
              title: 'Multiple profiles',
              description:
                  'Keep protocols, history, weight, inventory, and schedules separated for each person or dependent.',
            ),

            const SizedBox(height: AppSpacing.sm),

            const _PremiumFeatureCard(
              icon: ArcticIcons.insights_outlined,
              title: 'Weight analytics',
              description:
                  'Unlock detailed trends, date ranges, weekly changes, records, goals, and projections.',
            ),

            const SizedBox(height: AppSpacing.sm),

            const _PremiumFeatureCard(
              icon: ArcticIcons.compare_outlined,
              title: 'Progress photo comparison',
              description:
                  'Compare progress sessions side by side to see visual changes over time.',
            ),

            const SizedBox(height: AppSpacing.sm),

            const _PremiumFeatureCard(
              icon: ArcticIcons.analytics_outlined,
              title: 'Advanced statistics',
              description:
                  'See adherence, missed doses, streaks, total usage, and protocol performance.',
            ),

            const SizedBox(height: AppSpacing.sm),

            const _PremiumFeatureCard(
              icon: ArcticIcons.calculate_outlined,
              title: 'Advanced calculators',
              description:
                  'Unlock specialized dosing calculators including Dose from Units and BAC Water.',
            ),

            const SizedBox(height: AppSpacing.lg),

            if (!hasPremium) ...[
              if (_isLoading)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                )
              else ...[
                if (monthlyPackage != null)
                  _SubscriptionOptionCard(
                    title: 'Monthly',
                    subtitle: 'Flexible monthly billing',
                    price: '${monthlyPackage.storeProduct.priceString} / month',
                    badge: null,
                    enabled: !_isPurchasing && !_isRestoring,
                    loading: _isPurchasing,
                    onTap: () => _purchasePackage(monthlyPackage),
                  ),

                if (monthlyPackage != null && annualPackage != null)
                  const SizedBox(height: AppSpacing.sm),

                if (annualPackage != null)
                  _SubscriptionOptionCard(
                    title: 'Annual',
                    subtitle: 'Best value for long-term tracking',
                    price: '${annualPackage.storeProduct.priceString} / year',
                    badge: 'BEST VALUE',
                    enabled: !_isPurchasing && !_isRestoring,
                    loading: _isPurchasing,
                    onTap: () => _purchasePackage(annualPackage),
                  ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.errorContainer,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              TextButton(
                onPressed: _isPurchasing || _isRestoring
                    ? null
                    : _restorePurchases,
                child: _isRestoring
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Restore Purchases'),
              ),

              const SizedBox(height: AppSpacing.sm),

              Text(
                'Subscriptions are billed through the App Store or Google Play and automatically renew unless cancelled at least 24 hours before the end of the current billing period. You can manage or cancel your subscription in your store account settings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3AA22).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: const Color(0xFFE3AA22).withValues(alpha: 0.35),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      ArcticIcons.verified_outlined,
                      color: Color(0xFFB77A00),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Your Premium features are unlocked.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              TextButton(
                onPressed: _isRestoring ? null : _restorePurchases,
                child: const Text('Restore Purchases'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SubscriptionOptionCard extends StatelessWidget {
  const _SubscriptionOptionCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.enabled,
    required this.loading,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String subtitle;
  final String price;
  final String? badge;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: badge != null ? colors.primary : colors.outlineVariant,
              width: badge != null ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: AppTypography.title,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                fontSize: AppTypography.micro,
                                fontWeight: FontWeight.w900,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      price,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: AppTypography.body,
                        fontWeight: FontWeight.w800,
                        color: colors.primary,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumFeatureCard extends StatelessWidget {
  const _PremiumFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Icon(icon, color: colors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
