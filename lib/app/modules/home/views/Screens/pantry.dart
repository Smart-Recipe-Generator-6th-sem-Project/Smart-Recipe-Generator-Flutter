// ... top imports unchanged
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_recipe_generator_flutter/app/routes/app_pages.dart';

class Pantry extends StatefulWidget {
  @override
  _PantryViewState createState() => _PantryViewState();
}

class _PantryViewState extends State<Pantry> {
  List<String> guestPantryItems = [];
  List<int> guestPantryIngredientIds = [];
  int currentPage = 1;
  final int pageSize = 100;

  bool isLoading = false;
  bool hasMore = true;

  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> ingredients = [];
  List<List<Map<String, dynamic>>> groupedIngredients = [];
  List<bool> isExpanded = [];

  List<String> selectedItems = [];
  List<String> myPantryItems = [];

  final String? storedToken = GetStorage().read('auth_token');

  @override
  void initState() {
    super.initState();
    fetchMyPantryItems();
    fetchIngredients();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMore) {
        currentPage++;
        fetchIngredients();
      }
    });
  }

  Future<void> fetchIngredients() async {
    if (isLoading || !hasMore) return;

    setState(() => isLoading = true);

    final offset = (currentPage - 1) * pageSize;
    final url = Uri.parse(
      'http://localhost:4000/ingredients?limit=$pageSize&offset=$offset',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      if (data.isEmpty || data.length < pageSize) {
        hasMore = false;
      }

      final newIngredients = data
          .map<Map<String, dynamic>>((item) => {
                'id': item['id'],
                'name': item['name'],
              })
          .toList();

      ingredients.addAll(newIngredients);
      groupedIngredients = _groupIngredients(ingredients, 20);
      isExpanded = List.generate(groupedIngredients.length, (_) => false);
    } else {
      print('Error fetching ingredients');
    }

    setState(() => isLoading = false);
  }

  Future<void> fetchMyPantryItems() async {
    if (storedToken != null) {
      final response = await http.get(
        Uri.parse('http://localhost:4000/pantries/mypantry'),
        headers: {'Authorization': 'Bearer $storedToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ingredientsInPantry = data['pantry']['ingredients'] as List;

        setState(() {
          myPantryItems =
              ingredientsInPantry
                  .map<String>((ingredient) => ingredient['name'])
                  .toList();
        });
      } else {
        print('Failed to fetch pantry items');
      }
    } else {
      setState(() {
        myPantryItems = guestPantryItems;
      });
    }
  }

  List<List<Map<String, dynamic>>> _groupIngredients(
    List<Map<String, dynamic>> list,
    int groupSize,
  ) {
    List<List<Map<String, dynamic>>> grouped = [];
    for (int i = 0; i < list.length; i += groupSize) {
      grouped.add(list.sublist(
        i,
        i + groupSize > list.length ? list.length : i + groupSize,
      ));
    }
    return grouped;
  }

  void toggleSelection(String item) {
    setState(() {
      selectedItems.contains(item)
          ? selectedItems.remove(item)
          : selectedItems.add(item);
    });
  }

  void confirmPantryAddition() async {
    print("Stored token: $storedToken");
    // Find ingredient IDs based on the selected ingredient names
    final selectedIngredientIds =
        ingredients
            .where((ingredient) => selectedItems.contains(ingredient['name']))
            .map<int>((ingredient) => ingredient['id'])
            .toList();

    final box = GetStorage();
    box.write('guest_ingredient_ids', selectedIngredientIds);
    box.write('guest_ingredient_names', guestPantryItems);

    if (selectedIngredientIds.isEmpty) return;
    
    if (storedToken != null) {
      // User is logged in — send to backend
      final body = jsonEncode({'ingredient_ids': selectedIngredientIds});

      final response = await http.post(
        Uri.parse('http://localhost:4000/pantry_ingredients'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $storedToken',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final pantryData = jsonDecode(response.body);

        setState(() {
          myPantryItems.addAll(selectedItems);
          selectedItems.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pantryData['message']),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add to pantry')));
      }
    } else {
      print("Selected ingredient IDs: $selectedIngredientIds");
      print("Selected items: $selectedItems");
      print(
        "Before add -> guestPantryIngredientIds: $guestPantryIngredientIds",
      );
      print("Before add -> guestPantryItems: $guestPantryItems");

      // Guest user — update local state only
      setState(() {
        guestPantryItems.addAll(
          selectedItems.where((item) => !guestPantryItems.contains(item)),
        );
        guestPantryIngredientIds.addAll(
          selectedIngredientIds.where(
            (id) => !guestPantryIngredientIds.contains(id),
          ),
        );
        selectedItems.clear();
      });

      print("After add -> guestPantryIngredientIds: $guestPantryIngredientIds");
      print("After add -> guestPantryItems: $guestPantryItems");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ingredients added to your guest pantry.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void fetchPantryAndMyItemsAgain() async {
    await fetchMyPantryItems();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("List Of Ingredients")),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 70),
            child: groupedIngredients.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: groupedIngredients.length,
                    itemBuilder: (context, index) {
                      final category = 'Category ${index + 1}';
                      final ingredientsGroup = groupedIngredients[index];
                      final expanded = isExpanded[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      category,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        expanded
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          isExpanded[index] = !expanded;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                AnimatedCrossFade(
                                  duration: Duration(milliseconds: 300),
                                  crossFadeState: expanded
                                      ? CrossFadeState.showFirst
                                      : CrossFadeState.showSecond,
                                  firstChild: _buildChips(ingredientsGroup),
                                  secondChild:
                                      _buildChips(ingredientsGroup.take(8)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (isLoading && hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (selectedItems.isNotEmpty)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: confirmPantryAddition,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text("Add to Pantry"),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Get.toNamed(Routes.MY_PANTRY);
                      fetchPantryAndMyItemsAgain();
                    },
                    icon: Icon(Icons.kitchen),
                    label: Text("My Pantry"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Get.toNamed(Routes.SEE_RECIPE),
                    child: Text("See Recipe"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChips(Iterable<Map<String, dynamic>> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: items.map((ingredient) {
        final name = ingredient['name'];
        final isInPantry = myPantryItems.contains(name);

        return ChoiceChip(
          label: Text(name),
          selected: selectedItems.contains(name),
          onSelected: isInPantry ? null : (_) => toggleSelection(name),
          backgroundColor: isInPantry ? Colors.grey.shade300 : null,
        );
      }).toList(),
    );
  }
}
