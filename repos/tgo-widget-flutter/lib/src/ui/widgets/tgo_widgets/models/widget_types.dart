// ignore_for_file: unnecessary_overload_parameter_type

/// Base class for all Widget data
abstract class WidgetData {
  final String type;

  const WidgetData({required this.type});

  factory WidgetData.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'unknown';
    switch (type) {
      case 'order':
        return OrderWidgetData.fromJson(json);
      case 'logistics':
        return LogisticsWidgetData.fromJson(json);
      case 'product':
        return ProductWidgetData.fromJson(json);
      case 'product_list':
        return ProductListWidgetData.fromJson(json);
      case 'price_comparison':
        return PriceComparisonWidgetData.fromJson(json);
      default:
        return UnknownWidgetData(type: type, rawData: json);
    }
  }

  Map<String, dynamic> toJson();
}

/// Unknown Widget data fallback
class UnknownWidgetData extends WidgetData {
  final Map<String, dynamic> rawData;

  const UnknownWidgetData({required super.type, required this.rawData});

  @override
  Map<String, dynamic> toJson() => rawData;
}

/// Widget action button
class WidgetAction {
  final String label;
  final String action;
  final String? style;
  final String? url;
  final Map<String, dynamic>? payload;

  const WidgetAction({
    required this.label,
    required this.action,
    this.style,
    this.url,
    this.payload,
  });

