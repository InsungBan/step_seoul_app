import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firebase Test',
      home: const ShoeTestPage(),
    );
  }
}

class ShoeTestPage extends StatefulWidget {
  const ShoeTestPage({super.key});

  @override
  State<ShoeTestPage> createState() => _ShoeTestPageState();
}

class _ShoeTestPageState extends State<ShoeTestPage> {
  String? imageUrl;
  String? errorMessage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadShoe();
  }

  Future<void> loadShoe() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('shoe')
          .doc('airforce_280_m_black_00')
          .get();

      if (!snapshot.exists) {
        setState(() {
          isLoading = false;
          errorMessage = 'airforce_280_m_black_00 문서가 없습니다.';
        });
        return;
      }

      final data = snapshot.data();

      print('Firestore 데이터: $data');

      final url = data?['shoeImage'];

      if (url == null || url.toString().isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'shoeImage 필드가 없습니다.';
        });
        return;
      }

      setState(() {
        imageUrl = url.toString();
        isLoading = false;
      });

      print('이미지 URL: $imageUrl');
    } catch (e) {
      print('Firestore 오류: $e');

      setState(() {
        isLoading = false;
        errorMessage = 'Firestore 오류\n$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('신발 이미지 테스트'),
      ),
      body: Center(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const CircularProgressIndicator();
    }

    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          errorMessage!,
          textAlign: TextAlign.center,
        ),
      );
    }

    if (imageUrl == null) {
      return const Text('이미지 URL이 없습니다.');
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            imageUrl!,
            width: 300,
            height: 300,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }

              return const SizedBox(
                width: 300,
                height: 300,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              print('이미지 로딩 오류: $error');

              return const SizedBox(
                width: 300,
                height: 300,
                child: Center(
                  child: Text(
                    '이미지를 불러오지 못했습니다.',
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          const Text(
            'Firestore에서 가져온 이미지',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              imageUrl!,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}