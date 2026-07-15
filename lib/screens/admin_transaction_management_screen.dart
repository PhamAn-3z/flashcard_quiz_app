import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class AdminTransactionManagementScreen extends StatefulWidget {
  const AdminTransactionManagementScreen({super.key});

  @override
  State<AdminTransactionManagementScreen> createState() => _AdminTransactionManagementScreenState();
}

class _AdminTransactionManagementScreenState extends State<AdminTransactionManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Quản lý Giao dịch', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded, color: Colors.redAccent),
            onPressed: () => _confirmCleanup(context),
            tooltip: 'Dọn dẹp hóa đơn lỗi',
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: context.read<AdminProvider>().fetchAllReceipts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final receipts = snapshot.data ?? [];
          if (receipts.isEmpty) return const Center(child: Text('Không có giao dịch nào.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: receipts.length,
            itemBuilder: (context, index) {
              final r = receipts[index];
              return _buildReceiptTile(r);
            },
          );
        },
      ),
    );
  }

  Widget _buildReceiptTile(Map<String, dynamic> r) {
    final bool isPaid = r['is_paid'] == 1 || r['is_paid'] == true;
    final double total = (r['total'] as num?)?.toDouble() ?? 0.0;
    final date = r['dayCreated'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(r['dayCreated'])) : '--';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: ListTile(
        title: Text('Hóa đơn #${r['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('User ID: ${r['user_id']} • $date'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(total)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            Text(isPaid ? 'Đã thu' : 'Chưa trả', style: TextStyle(color: isPaid ? Colors.green : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _confirmCleanup(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dọn dẹp hệ thống?'),
        content: const Text('Xóa toàn bộ các hóa đơn chưa thanh toán đã quá hạn?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final success = await context.read<AdminProvider>().cleanupReceipts();
              if (mounted) {
                Navigator.pop(ctx);
                setState(() {}); // Refresh list
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Đã dọn dẹp' : 'Thất bại')));
              }
            },
            child: const Text('Xác nhận'),
          )
        ],
      ),
    );
  }
}
