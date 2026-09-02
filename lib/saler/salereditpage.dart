import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
import '../services/product_store_api.dart';
import '../services/cataegori_api.dart';
import '../topbotam/topbar.dart';
import '../widgets/ngrok_image.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController discountController;
  late TextEditingController quantityController;

  List<File> imageFiles = [];
  List<Uint8List> webImages = [];
  List<dynamic> existingImages = [];

  List<dynamic> categories = [];
  int? selectedCategoryId;
  bool isCategoriesLoading = true;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product.productName);
    priceController = TextEditingController(text: widget.product.price);
    
    // Parse discount and availability from rawJson
    final rawDiscount = widget.product.rawJson['discount']?.toString() ?? '0';
    final rawQuantity = widget.product.rawJson['avail_count']?.toString() ?? '0';
    discountController = TextEditingController(text: rawDiscount);
    quantityController = TextEditingController(text: rawQuantity);

    // Load existing images
    existingImages = List<dynamic>.from(widget.product.images);

    // Determine selected category ID
    final catId = widget.product.category?['id'] ?? widget.product.rawJson['category_id'];
    if (catId != null) {
      selectedCategoryId = catId is int ? catId : int.tryParse(catId.toString());
    }

    _loadCategories();
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    discountController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final fetched = await CategoryApi.getCategories();
    if (!mounted) return;
    setState(() {
      categories = fetched;
      isCategoriesLoading = false;
    });
  }

  // 📸 PICK IMAGE
  Future<void> pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);

    if (picked != null) {
      final bytes = await picked.readAsBytes();

      setState(() {
        if (kIsWeb) {
          webImages.add(bytes);
        } else {
          imageFiles.add(File(picked.path));
        }
      });
    }
  }

  // 📸 DIALOG
  void pickImageDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera),
            title: const Text("Camera"),
            onTap: () {
              Navigator.pop(context);
              pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text("Gallery"),
            onTap: () {
              Navigator.pop(context);
              pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  // ❌ REMOVE NEW IMAGE
  void removeImage(int index) {
    setState(() {
      if (kIsWeb) {
        webImages.removeAt(index);
      } else {
        imageFiles.removeAt(index);
      }
    });
  }

  // ❌ DELETE EXISTING IMAGE FROM BACKEND
  Future<void> deleteExistingImage(int imageId, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Image"),
        content: const Text("Are you sure you want to permanently delete this image from the product?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show inline loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await ProductStoreApi.deleteProductImage(imageId);

    if (!mounted) return;
    Navigator.pop(context); // Close loading indicator

    if (result["success"]) {
      setState(() {
        existingImages.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image deleted successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "Failed to delete image")),
      );
    }
  }

  // 🚀 UPDATE PRODUCT API CALL
  Future<void> updateProduct() async {
    setState(() => isUpdating = true);

    var result = await ProductStoreApi.updateProduct(
      productId: widget.product.id,
      productName: nameController.text,
      categoryId: selectedCategoryId.toString(),
      price: priceController.text,
      discount: discountController.text,
      quantity: quantityController.text,
      imageFiles: imageFiles,
      webImages: webImages,
    );

    if (!mounted) return;
    setState(() => isUpdating = false);

    if (result["success"]) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product Updated Successfully")),
      );
      Navigator.pop(context, true); // Pop back with success indicator
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "Error updating product")),
      );
    }
  }

  // 🖼 NEW IMAGE WIDGET (SAFE)
  Widget buildImage(dynamic image, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: kIsWeb
              ? Image.memory(
                  image,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                )
              : Image.file(
                  image,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
        ),
        Positioned(
          right: 0,
          child: GestureDetector(
            onTap: () => removeImage(index),
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: Colors.white,
              child: Icon(Icons.close, color: Colors.red, size: 16),
            ),
          ),
        )
      ],
    );
  }

  // 🖼 EXISTING IMAGE WIDGET
  Widget buildExistingImage(dynamic imageMap, int index) {
    final imagePath = imageMap['image']?.toString() ?? '';
    final imageUrl = ProductModel.buildImageUrl(imagePath);
    final imageId = imageMap['id'] is int 
        ? imageMap['id'] as int 
        : int.tryParse(imageMap['id']?.toString() ?? '');

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: NgrokImage(
            imageUrl: imageUrl,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        if (imageId != null)
          Positioned(
            right: 0,
            child: GestureDetector(
              onTap: () => deleteExistingImage(imageId, index),
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.white,
                child: Icon(Icons.close, color: Colors.red, size: 16),
              ),
            ),
          )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = kIsWeb ? webImages : imageFiles;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 20, left: 20, right: 20),
              child: TopBar(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  "Edit Product",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _input(nameController, "Product Name"),
                      _categoryDropdown(),
                      _input(priceController, "Price", true),
                      _input(discountController, "Discount", true),
                      _input(quantityController, "Quantity", true),
                      const SizedBox(height: 20),

                      // Existing Images Section
                      if (existingImages.isNotEmpty) ...[
                        const Text(
                          "Existing Images",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF6A5AE0),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: List.generate(
                            existingImages.length,
                            (i) => buildExistingImage(existingImages[i], i),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // New Images Section
                      const Text(
                        "Add New Images",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF6A5AE0),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: pickImageDialog,
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text("Select Image"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1EEFF),
                          foregroundColor: const Color(0xFF6A5AE0),
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (images.isNotEmpty)
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: List.generate(
                            images.length,
                            (i) => buildImage(images[i], i),
                          ),
                        ),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isUpdating
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    updateProduct();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A5AE0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: isUpdating
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  "Update Product",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String hint, [bool num = false]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: c,
        keyboardType: num ? TextInputType.number : TextInputType.text,
        validator: (v) => v!.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          labelText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6A5AE0), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _categoryDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<int>(
        value: selectedCategoryId,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: "Category",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6A5AE0), width: 2),
          ),
        ),
        hint: Text(
          isCategoriesLoading
              ? "Loading categories..."
              : categories.isEmpty
                  ? "No categories available"
                  : "Select category",
        ),
        items: categories
            .map((category) {
              final id = category['id'] is int
                  ? category['id'] as int
                  : int.tryParse(category['id']?.toString() ?? '');
              final name = category['name']?.toString() ?? 'Unknown';
              if (id == null) return null;
              return DropdownMenuItem<int>(
                value: id,
                child: Text(name),
              );
            })
            .whereType<DropdownMenuItem<int>>()
            .toList(),
        onChanged: isCategoriesLoading || categories.isEmpty
            ? null
            : (value) {
                setState(() => selectedCategoryId = value);
              },
        validator: (value) {
          if (value == null) {
            return categories.isEmpty
                ? "No categories found"
                : "Please select a category";
          }
          return null;
        },
      ),
    );
  }
}
