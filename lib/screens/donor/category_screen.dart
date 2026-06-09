// ============================================================
// FILE: lib/screens/donor/category_screen.dart
//
// DESIGN: Matches uploaded screenshot exactly
//   - Back arrow + "Select Category" title
//   - "What are you donating today?" green heading
//   - 2-column grid of category cards (image + label)
//   - "Continue" button at bottom (activated when selected)
// ============================================================

import 'package:flutter/material.dart';

import 'donate_form_screen.dart';

class CategorySelectionScreen extends StatefulWidget {
  const CategorySelectionScreen({super.key});
  @override
  State<CategorySelectionScreen> createState() =>
      _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  // ── Which category is currently selected ────────────────────────────────
  String? _selectedCategory;

  // ── Brand green ──────────────────────────────────────────────────────────
  static const Color _green = Color(0xFF1B6B3A);

  // ── Categories list ──────────────────────────────────────────────────────
  // Each map has: name, icon (fallback), imageAsset (real image if available)
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Food',
      'icon': Icons.fastfood_rounded,
      'imageAsset': 'assets/images/cat_food.png',
      'color': const Color(0xFFFFF3E0),
    },
    {
      'name': 'Clothes',
      'icon': Icons.checkroom_rounded,
      'imageAsset': 'assets/images/cat_clothes.png',
      'color': const Color(0xFFE8F5E9),
    },
    {
      'name': 'Books',
      'icon': Icons.menu_book_rounded,
      'imageAsset': 'assets/images/cat_books.png',
      'color': const Color(0xFFE3F2FD),
    },
    {
      'name': 'Toys',
      'icon': Icons.toys_rounded,
      'imageAsset': 'assets/images/cat_toys.png',
      'color': const Color(0xFFFCE4EC),
    },
    {
      'name': 'Furniture',
      'icon': Icons.chair_rounded,
      'imageAsset': 'assets/images/cat_furniture.png',
      'color': const Color(0xFFF3E5F5),
    },
    {
      'name': 'Others',
      'icon': Icons.category_rounded,
      'imageAsset': 'assets/images/cat_others.png',
      'color': const Color(0xFFE0F7FA),
    },
  ];

  // ── Navigate to form when Continue is pressed ────────────────────────────
  void _onContinue() {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category first'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Pass the selected category name to the form screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DonationFormScreen(selectedCategory: _selectedCategory!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),

      // ── AppBar: back arrow + "Select Category" ────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Category',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      // ── Body ─────────────────────────────────────────────────────────────
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── "What are you donating today?" heading ──────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Text(
              'What are you\ndonating today?',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: _green,
                height: 1.3,
              ),
            ),
          ),

          // ── 2-Column grid of categories ─────────────────────────────────
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,       // 2 columns
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,  // Square cards
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final bool isSelected =
                    _selectedCategory == category['name'];

                return _CategoryCard(
                  name: category['name'],
                  icon: category['icon'],
                  imageAsset: category['imageAsset'],
                  bgColor: category['color'],
                  isSelected: isSelected,
                  selectedColor: _green,
                  onTap: () {
                    setState(() {
                      _selectedCategory = category['name'];
                    });
                  },
                );
              },
            ),
          ),

          // ── "Continue" button at bottom ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  // Gray when nothing selected, green when selected
                  backgroundColor: _selectedCategory != null
                      ? _green
                      : Colors.grey[300],
                  foregroundColor: _selectedCategory != null
                      ? Colors.white
                      : Colors.grey[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  elevation: _selectedCategory != null ? 4 : 0,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// WIDGET: Single Category Card
// ==============================================================================
class _CategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final String imageAsset;
  final Color bgColor;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.name,
    required this.icon,
    required this.imageAsset,
    required this.bgColor,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? selectedColor.withOpacity(0.2)
                  : Colors.black.withOpacity(0.06),
              blurRadius: isSelected ? 14 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Image (takes ~72% of card height) ─────────────────────
            Expanded(
              flex: 7,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14)),
                child: SizedBox(
                  width: double.infinity,
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.cover,
                    // If asset not found → show colored icon placeholder
                    errorBuilder: (_, __, ___) => Container(
                      color: bgColor,
                      child: Center(
                        child: Icon(
                          icon,
                          size: 52,
                          color: selectedColor.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Label ─────────────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? selectedColor : const Color(0xFF1B6B3A),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}