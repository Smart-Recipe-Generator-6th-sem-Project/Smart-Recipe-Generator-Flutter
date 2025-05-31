import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:smart_recipe_generator_flutter/app/models/recipe.dart';
import 'package:smart_recipe_generator_flutter/app/modules/recipe_detail/views/favorite_icon_button.dart';
import 'package:smart_recipe_generator_flutter/app/modules/seeRecipe/controllers/see_recipe_controller.dart';

class RecipeDetailView extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailView({super.key, required this.recipe});

  @override
  State<RecipeDetailView> createState() => _RecipeDetailViewState();
}

class _RecipeDetailViewState extends State<RecipeDetailView> {
  bool isCooked = false;
  bool isLoading = true;
  String? storedToken = GetStorage().read('auth_token');

  @override
  void initState() {
    super.initState();
    fetchCookedRecipeIds(); // <-- fetch cooked recipe list
  }

  Future<void> markAsCooked() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:4000/recipes/add_to_cooked_recipes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $storedToken',
        },
        body: jsonEncode({"id": widget.recipe.id}),
      );

      final Map<String, dynamic> resBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          isCooked = true; // <-- update state so button disables immediately
        });
        Get.snackbar("Success", resBody['message'] ?? "Marked as cooked.");
      } else {
        Get.snackbar("Info", resBody['message'] ?? "Could not mark as cooked.");
      }
    } catch (e) {
      print("Mark as cooked error: $e");
      Get.snackbar("Error", "Something went wrong.");
    }
  }

  Future<void> fetchCookedRecipeIds() async {
    try {
      String? storedToken = GetStorage().read('auth_token');
      final response = await http.get(
        Uri.parse('http://localhost:4000/recipes/cooked_recipe_ids'),
        headers: {'Authorization': 'Bearer $storedToken'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        List<dynamic> cookedIds = data['cooked_recipe_ids'];

        setState(() {
          isCooked = cookedIds.contains(
            int.tryParse(widget.recipe.id),
          );
          isLoading = false; // <-- Finish loading
        });
      } else {
        print("Failed to fetch cooked recipe IDs: ${response.body}");
        setState(() {
          isLoading = false; // <-- Also end loading on failure
        });
      }
    } catch (e) {
      print("Error fetching cooked recipe IDs: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.name),
        backgroundColor: const Color.fromARGB(213, 255, 119, 77),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image
            if (widget.recipe.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.recipe.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Recipe Name
                Text(
                  widget.recipe.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),

                // Love Icon
                FavoriteIconButton(
                  recipeId: widget.recipe.id,
                  recipeName: widget.recipe.name,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Ingredients Card
            if (widget.recipe.cleanedIngredients.isNotEmpty)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.restaurant_menu, color: Colors.deepOrange),
                          SizedBox(width: 8),
                          Text(
                            "Ingredients",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...widget.recipe.cleanedIngredients.map(
                        (ingredient) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text("• $ingredient"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Instructions Card
            if (widget.recipe.instructions.isNotEmpty)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.list_alt, color: Colors.deepOrange),
                          SizedBox(width: 8),
                          Text(
                            "Instructions",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(
                        widget.recipe.instructions.length,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${index + 1}. ",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(child: Text(widget.recipe.instructions[index])),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar:
          storedToken != null
              ? (isLoading
                  ? const SizedBox(
                    height: 64,
                    child: Center(child: CircularProgressIndicator()),
                  )
                  : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: isCooked ? null : markAsCooked,
                      icon: Icon(isCooked ? Icons.check_circle : Icons.check),
                      label: Text(
                        isCooked ? "Already Cooked" : "Mark As Cooked",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isCooked ? Colors.grey : Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ))
              : null,
    );
  }
}
