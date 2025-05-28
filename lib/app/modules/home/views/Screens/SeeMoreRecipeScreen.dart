import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:smart_recipe_generator_flutter/app/models/recipe.dart';
import 'package:smart_recipe_generator_flutter/app/modules/recipe_detail/views/recipe_detail_view.dart';

class SeeMoreRecipesScreen extends StatefulWidget {
  final String title;
  final List<Recipe> recipes;

  const SeeMoreRecipesScreen({required this.title, required this.recipes});

  @override
  State<SeeMoreRecipesScreen> createState() => _SeeMoreRecipesScreenState();
}

class _SeeMoreRecipesScreenState extends State<SeeMoreRecipesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Recipe> _filteredRecipes = [];
  int offset = 0;
  final int limit = 10;
  bool isLoading = false;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _filteredRecipes.addAll(widget.recipes);
    offset = widget.recipes.length;
    _scrollController.addListener(_onScroll);
    if (widget.recipes.length < limit) hasMore = false;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchMoreRecipes();
    }
  }

  Future<void> _fetchMoreRecipes() async {
    if (isLoading || !hasMore) return;

    setState(() => isLoading = true);

    try {
      final url = Uri.parse(
        'http://localhost:4000/recipes?limit=$limit&offset=$offset',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final newRecipes = data.map((item) => Recipe.fromJson(item)).toList();

        setState(() {
          _filteredRecipes.addAll(newRecipes);
          offset += newRecipes.length;
          if (newRecipes.length < limit) hasMore = false;
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _searchRecipes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRecipes =
          widget.recipes.where((recipe) {
            return recipe.name.toLowerCase().contains(query);
          }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        automaticallyImplyLeading: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search recipes...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child:
                _filteredRecipes.isEmpty
                    ? Center(
                      child: Text(
                        'No recipes found.',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(12),
                      itemCount: _filteredRecipes.length + (isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < _filteredRecipes.length) {
                          final recipe = _filteredRecipes[index];
                          return GestureDetector(
                            onTap:
                                () => Get.to(
                                  () => RecipeDetailView(recipe: recipe),
                                ),
                            child: Card(
                              elevation: 3,
                              margin: EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: SizedBox(
                                height: 200,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          recipe.imageUrl,
                                          width: 200,
                                          height: 200,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                                    width: 200,
                                                    height: 200,
                                                    color: Colors.grey[300],
                                                    child: Icon(
                                                      Icons.image_not_supported,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              recipe.name,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Ingredients:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Expanded(
                                              child: SingleChildScrollView(
                                                child: Wrap(
                                                  spacing: 6,
                                                  runSpacing: -4,
                                                  children:
                                                      recipe.cleanedIngredients
                                                          .map(
                                                            (
                                                              ingredient,
                                                            ) => Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    top: 8.0,
                                                                  ),
                                                              child: Chip(
                                                                label: Text(
                                                                  ingredient,
                                                                  style:
                                                                      TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                      ),
                                                                ),
                                                                backgroundColor:
                                                                    Colors.green
                                                                        .withOpacity(
                                                                          0.1,
                                                                        ),
                                                              ),
                                                            ),
                                                          )
                                                          .toList(),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        } else {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
