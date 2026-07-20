import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'cars_screen.dart';
import 'contact_screen.dart';
import 'login_screen.dart';
import 'my_bookings_screen.dart';
import 'profile_screen.dart';
import 'chatbot_screen.dart';
import 'favorites_screen.dart';
import 'notifications_inbox_screen.dart';
import '../widgets/admin_charts.dart';
import '../services/notification_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _userName = 'Guest';
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    NotificationService.instance.initialize();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!mounted) return;
    setState(() {
      _userName = doc.data()?['name'] ?? user.displayName ?? 'Guest';
      _profileImageUrl = doc.data()?['profile_image_url'] as String?;
    });
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
    await _loadUserData();
  }

  Future<void> _openChatbot() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatbotScreen(userName: _userName),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gulf Limousine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsInboxScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: _openProfile,
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openChatbot,
        backgroundColor: const Color(0xFFFF8C00),
        icon: const Icon(Icons.smart_toy_outlined),
        label: const Text('Ask AI'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            // Clear Android nav + FAB so Recent Activity stays scrollable
            88 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WelcomeBanner(name: _userName, email: email),
              const SizedBox(height: 20),
              _UserStatsSection(firestore: _firestore, userId: user?.uid, email: email),
              const SizedBox(height: 24),
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _QuickActionsGrid(
                onCars: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CarsScreen()),
                ),
                onBookings: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                ),
                onProfile: _openProfile,
                onContact: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactScreen()),
                ),
                onChatbot: _openChatbot,
              ),
              const SizedBox(height: 24),
              const Text(
                'Recent Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _RecentBookings(userId: user?.uid, email: email),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_userName),
            accountEmail: Text(_auth.currentUser?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: const Color(0xFFFF8C00),
              backgroundImage: _profileImageUrl != null &&
                      _profileImageUrl!.isNotEmpty
                  ? NetworkImage(_profileImageUrl!)
                  : null,
              child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                  ? const Icon(Icons.person, color: Colors.white, size: 36)
                  : null,
            ),
            decoration: const BoxDecoration(color: Colors.black),
          ),
          _drawerTile(Icons.home, 'Home', () => Navigator.pop(context)),
          _drawerTile(Icons.directions_car, 'Browse Cars', () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CarsScreen()));
          }),
          _drawerTile(Icons.calendar_today, 'My Bookings', () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
          }),
          _drawerTile(Icons.favorite, 'Favorites', () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()));
          }),
          _drawerTile(Icons.notifications_outlined, 'Notifications', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationsInboxScreen(),
              ),
            );
          }),
          _drawerTile(Icons.person, 'Profile', () {
            Navigator.pop(context);
            _openProfile();
          }),
          _drawerTile(Icons.phone, 'Contact', () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ContactScreen()));
          }),
          _drawerTile(Icons.smart_toy_outlined, 'AI Assistant', () {
            Navigator.pop(context);
            _openChatbot();
          }),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
        ],
      ),
    );
  }

  ListTile _drawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFF8C00)),
      title: Text(title),
      onTap: onTap,
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final String name;
  final String email;

  const _WelcomeBanner({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF000000), Color(0xFF333333)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              email,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Luxury car rentals at your fingertips',
            style: TextStyle(color: Color(0xFFFF8C00), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _UserStatsSection extends StatelessWidget {
  final FirebaseFirestore firestore;
  final String? userId;
  final String email;

  const _UserStatsSection({
    required this.firestore,
    required this.userId,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _UserStatCard(
          title: 'My Bookings',
          icon: Icons.calendar_today,
          stream: _bookingsStream(),
          valueFromSnapshot: (s) => '${s?.docs.length ?? 0}',
        ),
        _UserStatCard(
          title: 'Active',
          icon: Icons.hourglass_top,
          stream: _bookingsStream(),
          valueFromSnapshot: (s) {
            if (s == null) return '0';
            final active = s.docs.where((d) {
              final status = (d.data() as Map)['status']?.toString().toLowerCase();
              return status == 'pending' || status == 'confirmed';
            }).length;
            return '$active';
          },
        ),
        _UserStatCard(
          title: 'Available Cars',
          icon: Icons.directions_car,
          stream: firestore.collection('cars').where('available', isEqualTo: true).snapshots(),
          valueFromSnapshot: (s) => '${s?.docs.length ?? 0}',
        ),
        _UserStatCard(
          title: 'Fleet Total',
          icon: Icons.garage_outlined,
          stream: firestore.collection('cars').snapshots(),
          valueFromSnapshot: (s) => '${s?.docs.length ?? 0}',
        ),
      ],
    );
  }

  Stream<QuerySnapshot>? _bookingsStream() {
    if (userId != null) {
      return firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .snapshots();
    }
    if (email.isNotEmpty) {
      return firestore
          .collection('bookings')
          .where('user_email', isEqualTo: email)
          .snapshots();
    }
    return null;
  }
}

class _UserStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Stream<QuerySnapshot>? stream;
  final String Function(QuerySnapshot?) valueFromSnapshot;

  const _UserStatCard({
    required this.title,
    required this.icon,
    required this.stream,
    required this.valueFromSnapshot,
  });

  @override
  Widget build(BuildContext context) {
    if (stream == null) {
      return _card('0');
    }
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        return _card(valueFromSnapshot(snapshot.data));
      },
    );
  }

  Widget _card(String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: const Color(0xFFFF8C00), size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final VoidCallback onCars;
  final VoidCallback onBookings;
  final VoidCallback onProfile;
  final VoidCallback onContact;
  final VoidCallback onChatbot;

  const _QuickActionsGrid({
    required this.onCars,
    required this.onBookings,
    required this.onProfile,
    required this.onContact,
    required this.onChatbot,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _ActionTile(
          icon: Icons.directions_car,
          label: 'Browse Cars',
          color: const Color(0xFFFF8C00),
          onTap: onCars,
        ),
        _ActionTile(
          icon: Icons.calendar_today,
          label: 'My Bookings',
          color: Colors.black,
          onTap: onBookings,
        ),
        _ActionTile(
          icon: Icons.person,
          label: 'Profile',
          color: Colors.black87,
          onTap: onProfile,
        ),
        _ActionTile(
          icon: Icons.support_agent,
          label: 'Contact',
          color: const Color(0xFFFF8C00),
          onTap: onContact,
        ),
        _ActionTile(
          icon: Icons.smart_toy_outlined,
          label: 'AI Assistant',
          color: Colors.black87,
          onTap: onChatbot,
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentBookings extends StatelessWidget {
  final String? userId;
  final String email;

  const _RecentBookings({required this.userId, required this.email});

  @override
  Widget build(BuildContext context) {
    Stream<QuerySnapshot>? stream;
    if (userId != null) {
      stream = FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .limit(5)
          .snapshots();
    } else if (email.isNotEmpty) {
      stream = FirebaseFirestore.instance
          .collection('bookings')
          .where('user_email', isEqualTo: email)
          .limit(5)
          .snapshots();
    }

    if (stream == null) {
      return const Text('Sign in to see your bookings');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No recent bookings. Tap Browse Cars to get started.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? 'pending').toString();
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFF8C00).withValues(alpha: 0.2),
                  child: const Icon(Icons.directions_car, color: Color(0xFFFF8C00)),
                ),
                title: Text(resolveBookingCar(data)),
                subtitle: Text(
                  '${resolveBookingDateLabel(data)} · $status',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
