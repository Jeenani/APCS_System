import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/api_client.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = false;
  int _reminderDays = 3;
  bool _notifyHigh = true;
  bool _notifyMedium = true;
  bool _notifyLow = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final response = await ApiClient.get('/profile') as Map<String, dynamic>;
      final settings = response['notification_settings'];
      if (settings != null) {
        setState(() {
          _pushEnabled = settings['push_enabled'] ?? true;
          _soundEnabled = settings['sound_enabled'] ?? true;
          _vibrationEnabled = settings['vibration_enabled'] ?? false;
          _reminderDays = settings['reminder_days_before'] ?? 3;
          _notifyHigh = settings['notify_high_priority'] ?? true;
          _notifyMedium = settings['notify_medium_priority'] ?? true;
          _notifyLow = settings['notify_low_priority'] ?? false;
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiClient.put('/profile/notification-settings', {
        'push_enabled': _pushEnabled,
        'sound_enabled': _soundEnabled,
        'vibration_enabled': _vibrationEnabled,
        'reminder_days_before': _reminderDays,
        'notify_high_priority': _notifyHigh,
        'notify_medium_priority': _notifyMedium,
        'notify_low_priority': _notifyLow,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Настройки сохранены')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Настройки уведомлений'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle switches
            _SettingTile(
              icon: Icons.notifications_active,
              title: 'Push-уведомления',
              value: _pushEnabled,
              onChanged: (v) => setState(() => _pushEnabled = v),
            ),
            _SettingTile(
              icon: Icons.volume_up,
              title: 'Звуковые сигналы',
              value: _soundEnabled,
              onChanged: (v) => setState(() => _soundEnabled = v),
            ),
            _SettingTile(
              icon: Icons.vibration,
              title: 'Вибрация',
              value: _vibrationEnabled,
              onChanged: (v) => setState(() => _vibrationEnabled = v),
            ),
            const SizedBox(height: 20),

            // Reminder days
            const Text('Напоминать о задаче за:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [1, 3, 7].map((d) {
                  final selected = _reminderDays == d;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _reminderDays = d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$d ${d == 1 ? "день" : d < 5 ? "дня" : "дней"}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected ? Colors.white : AppColors.textPrimary,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Quiet hours
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Тихий режим', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.nightlight_round, color: Colors.grey[500], size: 20),
                      const SizedBox(width: 8),
                      Text('22:00 — 08:00', style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Priority filters
            const Text('Приоритеты для уведомлений', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _PriorityCheck(
                    label: 'Высокий',
                    color: AppColors.priorityHigh,
                    value: _notifyHigh,
                    onChanged: (v) => setState(() => _notifyHigh = v ?? true),
                  ),
                  _PriorityCheck(
                    label: 'Средний',
                    color: AppColors.priorityMedium,
                    value: _notifyMedium,
                    onChanged: (v) => setState(() => _notifyMedium = v ?? true),
                  ),
                  _PriorityCheck(
                    label: 'Низкий',
                    color: AppColors.priorityLow,
                    value: _notifyLow,
                    onChanged: (v) => setState(() => _notifyLow = v ?? false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Сохранить настройки', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingTile({required this.icon, required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _PriorityCheck extends StatelessWidget {
  final String label;
  final Color color;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _PriorityCheck({required this.label, required this.color, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Checkbox(value: value, onChanged: onChanged, activeColor: AppColors.primary),
      ],
    );
  }
}
