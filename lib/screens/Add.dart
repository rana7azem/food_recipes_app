import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _image;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/book_icon.png',
              height: 40,
            ),
            const SizedBox(width: 8),
            const Text(
              "FLAVOR FIESTA",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Add New Recipe",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Image upload section
              Text("Recipe Photo", style: TextStyle(color: Colors.grey[800])),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    image: _image != null
                        ? DecorationImage(
                            image: FileImage(_image!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _image == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.camera_alt_outlined,
                                size: 40, color: Colors.grey),
                            SizedBox(height: 10),
                            Text("Upload Photo",
                                style: TextStyle(color: Colors.grey)),
                          ],
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 25),

              _buildTextField("Recipe Name *", "e.g., Chocolate Chip Cookies"),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(child: _buildTextField("Category *", "e.g., Dessert")),
                  const SizedBox(width: 15),
                  Expanded(child: _buildTextField("Difficulty", "Easy")),
                ],
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(child: _buildTextField("Prep Time", "e.g., 15 min")),
                  const SizedBox(width: 15),
                  Expanded(child: _buildTextField("Cook Time", "e.g., 30 min")),

                ],
              ),
              const SizedBox(height: 15),

              _buildTextField("Servings", "4"),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Recipe added successfully!"),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text(
                    "Add Recipe",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
