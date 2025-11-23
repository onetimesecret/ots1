import 'dart:math';
import '../entities/monitoring.dart';
import '../entities/pricing_analysis.dart';

/// Engine for detecting and preventing cross-region arbitrage
class ArbitrageDetectionEngine {
  final Random _random = Random();

  /// Detect arbitrage opportunities across regions
  Future<List<ArbitrageOpportunity>> detectArbitrage({
    required Map<String, Map<String, double>> regionalPricing,
    required Map<String, double> transferCosts,
    required Map<String, double> exchangeRates,
  }) async {
    final opportunities = <ArbitrageOpportunity>[];
    final regions = regionalPricing.keys.toList();

    // Compare all region pairs
    for (int i = 0; i < regions.length; i++) {
      for (int j = i + 1; j < regions.length; j++) {
        final sourceRegion = regions[i];
        final targetRegion = regions[j];

        final sourcePricing = regionalPricing[sourceRegion]!;
        final targetPricing = regionalPricing[targetRegion]!;

        // Check each product tier
        for (final tier in sourcePricing.keys) {
          final sourcePrice = sourcePricing[tier]!;
          final targetPrice = targetPricing[tier] ?? 0;

          if (targetPrice == 0) continue;

          // Calculate adjusted price with transfer costs and exchange rates
          final transferCost = transferCosts['$sourceRegion-$targetRegion'] ?? 0;
          final exchangeRate = exchangeRates[sourceRegion] ?? 1.0;
          final adjustedSourcePrice = sourcePrice * exchangeRate + transferCost;

          final priceDifferential = targetPrice - adjustedSourcePrice;
          final differentialPercent = (priceDifferential / targetPrice).abs() * 100;

          // Flag if differential is significant
          if (differentialPercent > 15) {
            final potentialProfit = priceDifferential * 100; // Estimate for 100 units
            final riskScore = _calculateArbitrageRisk(
              differential: differentialPercent,
              sourceRegion: sourceRegion,
              targetRegion: targetRegion,
            );

            opportunities.add(
              ArbitrageOpportunity(
                id: 'arb_${DateTime.now().millisecondsSinceEpoch}_$i$j',
                sourceRegion: sourceRegion,
                targetRegion: targetRegion,
                productTier: tier,
                priceDifferential: priceDifferential,
                potentialProfit: potentialProfit,
                riskScore: riskScore,
                preventionMeasures: _generatePreventionMeasures(
                  differential: differentialPercent,
                  riskScore: riskScore,
                ),
                requiresAction: riskScore > 0.6,
              ),
            );
          }
        }
      }
    }

    return opportunities..sort((a, b) => b.riskScore.compareTo(a.riskScore));
  }

  /// Generate prevention strategies for arbitrage
  Future<Map<String, dynamic>> generatePreventionStrategy({
    required List<ArbitrageOpportunity> opportunities,
    required Map<String, Map<String, double>> regionalPricing,
  }) async {
    final strategies = <String, dynamic>{};
    final highRiskOpportunities = opportunities.where((o) => o.riskScore > 0.6).toList();

    strategies['summary'] = {
      'totalOpportunities': opportunities.length,
      'highRiskCount': highRiskOpportunities.length,
      'totalRiskScore': opportunities.isEmpty
          ? 0.0
          : opportunities.map((o) => o.riskScore).reduce((a, b) => a + b) / opportunities.length,
    };

    strategies['regionalAdjustments'] = await _calculateRegionalAdjustments(
      opportunities: highRiskOpportunities,
      regionalPricing: regionalPricing,
    );

    strategies['enforcementMeasures'] = [
      'Implement geo-IP verification',
      'Require billing address verification',
      'Monitor suspicious purchase patterns',
      'Apply region-locked licensing',
      'Implement usage-based verification',
    ];

    strategies['pricingHarmonization'] = await _generateHarmonizationPlan(
      opportunities: opportunities,
      regionalPricing: regionalPricing,
    );

    return strategies;
  }

  /// Monitor for suspicious arbitrage activity
  Future<List<Alert>> monitorArbitrageActivity({
    required List<Map<String, dynamic>> transactions,
    required Map<String, Map<String, double>> regionalPricing,
  }) async {
    final alerts = <Alert>[];
    final suspiciousPatterns = <String, int>{};

    for (final transaction in transactions) {
      final userId = transaction['userId'] as String;
      final region = transaction['region'] as String;
      final tier = transaction['tier'] as String;
      final billingCountry = transaction['billingCountry'] as String? ?? region;

      // Check for region mismatch
      if (region != billingCountry) {
        suspiciousPatterns[userId] = (suspiciousPatterns[userId] ?? 0) + 1;

        if (suspiciousPatterns[userId]! > 3) {
          alerts.add(
            Alert(
              id: 'arb_activity_${DateTime.now().millisecondsSinceEpoch}',
              type: 'arbitrage_activity',
              severity: 'warning',
              message: 'Suspicious arbitrage activity detected for user $userId: '
                  'Multiple purchases from different regions',
              triggeredAt: DateTime.now(),
              metadata: {
                'userId': userId,
                'transactionCount': suspiciousPatterns[userId],
                'regions': [region, billingCountry],
              },
              recommendedActions: [
                'Review user purchase history',
                'Verify billing information',
                'Consider account restriction',
                'Investigate IP patterns',
              ],
            ),
          );
        }
      }
    }

    return alerts;
  }

