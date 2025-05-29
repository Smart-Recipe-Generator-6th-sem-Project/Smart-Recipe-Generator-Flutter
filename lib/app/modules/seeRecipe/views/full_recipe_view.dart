import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:smart_recipe_generator_flutter/app/modules/recipe_detail/views/favorite_icon_button.dart';
import 'package:smart_recipe_generator_flutter/app/modules/home/controllers/cart_controller.dart';
import '../controllers/see_recipe_controller.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FullRecipeView extends StatefulWidget {
  final RecipeData recipeData;

  const FullRecipeView({super.key, required this.recipeData});

  @override
  State<FullRecipeView> createState() => _FullRecipeViewState();
}

class _FullRecipeViewState extends State<FullRecipeView> {
  final Set<String> addedIngredients = {};

  Future<void> addToShoppingList(String itemName) async {
    try {
      String? storedToken = GetStorage().read('auth_token');

      final postRes = await http.post(
        Uri.parse('http://localhost:4000/cart_ingredients'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $storedToken',
        },
        body: jsonEncode({"ingredient_name": itemName}),
      );

      final Map<String, dynamic> resBody = jsonDecode(postRes.body);

      if (postRes.statusCode == 200 || postRes.statusCode == 201) {
        setState(() {
          addedIngredients.add(itemName);
        });
        Get.snackbar("Success", '"$itemName" added to cart.');
        final cartController = Get.find<CartController>();
        await cartController.fetchCartIngredients();
      } else if (postRes.statusCode == 422 &&
          resBody['message']?.contains("already in cart") == true) {
        setState(() {
          addedIngredients.add(itemName);
        });
        Get.snackbar("Info", resBody['message']);
      } else {
        Get.snackbar("Error", resBody['message'] ?? 'Something went wrong.');
      }
    } catch (e) {
      print("Add to cart error: $e");
      Get.snackbar("Error", "Something went wrong.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipe = widget.recipeData.recipe;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Smart Chef", style: TextStyle(color: Colors.black)),
            const SizedBox(width: 8),
            Image.asset('assets/icons/applogo.png', height: 35),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  recipe.imageUrl ?? '',
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey[300],
                      ),
                      child: const Center(
                        child: Icon(Icons.restaurant, size: 60, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      recipe.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ),
                  FavoriteIconButton(recipeId: recipe.id, recipeName: recipe.name),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          Text("Ingredients", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...recipe.ingredients.map((ingredient) {
                        final isAvailable = widget.recipeData.matchingIngredients.contains(ingredient.name);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isAvailable
                                    ? Icons.check_circle
                                    : Icons.remove_circle_outline,
                                size: 18,
                                color:
                                    isAvailable ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(ingredient.name)),
                              if (!isAvailable)
                                TextButton.icon(
                                  onPressed:
                                      addedIngredients.contains(ingredient.name)
                                          ? null
                                          : () => addToShoppingList(
                                            ingredient.name,
                                          ),
                                  icon: const Icon(
                                    Icons.add_shopping_cart,
                                    size: 16,
                                  ),
                                  label: Text(
                                    addedIngredients.contains(ingredient.name)
                                        ? "Added"
                                        : "Add",
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.teal,
                                    disabledForegroundColor: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          Text("Instructions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(
                        recipe.instructions.length,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${index + 1}. ", style: const TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(child: Text(recipe.instructions[index] ?? '')),
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
      ),
    );
  }
}
