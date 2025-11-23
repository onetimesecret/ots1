import 'package:equatable/equatable.dart';

/// Real-time KPI tracking
class KPIDashboard extends Equatable {
  final DateTime timestamp;
  final Map<String, KPI> kpis;
  final List<Alert> activeAlerts;
  final Map<String, TrendData> trends;
  final double healthScore;

  const KPIDashboard({
    required this.timestamp,
    required this.kpis,
    required this.activeAlerts,
    required this.trends,
    required this.healthScore,
  });

  @override
  List<Object?> get props => [
        timestamp,
        kpis,
        activeAlerts,
        trends,
        healthScore,
      ];
}

/// Key Performance Indicator
class KPI extends Equatable {
  final String id;
  final String name;
  final double currentValue;
  final double targetValue;
  final double previousValue;
  final String unit;
  final String category;
  final KPIStatus status;

  const KPI({
    required this.id,
    required this.name,
    required this.currentValue,
    required this.targetValue,
    required this.previousValue,
    required this.unit,
    required this.category,
    required this.status,
  });

  double get percentageChange =>
      previousValue != 0
          ? ((currentValue - previousValue) / previousValue) * 100
          : 0;

  double get targetAchievement =>
      targetValue != 0 ? (currentValue / targetValue) * 100 : 0;

  @override
  List<Object?> get props => [
        id,
        name,
        currentValue,
        targetValue,
        previousValue,
        unit,
        category,
        status,
      ];
}

/// KPI status
enum KPIStatus {
  critical,
  warning,
  normal,
  good,
  excellent;

  String get displayName {
    switch (this) {
      case KPIStatus.critical:
        return 'Critical';
      case KPIStatus.warning:
        return 'Warning';
      case KPIStatus.normal:
        return 'Normal';
      case KPIStatus.good:
        return 'Good';
      case KPIStatus.excellent:
        return 'Excellent';
    }
  }
}

/// Alert for price deviations and anomalies
class Alert extends Equatable {
  final String id;
  final String type;
  final String severity;
  final String message;
  final DateTime triggeredAt;
  final Map<String, dynamic> metadata;
  final List<String> recommendedActions;
  final bool acknowledged;

  const Alert({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    required this.triggeredAt,
    required this.metadata,
    required this.recommendedActions,
    this.acknowledged = false,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        severity,
        message,
        triggeredAt,
        metadata,
        recommendedActions,
        acknowledged,
      ];
}

/// Trend data for KPIs
class TrendData extends Equatable {
  final String kpiId;
  final List<DataPoint> dataPoints;
  final String trendDirection;
  final double trendStrength;
  final Map<String, double> forecasts;

  const TrendData({
    required this.kpiId,
    required this.dataPoints,
    required this.trendDirection,
    required this.trendStrength,
    required this.forecasts,
  });

  @override
  List<Object?> get props => [
        kpiId,
        dataPoints,
        trendDirection,
        trendStrength,
        forecasts,
      ];
}

/// Data point in trend
class DataPoint extends Equatable {
  final DateTime timestamp;
  final double value;

  const DataPoint({
    required this.timestamp,
    required this.value,
  });

  @override
  List<Object?> get props => [timestamp, value];
}

/// Price deviation trigger configuration
class PriceDeviationTrigger extends Equatable {
  final String id;
  final String segmentId;
  final String tierId;
  final double baselinePrice;
  final double deviationThresholdPercent;
  final bool enabled;
  final List<String> notificationChannels;

  const PriceDeviationTrigger({
    required this.id,
    required this.segmentId,
    required this.tierId,
    required this.baselinePrice,
    required this.deviationThresholdPercent,
    this.enabled = true,
    required this.notificationChannels,
  });

  bool shouldTrigger(double currentPrice) {
    if (!enabled) return false;
    final deviation = ((currentPrice - baselinePrice) / baselinePrice).abs() * 100;
    return deviation > deviationThresholdPercent;
  }

  @override
  List<Object?> get props => [
        id,
        segmentId,
        tierId,
        baselinePrice,
        deviationThresholdPercent,
        enabled,
        notificationChannels,
      ];
}

/// Quarterly re-optimization recommendation
class ReoptimizationRecommendation extends Equatable {
  final String id;
  final DateTime generatedAt;
  final String segmentId;
  final Map<String, double> currentPrices;
  final Map<String, double> recommendedPrices;
  final String rationale;
  final double expectedRevenueImpact;
  final double confidenceScore;
  final List<String> keyFindings;

  const ReoptimizationRecommendation({
    required this.id,
    required this.generatedAt,
    required this.segmentId,
    required this.currentPrices,
    required this.recommendedPrices,
    required this.rationale,
    required this.expectedRevenueImpact,
    required this.confidenceScore,
    required this.keyFindings,
  });

  @override
  List<Object?> get props => [
        id,
        generatedAt,
        segmentId,
        currentPrices,
        recommendedPrices,
        rationale,
        expectedRevenueImpact,
        confidenceScore,
        keyFindings,
      ];
}

/// Cross-region arbitrage detection
class ArbitrageOpportunity extends Equatable {
  final String id;
  final String sourceRegion;
  final String targetRegion;
  final String productTier;
  final double priceDifferential;
  final double potentialProfit;
  final double riskScore;
  final List<String> preventionMeasures;
  final bool requiresAction;

  const ArbitrageOpportunity({
    required this.id,
    required this.sourceRegion,
    required this.targetRegion,
    required this.productTier,
    required this.priceDifferential,
    required this.potentialProfit,
    required this.riskScore,
    required this.preventionMeasures,
    this.requiresAction = false,
  });

  @override
  List<Object?> get props => [
        id,
        sourceRegion,
        targetRegion,
        productTier,
        priceDifferential,
        potentialProfit,
        riskScore,
        preventionMeasures,
        requiresAction,
      ];
}
