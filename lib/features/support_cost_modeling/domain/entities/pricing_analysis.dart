import 'package:equatable/equatable.dart';
import 'market_segment.dart';

/// Product tier for pricing
class ProductTier extends Equatable {
  final String id;
  final String name;
  final double basePrice;
  final List<String> features;
  final double supportCost;
  final double marginTarget;

  const ProductTier({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.features,
    required this.supportCost,
    required this.marginTarget,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        basePrice,
        features,
        supportCost,
        marginTarget,
      ];
}

/// Comprehensive pricing analysis for a segment
class PricingAnalysis extends Equatable {
  final String segmentId;
  final String segmentName;
  final DateTime generatedAt;
  final List<TierPricingRecommendation> tierRecommendations;
  final Map<MarketCondition, RevenueProjection> revenueProjections;
  final CompetitivePositioning competitivePositioning;
  final SensitivityAnalysis sensitivityAnalysis;
  final RiskAssessment riskAssessment;
  final ImplementationPlan implementationPlan;

  const PricingAnalysis({
    required this.segmentId,
    required this.segmentName,
    required this.generatedAt,
    required this.tierRecommendations,
    required this.revenueProjections,
    required this.competitivePositioning,
    required this.sensitivityAnalysis,
    required this.riskAssessment,
    required this.implementationPlan,
  });

  @override
  List<Object?> get props => [
        segmentId,
        segmentName,
        generatedAt,
        tierRecommendations,
        revenueProjections,
        competitivePositioning,
        sensitivityAnalysis,
        riskAssessment,
        implementationPlan,
      ];
}

/// Tier-specific pricing recommendation
class TierPricingRecommendation extends Equatable {
  final String tierId;
  final String tierName;
  final double optimalPrice;
  final double minPrice;
  final double maxPrice;
  final double projectedDemand;
  final double projectedRevenue;
  final double supportCost;
  final double margin;
  final String rationale;

  const TierPricingRecommendation({
    required this.tierId,
    required this.tierName,
    required this.optimalPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.projectedDemand,
    required this.projectedRevenue,
    required this.supportCost,
    required this.margin,
    required this.rationale,
  });

  bool get isProfitable => margin > 0;

  @override
  List<Object?> get props => [
        tierId,
        tierName,
        optimalPrice,
        minPrice,
        maxPrice,
        projectedDemand,
        projectedRevenue,
        supportCost,
        margin,
        rationale,
      ];
}

/// Revenue projection under different market conditions
class RevenueProjection extends Equatable {
  final MarketCondition condition;
  final double totalRevenue;
  final double totalCost;
  final double netProfit;
  final double customerCount;
  final double averageRevenuePerUser;
  final double customerLifetimeValue;
  final double churnRate;
  final Map<String, double> revenueByTier;

  const RevenueProjection({
    required this.condition,
    required this.totalRevenue,
    required this.totalCost,
    required this.netProfit,
    required this.customerCount,
    required this.averageRevenuePerUser,
    required this.customerLifetimeValue,
    required this.churnRate,
    required this.revenueByTier,
  });

  double get margin => totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0;

  @override
  List<Object?> get props => [
        condition,
        totalRevenue,
        totalCost,
        netProfit,
        customerCount,
        averageRevenuePerUser,
        customerLifetimeValue,
        churnRate,
        revenueByTier,
      ];
}

/// Competitive positioning analysis
class CompetitivePositioning extends Equatable {
  final List<CompetitorAnalysis> competitors;
  final String positioning;
  final double priceAdvantage;
  final double valueScore;
  final List<String> differentiators;
  final Map<String, double> featureComparison;

  const CompetitivePositioning({
    required this.competitors,
    required this.positioning,
    required this.priceAdvantage,
    required this.valueScore,
    required this.differentiators,
    required this.featureComparison,
  });

  @override
  List<Object?> get props => [
        competitors,
        positioning,
        priceAdvantage,
        valueScore,
        differentiators,
        featureComparison,
      ];
}

/// Individual competitor analysis
class CompetitorAnalysis extends Equatable {
  final String name;
  final double avgPrice;
  final double marketShare;
  final double customerSatisfaction;
  final List<String> strengths;
  final List<String> weaknesses;
  final double threatLevel;

  const CompetitorAnalysis({
    required this.name,
    required this.avgPrice,
    required this.marketShare,
    required this.customerSatisfaction,
    required this.strengths,
    required this.weaknesses,
    required this.threatLevel,
  });

