// cooked_recipes_controller.dart
import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:smart_recipe_generator_flutter/app/models/recipe.dart';

class CookedRecipesController extends GetxController {
  var isLoading = true.obs;
  RxList<Recipe> cookedRecipes = <Recipe>[].obs;

  Future<void> fetchCookedRecipes() async {
    try {
      final token = GetStorage().read("auth_token");
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('http://localhost:4000/recipes/cooked_recipes'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        cookedRecipes.value =
            data.map((json) => Recipe.fromJson(json)).toList();
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

}
