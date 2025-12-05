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
            UserFeedback.showWarning(context, 'Camera permission is required to take photos');
          }
          return;
        }
      } else {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          if (mounted) {
            UserFeedback.showWarning(context, 'Photo library permission is required');
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
        final fileSize = await File(pickedFile.path).length();
        if (fileSize > 10 * 1024 * 1024) {
          if (mounted) {
            UserFeedback.showWarning(context, 'Image size must be less than 10MB');
          }
          return;
        }

        setState(() {
          _image = File(pickedFile.path);
        });
        if (mounted) {
          UserFeedback.showSuccess(context, 'Image selected successfully');
        }
      }
    } catch (e) {
      if (mounted) {
        UserFeedback.showError(context, 'Failed to pick image: $e');
      }
    }
  }

  Future<String?> _uploadImageToFirebase(File imageFile) async {
    try {
      final fileName = "recipes/${DateTime.now().millisecondsSinceEpoch}.jpg";
      final ref = FirebaseStorage.instance.ref().child(fileName);
      
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (mounted) {
        UserFeedback.showError(context, 'Upload failed: ${e.message}');
      }
      return null;
    } catch (e) {
      if (mounted) {
        UserFeedback.showError(context, 'Image upload error: $e');
      }
      return null;
    }
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      UserFeedback.showWarning(context, 'Please fix the errors in the form');
      return;
    }

    // Check if image is required (optional in this case)
    if (_image == null) {
      final confirm = await UserFeedback.showConfirmDialog(
        context,
        title: 'No Image Selected',
        message: 'Do you want to add recipe without an image?',
        confirmText: 'Continue',
        cancelText: 'Add Image',
      );
      if (confirm != true) return;
    }

    setState(() => _isUploading = true);

    try {
      // Show loading dialog
      if (mounted) {
        await UserFeedback.showLoadingDialog(
          context,
          message: 'Saving your recipe...',
          dismissible: false,
        );
      }

      // Upload image if selected
      String? imageUrl;
      if (_image != null) {
        imageUrl = await _uploadImageToFirebase(_image!);
        if (imageUrl == null && mounted) {
          Navigator.pop(context); // Close loading dialog
          UserFeedback.showWarning(context, 'Continuing without image');
        }
      }

      // Build recipe data
      final recipeData = {
        'name': FormValidator.sanitizeInput(_nameController.text),
        'category': FormValidator.sanitizeInput(_categoryController.text),
        'difficulty': FormValidator.sanitizeInput(_difficultyController.text),
        'prepTime': _prepTimeController.text.trim(),
        'cookTime': _cookTimeController.text.trim(),
        'servings': _servingsController.text.trim(),
        'description': FormValidator.sanitizeInput(_descriptionController.text),
        'image': imageUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      await FirebaseFirestore.instance.collection('recipes').add(recipeData);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Show success dialog
        await UserFeedback.showSuccessDialog(
          context,
          title: 'Success',
          message: 'Recipe added successfully!',
          onDismiss: () => Navigator.pop(context),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        UserFeedback.showErrorDialog(
          context,
          title: 'Firebase Error',
          message: 'Failed to save recipe: ${e.message}',
          onRetry: _saveRecipe,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        UserFeedback.showErrorDialog(
          context,
          title: 'Error',
          message: 'Failed to save recipe: $e',
          onRetry: _saveRecipe,
        );
      }
    } finally {
      setState(() => _isUploading = false);
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
                validator: FormValidator.validateRecipeName,
                onChanged: (value) => _formHandler.setFieldValue('name', value),
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _categoryController,
                      label: "Category *",
                      hint: "Dessert",
                      validator: FormValidator.validateCategory,
                      onChanged: (value) => _formHandler.setFieldValue('category', value),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildTextField(
                      controller: _difficultyController,
                      label: "Difficulty",
                      hint: "Easy, Medium, Hard",
                      validator: FormValidator.validateDifficulty,
                      onChanged: (value) => _formHandler.setFieldValue('difficulty', value),
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
                      label: "Prep Time (min)",
                      hint: "15",
                      validator: FormValidator.validateTime,
                      onChanged: (value) => _formHandler.setFieldValue('prepTime', value),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildTextField(
                      controller: _cookTimeController,
                      label: "Cook Time (min)",
                      hint: "30",
                      validator: FormValidator.validateTime,
                      onChanged: (value) => _formHandler.setFieldValue('cookTime', value),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _servingsController,
                label: "Servings",
                hint: "4",
                validator: FormValidator.validateServings,
                onChanged: (value) => _formHandler.setFieldValue('servings', value),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _descriptionController,
                label: "Description",
                hint: "Write short details about your recipe...",
                validator: FormValidator.validateDescription,
                onChanged: (value) => _formHandler.setFieldValue('description', value),
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
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Fields marked with * are required',
                        style: TextStyle(color: Colors.blue[700], fontSize: 13),
                      ),
                    ),
                  ],
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
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.orangeAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}
