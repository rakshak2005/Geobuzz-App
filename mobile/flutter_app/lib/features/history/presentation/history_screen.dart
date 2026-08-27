import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../shared/models/history_item.dart';
import '../domain/history_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Automation History', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (historyProvider.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.textSecondaryDark),
              tooltip: 'Clear History',
              onPressed: () {
                _confirmClearHistory(context);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
            child: Row(
              children: [
                _buildFilterChip(context, 'ALL', 'All Events'),
                _buildFilterChip(context, 'SOUND_PROFILE', 'Sound Profiles'),
                _buildFilterChip(context, 'ALARM', 'Alarms'),
                _buildFilterChip(context, 'REMINDER', 'Reminders'),
                _buildFilterChip(context, 'WIFI', 'WiFi'),
                _buildFilterChip(context, 'BLUETOOTH', 'Bluetooth'),
              ],
            ),
          ),

          // Events List
          Expanded(
            child: historyProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : historyProvider.history.isEmpty
                    ? _buildEmptyHistory()
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppDimensions.md),
                        itemCount: historyProvider.history.length,
                        itemBuilder: (ctx, index) {
                          final item = historyProvider.history[index];
                          return _buildHistoryCard(item);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String filterKey, String label) {
    final provider = context.watch<HistoryProvider>();
    final isSelected = provider.filterType == filterKey;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surfaceDark,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondaryDark,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        onSelected: (_) {
          provider.setFilter(filterKey);
        },
      ),
    );
  }

  Widget _buildHistoryCard(HistoryItem item) {
    final isSuccess = item.status == 'SUCCESS';
    final dateStr = DateFormat('dd MMM yyyy').format(item.timestamp);
    final timeStr = DateFormat('hh:mm a').format(item.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: AppDimensions.roundedLg,
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.ruleName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSuccess ? AppColors.success.withOpacity(0.15) : AppColors.error.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.triggerType,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.place_rounded, size: 14, color: AppColors.primaryLight),
              const SizedBox(width: 4),
              Text(
                item.locationName,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
              ),
              const Spacer(),
              Text(
                '$dateStr • $timeStr',
                style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark),
              ),
            ],
          ),
          if (item.message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLightDark.withOpacity(0.4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.message,
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimaryDark),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 48, color: AppColors.textMutedDark.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text('No History Records', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Triggered automations will appear here.', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
        ],
      ),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Clear All History?', style: TextStyle(color: Colors.white)),
        content: const Text('This will erase all recorded trigger logs.', style: TextStyle(color: AppColors.textSecondaryDark)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<HistoryProvider>().clearAllHistory();
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
