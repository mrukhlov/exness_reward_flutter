class Venue {
  final String id;
  final String name;
  final String type;
  final String priceLevel;
  final String category;
  final String distance;
  final double rating;
  final int reviews;
  final String image;
  final String discount;
  final DiscountType discountType;
  final bool isOpen;
  final double lat;
  final double lng;
  final bool isPartner;
  final String locationName;
  final String? description;
  final String? address;
  final String? phone;
  final String? website;
  final String? comments;
  final OpenHours? openHours;

  Venue({
    required this.id,
    required this.name,
    required this.type,
    required this.priceLevel,
    required this.category,
    required this.distance,
    required this.rating,
    required this.reviews,
    required this.image,
    required this.discount,
    required this.discountType,
    required this.isOpen,
    required this.lat,
    required this.lng,
    required this.isPartner,
    required this.locationName,
    this.description,
    this.address,
    this.phone,
    this.website,
    this.comments,
    this.openHours,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      priceLevel:
          json['priceLevel'] as String? ??
          json['price_level'] as String? ??
          '\$',
      category: json['category'] as String? ?? 'Uncategorized',
      distance: json['distance'] as String? ?? 'N/A',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: json['reviews'] as int? ?? json['reviews_count'] as int? ?? 0,
      image: json['image'] as String? ?? json['image_url'] as String? ?? '',
      discount:
          json['discount'] as String? ?? json['discount_text'] as String? ?? '',
      discountType: _parseDiscountType(
        json['discountType'] ?? json['discount_type'],
      ),
      isOpen: json['isOpen'] as bool? ?? json['is_open'] as bool? ?? true,
      lat:
          (json['lat'] as num?)?.toDouble() ??
          (json['latitude'] as num).toDouble(),
      lng:
          (json['lng'] as num?)?.toDouble() ??
          (json['longitude'] as num).toDouble(),
      isPartner:
          json['isPartner'] as bool? ?? json['is_partner'] as bool? ?? false,
      locationName:
          json['locationName'] as String? ??
          json['location_name'] as String? ??
          '',
      description: json['description'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      comments: json['comments'] as String?,
      openHours: json['openHours'] != null || json['open_hours'] != null
          ? OpenHours.fromJson(json['openHours'] ?? json['open_hours'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'priceLevel': priceLevel,
      'category': category,
      'distance': distance,
      'rating': rating,
      'reviews': reviews,
      'image': image,
      'discount': discount,
      'discountType': discountType.toString().split('.').last,
      'isOpen': isOpen,
      'lat': lat,
      'lng': lng,
      'isPartner': isPartner,
      'locationName': locationName,
      'description': description,
      'address': address,
      'phone': phone,
      'website': website,
      'comments': comments,
      'openHours': openHours?.toJson(),
    };
  }

  static DiscountType _parseDiscountType(dynamic value) {
    if (value == null) return DiscountType.percentage;
    final str = value.toString().toLowerCase();
    switch (str) {
      case 'bogo':
        return DiscountType.bogo;
      case 'free_trial':
        return DiscountType.freeTrial;
      case 'cashback':
        return DiscountType.cashback;
      default:
        return DiscountType.percentage;
    }
  }
}

enum DiscountType { percentage, bogo, freeTrial, cashback }

class OpenHours {
  final String monFri;
  final String satSun;

  OpenHours({required this.monFri, required this.satSun});

  factory OpenHours.fromJson(Map<String, dynamic> json) {
    return OpenHours(
      monFri: json['mon_fri'] as String? ?? '',
      satSun: json['sat_sun'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'mon_fri': monFri, 'sat_sun': satSun};
  }
}
