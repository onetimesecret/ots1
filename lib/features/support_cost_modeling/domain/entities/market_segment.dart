import 'package:equatable/equatable.dart';

/// Market segment with unique price elasticity characteristics
class MarketSegment extends Equatable {
  final String id;
  final String name;
  final String description;
  final PriceElasticityCurve elasticityCurve;
  final Map<String, double> demographics;
  final double marketSize;
  final double penetrationRate;
  final double growthRate;
  final String geography;
  final String industryVertical;

  const MarketSegment({
    required this.id,
    required this.name,
    required this.description,
    required this.elasticityCurve,
    required this.demographics,
    required this.marketSize,
    required this.penetrationRate,
    required this.growthRate,
    required this.geography,
    required this.industryVertical,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        elasticityCurve,
        demographics,
        marketSize,
        penetrationRate,
        growthRate,
        geography,
        industryVertical,
      ];
}

/// Price elasticity curve model
class PriceElasticityCurve extends Equatable {
  final double basePrice;
  final double elasticity;
  final double minPrice;
  final double maxPrice;
  final List<PricePoint> pricePoints;

  const PriceElasticityCurve({
    required this.basePrice,
    required this.elasticity,
    required this.minPrice,
    required this.maxPrice,
    required this.pricePoints,
  });

  /// Calculate demand at a given price point
  double calculateDemand(double price) {
    if (price < minPrice || price > maxPrice) return 0;
    final priceChange = (price - basePrice) / basePrice;
    final demandChange = -elasticity * priceChange;
    return 1 + demandChange;
  }

  /// Find optimal price for maximum revenue
  double findOptimalPrice(double baseDemand) {
    double maxRevenue = 0;
    double optimalPrice = basePrice;

    for (double price = minPrice; price <= maxPrice; price += 1.0) {
      final demand = calculateDemand(price) * baseDemand;
      final revenue = price * demand;
      if (revenue > maxRevenue) {
        maxRevenue = revenue;
        optimalPrice = price;
      }
    }

    return optimalPrice;
  }

  @override
  List<Object?> get props => [
        basePrice,
        elasticity,
        minPrice,
        maxPrice,
        pricePoints,
      ];
}

/// Price point in elasticity curve
class PricePoint extends Equatable {
  final double price;
  final double demand;
  final double revenue;

  const PricePoint({
    required this.price,
    required this.demand,
    required this.revenue,
  });

  @override
  List<Object?> get props => [price, demand, revenue];
}

/// Market condition types
enum MarketCondition {
  bull,
  base,
  bear;

  String get displayName {
    switch (this) {
      case MarketCondition.bull:
        return 'Bull Market (Optimistic)';
      case MarketCondition.base:
        return 'Base Market (Expected)';
      case MarketCondition.bear:
        return 'Bear Market (Pessimistic)';
    }
  }

  double get demandMultiplier {
    switch (this) {
      case MarketCondition.bull:
        return 1.3;
      case MarketCondition.base:
        return 1.0;
      case MarketCondition.bear:
        return 0.7;
    }
  }
}
