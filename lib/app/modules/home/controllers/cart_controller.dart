import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class CartController extends GetxController {
  var cartIngredients = [].obs;

  @override
  void onInit() {
    super.onInit();
    fetchCartIngredients();
  }

 Future<void> fetchCartIngredients() async {
  try {
    final token = GetStorage().read('auth_token'); // 🔐 read the stored token

    final response = await http.get(
      Uri.parse('http://localhost:4000/cart_ingredients'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      cartIngredients.value = jsonDecode(response.body);
    } else {
      Get.snackbar("Error", "Failed to load cart ingredients.");
    }
  } catch (e) {
    print("Fetch cart error: $e");
    Get.snackbar("Error", "Something went wrong while fetching cart.");
  }
}


 Future<void> deleteFromCartById(int cartIngredientId) async {
  try {
    final token = GetStorage().read('auth_token');

    final response = await http.delete(
      Uri.parse('http://localhost:4000/cart_ingredients/$cartIngredientId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final result = jsonDecode(response.body);

    if (response.statusCode == 200) {
      Get.snackbar("Deleted", result['message'] ?? "Ingredient removed.");
      await fetchCartIngredients();
    } else {
      Get.snackbar("Error", result['message'] ?? "Failed to remove ingredient.");
    }
  } catch (e) {
    print("Delete error: $e");
    Get.snackbar("Error", "Something went wrong while deleting.");
  }
}

}
