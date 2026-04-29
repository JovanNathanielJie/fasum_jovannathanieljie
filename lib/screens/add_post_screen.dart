import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  File? _image;
  String? _based64Image;
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  double? _latitude;
  double? _longitude;
  String? _aiCategory;
  String? _aiDescription;
  bool _isGenerating = false;
  List<String> categories = [
    'Jalan Rusak',
    'Marka Pudar',
    'Lampu Mati',
    'Trotoar Rusak',
    'Rambu Rusak',
    'Jembatan Rusak',
    'Sampah Menumpuk',
    'Saluran Tersumbat',
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

  void _showCategorySelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return ListView(
          shrinkWrap: true,
          children:
          categories.map((category) {
            return ListTile(
              title: Text(category),
              onTap: () {
                setState(() {
                  _aiCategory = category; // Ganti AI category dengan pilihan user
                });
                Navigator.pop(context);
              },
            );
          }).toList()
        );
      },
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _aiCategory = null;
          _aiDescription = null;
          _descriptionController.clear();
        });
        await _compressAndEncodeImage();
        await _generateDescriptionWithAI();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _compressAndEncodeImage() async {
    if (_image == null) return;
    try {
      final compressedImage = await FlutterImageCompress.compressWithFile(
        _image!.path,
        quality: 50,
      );
      if (compressedImage == null) return;
      setState(() {
        _based64Image = base64Encode(compressedImage);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to compress image: $e')),
        );
      }
    }
  }

  Future<void> _generateDescriptionWithAI() async {
    if (_image == null) return;
    setState(() => _isGenerating = true);
    try {
      final model = GenerativeModel(model: 'gemini-1.5-pro', apiKey: 'AIzaSyC_jkUoq48gu-Yvp-WbO9tdcpNizaCMK-E');
      final imageBytes = await _image!.readAsBytes();
      final content = Content.multi([
        DataPart('image/jpeg', imageBytes),
        TextPart(
          'Berdasarkan foto ini, identifikasi satu kategori utana kerusakan fasilitas umum '
          ' dari daftar berikut: Jalan Rusak, Harka Pudan, Lampu Mati, Trotoar Rusak, '
          ' Ranbu Rusak, Jembatan Rusak, Sampah Menumpuk, Saluran Tersumbat, Sungai Tercemar, '
          ' Sampah Sungai, Pohon Tumbang, Tanan Rusak, Fasilitas Rusak, Pipa Bocor, '
          ' Vandalisme, Banjir, dan Lainnya. '
          ' Pilih kategori yang paling dominan atau paling mendesak untuk dilaporkan. '
          ' Buat deskripsi singkat untuk laporan perbaikan, dan tambahkan permohonan perbaikan. '
          ' Fokus pada kerusakan yang terlihat dan hindari spekulasi.\n\n'
          ' Format output yang diinginkan:\n '
          ' Kategori: [satu kategori yang dipilih]\n'
          ' Deskripsi: [deskripsi singkat]',
        ),
      ]);
      final response = await model.generateContent([content]);
      final aiText = response.text;
      print('AI TEXT: $aiText');
      if (aiText != null && aiText.isNotEmpty) {
        final lines = aiText.trim().split('\n');
        String? category;
        String? description;
        for (var line in lines) {
          final lower = line.toLowerCase();
          if (lower.startsWith('kategori:')) {
            category = line.substring(9).trim();
          } else if (lower.startsWith('deskripsi:')) {
            description = line.substring(10).trim();
          } else if (lower.startsWith('keterangan:')) {
            description = line.substring(11).trim();
          }
        }
        description ??= aiText.trim();
        setState(() {
          _aiCategory = category ?? 'Tidak Diketahui';
          _aiDescription = description!;
          _descriptionController.text = _aiDescription!;
        });
      }
      } catch (e) {
        debugPrint('Failed to generate AI description: $e');
      } finally {
        if (mounted) setState(() => _isGenerating = false);
      }
    }
  

  Future<void> _getLocation() async {

  }

  Future<void> _submitPost() async {

  }

  void _showImageSourceDialog() {

  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}