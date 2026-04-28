import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fasum_jovannathanieljie/screens/detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasum_jovannathanieljie/screens/sign_in_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCategory;

  List<String> categories = [
    'Jalan Rusak',
    'Marka Pudar',
    'Lampu Mati',
    'Trotoar Rusak',
    'Rambu Rusak',
    'Jembatan Rusak',
    'Sampah Menumpuk',
    'Sungai Tercemar',
    'Sampah Sungai',
    'Pohon Tumbang',
    'Taman Rusak',
    'Fasilitas Rusak',
    'Pipa Bocor',
    'Vandalisme',
    'Banjir',
    'Lainnya',
    ];

    String formatTime (DateTime datetime) {
      final now = DateTime.now();
      final diff =now.difference(datetime);
      if (diff.inSeconds < 60) {
        return '${diff.inSeconds} secs ago';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} mins ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} hrs ago';
      } else if (diff.inDays < 48) {
        return '1 days ago';
      } else {
        return DateFormat('HH:mm').format(datetime); // Menggunakan intl lebih rapi
      }
    }

    Future<void> signOut() async {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
        (route) => false,
      );
    }

    void _showCategoryFilter() async {
      final result = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  ListTile(
                    leading: const Icon(Icons.clear),
                    title: const Text('Semua Kategori'),
                    onTap:
                      () => Navigator.pop(context, null), // null untuk memilih semua kategori
                  ),
                  const Divider(),
                  ...categories.map((category) => ListTile(
                    title: Text(category),
                    trailing: _selectedCategory == category ? 
                      Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
                    onTap: () => Navigator.pop(context, category),
                  ),
              ),
            ],
          ),
        )
        );
      }, // Tutup builder
    );
    if (result != null) {
      setState(() {
        _selectedCategory = result;
      });
    } else {
      setState(() {
        _selectedCategory = null; // Reset filter jika batal
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar (
        title: Text('Fasum', style: TextStyle(color: Colors.green[600], fontWeight: FontWeight.bold),),
        actions: [
          IconButton(
            onPressed: _showCategoryFilter,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Kategori',
          ),
          IconButton(
            onPressed: () {
              signOut();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final posts = snapshot.data!.docs.where((doc) {
              final data = doc.data();
              final category = data['category'] ?? 'Lainnya';
              return _selectedCategory == null || category == _selectedCategory;
            }).toList();

            if (posts.isEmpty) {
              return const Center(child: Text('Belum ada laporan untuk kategori ini'));
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final data = posts [index].data();
                final imageBase64 = data['image'];
                final description = data['description'];
                final createdAtStr = data['createdAt'];
                final fullName = data['fullName'] ?? 'Anonymous';
                final latitude = data['latitude'];
                final longitude = data['longitude'];
                final category = data['category'] ?? 'Lainnya';
                final createdAt = DateTime.parse(createdAtStr);
                String heroTag =
                  'fasum-image-${createdAt.millisecondsSinceEpoch}';
                
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(
                          imageBase64: imageBase64,
                          description: description,
                          createdAt: createdAt,
                          fullName: fullName,
                          latitude: latitude,
                          longitude: longitude,
                          category: category,
                          heroTag: heroTag,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if(imageBase64 != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(10)
                          ),
                          child: Hero(
                            tag: heroTag,
                            child: Image.memory(
                              base64Decode(imageBase64),
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8,),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                formatTime(createdAt),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                description ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        ),
                    ]
                  )
                );
              }
            );
          },
      )
    ),
  );
  }
}