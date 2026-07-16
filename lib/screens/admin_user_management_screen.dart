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
  String _searchQuery = '';
  late Future<void> _fetchFuture;

  @override
  void initState() {
    super.initState();
    _fetchFuture = context.read<AdminProvider>().fetchAllUsers();
  }

  void _refreshUsers() {
    setState(() {
      _fetchFuture = context.read<AdminProvider>().fetchAllUsers();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshUsers,
          )
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: FutureBuilder(
              future: _fetchFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredUsers = admin.users.where((user) {
                  final name = (user['full_name'] ?? '').toString().toLowerCase();
                  final email = (user['email'] ?? '').toString().toLowerCase();
                  final query = _searchQuery.toLowerCase();
                  return name.contains(query) || email.contains(query);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text('Không tìm thấy người dùng nào.'));
                }

                return RefreshIndicator(
                  onRefresh: () async => _refreshUsers(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      return _buildUserTile(context, filteredUsers[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm người dùng...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, Map<String, dynamic> user) {
    final String status = user['status'] ?? 'active';
    Color statusColor = Colors.green;
    String statusText = 'Hoạt động';

    switch (status) {
      case 'warned':
        statusColor = Colors.orange;
        statusText = 'Bị cảnh cáo';
        break;
      case 'temporarily_banned':
        statusColor = Colors.deepOrange;
        statusText = 'Khóa tạm thời';
        break;
      case 'permanently_banned':
        statusColor = Colors.red;
        statusText = 'Khóa vĩnh viễn';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: const Icon(Icons.person_rounded, color: AppColors.primary),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user['full_name'] ?? user['username'] ?? 'User',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusText,
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user['email'] ?? ''),
            if (user['role_id'] == 3)
              const Text('ADMIN', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10)),
          ],
        ),
        onTap: () => _showUserActions(context, user),
      ),
    );
  }

  void _showUserActions(BuildContext context, Map<String, dynamic> user) {
    if (user['role_id'] == 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể tác động lên tài khoản Admin khác')));
      return;
    }

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
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.history_rounded, color: Colors.blue),
              title: const Text('Xem lịch sử xử phạt'),
              onTap: () {
                Navigator.pop(ctx);
                _showPenaltyHistory(context, user);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              title: const Text('Gửi cảnh cáo'),
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

  void _showPenaltyHistory(BuildContext context, Map<String, dynamic> user) async {
    final userId = (user['user_id'] ?? user['id']).toString();
    final history = await context.read<AdminProvider>().fetchUserPenalties(userId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Lịch sử xử phạt: ${user['username']}'),
        content: SizedBox(
          width: double.maxFinite,
          child: history.isEmpty
              ? const Text('Chưa có lịch sử xử phạt.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return ListTile(
                      title: Text(item['penalty_type'] == 'warning' ? 'Cảnh cáo' : 'Ban'),
                      subtitle: Text('Lý do: ${item['reason']}\nNgày: ${item['created_at'].toString().split('T')[0]}'),
                      isThreeLine: true,
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
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
          decoration: const InputDecoration(hintText: 'Nhập lý do...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              final success = await action(controller.text);
              if (mounted) {
                Navigator.pop(ctx);
                _refreshUsers();
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
