import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:smart_recipe_generator_flutter/app/models/recipe.dart';
import 'package:smart_recipe_generator_flutter/app/modules/seeRecipe/views/full_recipe_view.dart';

class SeeRecipeController extends GetxController {
  final ScrollController scrollController = ScrollController();

  final isLoading = false.obs;
  final recipes = <RecipeData>[].obs;
  final totalRecipes = 0.obs;

  final int limit = 20;
  int offset = 0;
  bool allLoaded = false;

  final box = GetStorage();
  late String authToken;

  @override
  void onInit() {
    super.onInit();
    authToken = box.read('auth_token') ?? '';
    fetchRecipes();

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        fetchRecipes();
      }
    });
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  Future<void> fetchRecipes() async {
    if (allLoaded || isLoading.value) return;

    isLoading.value = true;

    try {
      http.Response response;

      if (authToken.isNotEmpty) {
        // ✅ Logged-in user — GET request
        response = await http.get(
          Uri.parse(
            'http://localhost:4000/recipes/generate_recipes?limit=$limit&offset=$offset',
          ),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );
      } else {
        // ✅ Guest user — POST request with ingredient_ids
        final box = GetStorage();
        final List<dynamic> guestIds = box.read('guest_ingredient_ids') ?? [];
        print("Guest Ingredient ids: ${guestIds}");

        if (guestIds.isEmpty) {
          print('No guest pantry ingredients available.');
          isLoading.value = false;
          return;
        }

        response = await http.post(
          Uri.parse('http://localhost:4000/recipes/generate_recipes?limit=$limit&offset=$offset'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'ingredient_ids': guestIds
          }),
        );
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        totalRecipes.value = data["total_recipes"];

        final List fetched = data["recipes"];
        if (fetched.isEmpty || recipes.length >= totalRecipes.value) {
          allLoaded = true;
        } else {
          final newRecipes =
              fetched.map((r) => RecipeData.fromJson(r)).toList();
          recipes.addAll(newRecipes.cast<RecipeData>());
          offset += limit;
        }
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception while fetching recipes: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void showFullRecipe(RecipeData recipeData) {
    Get.to(() => FullRecipeView(recipeData: recipeData));
  }
}

class RecipeData {
  final Recipe recipe;
  final int pantryIngredientsUsed;
  final List<String> missingIngredients;
  final List<String> matchingIngredients;
  final int totalIngredients;

  RecipeData({
    required this.recipe,
    required this.pantryIngredientsUsed,
    required this.missingIngredients,
    required this.matchingIngredients,
    required this.totalIngredients,
  });

  factory RecipeData.fromJson(Map<String, dynamic> json) {
    return RecipeData(
      recipe: Recipe.fromJson(json["recipe"]),
      pantryIngredientsUsed: json["pantry_ingredients_used"],
      missingIngredients: List<String>.from(json["missing_ingredients"] ?? []),
      matchingIngredients: List<String>.from(
        json["matching_ingredients"] ?? [],
      ),
      totalIngredients: json["total_ingredients"],
    );
  }
}

