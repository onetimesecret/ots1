import 'dart:io';
import '../domain/usecases/comprehensive_analysis_orchestrator.dart';

/// CLI tool for running support cost modeling analysis
class CostModelingCLI {
  final ComprehensiveAnalysisOrchestrator _orchestrator;

  CostModelingCLI({
    ComprehensiveAnalysisOrchestrator? orchestrator,
  }) : _orchestrator = orchestrator ?? ComprehensiveAnalysisOrchestrator();

  /// Run the CLI
  Future<void> run(List<String> arguments) async {
    _printHeader();

    final options = _parseArguments(arguments);

    if (options['help'] == true) {
      _printHelp();
      return;
    }

    try {
      final result = await _runAnalysis(options);
      _displayResults(result, options);
      await _exportResults(result, options);
    } catch (e, stackTrace) {
      _printError('Analysis failed: $e');
      if (options['verbose'] == true) {
        print('\nStack trace:');
        print(stackTrace);
      }
      exit(1);
    }
  }

  void _printHeader() {
    print('');
    print('╔═══════════════════════════════════════════════════════════════════╗');
    print('║   SUPPORT COST INVERSION MODELING & PRICING OPTIMIZATION CLI     ║');
    print('╚═══════════════════════════════════════════════════════════════════╝');
    print('');
  }

  Map<String, dynamic> _parseArguments(List<String> arguments) {
    final options = <String, dynamic>{
      'segments': 50,
      'companies': 100,
      'monitoring': true,
      'arbitrage': true,
      'verbose': false,
      'export': true,
      'format': 'txt',
      'help': false,
    };

    for (int i = 0; i < arguments.length; i++) {
      final arg = arguments[i];

      switch (arg) {
        case '-h':
        case '--help':
          options['help'] = true;
          break;
        case '-s':
        case '--segments':
          if (i + 1 < arguments.length) {
            options['segments'] = int.tryParse(arguments[++i]) ?? 50;
          }
          break;
        case '-c':
        case '--companies':
          if (i + 1 < arguments.length) {
            options['companies'] = int.tryParse(arguments[++i]) ?? 100;
          }
          break;
        case '--no-monitoring':
          options['monitoring'] = false;
          break;
        case '--no-arbitrage':
          options['arbitrage'] = false;
          break;
        case '-v':
        case '--verbose':
          options['verbose'] = true;
          break;
        case '--no-export':
          options['export'] = false;
          break;
        case '-f':
        case '--format':
          if (i + 1 < arguments.length) {
            options['format'] = arguments[++i];
          }
          break;
      }
    }

    return options;
  }

  void _printHelp() {
    print('Usage: dart run lib/features/support_cost_modeling/cli/cost_modeling_cli.dart [OPTIONS]');
    print('');
    print('Options:');
    print('  -h, --help              Show this help message');
    print('  -s, --segments N        Number of market segments to analyze (default: 50)');
    print('  -c, --companies N       Number of companies to benchmark (default: 100)');
    print('  --no-monitoring         Disable monitoring dashboard generation');
    print('  --no-arbitrage          Disable arbitrage detection');
    print('  -v, --verbose           Enable verbose output');
    print('  --no-export             Skip exporting results to file');
    print('  -f, --format FORMAT     Export format: txt, json, csv (default: txt)');
    print('');
    print('Examples:');
    print('  dart run lib/features/support_cost_modeling/cli/cost_modeling_cli.dart');
    print('  dart run lib/features/support_cost_modeling/cli/cost_modeling_cli.dart -s 100 -c 200');
    print('  dart run lib/features/support_cost_modeling/cli/cost_modeling_cli.dart --no-monitoring -v');
    print('');
  }

  Future<ComprehensiveAnalysisResult> _runAnalysis(
    Map<String, dynamic> options,
  ) async {
    final startTime = DateTime.now();

    print('Configuration:');
    print('  Market Segments: ${options['segments']}');
    print('  Benchmark Companies: ${options['companies']}');
    print('  Monitoring Enabled: ${options['monitoring']}');
    print('  Arbitrage Detection: ${options['arbitrage']}');
    print('');

    final result = await _orchestrator.runCompleteAnalysis(
      segmentCount: options['segments'] as int,
      benchmarkCompanyCount: options['companies'] as int,
      includeMonitoring: options['monitoring'] as bool,
      includeArbitrage: options['arbitrage'] as bool,
    );

    final duration = DateTime.now().difference(startTime);
    print('⏱️  Analysis completed in ${duration.inSeconds} seconds\n');

    return result;
  }

  void _displayResults(
    ComprehensiveAnalysisResult result,
    Map<String, dynamic> options,
  ) {
    if (options['verbose'] != true) {
      _displaySummary(result);
    } else {
      final report = _orchestrator.generateDetailedReport(result);
      print(report);
    }
  }

