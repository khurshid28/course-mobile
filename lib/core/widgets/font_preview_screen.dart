import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Font preview screen - fontlarni ko'rish uchun test ekrani
class FontPreviewScreen extends StatelessWidget {
  const FontPreviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fonts = [
      'Poppins',
      'Nunito',
      'Rubik',
      'Inter',
      'Montserrat',
      'Roboto',
      'OpenSans',
      'Lato',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Font Preview'),
        // Back button avtomatik default Flutter back button
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: fonts.length,
        itemBuilder: (context, index) {
          final fontName = fonts[index];
          return _buildFontCard(fontName);
        },
      ),
    );
  }

  Widget _buildFontCard(String fontName) {
    TextStyle getTextStyle(String font) {
      switch (font) {
        case 'Poppins':
          return GoogleFonts.poppins();
        case 'Nunito':
          return GoogleFonts.nunito();
        case 'Rubik':
          return GoogleFonts.rubik();
        case 'Inter':
          return GoogleFonts.inter();
        case 'Montserrat':
          return GoogleFonts.montserrat();
        case 'Roboto':
          return GoogleFonts.roboto();
        case 'OpenSans':
          return GoogleFonts.openSans();
        case 'Lato':
          return GoogleFonts.lato();
        default:
          return GoogleFonts.poppins();
      }
    }

    final baseStyle = getTextStyle(fontName);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Font name
            Text(
              fontName,
              style: baseStyle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Regular
            Text(
              'Kurslar tizimi - Test',
              style: baseStyle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),

            // Bold
            Text(
              'Test natijasi: 85%',
              style: baseStyle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Medium
            Text(
              'Sertifikat olish huquqiga ega bo\'ldingiz',
              style: baseStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            // Light
            Text(
              'To\'g\'ri javoblar: 17/20',
              style: baseStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
