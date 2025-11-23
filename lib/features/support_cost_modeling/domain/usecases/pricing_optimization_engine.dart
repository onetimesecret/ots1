import 'dart:math';
import '../entities/market_segment.dart';
import '../entities/pricing_analysis.dart';

/// Advanced pricing optimization engine
class PricingOptimizationEngine {
  final Random _random = Random();

  /// Run comprehensive pricing analysis for a market segment
  Future<PricingAnalysis> analyzePricing({
    required MarketSegment segment,
    required List<ProductTier> productTiers,
    required List<Map<String, dynamic>> competitorData,
  }) async {
    // Generate tier recommendations
    final tierRecommendations = await _optimizeTierPricing(
      segment: segment,
      tiers: productTiers,
    );

    // Generate revenue projections for all market conditions
    final revenueProjections = await _projectRevenue(
      segment: segment,
      recommendations: tierRecommendations,
    );

    // Analyze competitive positioning
    final competitivePositioning = await _analyzeCompetitivePosition(
      segment: segment,
      recommendations: tierRecommendations,
      competitors: competitorData,
    );

    // Perform sensitivity analysis
    final sensitivityAnalysis = await _performSensitivityAnalysis(
      segment: segment,
      recommendations: tierRecommendations,
    );

    // Assess risks
    final riskAssessment = await _assessRisks(
      segment: segment,
      recommendations: tierRecommendations,
      competitivePositioning: competitivePositioning,
    );

    // Generate implementation plan
    final implementationPlan = await _generateImplementationPlan(
      segment: segment,
      recommendations: tierRecommendations,
    );

    return PricingAnalysis(
      segmentId: segment.id,
      segmentName: segment.name,
      generatedAt: DateTime.now(),
      tierRecommendations: tierRecommendations,
      revenueProjections: revenueProjections,
      competitivePositioning: competitivePositioning,
      sensitivityAnalysis: sensitivityAnalysis,
      riskAssessment: riskAssessment,
      implementationPlan: implementationPlan,
    );
  }

  Future<List<TierPricingRecommendation>> _optimizeTierPricing({
    required MarketSegment segment,
    required List<ProductTier> tiers,
  }) async {
    final recommendations = <TierPricingRecommendation>[];

    for (final tier in tiers) {
      // Find optimal price using elasticity curve
      final baseDemand = segment.marketSize * segment.penetrationRate;
      final optimalPrice = segment.elasticityCurve.findOptimalPrice(baseDemand);

      // Calculate demand at optimal price
      final demandMultiplier = segment.elasticityCurve.calculateDemand(optimalPrice);
      final projectedDemand = baseDemand * demandMultiplier;

      // Calculate revenue and costs
      final projectedRevenue = optimalPrice * projectedDemand;
      final supportCost = tier.supportCost * projectedDemand;
      final margin = projectedRevenue - supportCost;

      recommendations.add(
        TierPricingRecommendation(
          tierId: tier.id,
          tierName: tier.name,
          optimalPrice: optimalPrice,
          minPrice: optimalPrice * 0.8,
          maxPrice: optimalPrice * 1.3,
          projectedDemand: projectedDemand,
          projectedRevenue: projectedRevenue,
          supportCost: supportCost,
          margin: margin,
          rationale: _generateRationale(
            segment: segment,
            tier: tier,
            optimalPrice: optimalPrice,
          ),
        ),
      );
    }

    return recommendations;
  }

  Future<Map<MarketCondition, RevenueProjection>> _projectRevenue({
    required MarketSegment segment,
    required List<TierPricingRecommendation> recommendations,
  }) async {
    final projections = <MarketCondition, RevenueProjection>{};

    for (final condition in MarketCondition.values) {
      final multiplier = condition.demandMultiplier;

      double totalRevenue = 0;
      double totalCost = 0;
      int totalCustomers = 0;
      final revenueByTier = <String, double>{};

      for (final rec in recommendations) {
        final adjustedDemand = rec.projectedDemand * multiplier;
        final revenue = rec.optimalPrice * adjustedDemand;
        final cost = rec.supportCost * multiplier;

        totalRevenue += revenue;
        totalCost += cost;
        totalCustomers += adjustedDemand.toInt();
        revenueByTier[rec.tierName] = revenue;
      }

      final arpu = totalCustomers > 0 ? totalRevenue / totalCustomers : 0;
      final churnRate = _estimateChurnRate(condition);
      final clv = arpu * (1 / churnRate) * 12;

      projections[condition] = RevenueProjection(
        condition: condition,
        totalRevenue: totalRevenue,
        totalCost: totalCost,
        netProfit: totalRevenue - totalCost,
        customerCount: totalCustomers.toDouble(),
        averageRevenuePerUser: arpu,
        customerLifetimeValue: clv,
        churnRate: churnRate,
        revenueByTier: revenueByTier,
      );
    }

    return projections;
  }

