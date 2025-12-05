import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import '/helper/form_validator.dart';
import '/helper/user_feedback.dart';
import '/helper/form_handler.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _formHandler = FormHandler();
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

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _difficultyController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Camera permission denied'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          return;
        }
      } else {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Gallery permission denied'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          return;
        }
      }

      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Image selected successfully'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to pick image: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<String?> _uploadImageToFirebase(File imageFile) async {
    try {
      final fileName = "recipes/${DateTime.now().millisecondsSinceEpoch}.jpg";
      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Image upload error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return null;
    }
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all required fields.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
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

      await FirebaseFirestore.instance.collection('recipes').add(recipeData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Recipe added successfully!'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to add recipe: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        height: 150,
        child: Column(
          children: [
            Text(
              "Choose Image Source",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
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
                    backgroundColor: Theme.of(context).colorScheme.secondary,
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.cardColor,
        elevation: 1,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/cook-book.png', height: 28),
            const SizedBox(width: 8),
            Text(
              "Add New Recipe",
              style: theme.textTheme.titleLarge?.copyWith(
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
              Text("Recipe Photo", style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showImagePickerOptions,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: _image == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined,
                                size: 45,
                                color: theme.iconTheme.color?.withOpacity(0.6)),
                            const SizedBox(height: 10),
                            Text(
                              "Upload Photo",
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
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
                  _nameController, "Recipe Name *", "e.g., Chocolate Cake"),
              const SizedBox(height: 15),
              _buildTextField(_categoryController, "Category *", "Dessert"),
              const SizedBox(height: 15),
              _buildTextField(
                  _difficultyController, "Difficulty", "Easy, Medium, Hard"),
              const SizedBox(height: 15),
              _buildTextField(
                  _prepTimeController, "Prep Time (min)", "15",
                  keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              _buildTextField(
                  _cookTimeController, "Cook Time (min)", "30",
                  keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              _buildTextField(_servingsController, "Servings", "4",
                  keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              _buildTextField(_descriptionController, "Description",
                  "Write short details about your recipe...",
                  maxLines: 3, keyboardType: TextInputType.multiline),
              const SizedBox(height: 25),

              /// ✅ unified add button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _saveRecipe,
                  icon: _isUploading
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : const Icon(Icons.add, color: Colors.white),
                  label: Text(
                    _isUploading ? "Uploading..." : "Add Recipe",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    disabledBackgroundColor: Colors.grey[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType:
          maxLines > 1 ? TextInputType.multiline : keyboardType,
      textInputAction:
          maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      validator: (value) {
        if (label.contains('*') && (value == null || value.isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
    );
  }
}
