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
      backgroundColor: const Color(0xFFF3F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Automation History', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        actions: [
          if (historyProvider.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFF64748B)),
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
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF64748B),
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
        color: Colors.white,
        borderRadius: AppDimensions.roundedLg,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSuccess ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.triggerType,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.place_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                item.locationName,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const Spacer(),
              Text(
                '$dateStr • $timeStr',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          if (item.message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                item.message,
                style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 48, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text('No History Records', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 4),
          Text('Triggered automations will appear here.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        ],
      ),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Clear All History?', style: TextStyle(color: Color(0xFF0F172A))),
        content: const Text('This will erase all recorded trigger logs.', style: TextStyle(color: Color(0xFF64748B))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
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