  @override
  List<Object?> get props => [
        name,
        avgPrice,
        marketShare,
        customerSatisfaction,
        strengths,
        weaknesses,
        threatLevel,
      ];
}

/// Sensitivity analysis results
class SensitivityAnalysis extends Equatable {
  final Map<String, ParameterSensitivity> parameterSensitivities;
  final double overallVolatility;
  final List<String> criticalParameters;
  final Map<String, List<double>> scenarioMatrix;

  const SensitivityAnalysis({
    required this.parameterSensitivities,
    required this.overallVolatility,
    required this.criticalParameters,
    required this.scenarioMatrix,
  });

  @override
  List<Object?> get props => [
        parameterSensitivities,
        overallVolatility,
        criticalParameters,
        scenarioMatrix,
      ];
}

/// Parameter-specific sensitivity
class ParameterSensitivity extends Equatable {
  final String parameterName;
  final double baseValue;
  final double impact10Increase;
  final double impact10Decrease;
  final double elasticity;
  final String riskLevel;

  const ParameterSensitivity({
    required this.parameterName,
    required this.baseValue,
    required this.impact10Increase,
    required this.impact10Decrease,
    required this.elasticity,
    required this.riskLevel,
  });

  @override
  List<Object?> get props => [
        parameterName,
        baseValue,
        impact10Increase,
        impact10Decrease,
        elasticity,
        riskLevel,
      ];
}

/// Risk assessment
class RiskAssessment extends Equatable {
  final double overallRiskScore;
  final List<Risk> identifiedRisks;
  final Map<String, MitigationStrategy> mitigationStrategies;
  final String riskLevel;

  const RiskAssessment({
    required this.overallRiskScore,
    required this.identifiedRisks,
    required this.mitigationStrategies,
    required this.riskLevel,
  });

  @override
  List<Object?> get props => [
        overallRiskScore,
        identifiedRisks,
        mitigationStrategies,
        riskLevel,
      ];
}

/// Individual risk
class Risk extends Equatable {
  final String id;
  final String category;
  final String description;
  final double probability;
  final double impact;
  final double score;

  const Risk({
    required this.id,
    required this.category,
    required this.description,
    required this.probability,
    required this.impact,
    required this.score,
  });

  @override
  List<Object?> get props => [
        id,
        category,
        description,
        probability,
        impact,
        score,
      ];
}

/// Mitigation strategy
class MitigationStrategy extends Equatable {
  final String riskId;
  final String strategy;
  final double effectivenessScore;
  final double implementationCost;
  final String timeline;
  final List<String> actionItems;

  const MitigationStrategy({
    required this.riskId,
    required this.strategy,
    required this.effectivenessScore,
    required this.implementationCost,
    required this.timeline,
    required this.actionItems,
  });

  @override
  List<Object?> get props => [
        riskId,
        strategy,
        effectivenessScore,
        implementationCost,
        timeline,
        actionItems,
      ];
}

/// Implementation plan
class ImplementationPlan extends Equatable {
  final List<ImplementationPhase> phases;
  final double totalBudget;
  final int totalDurationDays;
  final Map<String, ResourceAllocation> resourceAllocations;
  final List<Milestone> milestones;

  const ImplementationPlan({
    required this.phases,
    required this.totalBudget,
    required this.totalDurationDays,
    required this.resourceAllocations,
    required this.milestones,
  });

  @override
  List<Object?> get props => [
        phases,
        totalBudget,
        totalDurationDays,
        resourceAllocations,
        milestones,
      ];
}

/// Implementation phase
class ImplementationPhase extends Equatable {
  final String name;
  final int durationDays;
  final double budget;
  final List<String> tasks;
  final List<String> deliverables;
  final List<String> dependencies;

  const ImplementationPhase({
    required this.name,
    required this.durationDays,
    required this.budget,
    required this.tasks,
    required this.deliverables,
    required this.dependencies,
  });

  @override
  List<Object?> get props => [
        name,
        durationDays,
        budget,
        tasks,
        deliverables,
        dependencies,
      ];
}

/// Resource allocation
class ResourceAllocation extends Equatable {
  final String resourceType;
  final double units;
  final double costPerUnit;
  final double totalCost;

  const ResourceAllocation({
    required this.resourceType,
    required this.units,
    required this.costPerUnit,
    required this.totalCost,
  });

  @override
  List<Object?> get props => [
        resourceType,
        units,
        costPerUnit,
        totalCost,
      ];
}

/// Milestone
class Milestone extends Equatable {
  final String name;
  final int dayFromStart;
  final List<String> deliverables;
  final List<String> successCriteria;

  const Milestone({
    required this.name,
    required this.dayFromStart,
    required this.deliverables,
    required this.successCriteria,
  });

  @override
  List<Object?> get props => [
        name,
        dayFromStart,
        deliverables,
        successCriteria,
      ];
}
