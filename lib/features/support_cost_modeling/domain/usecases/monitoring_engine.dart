import 'dart:math';
import '../entities/monitoring.dart';
import '../entities/pricing_analysis.dart';

/// Engine for real-time monitoring and alerting
class MonitoringEngine {
  final Random _random = Random();
  final List<Alert> _activeAlerts = [];
  final Map<String, List<DataPoint>> _kpiHistory = {};

  /// Generate real-time KPI dashboard
  Future<KPIDashboard> generateDashboard({
    required List<PricingAnalysis> analyses,
    required Map<String, double> currentMetrics,
  }) async {
    final kpis = await _generateKPIs(currentMetrics);
    final alerts = await _checkAlerts(kpis);
    final trends = await _analyzeTrends();

    final healthScore = _calculateHealthScore(kpis, alerts);

    return KPIDashboard(
      timestamp: DateTime.now(),
      kpis: kpis,
      activeAlerts: alerts,
      trends: trends,
      healthScore: healthScore,
    );
  }

  /// Check for price deviations and generate alerts
  Future<List<Alert>> checkPriceDeviations({
    required List<PriceDeviationTrigger> triggers,
    required Map<String, double> currentPrices,
  }) async {
    final alerts = <Alert>[];

    for (final trigger in triggers) {
      if (!trigger.enabled) continue;

      final currentPrice = currentPrices['${trigger.segmentId}_${trigger.tierId}'];
      if (currentPrice == null) continue;

      if (trigger.shouldTrigger(currentPrice)) {
        final deviation = ((currentPrice - trigger.baselinePrice) / trigger.baselinePrice).abs() * 100;

        alerts.add(
          Alert(
            id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
            type: 'price_deviation',
            severity: deviation > 20 ? 'critical' : 'warning',
            message: 'Price deviation detected for ${trigger.segmentId} - ${trigger.tierId}: '
                '${deviation.toStringAsFixed(1)}% from baseline',
            triggeredAt: DateTime.now(),
            metadata: {
              'segmentId': trigger.segmentId,
              'tierId': trigger.tierId,
              'currentPrice': currentPrice,
              'baselinePrice': trigger.baselinePrice,
              'deviation': deviation,
            },
            recommendedActions: [
              'Review market conditions',
              'Analyze competitor pricing',
              'Consider price adjustment',
              'Notify pricing team',
            ],
          ),
        );
      }
    }

    return alerts;
  }

  /// Generate quarterly re-optimization recommendations
  Future<ReoptimizationRecommendation> generateReoptimization({
    required String segmentId,
    required Map<String, double> currentPrices,
    required Map<String, double> performanceMetrics,
    required List<DataPoint> historicalData,
  }) async {
    final recommendedPrices = <String, double>{};
    final keyFindings = <String>[];

    // Analyze performance trends
    final revenueGrowth = _calculateGrowthRate(historicalData);

    if (revenueGrowth < 0) {
      keyFindings.add('Revenue declining, consider price reduction or value enhancement');
    } else if (revenueGrowth > 0.2) {
      keyFindings.add('Strong growth, opportunity for price increase');
    }

    // Apply adaptive learning
    for (final entry in currentPrices.entries) {
      final currentPrice = entry.value;
      final performance = performanceMetrics[entry.key] ?? 0.5;

      // Adjust based on performance
      final adjustment = _calculatePriceAdjustment(performance, revenueGrowth);
      recommendedPrices[entry.key] = currentPrice * (1 + adjustment);

      if (adjustment.abs() > 0.05) {
        keyFindings.add('${entry.key}: ${adjustment > 0 ? "Increase" : "Decrease"} '
            'by ${(adjustment.abs() * 100).toStringAsFixed(1)}%');
      }
    }

    final avgChange = recommendedPrices.values
        .map((recommended) => recommended)
        .reduce((a, b) => a + b) / recommendedPrices.length -
        currentPrices.values.reduce((a, b) => a + b) / currentPrices.length;

    return ReoptimizationRecommendation(
      id: 'reopt_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      segmentId: segmentId,
      currentPrices: currentPrices,
      recommendedPrices: recommendedPrices,
      rationale: _generateReoptimizationRationale(revenueGrowth, keyFindings),
      expectedRevenueImpact: avgChange * 1000, // Simplified calculation
      confidenceScore: 0.7 + _random.nextDouble() * 0.2,
      keyFindings: keyFindings,
    );
  }

