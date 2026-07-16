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
  late Future<List<Map<String, dynamic>>> _receiptsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _receiptsFuture = context.read<AdminProvider>().fetchAllReceipts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Quản lý Giao dịch', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded, color: Colors.redAccent),
            onPressed: () => _confirmCleanup(context),
            tooltip: 'Dọn dẹp hóa đơn lỗi',
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _receiptsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final receipts = snapshot.data ?? [];
          if (receipts.isEmpty) return const Center(child: Text('Không có giao dịch nào.'));

          return RefreshIndicator(
            onRefresh: () async => _refreshData(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: receipts.length,
              itemBuilder: (context, index) {
                final r = receipts[index];
                return _buildReceiptTile(r);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildReceiptTile(Map<String, dynamic> r) {
    final bool isPaid = r['is_paid'] == 1 || r['is_paid'] == true;
    final double total = (r['total'] as num?)?.toDouble() ?? 0.0;
    
    // Hỗ trợ cả hai tên trường common: created_at (mặc định Supabase) hoặc dayCreated
    final rawDate = r['created_at'] ?? r['dayCreated'];
    final date = rawDate != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(rawDate)) : '--';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: ListTile(
        title: Text('Hóa đơn #${r['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('User: ${r['user_id']}\n$date'),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(total)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isPaid ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isPaid ? 'Đã thu' : 'Chờ trả', 
                style: TextStyle(color: isPaid ? Colors.green : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)
              ),
            ),
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
              final messenger = ScaffoldMessenger.of(context);
              final error = await context.read<AdminProvider>().cleanupReceipts();
              if (mounted) {
                Navigator.pop(ctx);
                _refreshData();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(error == null ? 'Đã dọn dẹp thành công' : 'Thất bại: $error'),
                    backgroundColor: error == null ? Colors.green : Colors.red,
                  )
                );
              }
            },
            child: const Text('Xác nhận'),
          )
        ],
      ),
    );
  }
}
