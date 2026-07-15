import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../utils/constants.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Quản lý Người dùng', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: admin.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 1, // Assume list from fetchAllUsers, for demo I'll use placeholders if needed
              // Wait, I should use the real data from provider if I had a list getter.
              // Let's add a getter for users in AdminProvider if not present.
              itemBuilder: (context, index) {
                // For now, let's assume fetchAllUsers returns the list directly or we use a future builder.
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: context.read<AdminProvider>().fetchAllUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox();
                    final users = snapshot.data ?? [];
                    if (users.isEmpty) return const Center(child: Text('Không có người dùng nào.'));
                    
                    return Column(
                      children: users.map((user) => _buildUserTile(context, user)).toList(),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildUserTile(BuildContext context, Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white)),
        title: Text(user['full_name'] ?? user['username'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(user['email'] ?? ''),
        trailing: const Icon(Icons.more_vert),
        onTap: () => _showUserActions(context, user),
      ),
    );
  }

  void _showUserActions(BuildContext context, Map<String, dynamic> user) {
    final admin = context.read<AdminProvider>();
    final userId = (user['user_id'] ?? user['id']).toString();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Thao tác với ${user['username']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              title: const Text('Cảnh cáo'),
              onTap: () {
                Navigator.pop(ctx);
                _showActionDialog(context, 'Cảnh cáo', (reason) => admin.warnUser(userId, reason));
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined, color: Colors.deepOrange),
              title: const Text('Ban tạm thời (7 ngày)'),
              onTap: () {
                Navigator.pop(ctx);
                _showActionDialog(context, 'Ban tạm thời', (reason) => admin.tempBanUser(userId, reason, 7));
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_flipped, color: Colors.red),
              title: const Text('Ban vĩnh viễn', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _showActionDialog(context, 'Ban vĩnh viễn', (reason) => admin.permBanUser(userId, reason));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showActionDialog(BuildContext context, String title, Future<bool> Function(String reason) action) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Lý do xử phạt...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final success = await action(controller.text);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Thực hiện thành công' : 'Thất bại'))
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
