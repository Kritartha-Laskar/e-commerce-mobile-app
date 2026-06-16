import 'package:flutter/material.dart';
import '../home/home_page.dart';
import '../services/user_information.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(15),
              color: Colors.white,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Add Address",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _input(addressController, "Address"),
                        _input(cityController, "City"),
                        _input(stateController, "State"),
                        _input(pincodeController, "Pincode", isNumber: true),
                        _input(countryController, "Country"),
                        _input(
                          latitudeController,
                          "Latitude",
                          isOptional: true,
                        ),
                        _input(
                          longitudeController,
                          "Longitude",
                          isOptional: true,
                        ),

                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {

                              final prefs = await SharedPreferences.getInstance();
                              String? token = prefs.getString('token');

                              if (token == null) {
                                // print("Token missing");
                                debugPrint("Token missing");
                                return;
                              }

                              bool success = await UserInformationService.addAddress(
                                token: token,
                                addressLine: addressController.text,
                                city: cityController.text,
                                state: stateController.text,
                                pincode: pincodeController.text,
                                country: countryController.text,
                                latitude: latitudeController.text.isEmpty
                                    ? null
                                    : latitudeController.text,
                                longitude: longitudeController.text.isEmpty
                                    ? null
                                    : longitudeController.text,
                              );

                              if (!mounted) return;

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Address Saved Successfully"),
                                    backgroundColor: Color(0xFF6A5AE0),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                // Pop back to AddressPage so the list reloads
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Failed to save address")),
                                );
                              }
                            }
                          },

                          child: const Text("Save"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
    bool isOptional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (value) {
          if (!isOptional && (value == null || value.isEmpty)) {
            return "Required";
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
