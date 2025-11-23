import '../entities/support_benchmark.dart';
import '../entities/cost_model.dart';
import '../entities/market_segment.dart';
import '../entities/pricing_analysis.dart';
import '../entities/monitoring.dart';
import '../../data/datasources/support_benchmark_datasource.dart';
import '../../data/datasources/market_segment_datasource.dart';
import 'cost_modeling_engine.dart';
import 'pricing_optimization_engine.dart';
import 'monitoring_engine.dart';
import 'arbitrage_detection_engine.dart';

/// Orchestrates the complete support cost modeling and pricing analysis
class ComprehensiveAnalysisOrchestrator {
  final SupportBenchmarkDataSource _benchmarkDataSource;
  final MarketSegmentDataSource _segmentDataSource;
  final CostModelingEngine _costModelingEngine;
  final PricingOptimizationEngine _pricingEngine;
  final MonitoringEngine _monitoringEngine;
  final ArbitrageDetectionEngine _arbitrageEngine;

  ComprehensiveAnalysisOrchestrator({
    SupportBenchmarkDataSource? benchmarkDataSource,
    MarketSegmentDataSource? segmentDataSource,
    CostModelingEngine? costModelingEngine,
    PricingOptimizationEngine? pricingEngine,
    MonitoringEngine? monitoringEngine,
    ArbitrageDetectionEngine? arbitrageEngine,
  })  : _benchmarkDataSource = benchmarkDataSource ?? SupportBenchmarkDataSource(),
        _segmentDataSource = segmentDataSource ?? MarketSegmentDataSource(),
        _costModelingEngine = costModelingEngine ?? CostModelingEngine(),
        _pricingEngine = pricingEngine ?? PricingOptimizationEngine(),
        _monitoringEngine = monitoringEngine ?? MonitoringEngine(),
        _arbitrageEngine = arbitrageEngine ?? ArbitrageDetectionEngine();

