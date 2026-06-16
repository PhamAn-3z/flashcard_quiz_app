import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Tin nhắn', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, size: 28),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: 8,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 80),
              itemBuilder: (context, index) {
                return _buildChatTile(context, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: 'Tìm kiếm cuộc trò chuyện...',
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
            border: InputBorder.none,
            icon: Icon(Icons.search_rounded, size: 20, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, int index) {
    final names = ['Nguyễn Văn A', 'Trần Thị B', 'Lê Văn C', 'Phạm Thị D', 'Hoàng Văn E', 'Vũ Thị F', 'Đặng Văn G', 'Bùi Thị H'];
    final lastMsgs = [
      'Chào bạn, bộ thẻ N3 này hay quá!',
      'Hôm nay bạn đã hoàn thành streak chưa?',
      'Cảm ơn bạn đã chia sẻ nhé.',
      'Bạn có rảnh luyện nghe không?',
      'Hẹn gặp bạn ở buổi offline nhé.',
      'Dịch giúp mình câu này với...',
      'Học tiếng Nhật vui thật đấy!',
      'Chào buổi sáng, chúc bạn học tốt!'
    ];
    final times = ['2 phút', '1 giờ', '3 giờ', 'Hôm qua', '2 ngày', '3 ngày', '1 tuần', '2 tuần'];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              names[index].isNotEmpty ? names[index][0] : '?', 
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
          if (index < 2)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(names[index], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      subtitle: Text(
        lastMsgs[index],
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: index < 2 ? AppColors.textPrimary : AppColors.textSecondary, 
                        fontWeight: index < 2 ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(times[index], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          if (index < 2)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(userName: names[index]),
          ),
        );
      },
    );
  }
}
