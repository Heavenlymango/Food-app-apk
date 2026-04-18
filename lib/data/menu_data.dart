import '../models/menu_item.dart';
import '../models/shop.dart';

const List<Shop> shops = [
  Shop(id: 'A1', name: 'Shop A1', description: 'Mixed Menu - Rice, Noodles & Drinks', healthyCount: 6, totalItems: 12, campus: 'RUPP'),
  Shop(id: 'A2-A3', name: 'Shop A2-A3', description: 'Joined Shop - Full Menu', healthyCount: 7, totalItems: 15, campus: 'RUPP'),
  Shop(id: 'A4', name: 'Shop A4', description: 'Mixed Menu', healthyCount: 4, totalItems: 10, campus: 'RUPP'),
  Shop(id: 'A5', name: 'Shop A5', description: 'Noodles & Rice', healthyCount: 5, totalItems: 10, campus: 'RUPP'),
  Shop(id: 'A6', name: 'Shop A6', description: 'Healthy Food Only', healthyCount: 10, totalItems: 10, campus: 'RUPP'),
  Shop(id: 'A7', name: 'Shop A7', description: 'Mixed Menu', healthyCount: 5, totalItems: 10, campus: 'RUPP'),
  Shop(id: 'A8', name: 'Shop A8', description: 'Meals & Drinks', healthyCount: 5, totalItems: 10, campus: 'RUPP'),
  Shop(id: 'A9', name: 'Shop A9', description: 'Rice & Noodles', healthyCount: 5, totalItems: 10, campus: 'RUPP'),
  Shop(id: 'A10', name: 'Shop A10', description: 'Full Menu', healthyCount: 5, totalItems: 10, campus: 'RUPP'),
  Shop(id: 'B1', name: 'Shop B1', description: 'Khmer Food & Rice', healthyCount: 4, totalItems: 10, campus: 'RUPP'),
  Shop(id: 'B2', name: 'Shop B2', description: 'Noodle Soups', healthyCount: 5, totalItems: 10, campus: 'RUPP'),
  Shop(id: 'B3', name: 'Shop B3', description: 'BBQ & Grilled Food', healthyCount: 5, totalItems: 10, campus: 'RUPP'),
  Shop(id: 'B4', name: 'Shop B4', description: 'Fried Snacks', healthyCount: 0, totalItems: 10, campus: 'RUPP'),
  Shop(id: 'B5', name: 'Shop B5', description: 'Breakfast & Porridge', healthyCount: 6, totalItems: 10, campus: 'RUPP'),
  Shop(id: 'B6', name: 'Shop B6', description: 'Healthy Bowls & Smoothies', healthyCount: 10, totalItems: 10, campus: 'RUPP'),
  Shop(id: 'B7', name: 'Shop B7', description: 'Fried Chicken & Cheese', healthyCount: 0, totalItems: 10, campus: 'RUPP'),
  Shop(id: 'B8', name: 'Shop B8', description: 'Smoothies & Drinks', healthyCount: 4, totalItems: 10, campus: 'RUPP'),
  Shop(id: 'B9', name: 'Shop B9', description: 'Coffee Shop Only', healthyCount: 3, totalItems: 10, campus: 'RUPP'),
  Shop(id: 'IFL-NC', name: 'Nature Café', description: 'Premium Organic & Healthy Food', healthyCount: 10, totalItems: 20, campus: 'IFL'),
  Shop(id: 'IFL-DMC', name: 'DMC Alumni Café', description: 'Affordable Baked Goods & Coffee', healthyCount: 11, totalItems: 20, campus: 'IFL'),
  Shop(id: 'IFL-NISET', name: 'Niset Café (IFL)', description: 'Rice Plates & Local Favorites', healthyCount: 7, totalItems: 22, campus: 'IFL'),
  Shop(id: 'IFL-URBAN', name: 'Urban Canteen', description: 'International Fine Dining', healthyCount: 9, totalItems: 20, campus: 'IFL'),
  Shop(id: 'IFL-NORM1', name: 'Normal Canteen 1', description: 'Budget Rice & Noodles', healthyCount: 11, totalItems: 20, campus: 'IFL'),
  Shop(id: 'IFL-NORM2', name: 'Normal Canteen 2', description: 'Noodles & Fried Rice', healthyCount: 8, totalItems: 20, campus: 'IFL'),
  Shop(id: 'IFL-NORM3', name: 'Normal Canteen 3', description: 'Vegetarian & Mixed Menu', healthyCount: 13, totalItems: 20, campus: 'IFL'),
];

