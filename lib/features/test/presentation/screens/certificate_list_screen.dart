import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/widgets/shimmer_widgets.dart';

class CertificateListScreen extends StatefulWidget {
  final String token;
  final String baseUrl;

  const CertificateListScreen({
    Key? key,
    required this.token,
    this.baseUrl = 'http://localhost:3000',
  }) : super(key: key);

  @override
  State<CertificateListScreen> createState() => _CertificateListScreenState();
}

class _CertificateListScreenState extends State<CertificateListScreen> {
  List<Map<String, dynamic>> _certificates = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/api/user/certificates'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _certificates = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load certificates');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadCertificate(
    String certificateNo,
    String courseName,
  ) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Yuklab olinmoqda...')));

      print('=== PDF DOWNLOAD STARTED ===');
      print('Certificate No: $certificateNo');
      print('Base URL: ${widget.baseUrl}');
      print(
        'Full URL: ${widget.baseUrl}/tests/certificates/download/$certificateNo',
      );

      final response = await http.get(
        Uri.parse(
          '${widget.baseUrl}/tests/certificates/download/$certificateNo',
        ),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body Length: ${response.bodyBytes.length} bytes');
      print('Content-Type: ${response.headers['content-type']}');

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/certificate_$certificateNo.pdf');
        print('Saving to: ${file.path}');

        await file.writeAsBytes(response.bodyBytes);

        final fileExists = await file.exists();
        final fileSize = await file.length();
        print('File saved successfully: $fileExists');
        print('File size: $fileSize bytes');
        print('=== PDF DOWNLOAD COMPLETED ===');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sertifikat saqlandi: ${file.path}'),
            action: SnackBarAction(
              label: 'Ulashish',
              onPressed: () => _shareCertificate(file.path, courseName),
            ),
          ),
        );

        // PDF ni ko'rsatish
        _viewPdf(file.path, certificateNo);
      } else {
        print('=== DOWNLOAD FAILED ===');
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw Exception('Download failed with status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('=== PDF DOWNLOAD ERROR ===');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
    }
  }

  Future<void> _shareCertificate(String filePath, String courseName) async {
    try {
      await Share.shareXFiles([
        XFile(filePath),
      ], text: 'Mening $courseName kursi uchun sertifikatim!');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
    }
  }

  void _viewPdf(String filePath, String certificateNo) {
    print('=== OPENING PDF VIEWER ===');
    print('File Path: $filePath');
    print('Certificate No: $certificateNo');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PdfViewScreen(filePath: filePath, certificateNo: certificateNo),
      ),
    );
  }

  void _verifyCertificate() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Sertifikatni tekshirish'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Sertifikat raqami',
              hintText: 'CERT-XXXX-XXXX',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Bekor qilish'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _checkCertificate(controller.text.trim());
              },
              child: const Text('Tekshirish'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkCertificate(String certificateNo) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${widget.baseUrl}/api/tests/certificates/verify/$certificateNo',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _showCertificateInfo(data);
      } else {
        throw Exception('Sertifikat topilmadi');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
    }
  }

  void _showCertificateInfo(Map<String, dynamic> certificate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Sertifikat haqiqiy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Raqam', certificate['certificateNo']),
            _buildInfoRow('Ism', certificate['user']['fullName']),
            _buildInfoRow('Kurs', certificate['testResult']['test']['title']),
            _buildInfoRow('Natija', '${certificate['testResult']['score']}%'),
            _buildInfoRow(
              'Berilgan sana',
              _formatDate(certificate['issuedAt']),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day}.${date.month}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mening sertifikatlarim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.verified),
            tooltip: 'Sertifikatni tekshirish',
            onPressed: _verifyCertificate,
          ),
        ],
      ),
      body: _isLoading
          ? ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: 3,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: const CertificateCardShimmer(),
              ),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadCertificates,
                    child: const Text('Qayta urinish'),
                  ),
                ],
              ),
            )
          : _certificates.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.workspace_premium,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hozircha sertifikatlar yo\'q',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Test topshiring va sertifikat oling!',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadCertificates,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _certificates.length,
                itemBuilder: (context, index) {
                  final cert = _certificates[index];
                  return _buildCertificateCard(cert);
                },
              ),
            ),
    );
  }

  Widget _buildCertificateCard(Map<String, dynamic> certificate) {
    final certificateNo = certificate['certificateNo'];
    final testResult = certificate['testResult'];
    final test = testResult['test'];
    final courseName = test['section']?['course']?['title'] ?? test['title'];
    final score = testResult['score'];
    final issuedAt = _formatDate(certificate['issuedAt']);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.amber[600]!, Colors.amber[800]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SERTIFIKAT',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          certificateNo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),

              // Course info
              Text(
                courseName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Score and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Natija: $score%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        issuedAt,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _downloadCertificate(certificateNo, courseName),
                      icon: const Icon(Icons.download),
                      label: const Text('Yuklab olish'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.amber[800],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      // Direct share if already downloaded
                      final dir = await getApplicationDocumentsDirectory();
                      final file = File(
                        '${dir.path}/certificate_$certificateNo.pdf',
                      );
                      if (await file.exists()) {
                        _shareCertificate(file.path, courseName);
                      } else {
                        _downloadCertificate(certificateNo, courseName);
                      }
                    },
                    icon: const Icon(Icons.share),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PdfViewScreen extends StatelessWidget {
  final String filePath;
  final String certificateNo;

  const PdfViewScreen({
    Key? key,
    required this.filePath,
    required this.certificateNo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sertifikat: $certificateNo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              await Share.shareXFiles([XFile(filePath)]);
            },
          ),
        ],
      ),
      body: PDFView(
        filePath: filePath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
      ),
    );
  }
}
