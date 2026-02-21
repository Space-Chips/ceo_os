class BlockList {
  final String id;
  final String name;
  final bool adultBlocking;
  final List<String> blockedPackageNames; // Android package names or iOS bundle IDs
  final List<String> blockedCategories; // e.g., 'social', 'games'
  final bool isActive;

  BlockList({
    required this.id,
    required this.name,
    this.adultBlocking = false,
    this.blockedPackageNames = const [],
    this.blockedCategories = const [],
    this.isActive = false,
  });

  factory BlockList.fromJson(Map<String, dynamic> json) {
    return BlockList(
      id: json['id'],
      name: json['name'],
      adultBlocking: json['adult_blocking'] ?? false,
      blockedPackageNames: List<String>.from(json['blocked_package_names'] ?? []),
      blockedCategories: List<String>.from(json['blocked_categories'] ?? []),
      isActive: json['is_active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'adult_blocking': adultBlocking,
      'blocked_package_names': blockedPackageNames,
      'blocked_categories': blockedCategories,
      'is_active': isActive,
    };
  }
}
