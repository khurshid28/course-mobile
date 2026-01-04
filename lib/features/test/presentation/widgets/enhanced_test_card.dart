import 'package:flutter/material.dart';
import '../../data/models/test_model.dart';

class EnhancedTestCard extends StatelessWidget {
  final TestModel test;
  final VoidCallback onStart;

  const EnhancedTestCard({Key? key, required this.test, required this.onStart})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isPassed = test.lastAttempt?.isPassed ?? false;
    final bool hasAttempted = test.lastAttempt != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: test.isAvailable ? onStart : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: test.isAvailable
                ? LinearGradient(
                    colors: [Colors.blue[50]!, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: _getGradient(test.isAvailable, isPassed),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _getColor(
                              test.isAvailable,
                              isPassed,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getIcon(test.isAvailable, isPassed),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            test.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: test.isAvailable
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                          ),
                          if (hasAttempted && isPassed) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '✓ O\'tilgan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Info chips
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      Icons.quiz,
                      '${test.questions.length} savol',
                      Colors.blue,
                    ),
                    _buildInfoChip(
                      Icons.timer,
                      '${test.maxDuration} min',
                      Colors.orange,
                    ),
                    _buildInfoChip(
                      Icons.star,
                      'O\'tish: ${test.passingScore}%',
                      Colors.amber,
                    ),
                    _buildInfoChip(
                      Icons.workspace_premium,
                      'Sertifikat: ${test.minCorrectAnswers}+',
                      Colors.purple,
                    ),
                  ],
                ),

                // Last attempt info
                if (hasAttempted) ...[
                  const SizedBox(height: 16),
                  _buildAttemptInfo(test, isPassed),
                ],

                // Availability message
                if (!test.isAvailable) ...[
                  const SizedBox(height: 12),
                  _buildUnavailableMessage(),
                ],

                // Start button
                if (test.isAvailable) ...[
                  const SizedBox(height: 16),
                  _buildStartButton(hasAttempted),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _getGradient(bool isAvailable, bool isPassed) {
    if (!isAvailable) {
      return LinearGradient(colors: [Colors.grey[400]!, Colors.grey[600]!]);
    }
    if (isPassed) {
      return LinearGradient(colors: [Colors.green[400]!, Colors.green[600]!]);
    }
    return LinearGradient(colors: [Colors.blue[400]!, Colors.blue[600]!]);
  }

  Color _getColor(bool isAvailable, bool isPassed) {
    if (!isAvailable) return Colors.grey;
    if (isPassed) return Colors.green;
    return Colors.blue;
  }

  IconData _getIcon(bool isAvailable, bool isPassed) {
    if (!isAvailable) return Icons.lock;
    if (isPassed) return Icons.check_circle;
    return Icons.quiz;
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptInfo(TestModel test, bool isPassed) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPassed ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPassed ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPassed ? Icons.check_circle : Icons.info_outline,
            size: 20,
            color: isPassed ? Colors.green[700] : Colors.orange[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Oxirgi natija: ${test.lastAttempt!.score}% (${test.lastAttempt!.correctAnswers}/${test.lastAttempt!.totalQuestions})',
              style: TextStyle(
                fontSize: 13,
                color: isPassed ? Colors.green[900] : Colors.orange[900],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailableMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.lock, color: Colors.red[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Bu test hozircha mavjud emas',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red[900],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(bool hasAttempted) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onStart,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(hasAttempted ? Icons.refresh : Icons.play_arrow, size: 22),
            const SizedBox(width: 8),
            Text(
              hasAttempted ? 'Qayta topshirish' : 'Testni boshlash',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
