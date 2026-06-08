import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject_goal.dart';
import '../providers/app_provider.dart';
import '../widgets/primary_button.dart';
import '../widgets/stat_chip.dart';
import '../utils/helpers.dart';

class HomeDashboard extends StatelessWidget {
  final void Function(int) onNavigate;
  final VoidCallback onSettings;

  const HomeDashboard({
    super.key,
    required this.onNavigate,
    required this.onSettings,
  });

  Future<void> _showLessonDialog(BuildContext context, AppProvider provider, [SubjectGoal? existing]) async {
    final formKey = GlobalKey<FormState>();
    final subjectController = TextEditingController(text: existing?.subject ?? '');
    final currentNetController = TextEditingController(text: existing != null ? existing.currentNet.toStringAsFixed(1) : '');
    final targetNetController = TextEditingController(text: existing != null ? existing.targetNet.toStringAsFixed(1) : '');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existing == null ? 'Ders Ekle' : 'Dersi Düzenle'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Ders Adı'),
                  validator: (value) => (value?.isEmpty ?? true) ? 'Ders adını girin' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: currentNetController,
                  decoration: const InputDecoration(labelText: 'Mevcut Net'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Mevcut net girin';
                    return double.tryParse(value!) == null ? 'Geçerli bir sayı girin' : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: targetNetController,
                  decoration: const InputDecoration(labelText: 'Hedef Net'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Hedef net girin';
                    return double.tryParse(value!) == null ? 'Geçerli bir sayı girin' : null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')),
            TextButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final subject = subjectController.text.trim();
                final currentNet = double.parse(currentNetController.text);
                final targetNet = double.parse(targetNetController.text);
                await provider.addSubjectGoal(
                  SubjectGoal(
                    subject: subject,
                    currentNet: currentNet,
                    targetNet: targetNet,
                    createdAt: existing?.createdAt ?? DateTime.now(),
                  ),
                );
                Navigator.of(context).pop();
              },
              child: Text(existing == null ? 'Ekle' : 'Güncelle'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.user;
    final recentTests = provider.recentResults;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    Widget buildLessonCard(SubjectGoal goal) {
      final averageNet = provider.subjectAverageNet(goal.subject);
      final tests = provider.subjectTestCount(goal.subject);
      final recommendedStudy = provider.subjectRecommendedStudyTime(goal.subject).toStringAsFixed(0);

      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(goal.subject, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    onPressed: () => _showLessonDialog(context, provider, goal),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Mevcut: ${goal.currentNet.toStringAsFixed(1)}  •  Hedef: ${goal.targetNet.toStringAsFixed(1)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Flexible(
                        flex: 1,
                        child: StatChip(label: 'Net Ortalaması', value: averageNet > 0 ? averageNet.toStringAsFixed(1) : goal.currentNet.toStringAsFixed(1), color: Colors.indigo),
                      ),
                      Flexible(
                        flex: 1,
                        child: StatChip(label: 'Test Sayısı', value: '$tests', color: Colors.teal),
                      ),
                      Flexible(
                        flex: 1,
                        child: StatChip(label: 'Önerilen Süre', value: '$recommendedStudy dk', color: Colors.deepPurple),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Akademik Başarı Merkezi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: onSettings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            Text(
              'Merhaba, ${user.name}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Derslerinizi ekleyin, her ders için özel plan ve grafik önerileri alın.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ders Hedefleri', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        TextButton.icon(
                          onPressed: () => _showLessonDialog(context, provider),
                          icon: const Icon(Icons.add),
                          label: const Text('Ders Ekle'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (provider.subjectGoals.isEmpty)
                      Text('Henüz ders eklemediniz. Yeni ders ekleyerek ilerlemeye başlayın.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]))
                    else
                      Column(
                        children: provider.subjectGoals.map((goal) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: buildLessonCard(goal),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: StatChip(label: 'Toplam Ders', value: '${provider.totalSubjects}', color: Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: StatChip(label: 'Toplam Test', value: '${provider.totalTests}', color: Colors.teal)),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Günlük AI Önerisi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Zayıf konulara ağırlık ver', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Text(
                      provider.dailyRecommendation,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700], height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      runSpacing: 10,
                      spacing: 10,
                      children: provider.weakSubjects.map((subject) => Chip(label: Text(subject))).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Hızlı Geçişler',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Test Gir',
                    onTap: () => onNavigate(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'AI Analiz',
                    onTap: () => onNavigate(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Plan Oluştur',
                    onTap: () => onNavigate(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Raporlar',
                    onTap: () => onNavigate(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Son Kayıtlar',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (recentTests.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Icon(Icons.timeline, size: 60, color: Colors.grey),
                    const SizedBox(height: 14),
                    Text(
                      'Henüz test verisi yok. Test girişi yaparak AI analizlerine başlayın.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...recentTests.map(
                (result) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    tileColor: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.16),
                      child: Icon(Icons.auto_graph, color: Theme.of(context).colorScheme.primary),
                    ),
                    title: Text(result.subject, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text('${AppDateUtils.formatDate(result.date)} • Net ${result.actualNet.toStringAsFixed(1)}'),
                    trailing: Text('${result.correct}/${result.totalQuestions}'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