  Future<CompetitivePositioning> _analyzeCompetitivePosition({
    required MarketSegment segment,
    required List<TierPricingRecommendation> recommendations,
    required List<Map<String, dynamic>> competitors,
  }) async {
    final competitorAnalyses = competitors.map((c) {
      return CompetitorAnalysis(
        name: c['name'] as String,
        avgPrice: c['avgPrice'] as double,
        marketShare: c['marketShare'] as double,
        customerSatisfaction: c['customerSatisfaction'] as double,
        strengths: List<String>.from(c['strengths'] as List),
        weaknesses: List<String>.from(c['weaknesses'] as List),
        threatLevel: c['threatLevel'] as double,
      );
    }).toList();

    final avgCompetitorPrice = competitorAnalyses.isEmpty
        ? 0.0
        : competitorAnalyses.map((c) => c.avgPrice).reduce((a, b) => a + b) /
            competitorAnalyses.length;

    final ourAvgPrice = recommendations.isEmpty
        ? 0.0
        : recommendations.map((r) => r.optimalPrice).reduce((a, b) => a + b) /
            recommendations.length;

    final priceAdvantage = avgCompetitorPrice > 0
        ? ((avgCompetitorPrice - ourAvgPrice) / avgCompetitorPrice) * 100
        : 0;

    return CompetitivePositioning(
      competitors: competitorAnalyses,
      positioning: _determinePositioning(priceAdvantage),
      priceAdvantage: priceAdvantage,
      valueScore: 0.75 + _random.nextDouble() * 0.2,
      differentiators: [
        'Superior support SLAs',
        'Transparent pricing',
        'Better cost efficiency',
        'Advanced analytics',
      ],
      featureComparison: {
        'pricing': priceAdvantage > 0 ? 1.0 : 0.5,
        'features': 0.8,
        'support': 0.9,
        'reliability': 0.85,
      },
    );
  }

  Future<SensitivityAnalysis> _performSensitivityAnalysis({
    required MarketSegment segment,
    required List<TierPricingRecommendation> recommendations,
  }) async {
    final parameterSensitivities = <String, ParameterSensitivity>{};

    // Analyze key parameters
    final parameters = {
      'price': recommendations.first.optimalPrice,
      'demand': recommendations.first.projectedDemand,
      'supportCost': recommendations.first.supportCost,
      'elasticity': segment.elasticityCurve.elasticity,
    };

    for (final entry in parameters.entries) {
      final param = entry.key;
      final baseValue = entry.value;

      final impact10Inc = _calculateImpact(baseValue, 0.10);
      final impact10Dec = _calculateImpact(baseValue, -0.10);

      parameterSensitivities[param] = ParameterSensitivity(
        parameterName: param,
        baseValue: baseValue,
        impact10Increase: impact10Inc,
        impact10Decrease: impact10Dec,
        elasticity: (impact10Inc - impact10Dec) / (2 * baseValue),
        riskLevel: _assessParameterRisk(param, impact10Inc, impact10Dec),
      );
    }

    return SensitivityAnalysis(
      parameterSensitivities: parameterSensitivities,
      overallVolatility: 0.15 + _random.nextDouble() * 0.1,
      criticalParameters: ['price', 'demand'],
      scenarioMatrix: _generateScenarioMatrix(),
    );
  }

  Future<RiskAssessment> _assessRisks({
    required MarketSegment segment,
    required List<TierPricingRecommendation> recommendations,
    required CompetitivePositioning competitivePositioning,
  }) async {
    final risks = <Risk>[
      Risk(
        id: 'risk_1',
        category: 'Market',
        description: 'Competitive price pressure',
        probability: 0.6,
        impact: 0.7,
        score: 0.42,
      ),
      Risk(
        id: 'risk_2',
        category: 'Operational',
        description: 'Support cost escalation',
        probability: 0.4,
        impact: 0.8,
        score: 0.32,
      ),
      Risk(
        id: 'risk_3',
        category: 'Demand',
        description: 'Market demand volatility',
        probability: 0.5,
        impact: 0.6,
        score: 0.30,
      ),
    ];

    final mitigations = <String, MitigationStrategy>{
      'risk_1': MitigationStrategy(
        riskId: 'risk_1',
        strategy: 'Enhance value proposition with superior features',
        effectivenessScore: 0.75,
        implementationCost: 50000,
        timeline: '3 months',
        actionItems: [
          'Develop advanced analytics dashboard',
          'Improve API capabilities',
          'Enhance documentation',
        ],
      ),
      'risk_2': MitigationStrategy(
        riskId: 'risk_2',
        strategy: 'Optimize support operations with automation',
        effectivenessScore: 0.8,
        implementationCost: 30000,
        timeline: '2 months',
        actionItems: [
          'Implement AI chatbot',
          'Create self-service knowledge base',
          'Automate ticket routing',
        ],
      ),
      'risk_3': MitigationStrategy(
        riskId: 'risk_3',
        strategy: 'Diversify market segments and pricing tiers',
        effectivenessScore: 0.7,
        implementationCost: 20000,
        timeline: '4 months',
        actionItems: [
          'Expand to new verticals',
          'Introduce flexible pricing',
          'Develop partner channel',
        ],
      ),
    };

    final overallScore = risks.isEmpty
        ? 0.0
        : risks.map((r) => r.score).reduce((a, b) => a + b) / risks.length;

    return RiskAssessment(
      overallRiskScore: overallScore,
      identifiedRisks: risks,
      mitigationStrategies: mitigations,
      riskLevel: _getRiskLevel(overallScore),
    );
  }

