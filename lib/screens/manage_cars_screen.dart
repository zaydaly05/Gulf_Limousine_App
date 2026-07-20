import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_car_screen.dart';
import 'edit_car_screen.dart';
import '../services/cloudinary_service.dart';

class ManageCarsScreen extends StatefulWidget {
  const ManageCarsScreen({super.key});

  @override
  State<ManageCarsScreen> createState() => _ManageCarsScreenState();
}

class _ManageCarsScreenState extends State<ManageCarsScreen> {
  final CloudinaryService cloudinary = CloudinaryService();
  bool isUploading = false;

  /// Delete car confirmation + delete image from Cloudinary
  Future<void> deleteCar(
      BuildContext context,
      String id,
      String? publicId,
      ) async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text("Delete Car",
            style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to delete this car?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          TextButton(
            child: const Text("Delete",
                style: TextStyle(color: Colors.red)),
            onPressed: () async {
              // delete image from cloudinary
              if (publicId != null && publicId.isNotEmpty) {
                await cloudinary.deleteImage(publicId);
              }

              // delete firestore doc
              await FirebaseFirestore.instance
                  .collection('cars')
                  .doc(id)
                  .delete();

              Navigator.pop(dialogContext);
            },
          ),
        ],
      ),
    );
  }

  /// Pick image and upload to Cloudinary
  Future<void> pickAndUploadCarImage(String carId) async {
    try {
      setState(() => isUploading = true);

      final imageData = await cloudinary.uploadImage();

      if (imageData != null) {
        await FirebaseFirestore.instance
            .collection('cars')
            .doc(carId)
            .update({
          'image_url': imageData['secure_url'],
          'public_id': imageData['public_id'],
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image uploaded successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Manage Cars"),
        backgroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddCarScreen(),
            ),
          );
        },
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('cars')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              if (!snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    "No cars found",
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final car =
                  doc.data() as Map<String, dynamic>;

                  return Card(
                    color: Colors.grey.shade900,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(16),
                    ),
                    margin:
                    const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: car['image_url'] != null &&
                          car['image_url']
                              .toString()
                              .isNotEmpty
                          ? ClipRRect(
                        borderRadius:
                        BorderRadius.circular(8),
                        child: Image.network(
                          car['image_url'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error,
                              stackTrace) =>
                          const Icon(
                            Icons.broken_image,
                            color: Colors.red,
                          ),
                        ),
                      )
                          : const Icon(
                        Icons.directions_car,
                        color: Colors.orange,
                        size: 40,
                      ),
                      title: Text(
                        car['name'] ?? 'No Name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "${car['brand'] ?? ''} • ${car['price_per_day'] ?? ''} EGP/day",
                        style: TextStyle(
                            color: Colors.grey.shade400),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.image,
                                color: Colors.orange),
                            tooltip: 'Upload Image',
                            onPressed: () =>
                                pickAndUploadCarImage(
                                    doc.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditCarScreen(
                                        carId: doc.id,
                                        carData: car,
                                      ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            onPressed: () =>
                                deleteCar(
                                  context,
                                  doc.id,
                                  car['public_id'],
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          if (isUploading)
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
}
