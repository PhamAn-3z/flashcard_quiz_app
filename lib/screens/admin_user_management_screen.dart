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
  final TextEditingController _searchController = TextEditingController();

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
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: _buildSearchSection(),
          ),
          FutureBuilder(
            future: _fetchFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && admin.users.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final filteredUsers = admin.users.where((user) {
                final name = (user['full_name'] ?? '').toString().toLowerCase();
                final email = (user['email'] ?? '').toString().toLowerCase();
                final query = _searchQuery.toLowerCase();
                return name.contains(query) || email.contains(query);
              }).toList();

              if (filteredUsers.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search_rounded, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('Không tìm thấy người dùng nào', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildUserCard(context, filteredUsers[index]),
                    childCount: filteredUsers.length,
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
        title: const Text('Quản lý Người dùng', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        centerTitle: false,
        titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 16),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFF1E40AF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _refreshUsers,
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm tên, email...',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
            suffixIcon: _searchQuery.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> user) {
    final String status = user['status'] ?? 'active';
    Color statusColor = Colors.green;
    String statusText = 'Hoạt động';

    switch (status) {
      case 'warned':
        statusColor = Colors.orange;
        statusText = 'Cảnh báo';
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

    final bool isAdmin = user['role_id']?.toString() == '3';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showUserActions(context, user),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: (isAdmin ? Colors.amber : AppColors.primary).withOpacity(0.1),
                      child: Icon(
                        isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                        color: isAdmin ? Colors.amber[800] : AppColors.primary,
                        size: 30,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(Icons.circle, color: statusColor, size: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user['full_name'] ?? user['username'] ?? 'User',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusChip(statusText, statusColor),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user['email'] ?? '',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isAdmin)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'QUẢN TRỊ VIÊN',
                            style: TextStyle(color: Colors.amber[900], fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
      ),
    );
  }

  void _showUserActions(BuildContext context, Map<String, dynamic> user) {
    if (user['role_id']?.toString() == '3') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tài khoản quản trị được bảo vệ.')));
      return;
    }

    final admin = context.read<AdminProvider>();
    final userId = (user['user_id'] ?? user['id']).toString();
    final String username = user['username'] ?? user['full_name'] ?? 'Người dùng';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom, // Tránh bàn phím nếu có
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(username, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                    Text(user['email'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    const SizedBox(height: 24),
                    _buildActionTile(
                      icon: Icons.history_rounded,
                      color: Colors.blue,
                      title: 'Lịch sử xử phạt',
                      onTap: () {
                        Navigator.pop(ctx);
                        _showPenaltyHistory(context, user);
                      },
                    ),
                    _buildActionTile(
                      icon: Icons.warning_amber_rounded,
                      color: Colors.orange,
                      title: 'Gửi cảnh cáo',
                      onTap: () {
                        Navigator.pop(ctx);
                        _showActionDialog(context, 'Gửi cảnh cáo', 'Lý do cảnh cáo...', (reason) => admin.warnUser(userId, reason));
                      },
                    ),
                    _buildActionTile(
                      icon: Icons.timer_outlined,
                      color: Colors.deepOrange,
                      title: 'Khóa tạm thời (7 ngày)',
                      onTap: () {
                        Navigator.pop(ctx);
                        _showActionDialog(context, 'Ban tạm thời', 'Lý do khóa tài khoản...', (reason) => admin.tempBanUser(userId, reason, 7));
                      },
                    ),
                    _buildActionTile(
                      icon: Icons.block_flipped,
                      color: Colors.red,
                      title: 'Khóa tài khoản vĩnh viễn',
                      isLast: true,
                      onTap: () {
                        Navigator.pop(ctx);
                        _showActionDialog(context, 'Ban vĩnh viễn', 'Lý do khóa vĩnh viễn...', (reason) => admin.permBanUser(userId, reason));
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({required IconData icon, required Color color, required String title, required VoidCallback onTap, bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color == Colors.red ? Colors.red : AppColors.textPrimary)),
          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
          contentPadding: EdgeInsets.zero,
        ),
        if (!isLast) Divider(color: Colors.grey[100]),
      ],
    );
  }

  void _showPenaltyHistory(BuildContext context, Map<String, dynamic> user) async {
    final userId = (user['user_id'] ?? user['id']).toString();
    final history = await context.read<AdminProvider>().fetchUserPenalties(userId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Lịch sử: ${user['username']}', style: const TextStyle(fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: double.maxFinite,
          child: history.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('Chưa có lịch sử xử phạt.', textAlign: TextAlign.center),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = history[index];
                    final adminName = item['admin']?['username'] ?? 'Hệ thống';
                    
                    String typeText = 'Cảnh cáo';
                    Color typeColor = Colors.orange;
                    if (item['penalty_type'] == 'temp_ban') {
                      typeText = 'Ban tạm thời';
                      typeColor = Colors.deepOrange;
                    } else if (item['penalty_type'] == 'perm_ban') {
                      typeText = 'Ban vĩnh viễn';
                      typeColor = Colors.red;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(typeText, style: TextStyle(color: typeColor, fontWeight: FontWeight.w900, fontSize: 14)),
                              const Spacer(),
                              Text(item['created_at'].toString().split('T')[0], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Lý do: ${item['reason']}', style: const TextStyle(fontSize: 13)),
                          Text('Bởi: $adminName', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('ĐÓNG', style: TextStyle(fontWeight: FontWeight.bold))
          )
        ],
      ),
    );
  }

  void _showActionDialog(BuildContext context, String title, String hint, Future<String?> Function(String reason) action) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('HỦY')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (controller.text.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              final error = await action(controller.text);
              if (mounted) {
                Navigator.pop(ctx);
                _refreshUsers();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(error == null ? 'Thực hiện thành công' : 'Thất bại: $error'),
                    backgroundColor: error == null ? Colors.green : Colors.red,
                    behavior: SnackBarBehavior.floating,
                  )
                );
              }
            },
            child: const Text('XÁC NHẬN'),
          )
        ],
      ),
    );
  }
}
