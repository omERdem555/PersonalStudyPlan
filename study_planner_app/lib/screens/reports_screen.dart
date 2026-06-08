import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'settings_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final testResults = provider.testResults;
    final subjectColors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.brown, Colors.indigo];
    final subjects = testResults.map((result) => result.subject).toSet().toList();
    final subjectTrendData = subjects.asMap().entries.map((entry) {
      final subject = entry.value;
      final results = testResults.where((item) => item.subject == subject).toList();
      final spots = results.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.actualNet)).toList();
      return {
        'subject': subject,
        'spots': spots,
        'color': subjectColors[entry.key % subjectColors.length],
      };
    }).toList();
    final maxX = subjectTrendData.fold(1, (prev, data) {
      final length = (data['spots'] as List<FlSpot>).length;
      return length > prev ? length : prev;
    }) - 1;
    final maxTrend = subjectTrendData.expand((data) => (data['spots'] as List<FlSpot>).map((spot) => spot.y)).fold<double>(0.0, (prev, value) => value > prev ? value : prev);
    final minTrend = subjectTrendData.expand((data) => (data['spots'] as List<FlSpot>).map((spot) => spot.y)).fold<double>(maxTrend, (prev, value) => value < prev ? value : prev);
    final chartWidth = max(MediaQuery.of(context).size.width, (maxX + 1) * 80.0);

    final testEntries = testResults.asMap().entries.map((entry) {
      return {
        'index': entry.key,
        'subject': entry.value.subject,
        'studyTime': entry.value.studyTime,
        'color': subjectColors[subjects.indexOf(entry.value.subject) % subjectColors.length],
      };
    }).toList();
    final studyChartWidth = max(MediaQuery.of(context).size.width, testEntries.length * 80.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporlar ve İstatistikler'),
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
          Text('Haftalık & Aylık Rapor', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ders Bazlı Özet', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (provider.subjectGoals.isNotEmpty) ...provider.subjectGoals.map((goal) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(goal.subject, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        _ReportMetric(label: 'Toplam Test', value: provider.subjectTestCount(goal.subject).toString()),
                        _ReportMetric(label: 'Ortalama Net', value: provider.subjectAverageNet(goal.subject).toStringAsFixed(1)),
                        _ReportMetric(label: 'Hedef Net', value: goal.targetNet.toStringAsFixed(1)),
                        _ReportMetric(label: 'Çalışma Süresi', value: '${provider.subjectStudyTimeTotal(goal.subject)} dk'),
                        const SizedBox(height: 12),
                      ],
                    );
                  }).toList() else ...[
                    Text('Henüz ders bazlı veri kaydı yok.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[700])),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Net Trendi (Gelişim)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 220,
                child: testResults.isEmpty
                    ? const Center(child: Text('Veri yok'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: chartWidth,
                          child: LineChart(
                            LineChartData(
                              minX: 0,
                              maxX: maxX.toDouble(),
                              minY: (minTrend - 5).clamp(0, double.infinity),
                              maxY: maxTrend + 5,
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
                                      final subject = subjectTrendData[spot.barIndex]['subject'] as String;
                                      final color = subjectTrendData[spot.barIndex]['color'] as Color;
                                      return LineTooltipItem(
                                        '$subject: ${spot.y.toStringAsFixed(1)}',
                                        TextStyle(color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 50,
                                    interval: ((maxTrend - minTrend) / 5).ceil().toDouble(),
                                    getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(0), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 35,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 || index >= testResults.length) return const Text('');
                                      final subject = testResults[index].subject;
                                      return SizedBox(
                                        width: 70,
                                        child: Text(subject, style: const TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.center),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: subjectTrendData.map((data) {
                                return LineChartBarData(
                                  spots: data['spots'] as List<FlSpot>,
                                  isCurved: true,
                                  barWidth: 3,
                                  color: data['color'] as Color,
                                  dotData: FlDotData(show: true),
                                  belowBarData: BarAreaData(show: true, color: (data['color'] as Color).withAlpha((0.16 * 255).round())),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Çalışma Süresi Trendi (dakika)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 240,
                child: testEntries.isEmpty
                    ? const Center(child: Text('Çalışma verisi henüz yok'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: studyChartWidth,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              barGroups: testEntries.map((entry) {
                                return BarChartGroupData(
                                  x: entry['index'] as int,
                                  barRods: [
                                    BarChartRodData(
                                      toY: (entry['studyTime'] as int).toDouble(),
                                      color: entry['color'] as Color,
                                      width: 18,
                                    ),
                                  ],
                                );
                              }).toList(),
                              gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withAlpha((0.12 * 255).round()), strokeWidth: 1)),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 55,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 || index >= testEntries.length) return const Text('');
                                      final subject = testEntries[index]['subject'] as String;
                                      return SizedBox(
                                        width: 70,
                                        child: Text(subject, style: const TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.center),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (group) => Theme.of(context).colorScheme.primary,
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    final subject = testEntries[group.x.toInt()]['subject'] as String;
                                    return BarTooltipItem('$subject: ${rod.toY.toInt()} dk', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                                  },
                                ),
                              ),
                              maxY: testEntries.map((entry) => entry['studyTime'] as int).fold<double>(0.0, (prev, value) => value > prev ? value.toDouble() : prev.toDouble()) + 10,
                              minY: 0,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportMetric extends StatelessWidget {
  final String label;
  final String value;

  const _ReportMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
          Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
