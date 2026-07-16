import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class AdminPromoCodeManagementScreen extends StatefulWidget {
  const AdminPromoCodeManagementScreen({super.key});

  @override
  State<AdminPromoCodeManagementScreen> createState() => _AdminPromoCodeManagementScreenState();
}

class _AdminPromoCodeManagementScreenState extends State<AdminPromoCodeManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchAllPromoCodes();
    });
  }

  void _refreshData() {
    context.read<AdminProvider>().fetchAllPromoCodes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Quản lý Mã khuyến mãi', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPromoCodeDialog(context),
        label: const Text('Thêm mã mới'),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: AppColors.primary,
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.promoCodes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final promos = provider.promoCodes;
          if (promos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.discount_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Chưa có mã khuyến mãi nào', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshData(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: promos.length,
              itemBuilder: (context, index) {
                final promo = promos[index];
                return _buildPromoTile(promo);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromoTile(Map<String, dynamic> promo) {
    final bool isExpired = promo['Expired'] == true;
    final double salesFactor = (promo['sales'] as num?)?.toDouble() ?? 1.0;
    final int discountPercent = (100 - (salesFactor * 100)).toInt();
    final String code = promo['id']?.toString() ?? 'N/A';
    final rawDate = promo['dayExpired'];
    final date = rawDate != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(rawDate)) : '--';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (isExpired ? Colors.grey : AppColors.primary).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.confirmation_number_rounded, color: isExpired ? Colors.grey : AppColors.primary),
        ),
        title: Text("Mã: $code", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Giảm: $discountPercent%'),
            Text('Hết hạn: $date', style: TextStyle(color: isExpired ? Colors.red : Colors.grey[600], fontSize: 12)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showPromoCodeDialog(context, promo: promo);
            } else if (value == 'toggle') {
              _toggleStatus(promo['id']);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
            PopupMenuItem(
              value: 'toggle', 
              child: Text(isExpired ? 'Kích hoạt lại' : 'Đánh dấu hết hạn'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleStatus(dynamic id) async {
    if (id == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<AdminProvider>().togglePromoCodeStatus(id is int ? id : int.parse(id.toString()));
    if (error == null) {
      _refreshData();
    } else {
      messenger.showSnackBar(SnackBar(content: Text('Lỗi: $error'), backgroundColor: Colors.red));
    }
  }

  void _showPromoCodeDialog(BuildContext context, {Map<String, dynamic>? promo}) {
    final isEditing = promo != null;
    final salesFactor = (promo?['sales'] as num?)?.toDouble() ?? 1.0;
    final initialDiscount = (100 - (salesFactor * 100)).toInt();
    
    final salesController = TextEditingController(text: isEditing ? initialDiscount.toString() : '');
    DateTime selectedDate = promo?['dayExpired'] != null ? DateTime.parse(promo!['dayExpired']) : DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Cập nhật mã' : 'Thêm mã mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isEditing)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mã khuyến mãi (ID)'),
                    subtitle: Text(promo['id'].toString()),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: salesController,
                  decoration: const InputDecoration(
                    labelText: 'Phần trăm giảm giá (%)', 
                    hintText: 'VD: 20 để giảm 20%',
                    helperText: 'BE tính: Tổng = Giá * (1 - %giảm/100)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày hết hạn'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today_rounded),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final discountPercent = double.tryParse(salesController.text);
                if (discountPercent == null || discountPercent < 0 || discountPercent > 100) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phần trăm không hợp lệ (0-100)')));
                  return;
                }

                // BE logic: price * salesFactor. So 20% discount means factor 0.8
                final salesFactorToSend = (100.0 - discountPercent) / 100.0;

                final data = {
                  'sales': salesFactorToSend,
                  'dayExpired': selectedDate.toIso8601String().split('T')[0],
                  'Expired': promo?['Expired'] ?? false,
                };

                final messenger = ScaffoldMessenger.of(context);
                final provider = context.read<AdminProvider>();
                String? error;

                if (isEditing) {
                  error = await provider.updatePromoCode(promo!['id'], data);
                } else {
                  error = await provider.createPromoCode(data);
                }

                if (ctx.mounted) {
                  if (error == null) {
                    Navigator.pop(ctx);
                    _refreshData();
                    messenger.showSnackBar(SnackBar(content: Text(isEditing ? 'Đã cập nhật' : 'Đã thêm thành công'), backgroundColor: Colors.green));
                  } else {
                    messenger.showSnackBar(SnackBar(content: Text('Lỗi: $error'), backgroundColor: Colors.red));
                  }
                }
              },
              child: Text(isEditing ? 'Cập nhật' : 'Thêm'),
            ),
          ],
        ),
      ),
    );
  }
}
