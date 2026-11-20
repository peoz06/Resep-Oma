import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/recipe_service.dart';

class NotificationsSheet extends StatelessWidget {
  final String? uid;

  const NotificationsSheet({super.key, this.uid});

  static void show(BuildContext context, {String? uid}) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => NotificationsSheet(uid: uid),
      );

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const Expanded(
                  child: Text('Notifikasi',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold))),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ]),
            if (uid == null)
              const Text('Masuk akun untuk melihat aktivitas resep Anda.')
            else
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: RecipeService.watchNotifications(uid!),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Gagal memuat notifikasi.');
                  }
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  final items = snapshot.data!.docs.toList()
                    ..sort((a, b) {
                      final dateA = (a.data()['createdAt'] as Timestamp?)
                              ?.millisecondsSinceEpoch ??
                          0;
                      final dateB = (b.data()['createdAt'] as Timestamp?)
                              ?.millisecondsSinceEpoch ??
                          0;
                      return dateB.compareTo(dateA);
                    });
                  if (items.isEmpty) {
                    return const Text('Belum ada aktivitas baru.');
                  }
                  return Flexible(
                      child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final data = item.data();
                      final action = switch (data['kind']) {
                        'like' => 'menyukai',
                        'recook' => 'memasak ulang',
                        _ => 'mengulas',
                      };
                      return ListTile(
                        leading: Icon(data['seen'] == true
                            ? Icons.notifications_none
                            : Icons.notifications_active),
                        title:
                            Text('Seseorang $action resep "${data['title']}"'),
                        subtitle: Text(data['seen'] == true
                            ? 'Sudah dibaca'
                            : 'Ketuk untuk tandai dibaca'),
                        onTap: data['seen'] == true
                            ? null
                            : () async {
                                try {
                                  await RecipeService.markNotificationRead(item.id);
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Gagal menandai notifikasi dibaca.')),
                                    );
                                  }
                                }
                              },
                      );
                    },
                  ));
                },
              ),
          ]),
        ),
      );
}
