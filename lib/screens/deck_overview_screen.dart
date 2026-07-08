import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/comment.dart';
import '../providers/auth_provider.dart';
import '../providers/deck_provider.dart';
import '../utils/constants.dart';
import 'flashcard_learning_screen.dart';

class DeckOverviewScreen extends StatefulWidget {
  final int deckId;
  final String title;
  final Map<String, int> ankiStats;

  const DeckOverviewScreen({
    super.key,
    required this.deckId,
    required this.title,
    required this.ankiStats,
  });

  @override
  State<DeckOverviewScreen> createState() => _DeckOverviewScreenState();
}

class _DeckOverviewScreenState extends State<DeckOverviewScreen> {
  List<Comment> _commentTree = [];
  List<Comment> _flatCommentsList = []; // Mảng phẳng lưu trữ toàn bộ comment từ API
  bool _isLoading = true;
  bool _isPublishing = false;
  int? replyingToCommentId; 
  String? _replyingToUser;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchAndProcessComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  // 1. Thuật toán Ép phẳng Cây (Facebook-style): Tối đa 2 tầng hiển thị
  List<Comment> _buildFlattenedTree(List<Comment> flatList) {
    // Tạo bản đồ tra cứu nhanh dữ liệu gốc (để lấy username khi mention)
    final Map<int, Comment> originalMap = {for (var c in flatList) c.id: c};
    
    // Tạo bản đồ cho kết quả (với list replies rỗng để gom dữ liệu phẳng vào)
    final Map<int, Comment> resultMap = {
      for (var c in flatList) c.id: c.copyWith(replies: [])
    };
    
    final List<Comment> roots = [];

    // Bước 1: Xác định các Node gốc (Tầng 1)
    for (var comment in flatList) {
      if (comment.parentId == null) {
        roots.add(resultMap[comment.id]!);
      }
    }

    // Bước 2: Duyệt các Node con (Tầng 2 trở đi) và ép phẳng
    for (var comment in flatList) {
      if (comment.parentId == null) continue;

      // Tìm "Tổ tiên gốc" (Root Ancestor) của comment này
      int currentParentId = comment.parentId!;
      Comment? ancestor = originalMap[currentParentId];
      
      // Truy vết ngược lên trên cho đến khi chạm tới Node Gốc (parentId == null)
      while (ancestor != null && ancestor.parentId != null) {
        currentParentId = ancestor.parentId!;
        ancestor = originalMap[currentParentId];
      }

      if (ancestor != null) {
        final rootComment = resultMap[ancestor.id];
        final currentComment = resultMap[comment.id]!;

        // Nếu là Tầng 3 trở đi (cháu/chắt), tự động chèn @mention người nó phản hồi trực tiếp
        final directParent = originalMap[comment.parentId];
        if (directParent != null && directParent.parentId != null) {
          currentComment.content = "@${directParent.username} ${currentComment.content}";
        }

        // Đẩy toàn bộ vào mảng replies của Gốc tương ứng (Chỉ hiển thị thụt lề 1 cấp)
        rootComment?.replies.add(currentComment);
      }
    }

    // Sắp xếp Roots: Mới nhất lên đầu
    roots.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // Sắp xếp Replies trong mỗi Root: Cũ nhất lên đầu (theo luồng hội thoại)
    for (var root in roots) {
      root.replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return roots;
  }

  Future<void> _fetchAndProcessComments() async {
    setState(() => _isLoading = true);
    final flatComments = await context.read<DeckProvider>().fetchComments(widget.deckId);
    if (mounted) {
      setState(() {
        _flatCommentsList = flatComments;
        _commentTree = _buildFlattenedTree(_flatCommentsList);
        _isLoading = false;
      });
    }
  }

  Future<void> _publishComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isPublishing = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final dio = Dio();
      
      final response = await dio.post(
        '${ApiConstants.baseUrl}/decks/${widget.deckId}/comments',
        data: {
          "content": content,
          "parentCommentId": replyingToCommentId,
        },
        options: Options(
          headers: {'Authorization': 'Bearer ${authProvider.token}'},
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> data = response.data['data'];
        
        final newComment = Comment(
          id: data['comment_id'] ?? data['id'],
          parentId: data['parent_comment_id'] ?? data['parentId'],
          content: data['content'],
          createdAt: DateTime.parse(data['created_at'] ?? data['createdAt']),
          username: authProvider.user?.username ?? 'Tôi',
          avatarUrl: null,
          totalLikes: 0,
          isLikedByMe: false,
        );

        setState(() {
          _flatCommentsList.add(newComment);
          _commentTree = _buildFlattenedTree(_flatCommentsList);
          
          _commentController.clear();
          replyingToCommentId = null;
          _replyingToUser = null;
        });
      }
    } catch (e) {
      debugPrint('Error publishing comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể gửi bình luận. Vui lòng thử lại!'))
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  void _onReply(int id, String user) {
    setState(() {
      replyingToCommentId = id;
      _replyingToUser = user;
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      replyingToCommentId = null;
      _replyingToUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Tổng quan bộ đề', style: TextStyle(fontSize: 16, color: Colors.black87)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _buildHeader(context),
                const Divider(color: Colors.black12, height: 32, thickness: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Thảo luận (${_flatCommentsList.length})', 
                    style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                if (_isLoading)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ))
                else if (_commentTree.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('Chưa có thảo luận nào.', style: TextStyle(color: Colors.black38)),
                  ))
                else
                  ..._commentTree.map((c) => _buildCommentNode(c)),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildInputBar(),
    );
  }

