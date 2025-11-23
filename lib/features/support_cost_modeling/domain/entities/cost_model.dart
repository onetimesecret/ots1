import 'package:equatable/equatable.dart';
import 'support_benchmark.dart';

/// Cost-per-ticket model by tier
class CostPerTicketModel extends Equatable {
  final SupportTier tier;
  final double baseCost;
  final double variableCost;
  final double fixedCost;
  final double responseTimeSLA;
  final double resolutionTimeSLA;
  final double satisfactionTarget;
  final Map<String, double> costBreakdown;

  const CostPerTicketModel({
    required this.tier,
    required this.baseCost,
    required this.variableCost,
    required this.fixedCost,
    required this.responseTimeSLA,
    required this.resolutionTimeSLA,
    required this.satisfactionTarget,
    required this.costBreakdown,
  });

  double calculateCost(int ticketVolume) {
    return baseCost + (variableCost * ticketVolume) + fixedCost;
  }

  double get costPerTicket => baseCost + variableCost;

  @override
  List<Object?> get props => [
        tier,
        baseCost,
        variableCost,
        fixedCost,
        responseTimeSLA,
        resolutionTimeSLA,
        satisfactionTarget,
        costBreakdown,
      ];
}

/// P&L Impact Model
class PLImpactModel extends Equatable {
  final String scenarioName;
  final SupportTier tier;
  final double monthlyRevenue;
  final double monthlySupportCost;
  final double customerAcquisitionCost;
  final double customerLifetimeValue;
  final double churnRate;
  final int customerCount;
  final double grossMargin;
  final double netMargin;

  const PLImpactModel({
    required this.scenarioName,
    required this.tier,
    required this.monthlyRevenue,
    required this.monthlySupportCost,
    required this.customerAcquisitionCost,
    required this.customerLifetimeValue,
    required this.churnRate,
    required this.customerCount,
    required this.grossMargin,
    required this.netMargin,
  });

  double get supportCostPercentage =>
      monthlyRevenue > 0 ? (monthlySupportCost / monthlyRevenue) * 100 : 0;

  double get netProfit => monthlyRevenue - monthlySupportCost;

  double get roi =>
      customerAcquisitionCost > 0
          ? ((customerLifetimeValue - customerAcquisitionCost) /
              customerAcquisitionCost) *
              100
          : 0;

  bool get isProfitable => netProfit > 0 && supportCostPercentage < 30;

  @override
  List<Object?> get props => [
        scenarioName,
        tier,
        monthlyRevenue,
        monthlySupportCost,
        customerAcquisitionCost,
        customerLifetimeValue,
        churnRate,
        customerCount,
        grossMargin,
        netMargin,
      ];
}