  /// Calculate risk-adjusted pricing across regions
  Future<Map<String, Map<String, double>>> calculateRiskAdjustedPricing({
    required Map<String, Map<String, double>> basePricing,
    required List<ArbitrageOpportunity> opportunities,
    required double riskTolerance,
  }) async {
    final adjustedPricing = <String, Map<String, double>>{};

    for (final region in basePricing.keys) {
      adjustedPricing[region] = Map.from(basePricing[region]!);

      // Find opportunities affecting this region
      final regionOpportunities = opportunities.where(
        (o) => o.sourceRegion == region || o.targetRegion == region,
      );

      for (final opp in regionOpportunities) {
        if (opp.riskScore > riskTolerance) {
          final tier = opp.productTier;
          final currentPrice = adjustedPricing[region]![tier] ?? 0;

          // Apply risk-based adjustment
          final adjustment = _calculateRiskAdjustment(
            riskScore: opp.riskScore,
            differential: opp.priceDifferential,
            isSource: opp.sourceRegion == region,
          );

          adjustedPricing[region]![tier] = currentPrice * (1 + adjustment);
        }
      }
    }

    return adjustedPricing;
  }

  double _calculateArbitrageRisk({
    required double differential,
    required String sourceRegion,
    required String targetRegion,
  }) {
    // Base risk on price differential
    double risk = min(1.0, differential / 50);

    // Adjust for region characteristics
    final highRiskPairs = {
      'North America-Asia Pacific': 0.2,
      'Europe-Latin America': 0.15,
      'Middle East-Africa': 0.1,
    };

    final pair = '$sourceRegion-$targetRegion';
    risk += highRiskPairs[pair] ?? 0;

    return min(1.0, risk);
  }

  List<String> _generatePreventionMeasures({
    required double differential,
    required double riskScore,
  }) {
    final measures = <String>['Monitor cross-region purchases'];

    if (differential > 20) {
      measures.add('Implement stricter geo-verification');
    }

    if (riskScore > 0.7) {
      measures.addAll([
        'Apply region-locked licensing',
        'Require additional verification',
        'Implement purchase limits',
      ]);
    } else if (riskScore > 0.4) {
      measures.add('Enhanced transaction monitoring');
    }

    measures.add('Regular pricing review');

    return measures;
  }

  Future<Map<String, Map<String, double>>> _calculateRegionalAdjustments({
    required List<ArbitrageOpportunity> opportunities,
    required Map<String, Map<String, double>> regionalPricing,
  }) async {
    final adjustments = <String, Map<String, double>>{};

    for (final opp in opportunities) {
      // Suggest narrowing the gap
      final targetAdjustment = opp.priceDifferential * 0.3; // Close 30% of gap

      adjustments.putIfAbsent(opp.sourceRegion, () => {});
      adjustments.putIfAbsent(opp.targetRegion, () => {});

      adjustments[opp.sourceRegion]![opp.productTier] = targetAdjustment * 0.5;
      adjustments[opp.targetRegion]![opp.productTier] = -targetAdjustment * 0.5;
    }

    return adjustments;
  }

  Future<Map<String, dynamic>> _generateHarmonizationPlan({
    required List<ArbitrageOpportunity> opportunities,
    required Map<String, Map<String, double>> regionalPricing,
  }) async {
    final plan = <String, dynamic>{};

    // Calculate average pricing for each tier
    final tierAverages = <String, double>{};
    for (final regionPrices in regionalPricing.values) {
      for (final entry in regionPrices.entries) {
        tierAverages[entry.key] = (tierAverages[entry.key] ?? 0) + entry.value;
      }
    }

    final regionCount = regionalPricing.length;
    tierAverages.updateAll((key, value) => value / regionCount);

    plan['targetPricing'] = tierAverages;
    plan['phases'] = [
      {
        'name': 'Phase 1: High-risk regions',
        'duration': '30 days',
        'regions': opportunities
            .where((o) => o.riskScore > 0.7)
            .map((o) => o.sourceRegion)
            .toSet()
            .toList(),
      },
      {
        'name': 'Phase 2: Medium-risk regions',
        'duration': '60 days',
        'regions': opportunities
            .where((o) => o.riskScore > 0.4 && o.riskScore <= 0.7)
            .map((o) => o.sourceRegion)
            .toSet()
            .toList(),
      },
      {
        'name': 'Phase 3: Low-risk regions',
        'duration': '90 days',
        'regions': regionalPricing.keys.toList(),
      },
    ];

    return plan;
  }

  double _calculateRiskAdjustment({
    required double riskScore,
    required double differential,
    required bool isSource,
  }) {
    // For source region (lower price), increase price
    // For target region (higher price), decrease price
    final adjustmentMagnitude = min(0.1, riskScore * 0.15);
    return isSource ? adjustmentMagnitude : -adjustmentMagnitude;
  }
}
