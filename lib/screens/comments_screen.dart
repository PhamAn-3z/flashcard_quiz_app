import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/deck_provider.dart';
import '../models/comment.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class CommentsScreen extends StatefulWidget {
  final int deckId;
  final String deckTitle;

  const CommentsScreen({super.key, required this.deckId, required this.deckTitle});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    final comments = await context.read<DeckProvider>().fetchComments(widget.deckId);
    if (mounted) {
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final success = await context.read<DeckProvider>().addComment(
      widget.deckId,
      _commentController.text.trim(),
    );

    if (success) {
      _commentController.clear();
      _loadComments();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi khi thêm bình luận')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Bình luận: ${widget.deckTitle}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? const Center(child: Text('Chưa có bình luận nào.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return _buildCommentItem(comment);
                        },
                      ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    final String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(comment.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  comment.username[0].toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                comment.username,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              Text(
                formattedDate,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.content,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Thêm bình luận...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addComment,
              icon: const Icon(Icons.send_rounded, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
