import 'dart:math';
import '../../domain/entities/market_segment.dart';

/// Data source for generating market segments
class MarketSegmentDataSource {
  final Random _random = Random();

  /// Generate diverse market segments with unique elasticity curves
  Future<List<MarketSegment>> generateSegments({int count = 50}) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final segments = <MarketSegment>[];
    final industries = [
      'Healthcare',
      'Finance',
      'Retail',
      'Manufacturing',
      'Technology',
      'Education',
      'Government',
      'Nonprofit',
      'Media',
      'Telecommunications',
    ];

    final geographies = [
      'North America',
      'Europe',
      'Asia Pacific',
      'Latin America',
      'Middle East',
      'Africa',
    ];

    for (int i = 0; i < count; i++) {
      final industry = industries[_random.nextInt(industries.length)];
      final geography = geographies[_random.nextInt(geographies.length)];

      final basePrice = 50.0 + _random.nextDouble() * 450.0;
      final elasticity = 0.5 + _random.nextDouble() * 2.5;
      final marketSize = 1000000 + _random.nextDouble() * 50000000;

      segments.add(
        MarketSegment(
          id: 'segment_$i',
          name: '$industry - $geography - Segment ${i + 1}',
          description: 'Market segment for $industry sector in $geography region',
          elasticityCurve: _generateElasticityCurve(basePrice, elasticity),
          demographics: {
            'avgCompanySize': 50.0 + _random.nextDouble() * 950.0,
            'avgRevenue': 500000 + _random.nextDouble() * 99500000,
            'techSavvy': _random.nextDouble(),
            'budgetSensitivity': _random.nextDouble(),
          },
          marketSize: marketSize,
          penetrationRate: 0.01 + _random.nextDouble() * 0.2,
          growthRate: -0.05 + _random.nextDouble() * 0.35,
          geography: geography,
          industryVertical: industry,
        ),
      );
    }

    return segments;
  }

  PriceElasticityCurve _generateElasticityCurve(
    double basePrice,
    double elasticity,
  ) {
    final minPrice = basePrice * 0.5;
    final maxPrice = basePrice * 2.0;
    final pricePoints = <PricePoint>[];

    for (double price = minPrice; price <= maxPrice; price += 10) {
      final priceChange = (price - basePrice) / basePrice;
      final demandChange = -elasticity * priceChange;
      final demand = 1000 * (1 + demandChange);
      final revenue = price * demand;

      pricePoints.add(
        PricePoint(
          price: price,
          demand: demand > 0 ? demand : 0,
          revenue: revenue > 0 ? revenue : 0,
        ),
      );
    }

    return PriceElasticityCurve(
      basePrice: basePrice,
      elasticity: elasticity,
      minPrice: minPrice,
      maxPrice: maxPrice,
      pricePoints: pricePoints,
    );
  }

  /// Generate competitor data for a segment
  Future<List<Map<String, dynamic>>> generateCompetitors({
    required String segmentId,
    int count = 3,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final competitors = <Map<String, dynamic>>[];
    final names = [
      'CompetitorA',
      'CompetitorB',
      'CompetitorC',
      'CompetitorD',
      'CompetitorE',
    ];

    for (int i = 0; i < count && i < names.length; i++) {
      competitors.add({
        'name': names[i],
        'avgPrice': 100.0 + _random.nextDouble() * 400.0,
        'marketShare': 0.05 + _random.nextDouble() * 0.3,
        'customerSatisfaction': 0.6 + _random.nextDouble() * 0.4,
        'strengths': _generateStrengths(),
        'weaknesses': _generateWeaknesses(),
        'threatLevel': _random.nextDouble(),
      });
    }

    return competitors;
  }

  List<String> _generateStrengths() {
    final allStrengths = [
      'Strong brand recognition',
      'Extensive feature set',
      'Lower pricing',
      'Better customer support',
      'Established market presence',
      'Superior integration ecosystem',
      'Advanced analytics',
      'Mobile-first approach',
    ];

    final count = 2 + _random.nextInt(3);
    final strengths = <String>[];
    final shuffled = List<String>.from(allStrengths)..shuffle(_random);

    for (int i = 0; i < count && i < shuffled.length; i++) {
      strengths.add(shuffled[i]);
    }

    return strengths;
  }

  List<String> _generateWeaknesses() {
    final allWeaknesses = [
      'Higher pricing',
      'Complex user interface',
      'Limited integrations',
      'Slow customer support',
      'Legacy technology',
      'Poor mobile experience',
      'Limited customization',
      'Scalability issues',
    ];

    final count = 2 + _random.nextInt(3);
    final weaknesses = <String>[];
    final shuffled = List<String>.from(allWeaknesses)..shuffle(_random);

    for (int i = 0; i < count && i < shuffled.length; i++) {
      weaknesses.add(shuffled[i]);
    }

    return weaknesses;
  }
}
