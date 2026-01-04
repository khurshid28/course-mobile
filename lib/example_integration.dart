// Example integration in your main app

import 'package:flutter/material.dart';
import 'features/test/presentation/screens/test_list_screen.dart';
import 'features/test/presentation/screens/certificate_list_screen.dart';
import 'features/test/data/repositories/test_repository.dart';

class CourseDetailScreen extends StatelessWidget {
  final int courseId;
  final String authToken;

  const CourseDetailScreen({
    Key? key,
    required this.courseId,
    required this.authToken,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kurs tafsilotlari')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Other course content...

          // Tests Section
          Card(
            child: ListTile(
              leading: const Icon(Icons.quiz, color: Colors.blue),
              title: const Text('Testlar'),
              subtitle: const Text('Kurs testlarini topshiring'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TestListScreen(
                      courseId: courseId,
                      repository: TestRepository(token: authToken),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Certificates Section
          Card(
            child: ListTile(
              leading: const Icon(Icons.workspace_premium, color: Colors.amber),
              title: const Text('Mening sertifikatlarim'),
              subtitle: const Text('Olgan sertifikatlaringiz'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CertificateListScreen(
                      token: authToken,
                      baseUrl: 'http://localhost:3000',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// In your profile/dashboard screen
class ProfileScreen extends StatelessWidget {
  final String authToken;

  const ProfileScreen({Key? key, required this.authToken}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        children: [
          // User info card...
          ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: const Text('Mening sertifikatlarim'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CertificateListScreen(
                    token: authToken,
                    baseUrl: 'http://localhost:3000',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
