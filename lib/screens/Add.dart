import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _image;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _difficultyController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController();
  final TextEditingController _cookTimeController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isUploading = false;

  // Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Camera permission denied ❌")),
        );
        return;
      }
    } else {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gallery permission denied ❌")),
        );
        return;
      }
    }

    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  //Upload to Firebase Storage
  Future<String?> _uploadImageToFirebase(File imageFile) async {
    try {
      final fileName = "recipes/${DateTime.now().millisecondsSinceEpoch}.jpg";
      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(imageFile);
      return await ref.getDownloadURL(); //return public link
    } catch (e) {
      debugPrint("Image upload error: $e");
      return null;
    }
  }

  // Save recipe data to Firestore
  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    String? imageUrl;
    if (_image != null) {
      imageUrl = await _uploadImageToFirebase(_image!);
    }

    final recipeData = {
      'name': _nameController.text.trim(),
      'category': _categoryController.text.trim(),
      'difficulty': _difficultyController.text.trim(),
      'prepTime': _prepTimeController.text.trim(),
      'cookTime': _cookTimeController.text.trim(),
      'servings': _servingsController.text.trim(),
      'description': _descriptionController.text.trim(),
      'image': imageUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('recipes').add(recipeData);
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Recipe added successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding recipe: $e")),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        height: 150,
        child: Column(
          children: [
            const Text(
              "Choose Image Source",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Camera"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                  icon: const Icon(Icons.image),
                  label: const Text("Gallery"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
        'assets/images/cook-book.png', 
        height: 28, 
      ),
      const SizedBox(width: 8),
      const Text(
        "Add New Recipe",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
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
              Text("Recipe Photo", style: TextStyle(color: Colors.grey[800])),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showImagePickerOptions,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _image == null
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined,
                                  size: 45, color: Colors.grey),
                              SizedBox(height: 10),
                              Text("Upload Photo",
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _image!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 25),

              _buildTextField(
                controller: _nameController,
                label: "Recipe Name *",
                hint: "e.g., Chocolate Cake",
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _categoryController,
                      label: "Category *",
                      hint: "Dessert",
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildTextField(
                      controller: _difficultyController,
                      label: "Difficulty",
                      hint: "Easy",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _prepTimeController,
                      label: "Prep Time",
                      hint: "15 min",
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildTextField(
                      controller: _cookTimeController,
                      label: "Cook Time",
                      hint: "30 min",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _servingsController,
                label: "Servings",
                hint: "4",
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _descriptionController,
                label: "Description",
                hint: "Write short details...",
                maxLines: 3,
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _saveRecipe,
                  icon: _isUploading
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : const Icon(Icons.add),
                  label: Text(
                    _isUploading ? "Uploading..." : "Add Recipe",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: (value) {
        if (label.contains('*') && (value == null || value.isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
      maxLines: maxLines,
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