  factory WidgetAction.fromJson(Map<String, dynamic> json) {
    return WidgetAction(
      label: json['label'] as String? ?? '',
      action: json['action'] as String? ?? '',
      style: json['style'] as String?,
      url: json['url'] as String?,
      payload: json['payload'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'action': action,
        if (style != null) 'style': style,
        if (url != null) 'url': url,
        if (payload != null) 'payload': payload,
      };
}

// ============================================
// Order Widget Models
// ============================================

enum OrderStatus {
  pending,
  paid,
  processing,
  shipped,
  delivered,
  completed,
  cancelled,
  refunded;

  static OrderStatus fromString(String? value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

class OrderItem {
  final String name;
  final String? sku;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? imageUrl;
  final String? imageAlt;
  final Map<String, String>? attributes;

  const OrderItem({
    required this.name,
    this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.imageUrl,
    this.imageAlt,
    this.attributes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final image = json['image'] as Map<String, dynamic>?;
    final attributesJson = json['attributes'] as Map<String, dynamic>?;
    Map<String, String>? attributes;
    if (attributesJson != null) {
      attributes = attributesJson.map((k, v) => MapEntry(k, v.toString()));
    }

    return OrderItem(
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String?,
      quantity: (json['quantity'] as num? ?? 0).toInt(),
      unitPrice: (json['unit_price'] as num? ?? 0).toDouble(),
      totalPrice: (json['total_price'] as num? ?? 0).toDouble(),
      imageUrl: image?['url'] as String?,
      imageAlt: image?['alt'] as String?,
      attributes: attributes,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (sku != null) 'sku': sku,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': totalPrice,
        if (imageUrl != null || imageAlt != null)
          'image': {
            if (imageUrl != null) 'url': imageUrl,
            if (imageAlt != null) 'alt': imageAlt,
          },
        if (attributes != null) 'attributes': attributes,
      };
}

class OrderWidgetData extends WidgetData {
  final String orderId;
  final OrderStatus status;
  final String? statusText;
  final List<OrderItem> items;
  final double subtotal;
  final double? shippingFee;
  final double? discount;
  final double total;
  final String? currency;
  final String? shippingAddress;
  final String? receiverName;
  final String? receiverPhone;
  final String? trackingNumber;
  final String? carrier;
  final List<WidgetAction>? actions;

  const OrderWidgetData({
    required this.orderId,
    required this.status,
    this.statusText,
    required this.items,
    required this.subtotal,
    this.shippingFee,
    this.discount,
    required this.total,
    this.currency,
    this.shippingAddress,
    this.receiverName,
    this.receiverPhone,
    this.trackingNumber,
    this.carrier,
    this.actions,
  }) : super(type: 'order');

  factory OrderWidgetData.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>? ?? [])
        .where((e) => e != null && e is Map<String, dynamic>)
        .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final actionsList = (json['actions'] as List<dynamic>?)
        ?.where((e) => e != null && e is Map<String, dynamic>)
        .map((e) => WidgetAction.fromJson(e as Map<String, dynamic>))
        .toList();

    return OrderWidgetData(
      orderId: json['order_id'] as String? ?? '',
      status: OrderStatus.fromString(json['status'] as String?),
      statusText: json['status_text'] as String?,
      items: itemsList,
      subtotal: (json['subtotal'] as num? ?? 0).toDouble(),
      shippingFee: (json['shipping_fee'] as num?)?.toDouble(),
      discount: (json['discount'] as num?)?.toDouble(),
      total: (json['total'] as num? ?? 0).toDouble(),
      currency: json['currency'] as String?,
      shippingAddress: json['shipping_address'] as String?,
      receiverName: json['receiver_name'] as String?,
      receiverPhone: json['receiver_phone'] as String?,
      trackingNumber: json['tracking_number'] as String?,
      carrier: json['carrier'] as String?,
      actions: actionsList,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'order',
        'order_id': orderId,
        'status': status.name,
        if (statusText != null) 'status_text': statusText,
        'items': items.map((e) => e.toJson()).toList(),
        'subtotal': subtotal,
        if (shippingFee != null) 'shipping_fee': shippingFee,
        if (discount != null) 'discount': discount,
        'total': total,
        if (currency != null) 'currency': currency,
        if (shippingAddress != null) 'shipping_address': shippingAddress,
        if (receiverName != null) 'receiver_name': receiverName,
        if (receiverPhone != null) 'receiver_phone': receiverPhone,
        if (trackingNumber != null) 'tracking_number': trackingNumber,
        if (carrier != null) 'carrier': carrier,
        if (actions != null) 'actions': actions!.map((e) => e.toJson()).toList(),
      };
}

// ============================================
// Logistics Widget Models
// ============================================

enum LogisticsStatus {
  pending,
  picked_up,
  in_transit,
  out_for_delivery,
  delivered,
  exception,
  returned;

  static LogisticsStatus fromString(String? value) {
    return LogisticsStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LogisticsStatus.pending,
    );
  }
}

class LogisticsEvent {
  final String time;
  final LogisticsStatus? status;
  final String description;
  final String? location;
  final String? operator;
  final String? phone;

  const LogisticsEvent({
    required this.time,
    this.status,
    required this.description,
    this.location,
    this.operator,
    this.phone,
  });

  factory LogisticsEvent.fromJson(Map<String, dynamic> json) {
    return LogisticsEvent(
      time: json['time'] as String? ?? '',
      status: json['status'] != null
          ? LogisticsStatus.fromString(json['status'] as String?)
          : null,
      description: json['description'] as String? ?? '',
      location: json['location'] as String?,
      operator: json['operator'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time,
        if (status != null) 'status': status!.name,
        'description': description,
        if (location != null) 'location': location,
        if (operator != null) 'operator': operator,
        if (phone != null) 'phone': phone,
      };
}

class LogisticsWidgetData extends WidgetData {
  final String trackingNumber;
  final String carrier;
  final String? carrierLogo;
  final String? carrierPhone;
  final LogisticsStatus status;
  final String? statusText;
  final String? estimatedDelivery;
  final String? receiver;
  final String? receiverAddress;
  final String? receiverPhone;
  final String? courierName;
  final String? courierPhone;
  final List<LogisticsEvent> timeline;
  final String? orderId;
  final List<WidgetAction>? actions;

  const LogisticsWidgetData({
    required this.trackingNumber,
    required this.carrier,
    this.carrierLogo,
    this.carrierPhone,
    required this.status,
    this.statusText,
    this.estimatedDelivery,
    this.receiver,
    this.receiverAddress,
    this.receiverPhone,
    this.courierName,
    this.courierPhone,
    required this.timeline,
    this.orderId,
    this.actions,
  }) : super(type: 'logistics');

  factory LogisticsWidgetData.fromJson(Map<String, dynamic> json) {
    final timelineList = (json['timeline'] as List<dynamic>? ?? [])
        .where((e) => e != null && e is Map<String, dynamic>)
        .map((e) => LogisticsEvent.fromJson(e as Map<String, dynamic>))
        .toList();
    final actionsList = (json['actions'] as List<dynamic>?)
        ?.where((e) => e != null && e is Map<String, dynamic>)
        .map((e) => WidgetAction.fromJson(e as Map<String, dynamic>))
        .toList();

    return LogisticsWidgetData(
      trackingNumber: json['tracking_number'] as String? ?? '',
      carrier: json['carrier'] as String? ?? '',
      carrierLogo: json['carrier_logo'] as String?,
      carrierPhone: json['carrier_phone'] as String?,
      status: LogisticsStatus.fromString(json['status'] as String?),
      statusText: json['status_text'] as String?,
      estimatedDelivery: json['estimated_delivery'] as String?,
      receiver: json['receiver'] as String?,
      receiverAddress: json['receiver_address'] as String?,
      receiverPhone: json['receiver_phone'] as String?,
      courierName: json['courier_name'] as String?,
      courierPhone: json['courier_phone'] as String?,
      timeline: timelineList,
      orderId: json['order_id'] as String?,
      actions: actionsList,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'logistics',
        'tracking_number': trackingNumber,
        'carrier': carrier,
        if (carrierLogo != null) 'carrier_logo': carrierLogo,
        if (carrierPhone != null) 'carrier_phone': carrierPhone,
        'status': status.name,
        if (statusText != null) 'status_text': statusText,
        if (estimatedDelivery != null) 'estimated_delivery': estimatedDelivery,
        if (receiver != null) 'receiver': receiver,
        if (receiverAddress != null) 'receiver_address': receiverAddress,
        if (receiverPhone != null) 'receiver_phone': receiverPhone,
        if (courierName != null) 'courier_name': courierName,
        if (courierPhone != null) 'courier_phone': courierPhone,
        'timeline': timeline.map((e) => e.toJson()).toList(),
        if (orderId != null) 'order_id': orderId,
        if (actions != null) 'actions': actions!.map((e) => e.toJson()).toList(),
      };
}

// ============================================
// Product Widget Models
// ============================================

class ProductWidgetData extends WidgetData {
  final String productId;
  final String name;
  final String? description;
  final String? brand;
  final String? category;
  final String? imageUrl;
  final String? imageAlt;
  final double price;
  final double? originalPrice;
  final String? currency;
  final String? discountLabel;
  final bool inStock;
  final int? stockQuantity;
  final String? stockStatus;
  final List<MapEntry<String, String>>? specs;
  final double? rating;
  final int? reviewCount;
  final List<String>? tags;
  final List<WidgetAction>? actions;
  final String? url;

  const ProductWidgetData({
    required this.productId,
    required this.name,
    this.description,
    this.brand,
    this.category,
    this.imageUrl,
    this.imageAlt,
    required this.price,
    this.originalPrice,
    this.currency,
    this.discountLabel,
    this.inStock = true,
    this.stockQuantity,
    this.stockStatus,
    this.specs,
    this.rating,
    this.reviewCount,
    this.tags,
    this.actions,
    this.url,
  }) : super(type: 'product');

  factory ProductWidgetData.fromJson(Map<String, dynamic> json) {
    final thumbnail = json['thumbnail'] as Map<String, dynamic>?;
    final specsJson = json['specs'] as List<dynamic>?;
    final specs = specsJson
        ?.where((e) => e != null && e is Map<String, dynamic>)
        .map((e) => MapEntry(e['name'].toString(), e['value'].toString()))
        .toList();
    final actionsList = (json['actions'] as List<dynamic>?)
        ?.where((e) => e != null && e is Map<String, dynamic>)
        .map((e) => WidgetAction.fromJson(e as Map<String, dynamic>))
        .toList();
    final tagsList = (json['tags'] as List<dynamic>?)?.cast<String>();

    return ProductWidgetData(
      productId: json['product_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      brand: json['brand'] as String?,
      category: json['category'] as String?,
      imageUrl: thumbnail?['url'] as String?,
      imageAlt: thumbnail?['alt'] as String?,
      price: (json['price'] as num? ?? 0).toDouble(),
      originalPrice: (json['original_price'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      discountLabel: json['discount_label'] as String?,
      inStock: json['in_stock'] as bool? ?? true,
      stockQuantity: (json['stock_quantity'] as num?)?.toInt(),
      stockStatus: json['stock_status'] as String?,
      specs: specs,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['review_count'] as num?)?.toInt(),
      tags: tagsList,
      actions: actionsList,
      url: json['url'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'product',
        'product_id': productId,
        'name': name,
        if (description != null) 'description': description,
        if (brand != null) 'brand': brand,
        if (category != null) 'category': category,
        if (imageUrl != null || imageAlt != null)
          'thumbnail': {
            if (imageUrl != null) 'url': imageUrl,
            if (imageAlt != null) 'alt': imageAlt,
          },
        'price': price,
        if (originalPrice != null) 'original_price': originalPrice,
        if (currency != null) 'currency': currency,
        if (discountLabel != null) 'discount_label': discountLabel,
        'in_stock': inStock,
        if (stockQuantity != null) 'stock_quantity': stockQuantity,
        if (stockStatus != null) 'stock_status': stockStatus,
        if (specs != null)
          'specs': specs!.map((e) => {'name': e.key, 'value': e.value}).toList(),
        if (rating != null) 'rating': rating,
        if (reviewCount != null) 'review_count': reviewCount,
        if (tags != null) 'tags': tags,
        if (actions != null) 'actions': actions!.map((e) => e.toJson()).toList(),
        if (url != null) 'url': url,
      };
}

// ============================================
// Product List Widget Models
// ============================================

class ProductListItem {
  final String productId;
  final String name;
  final double price;
  final String? thumbnail;
  final double? rating;

  const ProductListItem({
    required this.productId,
    required this.name,
    required this.price,
    this.thumbnail,
    this.rating,
  });

  factory ProductListItem.fromJson(Map<String, dynamic> json) {
    return ProductListItem(
      productId: json['product_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num? ?? 0).toDouble(),
      thumbnail: json['thumbnail'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'name': name,
        'price': price,
        if (thumbnail != null) 'thumbnail': thumbnail,
        if (rating != null) 'rating': rating,
      };
}

class ProductListWidgetData extends WidgetData {
  final String? title;
  final String? subtitle;
  final List<ProductListItem> products;
  final int? totalCount;
  final int? page;
  final int? pageSize;
  final bool hasMore;
  final List<WidgetAction>? actions;

  const ProductListWidgetData({
    this.title,
    this.subtitle,
    required this.products,
    this.totalCount,
    this.page,
    this.pageSize,
    this.hasMore = false,
    this.actions,
  }) : super(type: 'product_list');

  factory ProductListWidgetData.fromJson(Map<String, dynamic> json) {
    final productsList = (json['products'] as List<dynamic>? ?? [])
        .map((e) => ProductListItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final actionsList = (json['actions'] as List<dynamic>?)
        ?.map((e) => WidgetAction.fromJson(e as Map<String, dynamic>))
        .toList();

    return ProductListWidgetData(
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      products: productsList,
      totalCount: (json['total_count'] as num?)?.toInt(),
      page: (json['page'] as num?)?.toInt(),
      pageSize: (json['page_size'] as num?)?.toInt(),
      hasMore: json['has_more'] as bool? ?? false,
      actions: actionsList,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'product_list',
        if (title != null) 'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        'products': products.map((e) => e.toJson()).toList(),
        if (totalCount != null) 'total_count': totalCount,
        if (page != null) 'page': page,
        if (pageSize != null) 'page_size': pageSize,
        'has_more': hasMore,
        if (actions != null) 'actions': actions!.map((e) => e.toJson()).toList(),
      };
}

// ============================================
// Price Comparison Widget Models
// ============================================

class PriceComparisonWidgetData extends WidgetData {
  final String? title;
  final List<String> columns;
  final List<Map<String, String>> items;
  final int? recommendedIndex;
  final String? recommendationReason;
  final List<WidgetAction>? actions;

  const PriceComparisonWidgetData({
    this.title,
    required this.columns,
    required this.items,
    this.recommendedIndex,
    this.recommendationReason,
    this.actions,
  }) : super(type: 'price_comparison');

  factory PriceComparisonWidgetData.fromJson(Map<String, dynamic> json) {
    final columnsList = (json['columns'] as List<dynamic>? ?? []).cast<String>();
    final itemsList = (json['items'] as List<dynamic>? ?? [])
        .map((e) => (e as Map<String, dynamic>).map((k, v) => MapEntry(k, v.toString())))
        .toList();
    final actionsList = (json['actions'] as List<dynamic>?)
        ?.map((e) => WidgetAction.fromJson(e as Map<String, dynamic>))
        .toList();

    return PriceComparisonWidgetData(
      title: json['title'] as String?,
      columns: columnsList,
      items: itemsList,
      recommendedIndex: (json['recommended_index'] as num?)?.toInt(),
      recommendationReason: json['recommendation_reason'] as String?,
      actions: actionsList,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'price_comparison',
        if (title != null) 'title': title,
        'columns': columns,
        'items': items,
        if (recommendedIndex != null) 'recommended_index': recommendedIndex,
        if (recommendationReason != null)
          'recommendation_reason': recommendationReason,
        if (actions != null) 'actions': actions!.map((e) => e.toJson()).toList(),
      };
}
