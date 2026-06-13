import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/kpi_model.dart';
import '../providers/task_provider.dart';

class KpiScreen extends StatefulWidget {
  const KpiScreen({super.key});

  @override
  State<KpiScreen> createState() => _KpiScreenState();
}

class _KpiScreenState extends State<KpiScreen> {
  KpiSummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadKpi();
  }

  Future<void> _loadKpi() async {
    setState(() => _loading = true);
    final data = await context.read<TaskProvider>().getMyKpi();
    if (mounted) {
      setState(() {
        _summary = data;
        _loading = false;
      });
    }
  }

  Color _scoreColor(double score) {
    if (score >= 80) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Мой KPI'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadKpi,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _summary == null || _summary!.kpis.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 200),
                      Center(
                        child: Text(
                          'Пока нет начисленных KPI',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Average KPI card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text('Средний KPI', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: 120, height: 120,
                              child: Stack(fit: StackFit.expand, children: [
                                CircularProgressIndicator(
                                  value: (_summary!.average) / 100,
                                  strokeWidth: 10,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation(_scoreColor(_summary!.average)),
                                ),
                                Center(child: Text('${_summary!.average.toStringAsFixed(1)}%', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _scoreColor(_summary!.average)))),
                              ]),
                            ),
                            const SizedBox(height: 8),
                            Text('Всего начислений: ${_summary!.totalCount}', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // KPI list
                      ..._summary!.kpis.map((kpi) => _KpiCard(kpi: kpi)),
                    ],
                  ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final KpiModel kpi;

  const _KpiCard({required this.kpi});

  Color _scoreColor(double score) {
    if (score >= 80) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kpi.task?.title ?? 'Задача #${kpi.taskId}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Подтверждено: ${kpi.confirmedAt != null ? _formatDate(kpi.confirmedAt!) : '-'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _scoreColor(kpi.score).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${kpi.score.toStringAsFixed(0)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _scoreColor(kpi.score),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }
}