  /// Run complete analysis pipeline
  Future<ComprehensiveAnalysisResult> runCompleteAnalysis({
    int segmentCount = 50,
    int benchmarkCompanyCount = 100,
    bool includeMonitoring = true,
    bool includeArbitrage = true,
  }) async {
    print('🚀 Starting Comprehensive Support Cost Modeling Analysis...\n');

    // Phase 1: Scrape and analyze support benchmarks
    print('📊 Phase 1: Scraping support cost benchmarks from $benchmarkCompanyCount SaaS companies...');
    final benchmarks = await _benchmarkDataSource.scrapeBenchmarks(
      companyCount: benchmarkCompanyCount,
    );
    print('✓ Collected ${benchmarks.length} support cost benchmarks\n');

    // Phase 2: Build cost-per-ticket models
    print('💰 Phase 2: Building cost-per-ticket models by support tier...');
    final costModels = await _costModelingEngine.buildCostModels(benchmarks);
    print('✓ Generated ${costModels.length} tier-based cost models\n');

    // Phase 3: Simulate P&L impact
    print('📈 Phase 3: Simulating P&L impact for different SLA scenarios...');
    final plScenarios = await _costModelingEngine.simulatePLImpact(
      costModels: costModels,
      customerCount: 1000,
      monthlyRevenuePerCustomer: 99.0,
      customerAcquisitionCost: 500,
      baseChurnRate: 0.08,
    );
    print('✓ Simulated ${plScenarios.length} P&L scenarios\n');

    // Phase 4: Generate pricing calculator insights
    print('🧮 Phase 4: Generating support pricing calculator...');
    final pricingCalculations = <String, Map<String, dynamic>>{};
    for (final entry in costModels.entries) {
      pricingCalculations[entry.key.displayName] =
          _costModelingEngine.calculateSupportPricing(
        tier: entry.key,
        expectedMonthlyTickets: 1000,
        targetMargin: 0.25,
        costModel: entry.value,
      );
    }
    print('✓ Generated pricing recommendations for ${pricingCalculations.length} tiers\n');

    // Phase 5: Multi-scenario analysis across market segments
    print('🌍 Phase 5: Running multi-scenario analysis across $segmentCount market segments...');
    final segments = await _segmentDataSource.generateSegments(count: segmentCount);
    final segmentAnalyses = <PricingAnalysis>[];

    final productTiers = _generateProductTiers(costModels);

    int processedCount = 0;
    for (final segment in segments) {
      processedCount++;
      if (processedCount % 10 == 0) {
        print('  Processing segment $processedCount/$segmentCount...');
      }

      final competitors = await _segmentDataSource.generateCompetitors(
        segmentId: segment.id,
        count: 3,
      );

      final analysis = await _pricingEngine.analyzePricing(
        segment: segment,
        productTiers: productTiers,
        competitorData: competitors,
      );

      segmentAnalyses.add(analysis);
    }
    print('✓ Completed analysis for ${segmentAnalyses.length} market segments\n');

    // Phase 6: Monitoring dashboard
    KPIDashboard? dashboard;
    if (includeMonitoring) {
      print('📱 Phase 6: Generating real-time monitoring dashboard...');
      dashboard = await _monitoringEngine.generateDashboard(
        analyses: segmentAnalyses,
        currentMetrics: {
          'revenue': 250000,
          'margin': 0.35,
          'customerCount': 1200,
          'churnRate': 0.07,
          'supportCost': 0.12,
          'nps': 55,
        },
      );
      print('✓ Dashboard generated with ${dashboard.kpis.length} KPIs and ${dashboard.activeAlerts.length} alerts\n');
    }

    // Phase 7: Arbitrage detection
    List<ArbitrageOpportunity>? arbitrageOpportunities;
    Map<String, dynamic>? arbitrageStrategy;
    if (includeArbitrage) {
      print('🔍 Phase 7: Running cross-region arbitrage detection...');
      final regionalPricing = _generateRegionalPricing(productTiers);
      arbitrageOpportunities = await _arbitrageEngine.detectArbitrage(
        regionalPricing: regionalPricing,
        transferCosts: {
          'North America-Europe': 10,
          'North America-Asia Pacific': 20,
          'Europe-Asia Pacific': 15,
        },
        exchangeRates: {
          'North America': 1.0,
          'Europe': 0.92,
          'Asia Pacific': 0.85,
        },
      );

      if (arbitrageOpportunities.isNotEmpty) {
        arbitrageStrategy = await _arbitrageEngine.generatePreventionStrategy(
          opportunities: arbitrageOpportunities,
          regionalPricing: regionalPricing,
        );
      }
      print('✓ Detected ${arbitrageOpportunities.length} arbitrage opportunities\n');
    }

    // Phase 8: Generate alerts and recommendations
    print('⚠️  Phase 8: Generating automated alerts and recommendations...');
    final alerts = <Alert>[];
    final reoptimizations = <ReoptimizationRecommendation>[];

    for (final analysis in segmentAnalyses.take(5)) {
      final reopt = await _monitoringEngine.generateReoptimization(
        segmentId: analysis.segmentId,
        currentPrices: {
          for (var rec in analysis.tierRecommendations)
            rec.tierId: rec.optimalPrice
        },
        performanceMetrics: {'revenue': 0.8},
        historicalData: [],
      );
      reoptimizations.add(reopt);
    }
    print('✓ Generated ${reoptimizations.length} re-optimization recommendations\n');

    print('✅ Analysis Complete!\n');

    return ComprehensiveAnalysisResult(
      benchmarks: benchmarks,
      costModels: costModels,
      plScenarios: plScenarios,
      pricingCalculations: pricingCalculations,
      segmentAnalyses: segmentAnalyses,
      dashboard: dashboard,
      arbitrageOpportunities: arbitrageOpportunities ?? [],
      arbitrageStrategy: arbitrageStrategy,
      reoptimizations: reoptimizations,
      generatedAt: DateTime.now(),
    );
  }

  /// Generate detailed report from analysis
  String generateDetailedReport(ComprehensiveAnalysisResult result) {
    final buffer = StringBuffer();

    buffer.writeln('═══════════════════════════════════════════════════════════════════');
    buffer.writeln('    COMPREHENSIVE SUPPORT COST MODELING & PRICING ANALYSIS REPORT');
    buffer.writeln('═══════════════════════════════════════════════════════════════════');
    buffer.writeln('Generated: ${result.generatedAt.toIso8601String()}\n');

    // Executive Summary
    buffer.writeln('EXECUTIVE SUMMARY');
    buffer.writeln('─────────────────────────────────────────────────────────────────');
    buffer.writeln('• Analyzed ${result.benchmarks.length} SaaS companies for support cost benchmarks');
    buffer.writeln('• Generated ${result.costModels.length} tier-based cost models');
    buffer.writeln('• Evaluated ${result.segmentAnalyses.length} market segments');
    buffer.writeln('• Simulated ${result.plScenarios.length} P&L scenarios');
    buffer.writeln('• Identified ${result.arbitrageOpportunities.length} arbitrage opportunities\n');

    // Support Cost Benchmarks
    buffer.writeln('\n1. SUPPORT COST BENCHMARKS');
    buffer.writeln('─────────────────────────────────────────────────────────────────');
    final avgByTier = <String, List<double>>{};
    for (final benchmark in result.benchmarks) {
      avgByTier.putIfAbsent(benchmark.supportTier, () => []).add(benchmark.costPerTicket);
    }

    for (final entry in avgByTier.entries) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      buffer.writeln('${entry.key}: \$${avg.toStringAsFixed(2)} per ticket (${entry.value.length} companies)');
    }