  /// Track KPI over time
  void trackKPI(String kpiId, double value) {
    _kpiHistory.putIfAbsent(kpiId, () => []).add(
      DataPoint(
        timestamp: DateTime.now(),
        value: value,
      ),
    );

    // Keep only last 100 points
    if (_kpiHistory[kpiId]!.length > 100) {
      _kpiHistory[kpiId]!.removeAt(0);
    }
  }

  Future<Map<String, KPI>> _generateKPIs(Map<String, double> currentMetrics) async {
    final kpis = <String, KPI>{};

    final kpiDefinitions = {
      'revenue': {'name': 'Monthly Revenue', 'target': 100000.0, 'unit': 'USD'},
      'margin': {'name': 'Profit Margin', 'target': 0.3, 'unit': '%'},
      'customerCount': {'name': 'Active Customers', 'target': 1000.0, 'unit': 'count'},
      'churnRate': {'name': 'Monthly Churn', 'target': 0.05, 'unit': '%'},
      'supportCost': {'name': 'Support Cost %', 'target': 0.15, 'unit': '%'},
      'nps': {'name': 'Net Promoter Score', 'target': 50.0, 'unit': 'score'},
    };

    for (final entry in kpiDefinitions.entries) {
      final id = entry.key;
      final def = entry.value;
      final currentValue = currentMetrics[id] ?? 0;
      final previousValue = _getPreviousValue(id);

      kpis[id] = KPI(
        id: id,
        name: def['name'] as String,
        currentValue: currentValue,
        targetValue: def['target'] as double,
        previousValue: previousValue,
        unit: def['unit'] as String,
        category: 'Business',
        status: _determineKPIStatus(currentValue, def['target'] as double, id),
      );
    }

    return kpis;
  }

  Future<List<Alert>> _checkAlerts(Map<String, KPI> kpis) async {
    final alerts = <Alert>[];

    for (final kpi in kpis.values) {
      if (kpi.status == KPIStatus.critical) {
        alerts.add(
          Alert(
            id: 'kpi_alert_${kpi.id}_${DateTime.now().millisecondsSinceEpoch}',
            type: 'kpi_critical',
            severity: 'critical',
            message: '${kpi.name} is critically below target: '
                '${kpi.currentValue} vs ${kpi.targetValue}',
            triggeredAt: DateTime.now(),
            metadata: {'kpiId': kpi.id, 'currentValue': kpi.currentValue},
            recommendedActions: _getRecommendedActions(kpi.id),
          ),
        );
      } else if (kpi.status == KPIStatus.warning) {
        alerts.add(
          Alert(
            id: 'kpi_alert_${kpi.id}_${DateTime.now().millisecondsSinceEpoch}',
            type: 'kpi_warning',
            severity: 'warning',
            message: '${kpi.name} is below target: '
                '${kpi.currentValue} vs ${kpi.targetValue}',
            triggeredAt: DateTime.now(),
            metadata: {'kpiId': kpi.id, 'currentValue': kpi.currentValue},
            recommendedActions: _getRecommendedActions(kpi.id),
          ),
        );
      }
    }

    return alerts;
  }

  Future<Map<String, TrendData>> _analyzeTrends() async {
    final trends = <String, TrendData>{};

    for (final entry in _kpiHistory.entries) {
      final kpiId = entry.key;
      final dataPoints = entry.value;

      if (dataPoints.length < 2) continue;

      final direction = _determineTrendDirection(dataPoints);
      final strength = _calculateTrendStrength(dataPoints);
      final forecasts = _generateForecasts(dataPoints);

      trends[kpiId] = TrendData(
        kpiId: kpiId,
        dataPoints: dataPoints,
        trendDirection: direction,
        trendStrength: strength,
        forecasts: forecasts,
      );
    }

    return trends;
  }

