import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cloudinary_service.dart';

class AddCarScreen extends StatefulWidget {
  const AddCarScreen({super.key});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController name = TextEditingController();
  final TextEditingController brand = TextEditingController();
  final TextEditingController price = TextEditingController();
  final TextEditingController seats = TextEditingController();

  final CloudinaryService cloudinary = CloudinaryService();

  String fuelType = "Petrol";
  bool _isLoading = false;

  String? imageUrl;
  String? publicId;

  /// 🚗 ADD CAR
  Future<void> _addCar() async {
    if (!_formKey.currentState!.validate()) return;

    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please upload a car image"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      await FirebaseFirestore.instance.collection('cars').add({
        'name': name.text.trim(),
        'brand': brand.text.trim(),
        'price_per_day': double.parse(price.text.trim()),
        'seats': int.parse(seats.text.trim()),
        'fuel_type': fuelType,
        'image_url': imageUrl,
        'public_id': publicId,
        'available': true,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Car added successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 📷 Upload image to Cloudinary
  Future<void> _uploadImage() async {
    try {
      setState(() => _isLoading = true);

      final imageData = await cloudinary.uploadImage();

      if (imageData != null) {
        setState(() {
          imageUrl = imageData['secure_url'];
          publicId = imageData['public_id'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Image uploaded successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Add New Car"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              /// 🖼 IMAGE UPLOAD
              GestureDetector(
                onTap: _uploadImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(16),
                    image: imageUrl != null
                        ? DecorationImage(
                      image: NetworkImage(imageUrl!),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: imageUrl == null
                      ? const Center(
                    child: Icon(
                      Icons.add_a_photo,
                      size: 50,
                      color: Colors.white70,
                    ),
                  )
                      : null,
                ),
              ),

              const SizedBox(height: 20),

              _input("Car Name", name),
              _input("Brand", brand),
              _input("Price per Day", price,
                  type: TextInputType.number),
              _input("Number of Seats", seats,
                  type: TextInputType.number),

              const SizedBox(height: 10),
              const Text(
                "Fuel Type",
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 5),

              DropdownButtonFormField<String>(
                initialValue: fuelType,
                dropdownColor: Colors.grey.shade900,
                items: ["Petrol", "Diesel", "Electric"]
                    .map(
                      (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
                )
                    .toList(),
                onChanged: (val) => setState(() => fuelType = val!),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade800,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.all(14),
                ),
                onPressed: _isLoading ? null : _addCar,
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text("Add Car"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(
      String label,
      TextEditingController controller, {
        TextInputType type = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        validator: (v) => v!.isEmpty ? "Required" : null,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
          const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.grey.shade800,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.orange),
          ),
        ),
      ),
    );
  }
}
