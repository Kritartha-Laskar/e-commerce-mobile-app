import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import '../services/product_store_api.dart';
import '../services/cataegori_api.dart';
import '../topbotam/topbar.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final discountController = TextEditingController();
  final quantityController = TextEditingController();

  List<File> imageFiles = [];
  List<Uint8List> webImages = [];

  List<dynamic> categories = [];
  int? selectedCategoryId;
  bool isCategoriesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
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

  // ❌ REMOVE IMAGE
  void removeImage(int index) {
    setState(() {
      if (kIsWeb) {
        webImages.removeAt(index);
      } else {
        imageFiles.removeAt(index);
      }
    });
  }

  // 🚀 API CALL
  Future<void> uploadProduct() async {
    var result = await ProductStoreApi.addProduct(
      productName: nameController.text,
      categoryId: selectedCategoryId.toString(),
      price: priceController.text,
      discount: discountController.text,
      quantity: quantityController.text,
      imageFiles: imageFiles,
      webImages: webImages,
    );

    if (!mounted) return;

    if (result["success"]) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product Added Successfully")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "Error")),
      );
    }
  }

  // 🖼 IMAGE WIDGET (SAFE)
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
            child: const Icon(Icons.close, color: Colors.red),
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
                  "Add Product",
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
                    children: [
              _input(nameController, "Product Name"),
              _categoryDropdown(),
              _input(priceController, "Price", true),
              _input(discountController, "Discount", true),
              _input(quantityController, "Quantity", true),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: pickImageDialog,
                child: const Text("Add Image"),
              ),

              Wrap(
                children: List.generate(
                  images.length,
                  (i) => buildImage(images[i], i),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    uploadProduct();
                  }
                },
                child: const Text("Submit"),
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
    return TextFormField(
      controller: c,
      keyboardType: num ? TextInputType.number : TextInputType.text,
      validator: (v) => v!.isEmpty ? "Required" : null,
      decoration: InputDecoration(labelText: hint),
    );
  }

  Widget _categoryDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<int>(
        value: selectedCategoryId,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: "Category",
          border: UnderlineInputBorder(),
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