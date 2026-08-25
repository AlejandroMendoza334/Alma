import 'package:flutter/material.dart';
import '../../../../core/services/injection_container.dart';
import '../providers/affirmation_provider.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late final AffirmationProvider _provider;

  // Categorías fijas de nuestro JSON
  final List<Map<String, String>> categories = const [
    {'key': 'calma', 'label': 'Calma'},
    {'key': 'manifestacion', 'label': 'Manifestación'},
    {'key': 'autoestima', 'label': 'Autoestima'},
  ];

  String _selectedCategory = 'calma';

  @override
  void initState() {
    super.initState();
    _provider = sl<AffirmationProvider>();
    _provider.loadByCategory(_selectedCategory);
  }

  void _onCategorySelected(String key) {
    setState(() {
      _selectedCategory = key;
    });
    _provider.loadByCategory(key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Estados y Categorías',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Chips selector de categoría
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = cat['key'] == _selectedCategory;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(cat['label']!),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                    ),
                    selectedColor: Colors.white,
                    backgroundColor: const Color(0xFF1E1E1E),
                    onSelected: (_) => _onCategorySelected(cat['key']!),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Lista de afirmaciones filtradas
          Expanded(
            child: ListenableBuilder(
              listenable: _provider,
              builder: (context, _) {
                if (_provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white70),
                  );
                }

                final list = _provider.categoryAffirmations;

                if (list.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay afirmaciones en esta categoría',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          '"${item.text}"',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}