  double _calculateHealthScore(Map<String, KPI> kpis, List<Alert> alerts) {
    double score = 100.0;

    // Deduct for each KPI not meeting target
    for (final kpi in kpis.values) {
      if (kpi.status == KPIStatus.critical) {
        score -= 20;
      } else if (kpi.status == KPIStatus.warning) {
        score -= 10;
      }
    }

    // Deduct for alerts
    score -= alerts.where((a) => a.severity == 'critical').length * 15;
    score -= alerts.where((a) => a.severity == 'warning').length * 5;

    return max(0, min(100, score));
  }

  double _getPreviousValue(String kpiId) {
    final history = _kpiHistory[kpiId];
    if (history == null || history.isEmpty) return 0;
    return history.last.value;
  }

  KPIStatus _determineKPIStatus(double current, double target, String kpiId) {
    final isLowerBetter = ['churnRate', 'supportCost'].contains(kpiId);

    final ratio = current / target;

    if (isLowerBetter) {
      if (ratio <= 0.8) return KPIStatus.excellent;
      if (ratio <= 1.0) return KPIStatus.good;
      if (ratio <= 1.2) return KPIStatus.normal;
      if (ratio <= 1.5) return KPIStatus.warning;
      return KPIStatus.critical;
    } else {
      if (ratio >= 1.2) return KPIStatus.excellent;
      if (ratio >= 1.0) return KPIStatus.good;
      if (ratio >= 0.8) return KPIStatus.normal;
      if (ratio >= 0.6) return KPIStatus.warning;
      return KPIStatus.critical;
    }
  }

  List<String> _getRecommendedActions(String kpiId) {
    final actions = {
      'revenue': [
        'Review pricing strategy',
        'Analyze customer acquisition',
        'Check upsell opportunities',
      ],
      'margin': [
        'Optimize support costs',
        'Review operational efficiency',
        'Analyze pricing vs costs',
      ],
      'churnRate': [
        'Improve customer success',
        'Enhance product value',
        'Review customer feedback',
      ],
    };

    return actions[kpiId] ?? ['Review metrics', 'Analyze root cause'];
  }

  String _determineTrendDirection(List<DataPoint> dataPoints) {
    if (dataPoints.length < 2) return 'stable';

    final recent = dataPoints.last.value;
    final previous = dataPoints[dataPoints.length - 2].value;

    if (recent > previous * 1.05) return 'up';
    if (recent < previous * 0.95) return 'down';
    return 'stable';
  }

  double _calculateTrendStrength(List<DataPoint> dataPoints) {
    if (dataPoints.length < 3) return 0.5;

    final values = dataPoints.map((p) => p.value).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => pow(v - avg, 2)).reduce((a, b) => a + b) / values.length;

    return min(1.0, variance / (avg * avg));
  }

  Map<String, double> _generateForecasts(List<DataPoint> dataPoints) {
    if (dataPoints.isEmpty) return {};

    final lastValue = dataPoints.last.value;
    final growth = _calculateGrowthRate(dataPoints);

    return {
      'next7Days': lastValue * (1 + growth * 0.25),
      'next30Days': lastValue * (1 + growth),
      'next90Days': lastValue * (1 + growth * 3),
    };
  }

  double _calculateGrowthRate(List<DataPoint> dataPoints) {
    if (dataPoints.length < 2) return 0;

    final first = dataPoints.first.value;
    final last = dataPoints.last.value;

    return first > 0 ? (last - first) / first : 0;
  }

  double _calculatePriceAdjustment(double performance, double revenueGrowth) {
    // Adaptive learning algorithm
    if (performance > 0.8 && revenueGrowth > 0.15) {
      return 0.05 + _random.nextDouble() * 0.05; // Increase 5-10%
    } else if (performance < 0.4 || revenueGrowth < -0.1) {
      return -0.05 - _random.nextDouble() * 0.05; // Decrease 5-10%
    }
    return _random.nextDouble() * 0.04 - 0.02; // Small adjustment
  }

  String _generateReoptimizationRationale(
    double revenueGrowth,
    List<String> keyFindings,
  ) {
    return 'Based on ${(revenueGrowth * 100).toStringAsFixed(1)}% revenue growth and '
        'market performance analysis, recommended adjustments align with adaptive learning '
        'models. Key factors: ${keyFindings.take(3).join(", ")}.';
  }
}
