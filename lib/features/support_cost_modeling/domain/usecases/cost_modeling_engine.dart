import 'dart:math';
import '../entities/support_benchmark.dart';
import '../entities/cost_model.dart';

/// Engine for building cost-per-ticket models
class CostModelingEngine {
  /// Build cost models from benchmarks
  Future<Map<SupportTier, CostPerTicketModel>> buildCostModels(
    List<SupportBenchmark> benchmarks,
  ) async {
    final models = <SupportTier, CostPerTicketModel>{};

    for (final tier in SupportTier.values) {
      final tierBenchmarks = benchmarks
          .where((b) => _mapStringToTier(b.supportTier) == tier)
          .toList();

      if (tierBenchmarks.isEmpty) continue;

      final avgCostPerTicket = _average(
        tierBenchmarks.map((b) => b.costPerTicket),
      );

      final avgResponseTime = _average(
        tierBenchmarks.map((b) => b.responseTimeSLA),
      );

      final avgResolutionTime = _average(
        tierBenchmarks.map((b) => b.resolutionTimeSLA),
      );

      final avgSatisfaction = _average(
        tierBenchmarks.map((b) => b.customerSatisfactionScore),
      );

      // Calculate cost breakdown
      final costBreakdown = _calculateCostBreakdown(tierBenchmarks);

      models[tier] = CostPerTicketModel(
        tier: tier,
        baseCost: avgCostPerTicket * 0.6, // 60% base
        variableCost: avgCostPerTicket * 0.3, // 30% variable
        fixedCost: avgCostPerTicket * 0.1 * 1000, // 10% fixed overhead
        responseTimeSLA: avgResponseTime,
        resolutionTimeSLA: avgResolutionTime,
        satisfactionTarget: avgSatisfaction,
        costBreakdown: costBreakdown,
      );
    }

    return models;
  }

  /// Simulate P&L impact for different SLA scenarios
  Future<List<PLImpactModel>> simulatePLImpact({
    required Map<SupportTier, CostPerTicketModel> costModels,
    required int customerCount,
    required double monthlyRevenuePerCustomer,
    required double customerAcquisitionCost,
    required double baseChurnRate,
  }) async {
    final scenarios = <PLImpactModel>[];

    for (final entry in costModels.entries) {
      final tier = entry.key;
      final model = entry.value;

      // Estimate ticket volume based on tier
      final ticketsPerCustomer = _estimateTicketsPerCustomer(tier);
      final monthlyTickets = (customerCount * ticketsPerCustomer).toInt();

      // Calculate costs
      final monthlySupportCost = model.calculateCost(monthlyTickets);
      final monthlyRevenue = customerCount * monthlyRevenuePerCustomer;

      // Adjust churn based on support quality
      final churnMultiplier = _getChurnMultiplier(tier);
      final adjustedChurnRate = baseChurnRate * churnMultiplier;

      // Calculate CLV
      final avgCustomerLifeMonths = adjustedChurnRate > 0
          ? 1 / adjustedChurnRate
          : 24.0;
      final customerLifetimeValue =
          monthlyRevenuePerCustomer * avgCustomerLifeMonths;

      // Calculate margins
      final grossMargin = monthlyRevenue - monthlySupportCost;
      final grossMarginPercent = monthlyRevenue > 0
          ? (grossMargin / monthlyRevenue) * 100
          : 0;

      final netMargin = grossMargin * 0.7; // Assume 30% other costs
      final netMarginPercent = monthlyRevenue > 0
          ? (netMargin / monthlyRevenue) * 100
          : 0;

      scenarios.add(
        PLImpactModel(
          scenarioName: '${tier.displayName} Support',
          tier: tier,
          monthlyRevenue: monthlyRevenue,
          monthlySupportCost: monthlySupportCost,
          customerAcquisitionCost: customerAcquisitionCost,
          customerLifetimeValue: customerLifetimeValue,
          churnRate: adjustedChurnRate,
          customerCount: customerCount,
          grossMargin: grossMarginPercent,
          netMargin: netMarginPercent,
        ),
      );
    }

    return scenarios;
  }

  /// Generate support pricing calculator recommendations
  Map<String, dynamic> calculateSupportPricing({
    required SupportTier tier,
    required int expectedMonthlyTickets,
    required double targetMargin,
    required CostPerTicketModel costModel,
  }) {
    final totalCost = costModel.calculateCost(expectedMonthlyTickets);
    final costPerTicket = totalCost / expectedMonthlyTickets;

    // Calculate required price for target margin
    final requiredPricePerTicket = costPerTicket / (1 - targetMargin);

    // Calculate monthly and annual pricing
    final monthlyPrice = requiredPricePerTicket * expectedMonthlyTickets;
    final annualPrice = monthlyPrice * 12 * 0.9; // 10% annual discount

    return {
      'tier': tier.displayName,
      'costPerTicket': costPerTicket,
      'requiredPricePerTicket': requiredPricePerTicket,
      'monthlyPrice': monthlyPrice,
      'annualPrice': annualPrice,
      'margin': targetMargin * 100,
      'responseSLA': '${costModel.responseTimeSLA} hours',
      'resolutionSLA': '${costModel.resolutionTimeSLA} hours',
      'isProfitable': requiredPricePerTicket > costPerTicket,
      'breakEvenTickets': costModel.fixedCost / costPerTicket,
    };
  }

  SupportTier _mapStringToTier(String tierString) {
    switch (tierString.toLowerCase()) {
      case 'basic':
        return SupportTier.basic;
      case 'standard':
        return SupportTier.standard;
      case 'premium':
        return SupportTier.premium;
      case 'enterprise':
        return SupportTier.enterprise;
      case 'vip':
        return SupportTier.vip;
      default:
        return SupportTier.standard;
    }
  }

  double _average(Iterable<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  Map<String, double> _calculateCostBreakdown(
    List<SupportBenchmark> benchmarks,
  ) {
    final avgSalary = _average(benchmarks.map((b) => b.avgSalaryPerAgent));
    final avgTooling = _average(benchmarks.map((b) => b.toolingCostPerAgent));
    final avgTraining = _average(benchmarks.map((b) => b.trainingCostPerAgent));
    final avgTeamSize = _average(benchmarks.map((b) => b.supportTeamSize.toDouble()));

    final totalAnnual = (avgSalary + avgTooling + avgTraining) * avgTeamSize;

    return {
      'salary': avgSalary / totalAnnual * 100,
      'tooling': avgTooling / totalAnnual * 100,
      'training': avgTraining / totalAnnual * 100,
      'overhead': 15.0,
    };
  }

  double _estimateTicketsPerCustomer(SupportTier tier) {
    switch (tier) {
      case SupportTier.basic:
        return 0.5;
      case SupportTier.standard:
        return 1.0;
      case SupportTier.premium:
        return 2.0;
      case SupportTier.enterprise:
        return 4.0;
      case SupportTier.vip:
        return 8.0;
    }
  }

  double _getChurnMultiplier(SupportTier tier) {
    switch (tier) {
      case SupportTier.basic:
        return 1.5; // Higher churn with basic support
      case SupportTier.standard:
        return 1.0;
      case SupportTier.premium:
        return 0.8;
      case SupportTier.enterprise:
        return 0.6;
      case SupportTier.vip:
        return 0.4; // Lowest churn with VIP support
    }
  }
}
