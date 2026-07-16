import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class AdminMembershipManagementScreen extends StatefulWidget {
  const AdminMembershipManagementScreen({super.key});

  @override
  State<AdminMembershipManagementScreen> createState() => _AdminMembershipManagementScreenState();
}

class _AdminMembershipManagementScreenState extends State<AdminMembershipManagementScreen> {
  late Future<void> _fetchFuture;
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _fetchFuture = context.read<AdminProvider>().fetchAllMemberships();
  }

  void _refreshMemberships() {
    setState(() {
      _fetchFuture = context.read<AdminProvider>().fetchAllMemberships();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Quản lý Gói thành viên', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshMemberships,
          )
        ],
      ),
      body: FutureBuilder(
        future: _fetchFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (admin.memberships.isEmpty) {
            return const Center(child: Text('Chưa có gói thành viên nào.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: admin.memberships.length,
            itemBuilder: (context, index) {
              return _buildMembershipCard(context, admin.memberships[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMembershipDialog(context),
        label: const Text('Thêm gói mới'),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildMembershipCard(BuildContext context, Map<String, dynamic> membership) {
    // Backend uses is_active
    final bool isActive = membership['is_active'] ?? true;
    final int id = membership['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isActive ? AppColors.primary : Colors.grey).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.card_membership_rounded,
                color: isActive ? AppColors.primary : Colors.grey,
              ),
            ),
            title: Text(
              membership['membershipRank'] ?? 'Gói VIP',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Text(
              'Thời hạn: ${membership['Duration']} ngày',
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: Switch(
              value: isActive,
              onChanged: (value) async {
                final error = await context.read<AdminProvider>().toggleMembershipStatus(id);
                if (error == null) {
                  _refreshMemberships();
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $error'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              activeColor: AppColors.primary,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem('Giá', _currencyFormat.format(membership['price'] ?? 0)),
                _buildInfoItem('Số bộ đề tối đa', '${membership['maxFlashcardSet'] ?? 0}'),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                      onPressed: () => _showMembershipDialog(context, membership: membership),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  void _showMembershipDialog(BuildContext context, {Map<String, dynamic>? membership}) {
    final bool isEditing = membership != null;
    final rankController = TextEditingController(text: membership?['membershipRank']);
    final durationController = TextEditingController(text: membership?['Duration']?.toString());
    final priceController = TextEditingController(text: membership?['price']?.toString());
    final maxSetController = TextEditingController(text: membership?['maxFlashcardSet']?.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Chỉnh sửa gói' : 'Thêm gói thành viên'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: rankController,
                decoration: const InputDecoration(labelText: 'Tên hạng (Rank)', hintText: 'VD: Gold, Platinum...'),
              ),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(labelText: 'Thời hạn (ngày)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Giá tiền (VNĐ)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: maxSetController,
                decoration: const InputDecoration(labelText: 'Số bộ đề tối đa'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              // Validation
              final rank = rankController.text.trim();
              if (rank.isEmpty) {
                _showError('Tên hạng không được để trống');
                return;
              }

              final duration = int.tryParse(durationController.text.trim());
              if (duration == null || duration <= 0) {
                _showError('Thời hạn phải là số nguyên lớn hơn 0');
                return;
              }

              final price = double.tryParse(priceController.text.trim());
              if (price == null || price < 0) {
                _showError('Giá tiền không hợp lệ');
                return;
              }

              final maxSet = int.tryParse(maxSetController.text.trim());
              if (maxSet == null || maxSet < 0) {
                _showError('Số bộ đề không hợp lệ');
                return;
              }

              final data = {
                'membershipRank': rank,
                'Duration': duration,
                'price': price,
                'maxFlashcardSet': maxSet,
              };

              String? error;
              if (isEditing) {
                error = await context.read<AdminProvider>().updateMembership(membership['id'], data);
              } else {
                error = await context.read<AdminProvider>().createMembership(data);
              }

              if (mounted) {
                if (error == null) {
                  Navigator.pop(ctx);
                  _refreshMemberships();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thao tác thành công'), backgroundColor: Colors.green)
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $error'), backgroundColor: Colors.red)
                  );
                }
              }
            },
            child: const Text('Lưu'),
          )
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
