import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_recipe_generator_flutter/app/modules/home/controllers/cart_controller.dart';

class Cart extends StatelessWidget {
  const Cart({super.key});

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.find<CartController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        automaticallyImplyLeading: false,
      ),
      body: Obx(() {
        final cartItems = cartController.cartIngredients;

        if (cartItems.isEmpty) {
          return const Center(
            child: Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: cartItems.length,
          itemBuilder: (context, index) {
            final cartItem = cartItems[index];
            final ingredient = cartItem['ingredient'] ?? cartItem;
            final cartIngredientId = cartItem['id']; // id of cart_ingredient record

            return Card(
              child: ListTile(
                title: Text(ingredient['name'] ?? 'Unknown'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    if (cartIngredientId != null) {
                      await cartController.deleteFromCartById(cartIngredientId);
                    } else {
                      Get.snackbar('Error', 'Invalid cart item ID.');
                    }
                  },
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
