import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import '/helper/form_validator.dart';
import '/helper/user_feedback.dart';
import '/helper/form_handler.dart';
import '/services/recipe_service.dart';
import '/services/notification_service.dart';

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

  /// Save image locally to app's documents directory (FREE - no Firebase Storage needed)
  Future<String?> _saveImageLocally(File imageFile) async {
    try {
      // Get the app's documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/recipe_images');
      
      // Create the directory if it doesn't exist
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      // Generate unique filename
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImagePath = '${imagesDir.path}/$fileName';
      
      // Copy the image to the app's directory
      await imageFile.copy(savedImagePath);
      
      print('✅ Image saved locally: $savedImagePath');
      return savedImagePath;
    } catch (e) {
      print('❌ Failed to save image locally: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Image save error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return null;
    }
  }

  Future<void> _saveRecipe() async {
    print('=== DEBUG: Starting recipe save process ===');
    
    if (!_formKey.currentState!.validate()) {
      print('DEBUG: Form validation failed');
      UserFeedback.showWarning(context, 'Please fix the errors in the form');
      return;
    }

    // Check authentication status first
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('DEBUG: User not authenticated');
      if (mounted) {
        UserFeedback.showError(context, 'Please log in to add recipes');
      }
      return;
    }
    print('DEBUG: User authenticated: ${user.uid}');

    // Check if image is required (optional in this case)
    if (_image == null) {
      final confirm = await UserFeedback.showConfirmDialog(
        context,
        title: 'No Image Selected',
        message: 'Do you want to add recipe without an image?',
        confirmText: 'Continue',
        cancelText: 'Add Image',
      );
      if (confirm != true) {
        return;
      }
    }

    setState(() => _isUploading = true);

    try {
      print('DEBUG: Showing loading dialog');
      // Show loading dialog (don't await - it will block)
      if (mounted) {
        UserFeedback.showLoadingDialog(
          context,
          message: 'Saving your recipe...',
          dismissible: false,
        );
      }

      // Save image locally if selected (FREE - no Firebase Storage needed)
      String? imageUrl;
      if (_image != null) {
        print('DEBUG: Starting local image save');
        imageUrl = await _saveImageLocally(_image!);
        print('DEBUG: Image saved locally. Path: $imageUrl');
        if (imageUrl == null && mounted) {
          Navigator.pop(context); // Close loading dialog
          UserFeedback.showWarning(context, 'Continuing without image');
        }
      }

      print('DEBUG: Preparing recipe data');
      final recipeData = {
        'name': _nameController.text.trim(),
        'category': _categoryController.text.trim(),
        'difficulty': _difficultyController.text.trim(),
        'prepTime': _prepTimeController.text.trim(),
        'cookTime': _cookTimeController.text.trim(),
        'servings': _servingsController.text.trim(),
        'description': FormValidator.sanitizeInput(_descriptionController.text),
        'imageUrl': imageUrl ?? '',
      };
      print('DEBUG: Recipe data: $recipeData');

      print('DEBUG: Saving to Firebase Realtime Database');
      
      // Save to Firebase Realtime Database using RecipeService
      final recipeService = RecipeService();
      await recipeService.addRecipe(
        name: recipeData['name']!,
        category: recipeData['category']!,
        difficulty: recipeData['difficulty']!,
        prepTime: recipeData['prepTime']!,
        cookTime: recipeData['cookTime']!,
        servings: recipeData['servings']!,
        description: recipeData['description']!,
        imageUrl: recipeData['imageUrl']!,
      );
      print('DEBUG: Recipe saved to Firebase successfully');

      // Store recipe name for notification before clearing
      final recipeName = recipeData['name']!;

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Clear form
        _nameController.clear();
        _categoryController.clear();
        _difficultyController.clear();
        _prepTimeController.clear();
        _cookTimeController.clear();
        _servingsController.clear();
        _descriptionController.clear();
        setState(() => _image = null);
        
        // Show notification for recipe added
        NotificationService.showRecipeAddedNotification(context, recipeName);
        
        // Show success dialog
        await UserFeedback.showSuccessDialog(
          context,
          title: 'Success',
          message: 'Recipe added successfully!',
          onDismiss: () => Navigator.pop(context),
        );
      }
    } on FirebaseException catch (e) {
      print('DEBUG: Firebase Exception: ${e.code} - ${e.message}');
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        UserFeedback.showErrorDialog(
          context,
          title: 'Firebase Error',
          message: 'Failed to save recipe: ${e.message}',
          onRetry: _saveRecipe,
        );
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      print('DEBUG: General Exception: $e');
      print('DEBUG: Stack trace: $stackTrace');
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
      print('DEBUG: Recipe save process completed');
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
                  controller: _nameController,
                  label: "Recipe Name *",
                  hint: "e.g., Chocolate Cake"),
              const SizedBox(height: 15),
              _buildTextField(
                  controller: _categoryController,
                  label: "Category *",
                  hint: "Dessert"),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _prepTimeController,
                      label: "Prep Time (min)",
                      hint: "15",
                      validator: (value) => FormValidator.validateTime(value, 'Prep Time'),
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
                      validator: (value) => FormValidator.validateTime(value, 'Cook Time'),
                      onChanged: (value) => _formHandler.setFieldValue('cookTime', value),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _buildTextField(
                  controller: _prepTimeController,
                  label: "Prep Time (min)",
                  hint: "15",
                  keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              _buildTextField(
                  controller: _cookTimeController,
                  label: "Cook Time (min)",
                  hint: "30",
                  keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              _buildTextField(
                  controller: _servingsController,
                  label: "Servings",
                  hint: "4",
                  keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              _buildTextField(
                  controller: _descriptionController,
                  label: "Description",
                  hint: "Write short details about your recipe...",
                  maxLines: 3,
                  keyboardType: TextInputType.multiline),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      textInputAction: maxLines == 1 ? TextInputAction.next : null,
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
      validator: validator ?? (value) {
        if (label.contains('*') && (value == null || value.isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
    );
  }
}
