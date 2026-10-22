class Channel {
  final String id;
  final String name;
  final String url;
  final String? logo;
  final String? category;
  final String? country;
  final String? group;
  bool isFavorite;

  Channel({
    required this.id,
    required this.name,
    required this.url,
    this.logo,
    this.category,
    this.country,
    this.group,
    this.isFavorite = false,
  });

  bool get isGeoBlocked =>
      name.toLowerCase().contains('geo-blocked') ||
      name.toLowerCase().contains('geoblocked') ||
      name.toLowerCase().contains('geo blocked');

  bool get isOffline =>
      name.toLowerCase().contains('[offline]') ||
      name.toLowerCase().contains('(offline)');

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'logo': logo,
        'category': category,
        'country': country,
        'group': group,
        'isFavorite': isFavorite,
      };

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Unknown Channel',
        url: json['url'] as String? ?? '',
        logo: json['logo'] as String?,
        category: json['category'] as String?,
        country: json['country'] as String?,
        group: json['group'] as String?,
        isFavorite: json['isFavorite'] as bool? ?? false,
      );

  Channel copyWith({
    String? id,
    String? name,
    String? url,
    String? logo,
    String? category,
    String? country,
    String? group,
    bool? isFavorite,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      logo: logo ?? this.logo,
      category: category ?? this.category,
      country: country ?? this.country,
      group: group ?? this.group,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
