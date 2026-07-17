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
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _receiptsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }
              
              if (snapshot.hasError) {
                return SliverFillRemaining(child: Center(child: Text('Lỗi: ${snapshot.error}')));
              }

              final receipts = snapshot.data ?? [];
              if (receipts.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('Chưa có giao dịch nào', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildReceiptCard(receipts[index]),
                    childCount: receipts.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Quản lý Giao dịch', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        centerTitle: false,
        titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 16),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _refreshData,
        ),
        IconButton(
          icon: const Icon(Icons.cleaning_services_rounded, color: Colors.white),
          onPressed: () => _confirmCleanup(context),
          tooltip: 'Dọn dẹp hóa đơn lỗi',
        )
      ],
    );
  }

  Widget _buildReceiptCard(Map<String, dynamic> r) {
    final bool isPaid = r['is_paid'] == 1 || r['is_paid'] == true;
    final double total = (r['total'] as num?)?.toDouble() ?? 0.0;
    
    final rawDate = r['created_at'] ?? r['dayCreated'];
    final date = rawDate != null ? DateFormat('dd/MM, HH:mm').format(DateTime.parse(rawDate)) : '--';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isPaid ? Colors.green : Colors.orange).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isPaid ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                color: isPaid ? Colors.green : Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hóa đơn #${r['id']}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID người dùng: ${r['user_id']}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    date,
                    style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(total),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                _buildStatusChip(isPaid ? 'THÀNH CÔNG' : 'CHỜ THANH TOÁN', isPaid ? Colors.green : Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
      ),
    );
  }

  void _confirmCleanup(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Dọn dẹp hệ thống?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Xóa toàn bộ các hóa đơn chưa thanh toán đã quá hạn để tối ưu cơ sở dữ liệu?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('HỦY')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
                    behavior: SnackBarBehavior.floating,
                  )
                );
              }
            },
            child: const Text('XÁC NHẬN XÓA'),
          )
        ],
      ),
    );
  }
}