  // 2. Widget hiển thị comment lồng nhau (Recursion - Max 2 levels)
  Widget _buildCommentNode(Comment comment, {int depth = 0}) {
    double leftPadding = depth == 0 ? 16.0 : 48.0; 

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: leftPadding, right: 16, top: 12, bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: depth == 0 ? 18 : 14,
                backgroundImage: comment.avatarUrl != null ? NetworkImage(comment.avatarUrl!) : null,
                backgroundColor: Colors.black12,
                child: comment.avatarUrl == null ? const Icon(Icons.person, size: 20, color: Colors.grey) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(comment.username, 
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    // Hiển thị nội dung (đã được chèn @mention nếu là tầng sâu)
                    _buildCommentContent(comment.content),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await context.read<DeckProvider>().likeComment(comment.id);
                            _fetchAndProcessComments();
                          },
                          child: Row(
                            children: [
                              Icon(
                                comment.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                                size: 16,
                                color: comment.isLikedByMe ? Colors.redAccent : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(comment.totalLikes.toString(), 
                                style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        GestureDetector(
                          onTap: () => _onReply(comment.id, comment.username),
                          child: const Text('Trả lời', 
                            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Render các replies (Ép phẳng vào Tầng 2)
        if (depth == 0 && comment.replies.isNotEmpty)
          ...comment.replies.map((r) => _buildCommentNode(r, depth: 1)),
      ],
    );
  }

  // Helper để highlight phần @mention trong comment
  Widget _buildCommentContent(String text) {
    if (text.startsWith('@')) {
      final firstSpace = text.indexOf(' ');
      if (firstSpace != -1) {
        final mention = text.substring(0, firstSpace);
        final content = text.substring(firstSpace);
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(text: mention, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              TextSpan(text: content, style: const TextStyle(color: Colors.black87)),
            ],
          ),
          style: const TextStyle(fontSize: 14),
        );
      }
    }
    return Text(text, style: const TextStyle(color: Colors.black87, fontSize: 14));
  }

  Widget _buildHeader(BuildContext context) {
    // Lấy dữ liệu mới nhất từ DeckProvider để cập nhật stats sau khi học
    final deckProvider = context.watch<DeckProvider>();
    final allDecks = [...deckProvider.myDecks, ...deckProvider.publicDecks];
    
    // Tìm bộ đề hiện tại trong danh sách của provider
    final matches = allDecks.where((d) => d.id == widget.deckId);
    final currentDeck = matches.isNotEmpty ? matches.first : null;

    // Ưu tiên lấy stats từ provider, nếu không có thì dùng stats ban đầu
    final displayStats = currentDeck != null 
      ? {
          'newCount': currentDeck.ankiStats.newCount,
          'learningCount': currentDeck.ankiStats.learningCount,
          'dueCount': currentDeck.ankiStats.dueCount,
        }
      : widget.ankiStats;

    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        children: [
          Text(widget.title, textAlign: TextAlign.center, 
            style: const TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatItem('New', displayStats['newCount'] ?? 0, Colors.blue),
                  const SizedBox(height: 8),
                  _buildStatItem('Learning', displayStats['learningCount'] ?? 0, Colors.red),
                  const SizedBox(height: 8),
                  _buildStatItem('To Review', displayStats['dueCount'] ?? 0, Colors.green),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => 
                    FlashcardLearningScreen(deckId: widget.deckId, deckName: widget.title)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('STUDY NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13))),
        Text(count.toString(), style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyingToCommentId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.primary.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Đang trả lời $_replyingToUser', 
                      style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                  ),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Để lại ý kiến của bạn...',
                      hintStyle: const TextStyle(color: Colors.black26),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _isPublishing 
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        width: 24, 
                        height: 24, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)
                      ),
                    )
                  : IconButton(
                      onPressed: _publishComment,
                      icon: const Icon(Icons.send, color: AppColors.primary),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
