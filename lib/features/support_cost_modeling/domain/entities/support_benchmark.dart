import 'package:equatable/equatable.dart';

/// Represents support cost benchmark data from a SaaS company
class SupportBenchmark extends Equatable {
  final String companyName;
  final String companySize;
  final String industry;
  final double costPerTicket;
  final String supportTier;
  final double responseTimeSLA; // in hours
  final double resolutionTimeSLA; // in hours
  final int monthlyTicketVolume;
  final double customerSatisfactionScore;
  final int supportTeamSize;
  final double avgSalaryPerAgent;
  final double toolingCostPerAgent;
  final double trainingCostPerAgent;
  final double overheadMultiplier;

  const SupportBenchmark({
    required this.companyName,
    required this.companySize,
    required this.industry,
    required this.costPerTicket,
    required this.supportTier,
    required this.responseTimeSLA,
    required this.resolutionTimeSLA,
    required this.monthlyTicketVolume,
    required this.customerSatisfactionScore,
    required this.supportTeamSize,
    required this.avgSalaryPerAgent,
    required this.toolingCostPerAgent,
    required this.trainingCostPerAgent,
    required this.overheadMultiplier,
  });

  double get annualCost =>
      (costPerTicket * monthlyTicketVolume * 12) +
      (supportTeamSize * (avgSalaryPerAgent + toolingCostPerAgent + trainingCostPerAgent) * overheadMultiplier);

  double get costPerCustomer =>
      monthlyTicketVolume > 0 ? costPerTicket : 0;

  @override
  List<Object?> get props => [
        companyName,
        companySize,
        industry,
        costPerTicket,
        supportTier,
        responseTimeSLA,
        resolutionTimeSLA,
        monthlyTicketVolume,
        customerSatisfactionScore,
        supportTeamSize,
        avgSalaryPerAgent,
        toolingCostPerAgent,
        trainingCostPerAgent,
        overheadMultiplier,
      ];
}

/// Support tier classification
enum SupportTier {
  basic,
  standard,
  premium,
  enterprise,
  vip;

  String get displayName {
    switch (this) {
      case SupportTier.basic:
        return 'Basic';
      case SupportTier.standard:
        return 'Standard';
      case SupportTier.premium:
        return 'Premium';
      case SupportTier.enterprise:
        return 'Enterprise';
      case SupportTier.vip:
        return 'VIP';
    }
  }
}

/// Company size classification
enum CompanySize {
  startup,
  small,
  medium,
  large,
  enterprise;

  String get displayName {
    switch (this) {
      case CompanySize.startup:
        return 'Startup (<10 employees)';
      case CompanySize.small:
        return 'Small (10-50 employees)';
      case CompanySize.medium:
        return 'Medium (50-500 employees)';
      case CompanySize.large:
        return 'Large (500-5000 employees)';
      case CompanySize.enterprise:
        return 'Enterprise (5000+ employees)';
    }
  }
}
