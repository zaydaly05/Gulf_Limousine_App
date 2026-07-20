import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageChauffeursScreen extends StatelessWidget {
  const ManageChauffeursScreen({super.key});

  Future<void> _delete(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Delete chauffeur?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will remove the chauffeur from the roster.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseFirestore.instance.collection('chauffeurs').doc(id).delete();
    }
  }

  Future<void> _openForm(
    BuildContext context, {
    String? id,
    Map<String, dynamic>? data,
  }) async {
    final name = TextEditingController(text: data?['name']?.toString() ?? '');
    final phone = TextEditingController(text: data?['phone']?.toString() ?? '');
    var active = data?['active'] != false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            backgroundColor: Colors.grey.shade900,
            title: Text(
              id == null ? 'Add Chauffeur' : 'Edit Chauffeur',
              style: const TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                TextField(
                  controller: phone,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Active',
                      style: TextStyle(color: Colors.white70)),
                  value: active,
                  activeThumbColor: Colors.orange,
                  onChanged: (v) => setLocal(() => active = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (name.text.trim().isEmpty) return;
                  final payload = {
                    'name': name.text.trim(),
                    'phone': phone.text.trim(),
                    'active': active,
                    'updatedAt': FieldValue.serverTimestamp(),
                  };
                  if (id == null) {
                    payload['createdAt'] = FieldValue.serverTimestamp();
                    await FirebaseFirestore.instance
                        .collection('chauffeurs')
                        .add(payload);
                  } else {
                    await FirebaseFirestore.instance
                        .collection('chauffeurs')
                        .doc(id)
                        .update(payload);
                  }
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                child: const Text('Save', style: TextStyle(color: Colors.orange)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Manage Chauffeurs'),
        backgroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _openForm(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chauffeurs').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No chauffeurs yet. Tap + to add one.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              80 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final active = data['active'] != false;
              return Card(
                color: Colors.grey.shade900,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.withValues(alpha: 0.2),
                    child: const Icon(Icons.person, color: Colors.orange),
                  ),
                  title: Text(
                    data['name']?.toString() ?? 'Chauffeur',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${data['phone'] ?? ''}${active ? '' : ' · Inactive'}',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _openForm(context, id: doc.id, data: data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _delete(context, doc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
