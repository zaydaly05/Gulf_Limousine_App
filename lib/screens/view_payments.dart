import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ViewPaymentsScreen extends StatelessWidget {
  const ViewPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔹 HEADER
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "View Payments",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // 🔹 PAYMENTS LIST
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('payments')
                    .orderBy('payment_date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No payments found",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {

                      final payment =
                      snapshot.data!.docs[index].data()
                      as Map<String, dynamic>;

                      // 🔹 Format Date
                      String formattedDate = "";
                      if (payment['payment_date'] != null) {
                        Timestamp timestamp = payment['payment_date'];
                        DateTime date = timestamp.toDate();
                        formattedDate =
                            DateFormat('dd MMM yyyy - hh:mm a')
                                .format(date);
                      }

                      // 🔹 Status Color
                      Color statusColor = Colors.orange;
                      if (payment['status'] == "paid") {
                        statusColor = Colors.green;
                      } else if (payment['status'] == "failed") {
                        statusColor = Colors.red;
                      }

                      return Card(
                        color: Colors.grey.shade900,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin:
                        const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [

                              // 🔹 Amount Row
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${payment['amount']} EGP",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),

                                  // 🔹 Status Badge
                                  Container(
                                    padding: const EdgeInsets
                                        .symmetric(
                                        horizontal: 10,
                                        vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      borderRadius:
                                      BorderRadius.circular(
                                          20),
                                    ),
                                    child: Text(
                                      payment['status'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight:
                                        FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // 🔹 Details
                              Text(
                                "User: ${payment['user_email']}",
                                style: TextStyle(
                                    color: Colors.grey.shade400),
                              ),
                              Text(
                                "Method: ${payment['method']}",
                                style: TextStyle(
                                    color: Colors.grey.shade400),
                              ),
                              Text(
                                "Date: $formattedDate",
                                style: TextStyle(
                                    color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
