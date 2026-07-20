import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'add_car_screen.dart';
import 'new_booking_screen.dart';
import 'add_user_screen.dart';

// ADMIN PAGES
import 'manage_cars_screen.dart';
import 'manage_users.dart';
import 'manage_bookings.dart';
import 'edit_booking_screen.dart';
import 'manage_chauffeurs_screen.dart';
import 'manage_reviews_screen.dart';
import 'view_payments.dart';
import 'login_screen.dart';
import 'chatbot_screen.dart';
import '../widgets/admin_charts.dart';
import '../services/notification_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // ignore: unawaited_futures
    NotificationService.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Gulf Limousine Admin",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.orange),
      ),

      /// 🔥 DRAWER
      drawer: Drawer(
        child: Container(
          color: Colors.black,
          child: ListView(
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.orange),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.admin_panel_settings,
                        color: Colors.white, size: 40),
                    SizedBox(height: 10),
                    Text(
                      "Admin Panel",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              _drawerItem(
                context,
                Icons.directions_car,
                "Manage Cars",
                const ManageCarsScreen(),
              ),
              _drawerItem(
                context,
                Icons.people,
                "Users",
                const ManageUsersScreen(),
              ),
              _drawerItem(
                context,
                Icons.calendar_today,
                "Bookings",
                const ManageBookingsScreen(),
              ),
              _drawerItem(
                context,
                Icons.badge,
                "Chauffeurs",
                const ManageChauffeursScreen(),
              ),
              _drawerItem(
                context,
                Icons.star,
                "Reviews",
                const ManageReviewsScreen(),
              ),
              _drawerItem(
                context,
                Icons.attach_money,
                "Payments",
                const ViewPaymentsScreen(),
              ),
              _drawerItem(
                context,
                Icons.smart_toy,
                "Ask AI",
                const ChatbotScreen(userName: 'Admin', adminMode: true),
              ),

              const Divider(color: Colors.white54),

              /// 🔴 LOGOUT BUTTON
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  _confirmLogout(context);
                },
              ),
            ],
          ),
        ),
      ),

      /// 🧠 BODY
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          // Clear Android system nav so Recent Bookings stay scrollable
          24 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Dashboard Overview",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            /// 📊 LIVE STATS
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              children: [
                _statCard(
                  "Total Cars",
                  firestore.collection('cars'),
                  Icons.directions_car,
                ),
                _statCard(
                  "Bookings",
                  firestore.collection('bookings'),
                  Icons.calendar_today,
                ),
                _statCard(
                  "Users",
                  firestore.collection('users'),
                  Icons.people,
                ),
                _revenueCard(),
                _extraKmPendingCard(),
                _extraKmCollectedCard(),
              ],
            ),

            const SizedBox(height: 16),
            _pendingExtraKmSection(),

            const SizedBox(height: 25),

            AdminAnalyticsSection(firestore: firestore),

            const SizedBox(height: 25),

            /// ⚡ QUICK ACTIONS
            const Text(
              "Quick Actions",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                QuickActionButton(
                  icon: Icons.add,
                  label: "Add Car",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddCarScreen(),
                    ),
                  ),
                ),
                QuickActionButton(
                  icon: Icons.confirmation_number,
                  label: "New Booking",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NewBookingScreen(),
                    ),
                  ),
                ),
                QuickActionButton(
                  icon: Icons.person_add,
                  label: "Add User",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddUserScreen(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            /// 🕒 RECENT BOOKINGS
            const Text(
              "Recent Bookings",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('bookings')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final extraLabel = bookingHasExtraKmCharge(data)
                        ? ' · ${extraKmPaymentStatusLabel(data)}'
                        : '';
                    return _bookingTile(
                      resolveBookingName(data),
                      resolveBookingCar(data),
                      resolveBookingDateLabel(data),
                      '${(data['status'] ?? 'pending').toString()}$extraLabel',
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🔐 LOGOUT CONFIRMATION
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                    (route) => false,
              );
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  /// 🔢 STAT CARD
  Widget _statCard(String title, Query query, IconData icon) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return DashboardCard(
          title: title,
          value: count.toString(),
          icon: icon,
        );
      },
    );
  }

  /// 💰 REVENUE
  Widget _revenueCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('payments').snapshots(),
      builder: (context, snapshot) {
        double total = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if ((data['status'] ?? '').toString() == 'paid') {
              total += (data['amount'] ?? 0).toDouble();
            }
          }
        }
        return DashboardCard(
          title: "Revenue (paid)",
          value: "EGP ${total.toStringAsFixed(0)}",
          icon: Icons.attach_money,
        );
      },
    );
  }

  Widget _extraKmPendingCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('bookings').snapshots(),
      builder: (context, snapshot) {
        final stats = computeExtraKmStats(snapshot.data?.docs ?? []);
        return DashboardCard(
          title: "Pending Extra KM",
          value: stats.pendingCount.toString(),
          icon: Icons.pending_actions,
        );
      },
    );
  }

  Widget _extraKmCollectedCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('bookings').snapshots(),
      builder: (context, snapshot) {
        final stats = computeExtraKmStats(snapshot.data?.docs ?? []);
        return DashboardCard(
          title: "Extra KM Collected",
          value: "EGP ${stats.paidAmount.toStringAsFixed(0)}",
          icon: Icons.add_road,
        );
      },
    );
  }

  Widget _pendingExtraKmSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('bookings').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final pending = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return bookingHasExtraKmCharge(data) &&
              (data['extraKmPaymentStatus'] ?? '') == 'pending';
        }).toList();

        if (pending.isEmpty) {
          return const SizedBox.shrink();
        }

        final stats = computeExtraKmStats(snapshot.data!.docs);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Pending Extra KM Payments",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageBookingsScreen(),
                      ),
                    );
                  },
                  child: const Text('Manage all'),
                ),
              ],
            ),
            Text(
              '${stats.pendingCount} booking(s) · '
              'EGP ${stats.pendingAmount.toStringAsFixed(0)} due',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            ...pending.take(3).map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final km = parseKmAllowance(data);
              final charge =
                  (km?['extraKmChargeEgp'] as num?)?.toDouble() ?? 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.speed, color: Colors.white, size: 20),
                  ),
                  title: Text(resolveBookingName(data)),
                  subtitle: Text(
                    '${resolveBookingCar(data)} · '
                    '${km?['extraKm'] ?? 0} extra km',
                  ),
                  trailing: Text(
                    'EGP ${charge.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditBookingScreen(
                          bookingId: doc.id,
                          bookingData: data,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        );
      },
    );
  }

  static Widget _drawerItem(
      BuildContext context,
      IconData icon,
      String title,
      Widget page,
      ) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
    );
  }

  static Widget _bookingTile(
    String name,
    String car,
    String date,
    String status,
  ) {
    Color statusColor = Colors.orange;
    if (status.toLowerCase() == 'paid' || status.toLowerCase() == 'confirmed') {
      statusColor = Colors.green;
    } else if (status.toLowerCase() == 'cancelled' ||
        status.toLowerCase() == 'failed') {
      statusColor = Colors.red;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(name),
        subtitle: Text('$car · $status'),
        trailing: date.isNotEmpty
            ? Text(date, style: const TextStyle(color: Colors.orange, fontSize: 12))
            : Chip(
                label: Text(
                  status,
                  style: TextStyle(fontSize: 11, color: statusColor),
                ),
                backgroundColor: statusColor.withValues(alpha: 0.12),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.orange, size: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
