import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../screens/settings_screen.dart';
import '../widgets/stat_chip.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  static const allSubjectsLabel = 'Tümü';
  String selectedSubject = allSubjectsLabel;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final subjectOptions = <String>{
      allSubjectsLabel,
      ...provider.testResults.map((result) => result.subject),
      ...provider.subjectGoals.map((goal) => goal.subject),
    }.toList();
    subjectOptions.sort((a, b) {
      if (a == allSubjectsLabel) return -1;
      if (b == allSubjectsLabel) return 1;
      return a.compareTo(b);
    });
    final activeSubject = subjectOptions.contains(selectedSubject) ? selectedSubject : allSubjectsLabel;

    final subjectColors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.brown, Colors.indigo];
    final subjects = activeSubject == allSubjectsLabel
        ? subjectOptions.where((subject) => subject != allSubjectsLabel).toList()
        : [activeSubject];

    final subjectChartData = subjects.map((subject) {
      final results = provider.subjectResults(subject);
      final spots = results.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value.actualNet)).toList();
      return {
        'subject': subject,
        'spots': spots,
        'color': subjectColors[subjects.indexOf(subject) % subjectColors.length],
      };
    }).toList();

    final hasSubjectData = subjectChartData.any((data) => (data['spots'] as List).isNotEmpty);
    final maxX = subjectChartData.map((data) => (data['spots'] as List).length).fold(1, (prev, value) => value > prev ? value : prev) - 1;
    final allValues = subjectChartData.expand((data) => (data['spots'] as List<FlSpot>).map((spot) => spot.y)).toList();
    final maxValue = allValues.isNotEmpty ? allValues.reduce(max) : 1.0;
    final minValue = allValues.isNotEmpty ? allValues.reduce(min) : 0.0;
    final chartRange = maxValue - minValue;
    final interval = chartRange > 0 ? (chartRange / 5).ceilToDouble() : 1.0;
    final minY = 0.0;
    final maxY = hasSubjectData ? maxValue + interval : 5.0;
    final chartWidth = max(MediaQuery.of(context).size.width, (maxX + 1) * 80.0);
    final analysisAdvice = activeSubject == allSubjectsLabel ? provider.dailyRecommendation : provider.subjectRecommendation(activeSubject);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Analiz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          Text('Genel Performans', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width / 2 - 26,
                child: StatChip(
                  label: 'Ortalama Net',
                  value: (activeSubject == allSubjectsLabel ? provider.averageNet : provider.subjectAverageNet(activeSubject)).toStringAsFixed(1),
                  color: Colors.indigo,
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 2 - 26,
                child: StatChip(
                  label: 'Hedef Açığı',
                  value: (activeSubject == allSubjectsLabel ? provider.targetGap : provider.subjectTargetGap(activeSubject)).toStringAsFixed(1),
                  color: Colors.red,
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 2 - 26,
                child: StatChip(
                  label: 'Toplam Test',
                  value: '${activeSubject == allSubjectsLabel ? provider.totalTests : provider.subjectTestCount(activeSubject)}',
                  color: Colors.teal,
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 2 - 26,
                child: StatChip(
                  label: 'Tamamlanma',
                  value: '${((activeSubject == allSubjectsLabel ? provider.completionRate : provider.subjectCompletionRate(activeSubject)) * 100).toStringAsFixed(1)}%',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Net Eğrisi', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              DropdownButton<String>(
                value: activeSubject,
                items: subjectOptions.map((subject) {
                  return DropdownMenuItem(value: subject, child: Text(subject));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedSubject = value;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                height: 240,
                child: hasSubjectData
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: chartWidth,
                          child: LineChart(
                            LineChartData(
                              minX: 0,
                              maxX: maxX.toDouble(),
                              minY: minY,
                              maxY: maxY,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withAlpha((0.12 * 255).round()), strokeWidth: 1),
                              ),
                              lineTouchData: LineTouchData(
                                enabled: true,
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipItems: (spots) {
                                    return spots.map((spot) {
                                      final subject = subjects[spot.barIndex];
                                      return LineTooltipItem(
                                        '$subject: ${spot.y.toStringAsFixed(1)}',
                                        TextStyle(color: (subjectChartData[spot.barIndex]['color'] as Color).computeLuminance() > 0.5 ? Colors.black : Colors.white),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    interval: interval,
                                    getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) => Text('T${value.toInt() + 1}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ),
                                ),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: subjectChartData.map((data) {
                                final spots = data['spots'] as List<FlSpot>;
                                return LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  barWidth: 3,
                                  color: data['color'] as Color,
                                  belowBarData: BarAreaData(show: true, color: (data['color'] as Color).withAlpha((0.16 * 255).round())),
                                  dotData: FlDotData(show: true),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          'Bu ders için henüz test verisi yok. Yeni test ekleyin.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Seçili Ders İçin Öneri', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(
            analysisAdvice,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[700], height: 1.4),
          ),
          if (activeSubject != allSubjectsLabel) ...[
            const SizedBox(height: 18),
            Text('Zayıf Konu', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(
              provider.subjectWeakness(activeSubject),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[700], height: 1.4),
            ),
          ],
          const SizedBox(height: 24),
          Text('Zayıf Dersler', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: provider.weakSubjects.map((subject) => Chip(label: Text(subject))).toList(),
          ),
        ],
      ),
    );
  }
}
