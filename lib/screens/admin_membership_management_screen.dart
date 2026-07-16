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
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          FutureBuilder(
            future: _fetchFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && admin.memberships.isEmpty) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }

              if (admin.memberships.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.card_membership_rounded, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text('Chưa có gói thành viên nào.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildMembershipCard(context, admin.memberships[index]),
                    childCount: admin.memberships.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMembershipDialog(context),
        label: const Text('Tạo gói mới', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
        title: const Text('Gói Hội viên', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        centerTitle: false,
        titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 16),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFFE11D48)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _refreshMemberships,
        ),
      ],
    );
  }

  Widget _buildMembershipCard(BuildContext context, Map<String, dynamic> membership) {
    final bool isActive = membership['is_active'] ?? true;
    final int id = membership['id'];
    final String rank = membership['membershipRank'] ?? 'Gói VIP';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 4))
        ],
        border: isActive ? null : Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isActive ? AppColors.primary : Colors.grey).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: isActive ? AppColors.primary : Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rank.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary, letterSpacing: 1),
                      ),
                      Text(
                        'Thời hạn: ${membership['Duration']} ngày',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: isActive,
                  activeColor: AppColors.primary,
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
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoCol('GIÁ NIÊM YẾT', _currencyFormat.format(membership['price'] ?? 0), Colors.green),
                _buildInfoCol('HẠN MỨC BỘ ĐỀ', '${membership['maxFlashcardSet'] ?? 0} bộ', Colors.blue),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[50],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                  onPressed: () => _showMembershipDialog(context, membership: membership),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoCol(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: color)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(isEditing ? 'Cập nhật gói' : 'Thêm gói hội viên mới', style: const TextStyle(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModernField(rankController, 'Tên hạng (VD: Premium)', Icons.title_rounded),
              const SizedBox(height: 12),
              _buildModernField(durationController, 'Thời hạn (ngày)', Icons.timer_rounded, isNumber: true),
              const SizedBox(height: 12),
              _buildModernField(priceController, 'Giá tiền (VNĐ)', Icons.payments_rounded, isNumber: true),
              const SizedBox(height: 12),
              _buildModernField(maxSetController, 'Hạn mức bộ đề', Icons.layers_rounded, isNumber: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('HỦY')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              final rank = rankController.text.trim();
              final duration = int.tryParse(durationController.text.trim());
              final price = double.tryParse(priceController.text.trim());
              final maxSet = int.tryParse(maxSetController.text.trim());

              if (rank.isEmpty || duration == null || price == null || maxSet == null) {
                _showError('Vui lòng nhập đầy đủ thông tin hợp lệ');
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
                    const SnackBar(content: Text('Thao tác thành công'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating)
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $error'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating)
                  );
                }
              }
            },
            child: const Text('LƯU GÓI'),
          )
        ],
      ),
    );
  }

  Widget _buildModernField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }
}
