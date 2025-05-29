import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class Recipe {
  final String name;
  final String ingredients;
  final String instructions;
  final File? image;

  Recipe({required this.name, required this.ingredients, required this.instructions, this.image});
}

class RecipeAlert extends StatefulWidget {
  @override
  _RecipeAlertState createState() => _RecipeAlertState();
}

class _RecipeAlertState extends State<RecipeAlert> {
  final _formKey = GlobalKey<FormState>();
  final List<Recipe> _recipes = [];

  String _name = '';
  String _ingredients = '';
  String _instructions = '';
  File? _image;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _addRecipe() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _recipes.add(Recipe(
          name: _name,
          ingredients: _ingredients,
          instructions: _instructions,
          image: _image,
        ));
        _image = null;
      });

      _formKey.currentState!.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      title: Center(child: Text('Add Recipe')),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: 550,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Form Section
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Recipe Name'),
                      validator: (value) => value!.isEmpty ? 'Enter a name' : null,
                      onSaved: (value) => _name = value!,
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Ingredients'),
                      maxLines: 2,
                      validator: (value) => value!.isEmpty ? 'Enter ingredients' : null,
                      onSaved: (value) => _ingredients = value!,
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Instructions'),
                      maxLines: 2,
                      validator: (value) => value!.isEmpty ? 'Enter instructions' : null,
                      onSaved: (value) => _instructions = value!,
                    ),
                    SizedBox(height: 10),
                    _image == null
                        ? Text('No image selected.')
                        : Image.file(_image!, height: 100),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.image),
                          label: Text('Upload Image'),
                          onPressed: _pickImage,
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _addRecipe,
                          child: Text('Save Recipe'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 10),

              /// Saved Recipes Section
              Text('Saved Recipes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 10),
              _recipes.isEmpty
                  ? Text('No recipes added yet.')
                  : Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _recipes.map((recipe) {
                        return Container(
                          width: 140,
                          child: Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            elevation: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                                  child: recipe.image != null
                                      ? Image.file(
                                          recipe.image!,
                                          height: 80,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          height: 80,
                                          width: double.infinity,
                                          color: Colors.grey[300],
                                          child: Icon(Icons.fastfood, size: 40),
                                        ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    recipe.name,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    recipe.ingredients,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(height: 6),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
