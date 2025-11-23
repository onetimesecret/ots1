import 'dart:math';
import '../../domain/entities/support_benchmark.dart';

/// Data source for support cost benchmarks
/// Simulates scraping 100+ SaaS companies' support structures
class SupportBenchmarkDataSource {
  final Random _random = Random();

  /// Scrape and generate support cost benchmarks from industry data
  /// In production, this would scrape actual data from sources like:
  /// - Public financial reports
  /// - Industry surveys (Gartner, Forrester)
  /// - Customer success benchmarking platforms
  /// - LinkedIn job postings for salary data
  /// - Company blogs and case studies
  Future<List<SupportBenchmark>> scrapeBenchmarks({
    int companyCount = 100,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 100));

    final benchmarks = <SupportBenchmark>[];
    final industries = [
      'SaaS',
      'FinTech',
      'HealthTech',
      'EdTech',
      'E-commerce',
      'MarketingTech',
      'DevTools',
      'Security',
    ];

    final companySizes = [
      'Startup',
      'Small',
      'Medium',
      'Large',
      'Enterprise',
    ];

    final supportTiers = [
      'Basic',
      'Standard',
      'Premium',
      'Enterprise',
      'VIP',
    ];

    for (int i = 0; i < companyCount; i++) {
      final industry = industries[_random.nextInt(industries.length)];
      final companySize = companySizes[_random.nextInt(companySizes.length)];
      final supportTier = supportTiers[_random.nextInt(supportTiers.length)];

      // Generate realistic costs based on tier and company size
      final tierMultiplier = _getTierMultiplier(supportTier);
      final sizeMultiplier = _getSizeMultiplier(companySize);

      final costPerTicket = 15.0 * tierMultiplier * sizeMultiplier +
          _random.nextDouble() * 20;

      final monthlyVolume = (500 * sizeMultiplier + _random.nextInt(2000)).toInt();
      final teamSize = (5 * sizeMultiplier + _random.nextInt(20)).toInt();
      final avgSalary = 60000.0 * sizeMultiplier + _random.nextDouble() * 20000;

      benchmarks.add(
        SupportBenchmark(
          companyName: 'Company_${i + 1}',
          companySize: companySize,
          industry: industry,
          costPerTicket: costPerTicket,
          supportTier: supportTier,
          responseTimeSLA: _getResponseSLA(supportTier),
          resolutionTimeSLA: _getResolutionSLA(supportTier),
          monthlyTicketVolume: monthlyVolume,
          customerSatisfactionScore: 0.7 + _random.nextDouble() * 0.3,
          supportTeamSize: teamSize,
          avgSalaryPerAgent: avgSalary,
          toolingCostPerAgent: 2000 + _random.nextDouble() * 3000,
          trainingCostPerAgent: 1000 + _random.nextDouble() * 2000,
          overheadMultiplier: 1.3 + _random.nextDouble() * 0.4,
        ),
      );
    }

    return benchmarks;
  }

  /// Get benchmarks filtered by criteria
  Future<List<SupportBenchmark>> getBenchmarksByCriteria({
    String? industry,
    String? companySize,
    String? supportTier,
  }) async {
    final allBenchmarks = await scrapeBenchmarks();

    return allBenchmarks.where((benchmark) {
      if (industry != null && benchmark.industry != industry) return false;
      if (companySize != null && benchmark.companySize != companySize) return false;
      if (supportTier != null && benchmark.supportTier != supportTier) return false;
      return true;
    }).toList();
  }

  /// Calculate average metrics by tier
  Future<Map<String, Map<String, double>>> calculateTierAverages() async {
    final benchmarks = await scrapeBenchmarks();
    final tierGroups = <String, List<SupportBenchmark>>{};

    for (final benchmark in benchmarks) {
      tierGroups.putIfAbsent(benchmark.supportTier, () => []).add(benchmark);
    }

    final averages = <String, Map<String, double>>{};

    for (final entry in tierGroups.entries) {
      final tier = entry.key;
      final group = entry.value;

      averages[tier] = {
        'avgCostPerTicket': _average(group.map((b) => b.costPerTicket)),
        'avgResponseTime': _average(group.map((b) => b.responseTimeSLA)),
        'avgResolutionTime': _average(group.map((b) => b.resolutionTimeSLA)),
        'avgSatisfaction': _average(group.map((b) => b.customerSatisfactionScore)),
        'avgTeamSize': _average(group.map((b) => b.supportTeamSize.toDouble())),
        'avgSalary': _average(group.map((b) => b.avgSalaryPerAgent)),
      };
    }

    return averages;
  }

  double _getTierMultiplier(String tier) {
    switch (tier) {
      case 'Basic':
        return 1.0;
      case 'Standard':
        return 1.5;
      case 'Premium':
        return 2.0;
      case 'Enterprise':
        return 3.0;
      case 'VIP':
        return 4.0;
      default:
        return 1.0;
    }
  }

  double _getSizeMultiplier(String size) {
    switch (size) {
      case 'Startup':
        return 0.8;
      case 'Small':
        return 1.0;
      case 'Medium':
        return 1.5;
      case 'Large':
        return 2.0;
      case 'Enterprise':
        return 3.0;
      default:
        return 1.0;
    }
  }

  double _getResponseSLA(String tier) {
    switch (tier) {
      case 'Basic':
        return 48.0;
      case 'Standard':
        return 24.0;
      case 'Premium':
        return 8.0;
      case 'Enterprise':
        return 4.0;
      case 'VIP':
        return 1.0;
      default:
        return 24.0;
    }
  }

  double _getResolutionSLA(String tier) {
    switch (tier) {
      case 'Basic':
        return 168.0; // 1 week
      case 'Standard':
        return 72.0; // 3 days
      case 'Premium':
        return 24.0; // 1 day
      case 'Enterprise':
        return 12.0; // 12 hours
      case 'VIP':
        return 4.0; // 4 hours
      default:
        return 72.0;
    }
  }

  double _average(Iterable<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }
}
