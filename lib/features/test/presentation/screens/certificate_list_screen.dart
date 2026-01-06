import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../../core/theme/app_colors.dart';

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
      print('=== LOADING CERTIFICATES ===');
      print('Base URL: ${widget.baseUrl}');
      print('Full URL: ${widget.baseUrl}/tests/certificates/my');
      print('Token length: ${widget.token.length}');
      print(
        'Token: ${widget.token.length > 20 ? widget.token.substring(0, 20) : widget.token}...',
      );

      final response = await http.get(
        Uri.parse('${widget.baseUrl}/tests/certificates/my'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Certificates loaded: ${data.length}');
        setState(() {
          _certificates = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        throw Exception(
          'Server xatoligi: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('=== CERTIFICATE LOAD ERROR ===');
      print('Error: $e');
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
            content: Text('Sertifikat saqlandi'),
            action: SnackBarAction(
              label: 'Ko\'rish',
              onPressed: () => _viewPdf(file.path, certificateNo),
            ),
          ),
        );

        // PDF ni ko'rsatmaymiz, faqat yuklab olamiz
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

  // Backend dan to'g'ridan-to'g'ri PDF ni ko'rish
  Future<void> _viewPdfFromBackend(String certificateNo) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PDF ochilmoqda...')));

      // Avval cache'dan tekshiramiz
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/certificate_$certificateNo.pdf');

      if (await file.exists()) {
        // Cache'dan ochish
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewScreen(
              filePath: file.path,
              certificateNo: certificateNo,
            ),
          ),
        );
      } else {
        // Backend URL dan ochish
        if (!mounted) return;
        final pdfUrl =
            '${widget.baseUrl}/tests/certificates/download/$certificateNo';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewScreen(
              pdfUrl: pdfUrl,
              certificateNo: certificateNo,
              token: widget.token,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
    }
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
                      onPressed: () => _viewPdfFromBackend(certificateNo),
                      icon: const Icon(Icons.visibility),
                      label: const Text('Ko\'rish'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.amber[800],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                        // Download first then share
                        await _downloadCertificate(certificateNo, courseName);
                        // After download, share it
                        if (await file.exists()) {
                          _shareCertificate(file.path, courseName);
                        }
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

class PdfViewScreen extends StatefulWidget {
  final String? filePath;
  final String certificateNo;
  final String? pdfUrl;
  final String? token;

  const PdfViewScreen({
    Key? key,
    this.filePath,
    required this.certificateNo,
    this.pdfUrl,
    this.token,
  }) : super(key: key);

  @override
  State<PdfViewScreen> createState() => _PdfViewScreenState();
}

class _PdfViewScreenState extends State<PdfViewScreen> {
  String? _localFilePath;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.filePath != null) {
      _localFilePath = widget.filePath;
    } else if (widget.pdfUrl != null) {
      _downloadPdfFromUrl();
    }
  }

  Future<void> _downloadPdfFromUrl() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse(widget.pdfUrl!),
        headers: widget.token != null
            ? {'Authorization': 'Bearer ${widget.token}'}
            : {},
      );

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File(
          '${dir.path}/certificate_${widget.certificateNo}.pdf',
        );
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          setState(() {
            _localFilePath = file.path;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('PDF yuklanmadi: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadToGallery(BuildContext context) async {
    try {
      if (_localFilePath == null) {
        throw Exception('Fayl topilmadi');
      }

      final file = File(_localFilePath!);
      if (!await file.exists()) {
        throw Exception('Fayl topilmadi');
      }

      // Copy to downloads directory
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final newPath =
          '${downloadsDir.path}/certificate_${widget.certificateNo}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await file.copy(newPath);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yuklab olindi: Download'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
          padding: const EdgeInsets.all(8),
        ),
        title: Text(
          'Sertifikat: ${widget.certificateNo}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (!_isLoading && _localFilePath != null) ...[
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/download.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              tooltip: 'Yuklab olish',
              onPressed: () => _downloadToGallery(context),
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/share.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              tooltip: 'Ulashish',
              onPressed: () async {
                try {
                  if (_localFilePath == null) {
                    throw Exception('Fayl topilmadi');
                  }

                  final file = File(_localFilePath!);
                  if (!await file.exists()) {
                    throw Exception('Fayl topilmadi');
                  }

                  // Share PDF file
                  await Share.shareXFiles(
                    [XFile(_localFilePath!)],
                    subject: 'Sertifikat: ${widget.certificateNo}',
                    text: 'Mening ${widget.certificateNo} sertifikatim',
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ulashishda xatolik: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.amber[700],
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'PDF yuklanmoqda...',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[400], size: 64),
                    const SizedBox(height: 24),
                    Text(
                      'PDF yuklashda xatolik',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (widget.pdfUrl != null) {
                          _downloadPdfFromUrl();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Qayta urinish'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _localFilePath != null
          ? PDFView(
              filePath: _localFilePath!,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              pageSnap: true,
              defaultPage: 0,
              fitPolicy: FitPolicy.BOTH,
              preventLinkNavigation: false,
              onRender: (pages) {
                print('PDF rendered with $pages pages');
              },
              onError: (error) {
                print('PDF View Error: $error');
                if (mounted) {
                  setState(() {
                    _error = 'PDF ko\'rsatishda xatolik: $error';
                  });
                }
              },
              onPageError: (page, error) {
                print('PDF Page $page Error: $error');
              },
              onViewCreated: (PDFViewController pdfViewController) {
                print('PDF View created successfully');
              },
              onPageChanged: (int? page, int? total) {
                print('Page changed: $page/$total');
              },
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'PDF topilmadi',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
