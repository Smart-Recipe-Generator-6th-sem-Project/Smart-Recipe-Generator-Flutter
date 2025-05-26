import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_recipe_generator_flutter/app/models/recipe.dart';
import 'package:smart_recipe_generator_flutter/app/modules/home/views/Screens/SeeMoreRecipeScreen.dart';
import 'package:smart_recipe_generator_flutter/app/modules/recipe_detail/views/recipe_detail_view.dart';
import 'package:http/http.dart' as http;

bool isLoggedIn = true;

List<Recipe> allRecipes = [];
bool isLoading = false;
 
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _ingredientController = TextEditingController();

  // Simulate pantry ingredients list
  List<String> pantryIngredients = [];

  @override
  void initState() {
    super.initState();
    fetchRecipes(limit: 10).then((recipes) {
      setState(() {
        allRecipes = recipes;
      });
    });
  }

  Future<List<Recipe>> fetchRecipes({int limit = 10, int offset = 0}) async {
    final url = Uri.parse(
      'http://localhost:4000/recipes?limit=$limit&offset=$offset',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Recipe.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch recipes');
    }
  }

  void _addIngredient() {
    if (_ingredientController.text.isNotEmpty) {
      setState(() {
        pantryIngredients.add(_ingredientController.text.trim());
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${_ingredientController.text} to pantry'),
          duration: Duration(seconds: 2),
        ),
      );
      _ingredientController.clear();
    }
  }

  void _searchRecipes() {
    if (_searchController.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Searching for: ${_searchController.text}'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _findRecipesFromPantry() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Finding recipes from your pantry ingredients...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return GestureDetector(
      onTap: () => Get.to(() => RecipeDetailView(recipe: recipe)),
      child: Container(
        width: 160,
        margin: EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                recipe.imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeSection(String title, List<Recipe> recipes) {
    const int maxToShow = 6;

    if (recipes.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (recipes.length > maxToShow)
                TextButton(
                  onPressed: () {
                    Get.to(() => SeeMoreRecipesScreen(title: title, recipes: recipes));
                  },
                  child: Text("See More"),
                )
            ],
          ),
        ),
        SizedBox(height: 12),
        Container(
          height: 200,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: recipes.length > maxToShow ? maxToShow : recipes.length,
            itemBuilder: (context, index) => _buildRecipeCard(recipes[index]),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPossibleRecipeBanner() {
    return pantryIngredients.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/possibleRecipes');
              },
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "You can make recipes using ${pantryIngredients.length} ingredient(s) in your pantry.",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            onPressed: () => _searchController.clear(),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: EdgeInsets.symmetric(vertical: 0),
                        ),
                        onSubmitted: (_) => _searchRecipes(),
                      ),
                    ),
                    // Padding(
                    //   padding: EdgeInsets.symmetric(horizontal: 16),
                    //   child: Row(
                    //     children: [
                    //       Expanded(
                    //         child: TextField(
                    //           controller: _ingredientController,
                    //           decoration: InputDecoration(
                    //             hintText: 'Add ingredient to pantry',
                    //             border: OutlineInputBorder(
                    //               borderRadius: BorderRadius.circular(10),
                    //             ),
                    //             contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    //           ),
                    //         ),
                    //       ),
                    //       SizedBox(width: 8),
                    //       ElevatedButton(
                    //         onPressed: _addIngredient,
                    //         child: Icon(Icons.add),
                    //         style: ElevatedButton.styleFrom(
                    //           shape: CircleBorder(),
                    //           padding: EdgeInsets.all(12),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    // Padding(
                    //   padding: EdgeInsets.all(16),
                    //   child: ElevatedButton(
                    //     onPressed: _findRecipesFromPantry,
                    //     child: Row(
                    //       mainAxisAlignment: MainAxisAlignment.center,
                    //       children: [
                    //         Icon(Icons.restaurant),
                    //         SizedBox(width: 8),
                    //         Text('What Can I Make Now?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    //       ],
                    //     ),
                    //     style: ElevatedButton.styleFrom(
                    //       padding: EdgeInsets.symmetric(vertical: 16),
                    //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    //     ),
                    //   ),
                    // ),

                    // 🧾 Show possible recipes banner if pantry has items
                    _buildPossibleRecipeBanner(),

                    if (isLoggedIn) _buildRecipeSection('Discover Recipes', allRecipes),
                    _buildRecipeSection('Based on Your Past Preferences', allRecipes),
                    SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ingredientController.dispose();
    super.dispose();
  }
}