  Future<ImplementationPlan> _generateImplementationPlan({
    required MarketSegment segment,
    required List<TierPricingRecommendation> recommendations,
  }) async {
    final phases = [
      ImplementationPhase(
        name: 'Phase 1: Analysis & Planning',
        durationDays: 14,
        budget: 15000,
        tasks: [
          'Finalize pricing structure',
          'Prepare marketing materials',
          'Train sales team',
        ],
        deliverables: [
          'Pricing documentation',
          'Sales playbook',
          'Training completion',
        ],
        dependencies: [],
      ),
      ImplementationPhase(
        name: 'Phase 2: System Updates',
        durationDays: 21,
        budget: 30000,
        tasks: [
          'Update billing system',
          'Configure pricing tiers',
          'Setup monitoring',
        ],
        deliverables: [
          'Updated billing system',
          'Configured tiers',
          'Monitoring dashboard',
        ],
        dependencies: ['Phase 1: Analysis & Planning'],
      ),
      ImplementationPhase(
        name: 'Phase 3: Rollout',
        durationDays: 14,
        budget: 20000,
        tasks: [
          'Announce new pricing',
          'Migrate existing customers',
          'Monitor and adjust',
        ],
        deliverables: [
          'Pricing announcement',
          'Migration complete',
          'Performance report',
        ],
        dependencies: ['Phase 2: System Updates'],
      ),
    ];

    final resourceAllocations = <String, ResourceAllocation>{
      'Engineering': ResourceAllocation(
        resourceType: 'Engineering',
        units: 2,
        costPerUnit: 15000,
        totalCost: 30000,
      ),
      'Product': ResourceAllocation(
        resourceType: 'Product',
        units: 1,
        costPerUnit: 12000,
        totalCost: 12000,
      ),
      'Marketing': ResourceAllocation(
        resourceType: 'Marketing',
        units: 1,
        costPerUnit: 10000,
        totalCost: 10000,
      ),
    };

    final milestones = [
      Milestone(
        name: 'Pricing Approved',
        dayFromStart: 7,
        deliverables: ['Approved pricing structure'],
        successCriteria: ['Executive sign-off'],
      ),
      Milestone(
        name: 'System Ready',
        dayFromStart: 28,
        deliverables: ['Updated systems'],
        successCriteria: ['All tests passing'],
      ),
      Milestone(
        name: 'Launch Complete',
        dayFromStart: 49,
        deliverables: ['Live pricing'],
        successCriteria: ['Zero critical issues'],
      ),
    ];

    return ImplementationPlan(
      phases: phases,
      totalBudget: 65000,
      totalDurationDays: 49,
      resourceAllocations: resourceAllocations,
      milestones: milestones,
    );
  }

  String _generateRationale({
    required MarketSegment segment,
    required ProductTier tier,
    required double optimalPrice,
  }) {
    return 'Optimal price of \$${optimalPrice.toStringAsFixed(2)} maximizes revenue '
        'for ${segment.name} based on price elasticity of '
        '${segment.elasticityCurve.elasticity.toStringAsFixed(2)}. '
        'This pricing balances market demand with support cost recovery.';
  }

  double _estimateChurnRate(MarketCondition condition) {
    switch (condition) {
      case MarketCondition.bull:
        return 0.05;
      case MarketCondition.base:
        return 0.10;
      case MarketCondition.bear:
        return 0.20;
    }
  }

  String _determinePositioning(double priceAdvantage) {
    if (priceAdvantage > 20) {
      return 'Premium Value';
    } else if (priceAdvantage > 0) {
      return 'Competitive';
    } else if (priceAdvantage > -20) {
      return 'Price Leader';
    } else {
      return 'Budget Option';
    }
  }

  double _calculateImpact(double baseValue, double changePercent) {
    return baseValue * (1 + changePercent) - baseValue;
  }

  String _assessParameterRisk(String param, double impactInc, double impactDec) {
    final maxImpact = max(impactInc.abs(), impactDec.abs());
    if (maxImpact > 100) return 'High';
    if (maxImpact > 50) return 'Medium';
    return 'Low';
  }

  Map<String, List<double>> _generateScenarioMatrix() {
    return {
      'bestCase': [1.2, 1.3, 1.15, 1.25],
      'baseCase': [1.0, 1.0, 1.0, 1.0],
      'worstCase': [0.8, 0.7, 0.85, 0.75],
    };
  }

  String _getRiskLevel(double score) {
    if (score > 0.7) return 'Critical';
    if (score > 0.5) return 'High';
    if (score > 0.3) return 'Medium';
    return 'Low';
  }
}