    // Cost Models
    buffer.writeln('\n2. COST-PER-TICKET MODELS');
    buffer.writeln('─────────────────────────────────────────────────────────────────');
    for (final entry in result.costModels.entries) {
      final model = entry.value;
      buffer.writeln('\n${entry.key.displayName} Tier:');
      buffer.writeln('  Cost per Ticket: \$${model.costPerTicket.toStringAsFixed(2)}');
      buffer.writeln('  Response SLA: ${model.responseTimeSLA}h');
      buffer.writeln('  Resolution SLA: ${model.resolutionTimeSLA}h');
      buffer.writeln('  Satisfaction Target: ${(model.satisfactionTarget * 100).toStringAsFixed(1)}%');
    }

    // P&L Impact
    buffer.writeln('\n3. P&L IMPACT ANALYSIS');
    buffer.writeln('─────────────────────────────────────────────────────────────────');
    for (final scenario in result.plScenarios) {
      buffer.writeln('\n${scenario.scenarioName}:');
      buffer.writeln('  Monthly Revenue: \$${scenario.monthlyRevenue.toStringAsFixed(2)}');
      buffer.writeln('  Support Cost: \$${scenario.monthlySupportCost.toStringAsFixed(2)} (${scenario.supportCostPercentage.toStringAsFixed(1)}%)');
      buffer.writeln('  Net Profit: \$${scenario.netProfit.toStringAsFixed(2)}');
      buffer.writeln('  Customer LTV: \$${scenario.customerLifetimeValue.toStringAsFixed(2)}');
      buffer.writeln('  ROI: ${scenario.roi.toStringAsFixed(1)}%');
      buffer.writeln('  Profitable: ${scenario.isProfitable ? "✓ Yes" : "✗ No"}');
    }

    // Pricing Calculator
    buffer.writeln('\n4. SUPPORT PRICING CALCULATOR');
    buffer.writeln('─────────────────────────────────────────────────────────────────');
    for (final entry in result.pricingCalculations.entries) {
      final calc = entry.value;
      buffer.writeln('\n${entry.key}:');
      buffer.writeln('  Monthly Price: \$${calc['monthlyPrice'].toStringAsFixed(2)}');
      buffer.writeln('  Annual Price: \$${calc['annualPrice'].toStringAsFixed(2)}');
      buffer.writeln('  Target Margin: ${calc['margin'].toStringAsFixed(1)}%');
      buffer.writeln('  Profitable: ${calc['isProfitable'] ? "✓ Yes" : "✗ No"}');
    }

    // Top Segment Analyses
    buffer.writeln('\n5. TOP MARKET SEGMENT ANALYSES (showing 5 of ${result.segmentAnalyses.length})');
    buffer.writeln('─────────────────────────────────────────────────────────────────');
    for (final analysis in result.segmentAnalyses.take(5)) {
      buffer.writeln('\nSegment: ${analysis.segmentName}');
      buffer.writeln('  Tier Recommendations: ${analysis.tierRecommendations.length}');

      for (final rec in analysis.tierRecommendations) {
        buffer.writeln('    ${rec.tierName}: \$${rec.optimalPrice.toStringAsFixed(2)} '
            '(Margin: \$${rec.margin.toStringAsFixed(2)})');
      }

      buffer.writeln('  Revenue Projections:');
      for (final entry in analysis.revenueProjections.entries) {
        final proj = entry.value;
        buffer.writeln('    ${entry.key.displayName}: \$${proj.totalRevenue.toStringAsFixed(2)} '
            '(Margin: ${proj.margin.toStringAsFixed(1)}%)');
      }

      buffer.writeln('  Competitive Position: ${analysis.competitivePositioning.positioning}');
      buffer.writeln('  Risk Level: ${analysis.riskAssessment.riskLevel}');
    }

    // Dashboard
    if (result.dashboard != null) {
      buffer.writeln('\n6. REAL-TIME MONITORING DASHBOARD');
      buffer.writeln('─────────────────────────────────────────────────────────────────');
      buffer.writeln('Health Score: ${result.dashboard!.healthScore.toStringAsFixed(1)}/100\n');

      buffer.writeln('Key Performance Indicators:');
      for (final kpi in result.dashboard!.kpis.values) {
        buffer.writeln('  ${kpi.name}: ${kpi.currentValue.toStringAsFixed(2)} ${kpi.unit} '
            '(Target: ${kpi.targetValue.toStringAsFixed(2)}) - ${kpi.status.displayName}');
      }

      if (result.dashboard!.activeAlerts.isNotEmpty) {
        buffer.writeln('\nActive Alerts: ${result.dashboard!.activeAlerts.length}');
        for (final alert in result.dashboard!.activeAlerts.take(3)) {
          buffer.writeln('  [${alert.severity.toUpperCase()}] ${alert.message}');
        }
      }
    }

