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
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          Consumer<AdminProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.promoCodes.isEmpty) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }

              final promos = provider.promoCodes;
              if (promos.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.confirmation_number_rounded, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('Chưa có mã khuyến mãi nào', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildPromoCard(promos[index]),
                    childCount: promos.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPromoCodeDialog(context),
        label: const Text('Thêm mã mới', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: AppColors.primary,
        elevation: 8,
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
        title: const Text('Mã Khuyến mãi', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        centerTitle: false,
        titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 16),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFFB45309)],
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
      ],
    );
  }

  Widget _buildPromoCard(Map<String, dynamic> promo) {
    final bool isExpired = promo['Expired'] == true;
    final double salesFactor = (promo['sales'] as num?)?.toDouble() ?? 1.0;
    final int discountPercent = (100 - (salesFactor * 100)).toInt();
    final String code = promo['id']?.toString() ?? 'N/A';
    final rawDate = promo['dayExpired'];
    final date = rawDate != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(rawDate)) : '--';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          // Coupon Design
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 4))
              ],
              border: Border.all(color: isExpired ? Colors.grey.withOpacity(0.2) : AppColors.primary.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                // Left Part: Discount
                Column(
                  children: [
                    Text(
                      '$discountPercent%',
                      style: TextStyle(
                        fontWeight: FontWeight.w900, 
                        fontSize: 24, 
                        color: isExpired ? Colors.grey : AppColors.primary
                      ),
                    ),
                    const Text('OFF', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey)),
                  ],
                ),
                const SizedBox(width: 20),
                // Vertical Divider Line
                Container(width: 1, height: 40, color: Colors.grey[200]),
                const SizedBox(width: 20),
                // Right Part: Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Mã: $code",
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.event_available_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('Hết hạn: $date', style: TextStyle(color: isExpired ? Colors.red : Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                ),
              ],
            ),
          ),
          // Expired Watermark
          if (isExpired)
            Positioned(
              right: 60,
              top: 10,
              child: Transform.rotate(
                angle: -0.2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'HẾT HẠN',
                    style: TextStyle(color: Colors.red.withOpacity(0.5), fontWeight: FontWeight.w900, fontSize: 10),
                  ),
                ),
              ),
            ),
        ],
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
      messenger.showSnackBar(SnackBar(content: Text('Lỗi: $error'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(isEditing ? 'Cập nhật mã' : 'Thêm mã mới', style: const TextStyle(fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isEditing)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Text('ID Mã:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text(promo['id'].toString(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: salesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Phần trăm giảm giá (%)', 
                  hintText: 'VD: 20 để giảm 20%',
                  prefixIcon: const Icon(Icons.percent_rounded),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
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
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: Colors.grey),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ngày hết hạn', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text(DateFormat('dd/MM/yyyy').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('HỦY')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final discountPercent = double.tryParse(salesController.text);
                if (discountPercent == null || discountPercent < 0 || discountPercent > 100) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phần trăm không hợp lệ (0-100)')));
                  return;
                }

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
                    messenger.showSnackBar(SnackBar(content: Text(isEditing ? 'Đã cập nhật' : 'Đã thêm thành công'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
                  } else {
                    messenger.showSnackBar(SnackBar(content: Text('Lỗi: $error'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
                  }
                }
              },
              child: Text(isEditing ? 'CẬP NHẬT' : 'TẠO MÃ'),
            ),
          ],
        ),
      ),
    );
  }
}
