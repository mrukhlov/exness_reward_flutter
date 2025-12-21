import 'package:flutter/material.dart';

/// Category icon mapping utility
/// Maps category names to Material Icons icon names
IconData getCategoryIcon(String categoryName) {
  if (categoryName.isEmpty) return Icons.category;

  // Handle "All" category specially
  if (categoryName.toLowerCase() == 'all') return Icons.grid_view;

  final normalized = categoryName.toLowerCase().trim();

  // Food & Dining categories
  if (normalized.contains('western') ||
      normalized.contains('european') ||
      normalized.contains('american')) {
    return Icons.restaurant;
  }
  if (normalized.contains('asian') ||
      normalized.contains('chinese') ||
      normalized.contains('japanese') ||
      normalized.contains('thai') ||
      normalized.contains('indian')) {
    return Icons.ramen_dining;
  }
  if (normalized.contains('italian') ||
      normalized.contains('pizza') ||
      normalized.contains('pasta')) {
    return Icons.local_pizza;
  }
  if (normalized.contains('mediterranean') ||
      normalized.contains('greek') ||
      normalized.contains('middle eastern')) {
    return Icons.restaurant_menu;
  }
  if (normalized.contains('seafood') || normalized.contains('fish')) {
    return Icons.set_meal;
  }
  if (normalized.contains('cafe') ||
      normalized.contains('coffee') ||
      normalized.contains('bakery')) {
    return Icons.local_cafe;
  }
  if (normalized.contains('fast food') || normalized.contains('burger')) {
    return Icons.fastfood;
  }
  if (normalized.contains('dining') ||
      normalized.contains('restaurant') ||
      normalized.contains('cuisine')) {
    return Icons.restaurant;
  }

  // Wellness & Fitness
  if (normalized.contains('yoga') || normalized.contains('pilates')) {
    return Icons.self_improvement;
  }
  if (normalized.contains('gym') ||
      normalized.contains('fitness') ||
      normalized.contains('training')) {
    return Icons.fitness_center;
  }
  if (normalized.contains('spa') ||
      normalized.contains('massage') ||
      normalized.contains('wellness') ||
      normalized.contains('beauty')) {
    return Icons.spa;
  }
  if (normalized.contains('salon') ||
      normalized.contains('hair') ||
      normalized.contains('barber')) {
    return Icons.content_cut;
  }

  // Retail & Shopping
  if (normalized.contains('retail') ||
      normalized.contains('shopping') ||
      normalized.contains('store')) {
    return Icons.shopping_bag;
  }
  if (normalized.contains('electronics') ||
      normalized.contains('gadgets') ||
      normalized.contains('tech')) {
    return Icons.devices;
  }
  if (normalized.contains('clothing') ||
      normalized.contains('fashion') ||
      normalized.contains('apparel')) {
    return Icons.checkroom;
  }
  if (normalized.contains('jewelry') || normalized.contains('watches')) {
    return Icons.diamond;
  }
  if (normalized.contains('books') || normalized.contains('bookstore')) {
    return Icons.menu_book;
  }
  if (normalized.contains('pharmacy') || normalized.contains('drugstore')) {
    return Icons.local_pharmacy;
  }

  // Travel & Services
  if (normalized.contains('travel') ||
      normalized.contains('hotel') ||
      normalized.contains('accommodation')) {
    return Icons.hotel;
  }
  if (normalized.contains('car') ||
      normalized.contains('automotive') ||
      normalized.contains('rental')) {
    return Icons.directions_car;
  }
  if (normalized.contains('flight') || normalized.contains('airline')) {
    return Icons.flight;
  }
  if (normalized.contains('bank') || normalized.contains('financial')) {
    return Icons.account_balance;
  }
  if (normalized.contains('insurance')) {
    return Icons.security;
  }

  // Entertainment
  if (normalized.contains('cinema') ||
      normalized.contains('movie') ||
      normalized.contains('theater')) {
    return Icons.movie;
  }
  if (normalized.contains('music') || normalized.contains('concert')) {
    return Icons.music_note;
  }
  if (normalized.contains('sports') || normalized.contains('stadium')) {
    return Icons.sports_soccer;
  }

  // Other
  if (normalized.contains('education') ||
      normalized.contains('school') ||
      normalized.contains('university')) {
    return Icons.school;
  }
  if (normalized.contains('health') ||
      normalized.contains('medical') ||
      normalized.contains('clinic')) {
    return Icons.local_hospital;
  }
  if (normalized.contains('pet') || normalized.contains('animal')) {
    return Icons.pets;
  }
  if (normalized.contains('home') ||
      normalized.contains('furniture') ||
      normalized.contains('decor')) {
    return Icons.home;
  }

  // Default fallback
  return Icons.category;
}

/// Get icon color for category (optional - can be used for theming)
Color getCategoryIconColor(String categoryName, {bool isActive = false}) {
  if (isActive) return Colors.black;

  final normalized = categoryName.toLowerCase().trim();

  // You can customize colors per category type here
  if (normalized.contains('dining') ||
      normalized.contains('restaurant') ||
      normalized.contains('food')) {
    return const Color(0xFFFF6B6B); // Red for food
  }
  if (normalized.contains('wellness') ||
      normalized.contains('spa') ||
      normalized.contains('fitness')) {
    return const Color(0xFF4ECDC4); // Teal for wellness
  }
  if (normalized.contains('retail') || normalized.contains('shopping')) {
    return const Color(0xFF95E1D3); // Mint for retail
  }
  if (normalized.contains('travel')) {
    return const Color(0xFFF38181); // Pink for travel
  }

  return const Color(0xFF9CA3AF); // Default gray
}
