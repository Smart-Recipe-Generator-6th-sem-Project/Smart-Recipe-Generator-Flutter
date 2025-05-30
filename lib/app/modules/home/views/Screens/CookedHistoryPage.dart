// CookedHistoryPage.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_recipe_generator_flutter/app/modules/home/controllers/cooked_recipes_controller.dart';
import 'package:smart_recipe_generator_flutter/app/modules/recipe_detail/views/recipe_detail_view.dart';

class CookedHistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CookedRecipesController cookedRecipesController = Get.put(
      CookedRecipesController(),
    );

    cookedRecipesController.fetchCookedRecipes();

    return Scaffold(
      appBar: AppBar(title: Text('My Cooked History')),
      body: Obx(() {
        if (cookedRecipesController.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (cookedRecipesController.cookedRecipes.isEmpty) {
          return Center(
            child: Text(
              'You haven’t cooked any recipes yet.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(12),
          itemCount: cookedRecipesController.cookedRecipes.length,
          itemBuilder: (context, index) {
            final recipe = cookedRecipesController.cookedRecipes[index];
            final ingredients = recipe.ingredients as List<dynamic>;

            return GestureDetector(
              onTap: () => Get.to(() => RecipeDetailView(recipe: recipe)),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            recipe.imageUrl ?? '',
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  width: 200,
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: Icon(Icons.image_not_supported),
                                ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                        ingredients.map((ingredient) {
                                          return Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              0,
                                              8.0,
                                              0,
                                              0,
                                            ),
                                            child: Chip(
                                              label: Text(
                                                ingredient.name,
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              backgroundColor: Colors.orange
                                                  .withOpacity(0.1),
                                            ),
                                          );
                                        }).toList(),
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
          },
        );
      }),
    );
  }
}