  void _displaySummary(ComprehensiveAnalysisResult result) {
    print('╔═══════════════════════════════════════════════════════════════════╗');
    print('║                        ANALYSIS SUMMARY                           ║');
    print('╚═══════════════════════════════════════════════════════════════════╝');
    print('');
    print('📊 Benchmarks Analyzed: ${result.benchmarks.length} companies');
    print('💰 Cost Models Generated: ${result.costModels.length} tiers');
    print('📈 P&L Scenarios: ${result.plScenarios.length}');
    print('🌍 Market Segments Analyzed: ${result.segmentAnalyses.length}');

    if (result.dashboard != null) {
      print('📱 Dashboard Health Score: ${result.dashboard!.healthScore.toStringAsFixed(1)}/100');
      print('⚠️  Active Alerts: ${result.dashboard!.activeAlerts.length}');
    }

    print('🔍 Arbitrage Opportunities: ${result.arbitrageOpportunities.length}');
    print('🔄 Re-optimization Recommendations: ${result.reoptimizations.length}');
    print('');

    // Top insights
    print('🎯 TOP INSIGHTS:');
    print('');

    // Most profitable tier
    final profitableScenarios = result.plScenarios.where((s) => s.isProfitable).toList();
    if (profitableScenarios.isNotEmpty) {
      final best = profitableScenarios.reduce(
        (a, b) => a.netProfit > b.netProfit ? a : b,
      );
      print('  ✓ Most Profitable Support Tier: ${best.tier.displayName}');
      print('    Net Profit: \$${best.netProfit.toStringAsFixed(2)}/month');
      print('    ROI: ${best.roi.toStringAsFixed(1)}%');
      print('');
    }

    // Best market segment
    if (result.segmentAnalyses.isNotEmpty) {
      final bestSegment = result.segmentAnalyses.reduce((a, b) {
        final aRevenue = a.revenueProjections[MarketCondition.base]?.totalRevenue ?? 0;
        final bRevenue = b.revenueProjections[MarketCondition.base]?.totalRevenue ?? 0;
        return aRevenue > bRevenue ? a : b;
      });

      final baseRevenue = bestSegment.revenueProjections[MarketCondition.base];
      print('  ✓ Highest Revenue Segment: ${bestSegment.segmentName}');
      if (baseRevenue != null) {
        print('    Projected Revenue: \$${baseRevenue.totalRevenue.toStringAsFixed(2)}');
        print('    Margin: ${baseRevenue.margin.toStringAsFixed(1)}%');
      }
      print('');
    }

    // Critical risks
    final highRiskArbitrage = result.arbitrageOpportunities
        .where((o) => o.requiresAction)
        .length;
    if (highRiskArbitrage > 0) {
      print('  ⚠️  High-Risk Arbitrage Opportunities: $highRiskArbitrage');
      print('    Immediate action required to prevent revenue leakage');
      print('');
    }

    print('For detailed report, run with --verbose flag');
    print('');
  }

  Future<void> _exportResults(
    ComprehensiveAnalysisResult result,
    Map<String, dynamic> options,
  ) async {
    if (options['export'] != true) return;

    final format = options['format'] as String;
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final filename = 'cost_modeling_analysis_$timestamp.$format';

    print('📄 Exporting results to: $filename');

    try {
      final content = _generateExportContent(result, format);
      final file = File(filename);
      await file.writeAsString(content);
      print('✓ Results exported successfully\n');
    } catch (e) {
      _printError('Failed to export results: $e');
    }
  }

  String _generateExportContent(
    ComprehensiveAnalysisResult result,
    String format,
  ) {
    switch (format.toLowerCase()) {
      case 'json':
        return _generateJSON(result);
      case 'csv':
        return _generateCSV(result);
      default:
        return _orchestrator.generateDetailedReport(result);
    }
  }

  String _generateJSON(ComprehensiveAnalysisResult result) {
    // Simplified JSON export
    final data = {
      'generatedAt': result.generatedAt.toIso8601String(),
      'summary': {
        'benchmarksCount': result.benchmarks.length,
        'costModelsCount': result.costModels.length,
        'segmentsAnalyzed': result.segmentAnalyses.length,
        'arbitrageOpportunities': result.arbitrageOpportunities.length,
      },
      'plScenarios': result.plScenarios.map((s) => {
        'tier': s.tier.displayName,
        'monthlyRevenue': s.monthlyRevenue,
        'supportCost': s.monthlySupportCost,
        'netProfit': s.netProfit,
        'isProfitable': s.isProfitable,
      }).toList(),
      'topSegments': result.segmentAnalyses.take(10).map((a) => {
        'name': a.segmentName,
        'recommendations': a.tierRecommendations.map((r) => {
          'tier': r.tierName,
          'optimalPrice': r.optimalPrice,
          'margin': r.margin,
        }).toList(),
      }).toList(),
    };

    // Simple JSON encoding (without using dart:convert for minimal dependencies)
    return data.toString().replaceAll('{', '{\n  ').replaceAll('}', '\n}');
  }

  String _generateCSV(ComprehensiveAnalysisResult result) {
    final buffer = StringBuffer();

    // P&L Scenarios CSV
    buffer.writeln('Support Tier,Monthly Revenue,Support Cost,Net Profit,Churn Rate,LTV,ROI,Profitable');
    for (final scenario in result.plScenarios) {
      buffer.writeln(
        '${scenario.tier.displayName},'
        '${scenario.monthlyRevenue},'
        '${scenario.monthlySupportCost},'
        '${scenario.netProfit},'
        '${scenario.churnRate},'
        '${scenario.customerLifetimeValue},'
        '${scenario.roi},'
        '${scenario.isProfitable}',
      );
    }

    buffer.writeln('');
    buffer.writeln('Segment,Tier,Optimal Price,Min Price,Max Price,Margin');
    for (final analysis in result.segmentAnalyses.take(20)) {
      for (final rec in analysis.tierRecommendations) {
        buffer.writeln(
          '${analysis.segmentName},'
          '${rec.tierName},'
          '${rec.optimalPrice},'
          '${rec.minPrice},'
          '${rec.maxPrice},'
          '${rec.margin}',
        );
      }
    }

    return buffer.toString();
  }

  void _printError(String message) {
    print('\n❌ ERROR: $message\n');
  }
}

/// Main entry point for CLI
Future<void> main(List<String> arguments) async {
  final cli = CostModelingCLI();
  await cli.run(arguments);
}
