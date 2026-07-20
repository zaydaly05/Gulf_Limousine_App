import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cloudinary_service.dart';

class EditCarScreen extends StatefulWidget {
  final String carId;
  final Map<String, dynamic> carData;

  const EditCarScreen({
    super.key,
    required this.carId,
    required this.carData,
  });

  @override
  State<EditCarScreen> createState() => _EditCarScreenState();
}

class _EditCarScreenState extends State<EditCarScreen> {
  late TextEditingController nameController;
  late TextEditingController brandController;
  late TextEditingController priceController;

  final CloudinaryService cloudinary = CloudinaryService();

  String? imageUrl;
  String? publicId;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    nameController =
        TextEditingController(text: widget.carData['name']);
    brandController =
        TextEditingController(text: widget.carData['brand']);
    priceController = TextEditingController(
        text: widget.carData['price_per_day'].toString());

    imageUrl = widget.carData['image_url'];
    publicId = widget.carData['public_id'];
  }

  Future<void> replaceImage() async {
    final imageData = await cloudinary.uploadImage();
    if (imageData == null) return;

    // delete old image if exists
    if (publicId != null && publicId!.isNotEmpty) {
      await cloudinary.deleteImage(publicId!);
    }

    setState(() {
      imageUrl = imageData['url'];
      publicId = imageData['public_id'];
    });
  }

  Future<void> updateCar() async {
    try {
      setState(() => isLoading = true);

      await FirebaseFirestore.instance
          .collection('cars')
          .doc(widget.carId)
          .update({
        'name': nameController.text,
        'brand': brandController.text,
        'price_per_day':
        double.parse(priceController.text),
        'image_url': imageUrl,
        'public_id': publicId,
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Edit Car"),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                /// IMAGE PREVIEW
                if (imageUrl != null && imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl!,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: Colors.orange,
                      size: 80,
                    ),
                  ),

                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: replaceImage,
                  child: const Text("Replace Image"),
                ),

                const SizedBox(height: 20),

                buildTextField(nameController, "Car Name"),
                buildTextField(brandController, "Brand"),
                buildTextField(
                  priceController,
                  "Price Per Day",
                  isNumber: true,
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: updateCar,
                  child: const Text("Update Car"),
                ),
              ],
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.orange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildTextField(
      TextEditingController controller,
      String label, {
        bool isNumber = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType:
        isNumber ? TextInputType.number : null,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
          const TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide:
            BorderSide(color: Colors.grey.shade700),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide:
            const BorderSide(color: Colors.orange),
          ),
        ),
      ),
    );
  }
}
