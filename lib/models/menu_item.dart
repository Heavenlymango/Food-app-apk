class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final int calories;
  final bool isHealthy;
  final bool isSpecial;
  final String image;
  final int preparationTime;
  final String shop;

  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.calories,
    required this.isHealthy,
    required this.isSpecial,
    required this.image,
    required this.preparationTime,
    required this.shop,
  });

  double get discountedPrice => isSpecial ? price * 0.7 : price;

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        price: (json['price'] as num).toDouble(),
        category: json['category'] as String,
        calories: json['calories'] as int,
        isHealthy: json['isHealthy'] as bool,
        isSpecial: json['isSpecial'] as bool,
        image: json['image'] as String,
        preparationTime: json['preparationTime'] as int,
        shop: json['shop'] as String,
      );
}