    // Arbitrage Detection
    if (result.arbitrageOpportunities.isNotEmpty) {
      buffer.writeln('\n7. CROSS-REGION ARBITRAGE DETECTION');
      buffer.writeln('─────────────────────────────────────────────────────────────────');
      buffer.writeln('Total Opportunities: ${result.arbitrageOpportunities.length}');
      buffer.writeln('High Risk Opportunities: ${result.arbitrageOpportunities.where((o) => o.riskScore > 0.6).length}\n');

      for (final opp in result.arbitrageOpportunities.take(5)) {
        buffer.writeln('  ${opp.sourceRegion} → ${opp.targetRegion} (${opp.productTier}):');
        buffer.writeln('    Price Differential: \$${opp.priceDifferential.toStringAsFixed(2)}');
        buffer.writeln('    Risk Score: ${(opp.riskScore * 100).toStringAsFixed(1)}%');
        buffer.writeln('    Potential Profit: \$${opp.potentialProfit.toStringAsFixed(2)}');
        buffer.writeln('    Requires Action: ${opp.requiresAction ? "✓ Yes" : "No"}\n');
      }
    }

    // Recommendations
    buffer.writeln('\n8. RE-OPTIMIZATION RECOMMENDATIONS');
    buffer.writeln('─────────────────────────────────────────────────────────────────');
    for (final reopt in result.reoptimizations.take(3)) {
      buffer.writeln('\nSegment: ${reopt.segmentId}');
      buffer.writeln('  Confidence: ${(reopt.confidenceScore * 100).toStringAsFixed(1)}%');
      buffer.writeln('  Expected Revenue Impact: \$${reopt.expectedRevenueImpact.toStringAsFixed(2)}');
      buffer.writeln('  Key Findings:');
      for (final finding in reopt.keyFindings.take(3)) {
        buffer.writeln('    • $finding');
      }
    }

    buffer.writeln('\n═══════════════════════════════════════════════════════════════════');
    buffer.writeln('                          END OF REPORT');
    buffer.writeln('═══════════════════════════════════════════════════════════════════\n');

    return buffer.toString();
  }

  List<ProductTier> _generateProductTiers(
    Map<SupportTier, CostPerTicketModel> costModels,
  ) {
    return costModels.entries.map((entry) {
      final tier = entry.key;
      final model = entry.value;

      return ProductTier(
        id: tier.name,
        name: tier.displayName,
        basePrice: model.costPerTicket * 2, // 100% markup
        features: _getTierFeatures(tier),
        supportCost: model.costPerTicket,
        marginTarget: 0.5,
      );
    }).toList();
  }

  List<String> _getTierFeatures(SupportTier tier) {
    final baseFeatures = ['Email support', 'Knowledge base access'];

    switch (tier) {
      case SupportTier.basic:
        return baseFeatures;
      case SupportTier.standard:
        return [...baseFeatures, 'Chat support', 'Business hours coverage'];
      case SupportTier.premium:
        return [...baseFeatures, 'Priority support', '24/7 coverage', 'Phone support'];
      case SupportTier.enterprise:
        return [
          ...baseFeatures,
          'Dedicated account manager',
          'Custom SLAs',
          'Priority bug fixes',
        ];
      case SupportTier.vip:
        return [
          ...baseFeatures,
          'Executive support',
          'Custom integrations',
          'Onsite support',
        ];
    }
  }

  Map<String, Map<String, double>> _generateRegionalPricing(
    List<ProductTier> tiers,
  ) {
    return {
      'North America': {for (var t in tiers) t.id: t.basePrice},
      'Europe': {for (var t in tiers) t.id: t.basePrice * 0.92},
      'Asia Pacific': {for (var t in tiers) t.id: t.basePrice * 0.85},
      'Latin America': {for (var t in tiers) t.id: t.basePrice * 0.75},
    };
  }
}

/// Result container for comprehensive analysis
class ComprehensiveAnalysisResult {
  final List<SupportBenchmark> benchmarks;
  final Map<SupportTier, CostPerTicketModel> costModels;
  final List<PLImpactModel> plScenarios;
  final Map<String, Map<String, dynamic>> pricingCalculations;
  final List<PricingAnalysis> segmentAnalyses;
  final KPIDashboard? dashboard;
  final List<ArbitrageOpportunity> arbitrageOpportunities;
  final Map<String, dynamic>? arbitrageStrategy;
  final List<ReoptimizationRecommendation> reoptimizations;
  final DateTime generatedAt;

  const ComprehensiveAnalysisResult({
    required this.benchmarks,
    required this.costModels,
    required this.plScenarios,
    required this.pricingCalculations,
    required this.segmentAnalyses,
    required this.dashboard,
    required this.arbitrageOpportunities,
    required this.arbitrageStrategy,
    required this.reoptimizations,
    required this.generatedAt,
  });
}
