import './models/widget_types.dart';

typedef WidgetBuilder = dynamic Function(Map<String, dynamic> json);

class WidgetRegistry {
  static final Map<String, WidgetBuilder> _registry = {};

  static void register(String type, WidgetBuilder builder) {
    _registry[type] = builder;
  }

  static WidgetData? parse(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == null) return null;

    if (_registry.containsKey(type)) {
      return _registry[type]!(json);
    }

    return WidgetData.fromJson(json);
  }

  static void initBuiltin() {
    register('order', (json) => OrderWidgetData.fromJson(json));
    register('logistics', (json) => LogisticsWidgetData.fromJson(json));
    register('product', (json) => ProductWidgetData.fromJson(json));
    register('product_list', (json) => ProductListWidgetData.fromJson(json));
    register('price_comparison', (json) => PriceComparisonWidgetData.fromJson(json));
  }
}

