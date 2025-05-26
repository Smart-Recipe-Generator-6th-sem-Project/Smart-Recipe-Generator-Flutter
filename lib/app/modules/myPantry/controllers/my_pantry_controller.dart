import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class MyPantryController extends GetxController {
  var myPantryItems =
      <Map<String, dynamic>>[].obs; // Update to hold item data with more detail
  var favoriteItems = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchPantryItems(); // Fetch pantry items when the controller is initialized
  }

  // Toggle favorite status for an item
  void toggleFavorite(Map<String, dynamic> item) {
    if (favoriteItems.contains(item)) {
      favoriteItems.remove(item);
    } else {
      favoriteItems.add(item);
    }
  }

  // Fetch pantry items from API
  Future<void> fetchPantryItems() async {
    final box = GetStorage();
    final storedToken = box.read('auth_token');

    if (storedToken == null) {
      // Guest user: Load from local storage
      print('Guest user detected');
      final guestIngredientNames = box.read('guest_ingredient_names') ?? [];
      final guestIngredientIds = box.read('guest_ingredient_ids') ?? [];

      print('Guest ingredient names: $guestIngredientNames');
      print('Guest ingredient ids: $guestIngredientIds');

      if (guestIngredientNames is List && guestIngredientIds is List) {
        myPantryItems.value = List.generate(guestIngredientNames.length, (
          index,
        ) {
          return {
            'id':
                guestIngredientIds.length > index
                    ? guestIngredientIds[index]
                    : null,
            'name': guestIngredientNames[index]
          };
        });
      }
      return;
    }

    // Logged-in user: Fetch from backend
    final response = await http.get(
      Uri.parse('http://localhost:4000/pantries/mypantry'),
      headers: {'Authorization': 'Bearer $storedToken'},
    );

    if (response.statusCode == 200) {
      final pantryData = jsonDecode(response.body);
      final List<dynamic> ingredients = pantryData['pantry']['ingredients'];

      myPantryItems.value = List<Map<String, dynamic>>.from(
        ingredients.map(
          (item) => {
            'id': item['id'],
            'name': item['name'],
            'created_at': item['created_at'],
            'updated_at': item['updated_at'],
          },
        ),
      );
    } else {
      print('Failed to load pantry data');
    }
  }

  // Add item to shopping list (for now just printing it)
  void addToShoppingList(Map<String, dynamic> item) {
    print('Added "${item['name']}" to shopping list');
    // You can also update a local shopping list RxList or send it to the backend
  }

  // Remove item from pantry
  Future<void> removeItem(Map<String, dynamic> item) async {
    final box = GetStorage();
    final storedToken = box.read('auth_token');

    if (storedToken == null) {
      // Guest user: Remove from local storage
      print('Guest user: removing item');

      final List<dynamic> guestIngredientIds =
          box.read('guest_ingredient_ids') ?? [];
      final List<dynamic> guestIngredientNames =
          box.read('guest_ingredient_names') ?? [];

      final int indexToRemove = guestIngredientNames.indexOf(item['name']);

      if (indexToRemove != -1) {
        guestIngredientNames.removeAt(indexToRemove);
        if (guestIngredientIds.length > indexToRemove) {
          guestIngredientIds.removeAt(indexToRemove);
        }

        // Update storage
        box.write('guest_ingredient_ids', guestIngredientIds);
        box.write('guest_ingredient_names', guestIngredientNames);

        // Update UI
        myPantryItems.removeWhere((element) => element['name'] == item['name']);

        Get.snackbar(
          'Removed',
          '${item['name']} removed from guest pantry.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color.fromARGB(235, 255, 80, 80),
          colorText: Colors.black,
        );
      } else {
        print('Item not found in guest pantry');
      }

      return;
    }

    // Logged-in user: Delete from backend
    final response = await http.delete(
      Uri.parse('http://localhost:4000/pantry_ingredients'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $storedToken',
      },
      body: jsonEncode({'ingredient_id': item['id']}),
    );

    if (response.statusCode == 200) {
      final message = jsonDecode(response.body)['message'];
      print(message);

      myPantryItems.removeWhere((element) => element['id'] == item['id']);

      Get.snackbar(
        'Success',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color.fromARGB(255, 220, 255, 220),
        colorText: Colors.black,
      );
    } else {
      print('Failed to delete item: ${response.body}');
      Get.snackbar(
        'Error',
        'Could not delete item. Try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color.fromARGB(255, 255, 230, 230),
        colorText: Colors.black,
      );
    }
  }
}