const List<MenuItem> menuItems = [
  // ── Shop A1 ──────────────────────────────────────────────────────────────
  MenuItem(id: 'A1-1', name: 'Chicken Fried Rice', description: 'Wok-fried rice with chicken and vegetables', price: 2.30, category: 'Rice', calories: 520, isHealthy: false, isSpecial: false, image: 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400', preparationTime: 8, shop: 'A1'),
  MenuItem(id: 'A1-2', name: 'Vegetable Stir-Fry', description: 'Fresh vegetables stir-fried with garlic', price: 1.90, category: 'Vegetables', calories: 180, isHealthy: true, isSpecial: true, image: 'https://images.unsplash.com/photo-1758979690131-11e2aa0b142b?w=400', preparationTime: 6, shop: 'A1'),
  MenuItem(id: 'A1-3', name: 'Fresh Spring Rolls', description: 'Rice paper rolls with vegetables and herbs', price: 1.20, category: 'Snacks', calories: 150, isHealthy: true, isSpecial: true, image: 'https://images.unsplash.com/photo-1695712641569-05eee7b37b6d?w=400', preparationTime: 5, shop: 'A1'),
  MenuItem(id: 'A1-4', name: 'Iced Milk Tea', description: 'Sweet milk tea with ice', price: 1.70, category: 'Drinks', calories: 180, isHealthy: false, isSpecial: false, image: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400', preparationTime: 3, shop: 'A1'),
  MenuItem(id: 'A1-5', name: 'Fruit Salad', description: 'Fresh mixed seasonal fruits', price: 2.00, category: 'Snacks', calories: 120, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1564093497595-593b96d80180?w=400', preparationTime: 5, shop: 'A1'),
  MenuItem(id: 'A1-7', name: 'Khmer Noodle Soup', description: 'Traditional soup with rice noodles', price: 2.20, category: 'Soup', calories: 320, isHealthy: true, isSpecial: true, image: 'https://images.unsplash.com/photo-1701480253822-1842236c9a97?w=400', preparationTime: 10, shop: 'A1'),
  MenuItem(id: 'A1-10', name: 'Iced Coffee', description: 'Strong iced coffee with condensed milk', price: 1.30, category: 'Drinks', calories: 150, isHealthy: false, isSpecial: false, image: 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400', preparationTime: 3, shop: 'A1'),
  MenuItem(id: 'A1-12', name: 'French Fries', description: 'Crispy golden french fries', price: 1.30, category: 'Snacks', calories: 360, isHealthy: false, isSpecial: false, image: 'https://images.unsplash.com/photo-1576107232684-1279f390859f?w=400', preparationTime: 6, shop: 'A1'),

  // ── Shop A2-A3 ────────────────────────────────────────────────────────────
  MenuItem(id: 'A2-1', name: 'Stir-Fried Noodles', description: 'Wok-tossed noodles with vegetables', price: 2.10, category: 'Noodles', calories: 450, isHealthy: false, isSpecial: false, image: 'https://images.unsplash.com/photo-1758979690131-11e2aa0b142b?w=400', preparationTime: 8, shop: 'A2-A3'),
  MenuItem(id: 'A2-2', name: 'Grilled Chicken Rice', description: 'Grilled chicken with steamed rice', price: 2.60, category: 'Rice', calories: 420, isHealthy: true, isSpecial: true, image: 'https://images.unsplash.com/photo-1581184953963-d15972933db1?w=400', preparationTime: 12, shop: 'A2-A3'),
  MenuItem(id: 'A2-4', name: 'Grilled Pork Rice', description: 'Marinated pork with broken rice', price: 2.50, category: 'Rice', calories: 480, isHealthy: true, isSpecial: true, image: 'https://images.unsplash.com/photo-1759670332534-21a316c53462?w=400', preparationTime: 12, shop: 'A2-A3'),
  MenuItem(id: 'A2-5', name: 'Chicken Salad Bowl', description: 'Fresh greens with grilled chicken', price: 2.50, category: 'Salads', calories: 280, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1649531794884-b8bb1de72e68?w=400', preparationTime: 8, shop: 'A2-A3'),
  MenuItem(id: 'A2-6', name: 'Beef Pho', description: 'Rich beef broth with noodles', price: 2.70, category: 'Noodles', calories: 420, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1631709497146-a239ef373cf1?w=400', preparationTime: 15, shop: 'A2-A3'),
  MenuItem(id: 'A2-7', name: 'Seafood Fried Rice', description: 'Mixed seafood with wok-fried rice', price: 2.90, category: 'Rice', calories: 560, isHealthy: false, isSpecial: true, image: 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400', preparationTime: 10, shop: 'A2-A3'),
  MenuItem(id: 'A2-8', name: 'Papaya Salad', description: 'Spicy green papaya salad', price: 1.50, category: 'Salads', calories: 120, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400', preparationTime: 6, shop: 'A2-A3'),
  MenuItem(id: 'A2-11', name: 'Tom Yum Soup', description: 'Spicy and sour Thai soup', price: 2.40, category: 'Soup', calories: 180, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=400', preparationTime: 12, shop: 'A2-A3'),
  MenuItem(id: 'A2-14', name: 'Shrimp Pad Thai', description: 'Classic Thai stir-fried noodles', price: 2.80, category: 'Noodles', calories: 520, isHealthy: false, isSpecial: false, image: 'https://images.unsplash.com/photo-1559314809-0d155014e29e?w=400', preparationTime: 10, shop: 'A2-A3'),

  // ── Shop A4 ───────────────────────────────────────────────────────────────
  MenuItem(id: 'A4-1', name: 'Grilled Pork Rice', description: 'Popular morning dish', price: 2.20, category: 'Rice', calories: 480, isHealthy: false, isSpecial: false, image: 'https://images.unsplash.com/photo-1759670332534-21a316c53462?w=400', preparationTime: 12, shop: 'A4'),
  MenuItem(id: 'A4-2', name: 'Beef Lok Lak', description: 'Khmer-style stir-fried beef with rice', price: 2.80, category: 'Rice', calories: 550, isHealthy: false, isSpecial: true, image: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400', preparationTime: 15, shop: 'A4'),
  MenuItem(id: 'A4-3', name: 'Fish Soup', description: 'Clear fish broth soup', price: 2.30, category: 'Soup', calories: 280, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1476718406336-bb5a9690ee2a?w=400', preparationTime: 10, shop: 'A4'),
  MenuItem(id: 'A4-5', name: 'Stir-Fried Vegetables', description: 'Low oil stir-fried vegetables', price: 1.80, category: 'Vegetables', calories: 180, isHealthy: true, isSpecial: true, image: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400', preparationTime: 6, shop: 'A4'),
  MenuItem(id: 'A4-6', name: 'Chicken Noodle Soup', description: 'Light chicken broth noodles', price: 2.10, category: 'Noodles', calories: 340, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=400', preparationTime: 10, shop: 'A4'),
  MenuItem(id: 'A4-9', name: 'Spring Rolls', description: 'Crispy vegetarian spring rolls', price: 1.50, category: 'Snacks', calories: 150, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1695712641569-05eee7b37b6d?w=400', preparationTime: 5, shop: 'A4'),

  // ── Shop A5 ───────────────────────────────────────────────────────────────
  MenuItem(id: 'A5-1', name: 'Beef Noodle Soup', description: 'Classic style beef pho', price: 2.50, category: 'Noodles', calories: 420, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1631709497146-a239ef373cf1?w=400', preparationTime: 12, shop: 'A5'),
  MenuItem(id: 'A5-2', name: 'BBQ Pork Rice', description: 'Sweet BBQ marinade pork', price: 2.00, category: 'Rice', calories: 500, isHealthy: false, isSpecial: true, image: 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=400', preparationTime: 12, shop: 'A5'),
  MenuItem(id: 'A5-3', name: 'Chicken Curry', description: 'Rice included', price: 2.40, category: 'Rice', calories: 580, isHealthy: false, isSpecial: false, image: 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=400', preparationTime: 15, shop: 'A5'),
  MenuItem(id: 'A5-4', name: 'Vegetable Stir Fry', description: 'Light salt, fresh vegetables', price: 1.70, category: 'Vegetables', calories: 190, isHealthy: true, isSpecial: true, image: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400', preparationTime: 6, shop: 'A5'),
  MenuItem(id: 'A5-5', name: 'Shrimp Fried Rice', description: 'Standard portion shrimp fried rice', price: 2.20, category: 'Rice', calories: 540, isHealthy: false, isSpecial: false, image: 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400', preparationTime: 8, shop: 'A5'),

  // ── Shop A6 (Healthy Only) ────────────────────────────────────────────────
  MenuItem(id: 'A6-1', name: 'Quinoa Salad Bowl', description: 'Quinoa with roasted vegetables', price: 3.50, category: 'Salads', calories: 310, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400', preparationTime: 8, shop: 'A6'),
  MenuItem(id: 'A6-2', name: 'Green Detox Smoothie', description: 'Spinach, cucumber, lemon blend', price: 2.50, category: 'Drinks', calories: 120, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1638176067239-fc40e1cadc68?w=400', preparationTime: 5, shop: 'A6'),
  MenuItem(id: 'A6-3', name: 'Steamed Chicken Breast', description: 'With mixed vegetables', price: 3.20, category: 'Meal', calories: 280, isHealthy: true, isSpecial: true, image: 'https://images.unsplash.com/photo-1580554996521-9cb34cc5b398?w=400', preparationTime: 12, shop: 'A6'),
  MenuItem(id: 'A6-4', name: 'Avocado Toast', description: 'Multigrain bread with avocado', price: 2.80, category: 'Breakfast', calories: 320, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1541519227354-08fa5d50c820?w=400', preparationTime: 7, shop: 'A6'),
  MenuItem(id: 'A6-5', name: 'Acai Berry Bowl', description: 'Acai blend with granola and fruits', price: 3.80, category: 'Breakfast', calories: 340, isHealthy: true, isSpecial: true, image: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400', preparationTime: 8, shop: 'A6'),

  // ── Shop B1 (Khmer Food) ──────────────────────────────────────────────────
  MenuItem(id: 'B1-1', name: 'Amok Fish', description: 'Traditional Khmer fish curry in coconut', price: 3.00, category: 'Khmer', calories: 380, isHealthy: true, isSpecial: true, image: 'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=400', preparationTime: 15, shop: 'B1'),
  MenuItem(id: 'B1-2', name: 'Lok Lak Beef', description: 'Stir-fried beef with lime-pepper sauce', price: 3.20, category: 'Khmer', calories: 520, isHealthy: false, isSpecial: true, image: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400', preparationTime: 15, shop: 'B1'),
  MenuItem(id: 'B1-3', name: 'Bai Sach Chrouk', description: 'Grilled pork over rice - Khmer breakfast', price: 2.20, category: 'Rice', calories: 480, isHealthy: false, isSpecial: false, image: 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=400', preparationTime: 10, shop: 'B1'),
  MenuItem(id: 'B1-4', name: 'Num Banh Chok', description: 'Khmer rice noodles with green curry', price: 2.00, category: 'Noodles', calories: 320, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=400', preparationTime: 10, shop: 'B1'),
  MenuItem(id: 'B1-5', name: 'Samlor Korko', description: 'Khmer stirring soup with vegetables', price: 2.50, category: 'Soup', calories: 240, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1476718406336-bb5a9690ee2a?w=400', preparationTime: 12, shop: 'B1'),

  // ── Shop B2 (Noodle Soups) ────────────────────────────────────────────────
  MenuItem(id: 'B2-1', name: 'Pho Bo', description: 'Vietnamese beef pho with herbs', price: 2.80, category: 'Noodles', calories: 420, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1631709497146-a239ef373cf1?w=400', preparationTime: 15, shop: 'B2'),
  MenuItem(id: 'B2-2', name: 'Wonton Noodle Soup', description: 'Egg noodles with pork wontons', price: 2.50, category: 'Noodles', calories: 380, isHealthy: false, isSpecial: true, image: 'https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=400', preparationTime: 12, shop: 'B2'),
  MenuItem(id: 'B2-3', name: 'Ramen', description: 'Japanese-style ramen with egg', price: 3.00, category: 'Noodles', calories: 520, isHealthy: false, isSpecial: false, image: 'https://images.unsplash.com/photo-1557872943-16a5ac26437e?w=400', preparationTime: 12, shop: 'B2'),
  MenuItem(id: 'B2-4', name: 'Laksa', description: 'Spicy coconut curry noodle soup', price: 2.90, category: 'Noodles', calories: 540, isHealthy: false, isSpecial: true, image: 'https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=400', preparationTime: 12, shop: 'B2'),

  // ── Shop B3 (BBQ & Grilled) ───────────────────────────────────────────────
  MenuItem(id: 'B3-1', name: 'BBQ Chicken Skewer', description: 'Marinated chicken skewers grilled', price: 2.50, category: 'BBQ', calories: 320, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=400', preparationTime: 15, shop: 'B3'),
  MenuItem(id: 'B3-2', name: 'Grilled Pork Ribs', description: 'Slow-grilled pork ribs', price: 4.50, category: 'BBQ', calories: 620, isHealthy: false, isSpecial: true, image: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400', preparationTime: 20, shop: 'B3'),
  MenuItem(id: 'B3-3', name: 'Grilled Corn', description: 'Sweet corn with butter', price: 1.00, category: 'Snacks', calories: 160, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1551754655-cd27e38d2076?w=400', preparationTime: 8, shop: 'B3'),
  MenuItem(id: 'B3-4', name: 'Grilled Seafood Platter', description: 'Shrimp, squid, and fish grilled', price: 5.00, category: 'BBQ', calories: 480, isHealthy: true, isSpecial: true, image: 'https://images.unsplash.com/photo-1615361200141-f45040f367be?w=400', preparationTime: 20, shop: 'B3'),

  // ── Shop B5 (Breakfast) ───────────────────────────────────────────────────
  MenuItem(id: 'B5-1', name: 'Rice Porridge', description: 'Cambodian congee with chicken', price: 1.80, category: 'Breakfast', calories: 280, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=400', preparationTime: 8, shop: 'B5'),
  MenuItem(id: 'B5-2', name: 'French Baguette', description: 'Cambodian baguette with pate', price: 1.50, category: 'Breakfast', calories: 340, isHealthy: false, isSpecial: false, image: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400', preparationTime: 5, shop: 'B5'),
  MenuItem(id: 'B5-3', name: 'Fried Egg Rice', description: 'Steamed rice with fried egg', price: 1.20, category: 'Breakfast', calories: 380, isHealthy: false, isSpecial: true, image: 'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=400', preparationTime: 6, shop: 'B5'),
  MenuItem(id: 'B5-4', name: 'Banana Pancakes', description: 'Fluffy pancakes with banana', price: 2.00, category: 'Breakfast', calories: 420, isHealthy: false, isSpecial: false, image: 'https://images.unsplash.com/photo-1528207776546-365bb710ee93?w=400', preparationTime: 10, shop: 'B5'),

  // ── Shop B6 (Healthy Bowls) ───────────────────────────────────────────────
  MenuItem(id: 'B6-1', name: 'Açaí Bowl', description: 'Açaí with granola, banana, berries', price: 3.50, category: 'Breakfast', calories: 320, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1511690656952-34342bb7c2f2?w=400', preparationTime: 8, shop: 'B6'),
  MenuItem(id: 'B6-2', name: 'Green Power Smoothie', description: 'Spinach, apple, ginger, lemon', price: 2.80, category: 'Drinks', calories: 140, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1638176067239-fc40e1cadc68?w=400', preparationTime: 5, shop: 'B6'),
  MenuItem(id: 'B6-3', name: 'Buddha Bowl', description: 'Grain bowl with roasted veggies and tahini', price: 4.00, category: 'Meal', calories: 420, isHealthy: true, isSpecial: true, image: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400', preparationTime: 10, shop: 'B6'),
  MenuItem(id: 'B6-4', name: 'Mango Smoothie Bowl', description: 'Mango, coconut milk, chia seeds', price: 3.20, category: 'Breakfast', calories: 280, isHealthy: true, isSpecial: true, image: 'https://images.unsplash.com/photo-1511690656952-34342bb7c2f2?w=400', preparationTime: 8, shop: 'B6'),

  // ── Shop B7 (Fried Chicken) ───────────────────────────────────────────────
  MenuItem(id: 'B7-1', name: 'Crispy Fried Chicken', description: 'Golden fried chicken pieces', price: 2.50, category: 'Fried', calories: 580, isHealthy: false, isSpecial: false, image: 'https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?w=400', preparationTime: 15, shop: 'B7'),
  MenuItem(id: 'B7-2', name: 'Cheese Burger', description: 'Beef patty with cheese and lettuce', price: 3.00, category: 'Meal', calories: 650, isHealthy: false, isSpecial: true, image: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400', preparationTime: 12, shop: 'B7'),
  MenuItem(id: 'B7-3', name: 'Chicken Wings', description: 'Spicy fried chicken wings', price: 2.00, category: 'Fried', calories: 480, isHealthy: false, isSpecial: false, image: 'https://images.unsplash.com/photo-1527477396000-e27163b481c2?w=400', preparationTime: 12, shop: 'B7'),
  MenuItem(id: 'B7-4', name: 'Cheese Fries', description: 'Fries with melted cheese sauce', price: 2.20, category: 'Snacks', calories: 520, isHealthy: false, isSpecial: false, image: 'https://images.unsplash.com/photo-1576107232684-1279f390859f?w=400', preparationTime: 8, shop: 'B7'),

  // ── Shop B9 (Coffee) ──────────────────────────────────────────────────────
  MenuItem(id: 'B9-1', name: 'Cambodian Iced Coffee', description: 'Strong coffee with condensed milk', price: 1.50, category: 'Coffee', calories: 180, isHealthy: false, isSpecial: false, image: 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400', preparationTime: 3, shop: 'B9'),
  MenuItem(id: 'B9-2', name: 'Cappuccino', description: 'Espresso with steamed milk foam', price: 2.50, category: 'Coffee', calories: 120, isHealthy: false, isSpecial: false, image: 'https://images.unsplash.com/photo-1529892485617-25f63cd7b1e9?w=400', preparationTime: 4, shop: 'B9'),
  MenuItem(id: 'B9-3', name: 'Matcha Latte', description: 'Japanese matcha with oat milk', price: 2.80, category: 'Coffee', calories: 160, isHealthy: true, isSpecial: true, image: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400', preparationTime: 4, shop: 'B9'),
  MenuItem(id: 'B9-4', name: 'Affogato', description: 'Vanilla ice cream with espresso', price: 3.00, category: 'Coffee', calories: 220, isHealthy: false, isSpecial: true, image: 'https://images.unsplash.com/photo-1529892485617-25f63cd7b1e9?w=400', preparationTime: 3, shop: 'B9'),

  // ── IFL - Nature Café ─────────────────────────────────────────────────────
  MenuItem(id: 'IFL-NC-1', name: 'Organic Salad Bowl', description: 'Organic greens with house dressing', price: 4.50, category: 'Salads', calories: 220, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400', preparationTime: 8, shop: 'IFL-NC'),
  MenuItem(id: 'IFL-NC-2', name: 'Cold Pressed Juice', description: 'Fresh pressed fruit and vegetable juice', price: 3.50, category: 'Drinks', calories: 130, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1638176067239-fc40e1cadc68?w=400', preparationTime: 5, shop: 'IFL-NC'),
  MenuItem(id: 'IFL-NC-3', name: 'Tofu Bowl', description: 'Pan-seared tofu with brown rice', price: 4.00, category: 'Meal', calories: 380, isHealthy: true, isSpecial: true, image: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400', preparationTime: 10, shop: 'IFL-NC'),
  MenuItem(id: 'IFL-NC-4', name: 'Granola Bowl', description: 'House-made granola with berries', price: 3.80, category: 'Breakfast', calories: 340, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1511690656952-34342bb7c2f2?w=400', preparationTime: 5, shop: 'IFL-NC'),

  // ── IFL - DMC Alumni Café ─────────────────────────────────────────────────
  MenuItem(id: 'IFL-DMC-1', name: 'Croissant', description: 'Buttery flaky croissant', price: 2.50, category: 'Breakfast', calories: 280, isHealthy: false, isSpecial: false, image: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400', preparationTime: 3, shop: 'IFL-DMC'),
  MenuItem(id: 'IFL-DMC-2', name: 'Americano', description: 'Double shot espresso', price: 2.00, category: 'Coffee', calories: 10, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400', preparationTime: 3, shop: 'IFL-DMC'),
  MenuItem(id: 'IFL-DMC-3', name: 'Egg & Ham Sandwich', description: 'On toasted sourdough', price: 3.50, category: 'Breakfast', calories: 420, isHealthy: false, isSpecial: true, image: 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400', preparationTime: 7, shop: 'IFL-DMC'),
  MenuItem(id: 'IFL-DMC-4', name: 'Banana Bread', description: 'Moist homemade banana bread', price: 2.20, category: 'Snacks', calories: 310, isHealthy: false, isSpecial: false, image: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400', preparationTime: 3, shop: 'IFL-DMC'),

  // ── IFL - Niset Café ──────────────────────────────────────────────────────
  MenuItem(id: 'IFL-NISET-1', name: 'Steamed White Rice + 3 Dishes', description: 'Rice with 3 selected side dishes', price: 2.50, category: 'Rice', calories: 520, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400', preparationTime: 8, shop: 'IFL-NISET'),
  MenuItem(id: 'IFL-NISET-2', name: 'Pork Lok Lak Rice', description: 'Khmer-style pork with fried egg', price: 2.80, category: 'Rice', calories: 560, isHealthy: false, isSpecial: true, image: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400', preparationTime: 12, shop: 'IFL-NISET'),
  MenuItem(id: 'IFL-NISET-3', name: 'Chicken Soup Noodles', description: 'Clear broth with rice noodles', price: 2.30, category: 'Noodles', calories: 320, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=400', preparationTime: 10, shop: 'IFL-NISET'),

  // ── IFL - Urban Canteen ───────────────────────────────────────────────────
  MenuItem(id: 'IFL-URBAN-1', name: 'Pasta Carbonara', description: 'Creamy Italian pasta', price: 5.50, category: 'Pasta', calories: 620, isHealthy: false, isSpecial: false, image: 'https://images.unsplash.com/photo-1545608284-b6a2951b86f9?w=400', preparationTime: 15, shop: 'IFL-URBAN'),
  MenuItem(id: 'IFL-URBAN-2', name: 'Caesar Salad', description: 'Romaine, croutons, parmesan', price: 4.50, category: 'Salads', calories: 320, isHealthy: false, isSpecial: false, image: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400', preparationTime: 8, shop: 'IFL-URBAN'),
  MenuItem(id: 'IFL-URBAN-3', name: 'Club Sandwich', description: 'Triple-decker with chicken and bacon', price: 4.80, category: 'Meal', calories: 580, isHealthy: false, isSpecial: true, image: 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400', preparationTime: 10, shop: 'IFL-URBAN'),
  MenuItem(id: 'IFL-URBAN-4', name: 'Grilled Salmon', description: 'Atlantic salmon with salad', price: 7.50, category: 'Meal', calories: 420, isHealthy: true, isSpecial: true, image: 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400', preparationTime: 18, shop: 'IFL-URBAN'),

  // ── IFL - Normal Canteen 1 ────────────────────────────────────────────────
  MenuItem(id: 'IFL-NORM1-1', name: 'Budget Fried Rice', description: 'Simple fried rice with egg', price: 1.50, category: 'Rice', calories: 480, isHealthy: false, isSpecial: false, image: 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400', preparationTime: 8, shop: 'IFL-NORM1'),
  MenuItem(id: 'IFL-NORM1-2', name: 'Noodle Soup', description: 'Simple noodle soup with pork', price: 1.50, category: 'Noodles', calories: 360, isHealthy: false, isSpecial: false, image: 'https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=400', preparationTime: 8, shop: 'IFL-NORM1'),
  MenuItem(id: 'IFL-NORM1-3', name: 'Rice + Stir-fry Veggies', description: 'Budget meal with rice', price: 1.20, category: 'Rice', calories: 340, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400', preparationTime: 6, shop: 'IFL-NORM1'),
  MenuItem(id: 'IFL-NORM1-4', name: 'Sugar Cane Juice', description: 'Fresh pressed sugarcane', price: 0.80, category: 'Drinks', calories: 120, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1638176067239-fc40e1cadc68?w=400', preparationTime: 3, shop: 'IFL-NORM1'),

  // ── IFL - Normal Canteen 2 ────────────────────────────────────────────────
  MenuItem(id: 'IFL-NORM2-1', name: 'Wok Noodles', description: 'Stir-fried egg noodles', price: 1.80, category: 'Noodles', calories: 420, isHealthy: false, isSpecial: false, image: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400', preparationTime: 8, shop: 'IFL-NORM2'),
  MenuItem(id: 'IFL-NORM2-2', name: 'Egg Fried Rice', description: 'Classic egg fried rice', price: 1.80, category: 'Rice', calories: 490, isHealthy: false, isSpecial: true, image: 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400', preparationTime: 8, shop: 'IFL-NORM2'),
  MenuItem(id: 'IFL-NORM2-3', name: 'Soup of the Day', description: 'Daily rotating soup', price: 1.50, category: 'Soup', calories: 200, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1476718406336-bb5a9690ee2a?w=400', preparationTime: 6, shop: 'IFL-NORM2'),

  // ── IFL - Normal Canteen 3 (Vegetarian) ──────────────────────────────────
  MenuItem(id: 'IFL-NORM3-1', name: 'Vegetable Curry', description: 'Mild vegetable curry with rice', price: 2.20, category: 'Vegetables', calories: 340, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=400', preparationTime: 10, shop: 'IFL-NORM3'),
  MenuItem(id: 'IFL-NORM3-2', name: 'Mixed Veg Stir Fry', description: 'Seasonal vegetables wok fried', price: 1.80, category: 'Vegetables', calories: 180, isHealthy: true, isSpecial: true, image: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400', preparationTime: 7, shop: 'IFL-NORM3'),
  MenuItem(id: 'IFL-NORM3-3', name: 'Tofu Soup', description: 'Light tofu and mushroom soup', price: 1.90, category: 'Soup', calories: 150, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1476718406336-bb5a9690ee2a?w=400', preparationTime: 8, shop: 'IFL-NORM3'),
  MenuItem(id: 'IFL-NORM3-4', name: 'Brown Rice Bowl', description: 'Brown rice with pickled vegetables', price: 2.00, category: 'Rice', calories: 320, isHealthy: true, isSpecial: false, image: 'https://images.unsplash.com/photo-1516684732162-798a0062be99?w=400', preparationTime: 6, shop: 'IFL-NORM3'),
];
