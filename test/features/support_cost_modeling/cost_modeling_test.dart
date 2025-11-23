import 'package:flutter_test/flutter_test.dart';
import 'package:onetimesecret_flutter/features/support_cost_modeling/data/datasources/support_benchmark_datasource.dart';
import 'package:onetimesecret_flutter/features/support_cost_modeling/data/datasources/market_segment_datasource.dart';
import 'package:onetimesecret_flutter/features/support_cost_modeling/domain/usecases/cost_modeling_engine.dart';
import 'package:onetimesecret_flutter/features/support_cost_modeling/domain/usecases/pricing_optimization_engine.dart';
import 'package:onetimesecret_flutter/features/support_cost_modeling/domain/usecases/monitoring_engine.dart';
import 'package:onetimesecret_flutter/features/support_cost_modeling/domain/usecases/arbitrage_detection_engine.dart';
import 'package:onetimesecret_flutter/features/support_cost_modeling/domain/usecases/comprehensive_analysis_orchestrator.dart';
import 'package:onetimesecret_flutter/features/support_cost_modeling/domain/entities/support_benchmark.dart';
import 'package:onetimesecret_flutter/features/support_cost_modeling/domain/entities/pricing_analysis.dart';

void main() {
  group('Support Cost Modeling Tests', () {
    late SupportBenchmarkDataSource benchmarkDataSource;
    late MarketSegmentDataSource segmentDataSource;
    late CostModelingEngine costEngine;
    late PricingOptimizationEngine pricingEngine;
    late MonitoringEngine monitoringEngine;
    late ArbitrageDetectionEngine arbitrageEngine;
    late ComprehensiveAnalysisOrchestrator orchestrator;

    setUp(() {
      benchmarkDataSource = SupportBenchmarkDataSource();
      segmentDataSource = MarketSegmentDataSource();
      costEngine = CostModelingEngine();
      pricingEngine = PricingOptimizationEngine();
      monitoringEngine = MonitoringEngine();
      arbitrageEngine = ArbitrageDetectionEngine();
      orchestrator = ComprehensiveAnalysisOrchestrator(
        benchmarkDataSource: benchmarkDataSource,
        segmentDataSource: segmentDataSource,
        costModelingEngine: costEngine,
        pricingEngine: pricingEngine,
        monitoringEngine: monitoringEngine,
        arbitrageEngine: arbitrageEngine,
      );
    });

    test('Should scrape support benchmarks from multiple companies', () async {
      final benchmarks = await benchmarkDataSource.scrapeBenchmarks(
        companyCount: 50,
      );

      expect(benchmarks, isNotEmpty);
      expect(benchmarks.length, equals(50));
      expect(benchmarks.first.companyName, isNotNull);
      expect(benchmarks.first.costPerTicket, greaterThan(0));
    });

    test('Should build cost-per-ticket models by tier', () async {
      final benchmarks = await benchmarkDataSource.scrapeBenchmarks(
        companyCount: 100,
      );
      final costModels = await costEngine.buildCostModels(benchmarks);

      expect(costModels, isNotEmpty);
      expect(costModels.keys, contains(SupportTier.basic));
      expect(costModels.keys, contains(SupportTier.premium));

      final basicModel = costModels[SupportTier.basic];
      expect(basicModel, isNotNull);
      expect(basicModel!.costPerTicket, greaterThan(0));
      expect(basicModel.responseTimeSLA, greaterThan(0));
    });

    test('Should simulate P&L impact for different SLAs', () async {
      final benchmarks = await benchmarkDataSource.scrapeBenchmarks(
        companyCount: 100,
      );
      final costModels = await costEngine.buildCostModels(benchmarks);

      final plScenarios = await costEngine.simulatePLImpact(
        costModels: costModels,
        customerCount: 1000,
        monthlyRevenuePerCustomer: 99.0,
        customerAcquisitionCost: 500,
        baseChurnRate: 0.08,
      );

      expect(plScenarios, isNotEmpty);

      for (final scenario in plScenarios) {
        expect(scenario.monthlyRevenue, greaterThan(0));
        expect(scenario.customerCount, equals(1000));
        expect(scenario.supportCostPercentage, greaterThanOrEqualTo(0));
      }

      // Verify profitability calculation
      final profitableScenarios = plScenarios.where((s) => s.isProfitable);
      expect(profitableScenarios, isNotEmpty);
    });

    test('Should generate support pricing calculator', () async {
      final benchmarks = await benchmarkDataSource.scrapeBenchmarks(
        companyCount: 100,
      );
      final costModels = await costEngine.buildCostModels(benchmarks);
      final model = costModels[SupportTier.standard]!;

      final pricing = costEngine.calculateSupportPricing(
        tier: SupportTier.standard,
        expectedMonthlyTickets: 1000,
        targetMargin: 0.25,
        costModel: model,
      );

      expect(pricing['tier'], equals('Standard'));
      expect(pricing['costPerTicket'], greaterThan(0));
      expect(pricing['monthlyPrice'], greaterThan(0));
      expect(pricing['annualPrice'], greaterThan(0));
      expect(pricing['isProfitable'], isTrue);
    });

    test('Should generate market segments with elasticity curves', () async {
      final segments = await segmentDataSource.generateSegments(count: 50);

      expect(segments, isNotEmpty);
      expect(segments.length, equals(50));

      final segment = segments.first;
      expect(segment.id, isNotNull);
      expect(segment.elasticityCurve.basePrice, greaterThan(0));
      expect(segment.elasticityCurve.elasticity, greaterThan(0));
      expect(segment.elasticityCurve.pricePoints, isNotEmpty);
    });

    test('Should optimize pricing for market segment', () async {
      final segments = await segmentDataSource.generateSegments(count: 1);
      final segment = segments.first;

      final benchmarks = await benchmarkDataSource.scrapeBenchmarks(
        companyCount: 50,
      );
      final costModels = await costEngine.buildCostModels(benchmarks);

      final productTiers = costModels.entries.map((entry) {
        return ProductTier(
          id: entry.key.name,
          name: entry.key.displayName,
          basePrice: entry.value.costPerTicket * 2,
          features: ['Feature 1', 'Feature 2'],
          supportCost: entry.value.costPerTicket,
          marginTarget: 0.5,
        );
      }).toList();

      final competitors = await segmentDataSource.generateCompetitors(
        segmentId: segment.id,
        count: 3,
      );

      final analysis = await pricingEngine.analyzePricing(
        segment: segment,
        productTiers: productTiers,
        competitorData: competitors,
      );

      expect(analysis.tierRecommendations, isNotEmpty);
      expect(analysis.revenueProjections, hasLength(3)); // bull, base, bear
      expect(analysis.competitivePositioning, isNotNull);
      expect(analysis.sensitivityAnalysis, isNotNull);
      expect(analysis.riskAssessment, isNotNull);
      expect(analysis.implementationPlan, isNotNull);
    });

    test('Should generate KPI dashboard with monitoring', () async {
      final dashboard = await monitoringEngine.generateDashboard(
        analyses: [],
        currentMetrics: {
          'revenue': 100000,
          'margin': 0.3,
          'customerCount': 1000,
          'churnRate': 0.08,
          'supportCost': 0.15,
          'nps': 50,
        },
      );

      expect(dashboard.kpis, isNotEmpty);
      expect(dashboard.healthScore, greaterThanOrEqualTo(0));
      expect(dashboard.healthScore, lessThanOrEqualTo(100));
      expect(dashboard.timestamp, isNotNull);
    });

    test('Should detect arbitrage opportunities across regions', () async {
      final regionalPricing = {
        'North America': {'basic': 100.0, 'premium': 200.0},
        'Europe': {'basic': 80.0, 'premium': 160.0},
        'Asia Pacific': {'basic': 60.0, 'premium': 120.0},
      };

      final opportunities = await arbitrageEngine.detectArbitrage(
        regionalPricing: regionalPricing,
        transferCosts: {
          'North America-Europe': 10,
          'North America-Asia Pacific': 20,
        },
        exchangeRates: {
          'North America': 1.0,
          'Europe': 0.9,
          'Asia Pacific': 0.85,
        },
      );

      expect(opportunities, isNotEmpty);

      final highRisk = opportunities.where((o) => o.riskScore > 0.5);
      expect(highRisk, isNotEmpty);

      for (final opp in opportunities) {
        expect(opp.priceDifferential, isNotNull);
        expect(opp.riskScore, greaterThanOrEqualTo(0));
        expect(opp.riskScore, lessThanOrEqualTo(1));
      }
    });

    test('Should run complete comprehensive analysis', () async {
      final result = await orchestrator.runCompleteAnalysis(
        segmentCount: 10,
        benchmarkCompanyCount: 50,
        includeMonitoring: true,
        includeArbitrage: true,
      );

      expect(result.benchmarks.length, equals(50));
      expect(result.costModels, isNotEmpty);
      expect(result.plScenarios, isNotEmpty);
      expect(result.pricingCalculations, isNotEmpty);
      expect(result.segmentAnalyses.length, equals(10));
      expect(result.dashboard, isNotNull);
      expect(result.reoptimizations, isNotEmpty);
    });

    test('Should generate detailed report', () async {
      final result = await orchestrator.runCompleteAnalysis(
        segmentCount: 5,
        benchmarkCompanyCount: 20,
        includeMonitoring: false,
        includeArbitrage: false,
      );

      final report = orchestrator.generateDetailedReport(result);

      expect(report, contains('COMPREHENSIVE SUPPORT COST MODELING'));
      expect(report, contains('SUPPORT COST BENCHMARKS'));
      expect(report, contains('P&L IMPACT ANALYSIS'));
      expect(report, contains('PRICING CALCULATOR'));
      expect(report, isNotEmpty);
    });
  });
}
