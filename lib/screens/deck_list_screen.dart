import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/deck_provider.dart';
import '../models/deck.dart';
import '../utils/constants.dart';
import 'flashcard_learning_screen.dart';
import 'bulk_import_screen.dart';

import 'package:intl/intl.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  String _searchQuery = '';
  String _activeFilter = 'Tất cả'; // 'Tất cả', 'Yêu thích', 'Gần đây'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeckProvider>().fetchDecks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Deck> _filterAndSortDecks(List<Deck> decks) {
    List<Deck> processed = [];
    
    for (var deck in decks) {
      // 1. Filter by search
      bool matchesSearch = deck.title.toLowerCase().contains(_searchQuery.toLowerCase());
      List<Deck> filteredSubs = _filterAndSortDecks(deck.subDecks);

      if (matchesSearch || filteredSubs.isNotEmpty) {
        processed.add(Deck(
          id: deck.id,
          title: deck.title,
          parentId: deck.parentId,
          publicStatus: deck.publicStatus,
          isFavorite: deck.isFavorite,
          lastStudiedAt: deck.lastStudiedAt,
          subDecks: filteredSubs,
        ));
      }
    }

    // 2. Sort the current level
    if (_activeFilter == 'Yêu thích') {
      processed.sort((a, b) {
        if (a.isFavorite && !b.isFavorite) return -1;
        if (!a.isFavorite && b.isFavorite) return 1;
        return a.title.compareTo(b.title);
      });
    } else if (_activeFilter == 'Gần đây') {
      processed.sort((a, b) {
        if (a.lastStudiedAt == null && b.lastStudiedAt == null) return a.title.compareTo(b.title);
        if (a.lastStudiedAt == null) return 1;
        if (b.lastStudiedAt == null) return -1;
        return b.lastStudiedAt!.compareTo(a.lastStudiedAt!);
      });
    } else {
      processed.sort((a, b) => a.title.compareTo(b.title));
    }

    return processed;
  }

  @override
  Widget build(BuildContext context) {
    final deckProvider = context.watch<DeckProvider>();
    final displayDecks = _filterAndSortDecks(deckProvider.decks);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Thư viện của tôi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 28),
            onPressed: () => _showAddOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bộ đề...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: ['Tất cả', 'Yêu thích ⭐', 'Gần đây 🕒'].map((filter) {
                final label = filter.split(' ')[0];
                final isSelected = _activeFilter == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _activeFilter = label);
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.black54,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: deckProvider.isLoading && deckProvider.myDecks.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => deckProvider.fetchMyDecks(),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      children: [
                        if (displayDecks.isNotEmpty) ...[
                          _buildSectionTitle("BỘ THẺ CỦA TÔI"),
                          ...displayDecks.map((d) => AnkiDeckTreeWidget(deck: d, activeFilter: _activeFilter)),
                        ] else if (_searchQuery.isEmpty)
                          _buildEmptyState(),
                        
                        const SizedBox(height: 32),
                        _buildSectionTitle("KHÁM PHÁ CỘNG ĐỒNG"),
                        const SizedBox(height: 12),
                        _buildPublicExploreList(deckProvider),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildPublicExploreList(DeckProvider provider) {
    final list = provider.publicDecks;
    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text('Đang tải bộ đề cộng đồng...', style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final deck = list[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FlashcardLearningScreen(deckId: deck.id, deckName: deck.title),
                ),
              );
            },
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black.withOpacity(0.03)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome_motion_rounded, color: Colors.blueAccent, size: 24),
                  const Spacer(),
                  Text(deck.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  const Text('Công khai', style: TextStyle(color: Colors.blueGrey, fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "Thư viện trống rỗng",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Hãy tạo bộ đề đầu tiên hoặc sử dụng tính năng Bulk Import để bắt đầu học tập!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_note, color: Colors.blue),
            title: const Text('Tạo bộ đề thủ công'),
            onTap: () {
              Navigator.pop(ctx);
              // Navigation logic for manual creation
            },
          ),
          ListTile(
            leading: const Icon(Icons.paste, color: Colors.orange),
            title: const Text('Bulk Import (Dán từ Quizlet)'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkImportScreen()));
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class AnkiDeckTreeWidget extends StatelessWidget {
  final Deck deck;
  final int depth;
  final String activeFilter;

  const AnkiDeckTreeWidget({
    super.key,
    required this.deck,
    this.activeFilter = 'Tất cả',
    this.depth = 0
  });

  String _formatLastStudied(DateTime? date) {
    if (date == null) return 'Chưa học';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Widget _buildAnkiBadge(int count, Color color) {
    if (count == 0) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        '$count',
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double leftPadding = depth * 16.0;

    if (deck.subDecks.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.only(left: leftPadding),
        child: ExpansionTile(
          shape: const Border(),
          leading: Icon(
            depth == 0 ? Icons.folder_rounded : Icons.folder_open_rounded, 
            color: Colors.amber,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deck.title,
                style: TextStyle(
                  fontWeight: depth == 0 ? FontWeight.bold : FontWeight.w500,
                  fontSize: depth == 0 ? 16 : 14,
                ),
              ),
              if (activeFilter == 'Gần đây' && deck.lastStudiedAt != null)
                Text(
                  'Lần cuối: ${_formatLastStudied(deck.lastStudiedAt)}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
            ],
          ),
          trailing: _buildTrailingActions(context),
          children: deck.subDecks.map((subChild) {
            return AnkiDeckTreeWidget(deck: subChild, depth: depth + 1, activeFilter: activeFilter);
          }).toList(),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(left: leftPadding),
      child: ListTile(
        leading: const Icon(Icons.style, color: Colors.blue),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              deck.title,
              style: TextStyle(fontSize: 14, color: Colors.black.withValues(alpha: 0.8)),
            ),
            if (deck.ankiStats != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    _buildAnkiBadge(deck.ankiStats!['newCount'] ?? 0, Colors.blue),
                    const SizedBox(width: 6),
                    _buildAnkiBadge(deck.ankiStats!['learningCount'] ?? 0, Colors.red),
                    const SizedBox(width: 6),
                    _buildAnkiBadge(deck.ankiStats!['dueCount'] ?? 0, Colors.green),
                  ],
                ),
              ),
            if (activeFilter == 'Gần đây' && deck.lastStudiedAt != null)
              Text(
                'Lần cuối: ${_formatLastStudied(deck.lastStudiedAt)}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
        trailing: _buildTrailingActions(context),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FlashcardLearningScreen(deckId: deck.id, deckName: deck.title),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrailingActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          deck.publicStatus == 'public' ? Icons.public : Icons.lock_outline,
          size: 16,
          color: Colors.grey,
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            context.read<DeckProvider>().toggleFavorite(deck.id, !deck.isFavorite);
          },
          child: Icon(
            deck.isFavorite ? Icons.star : Icons.star_border,
            size: 18,
            color: deck.isFavorite ? Colors.orange : Colors.grey,
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.more_vert, size: 20),
          onPressed: () => _showItemActions(context),
        )
      ],
    );
  }

  void _showItemActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Xóa vĩnh viễn', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(ctx);
              _showConfirmDelete(context);
            },
          ),
        ],
      ),
    );
  }

  void _showConfirmDelete(BuildContext context) {
    final TextEditingController confirmController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn có chắc chắn muốn xóa "${deck.title}"?'),
            const SizedBox(height: 8),
            const Text('Hành động này không thể hoàn tác. Vui lòng nhập "XÓA" để xác nhận.', style: TextStyle(fontSize: 12, color: Colors.red)),
            TextField(controller: confirmController, decoration: const InputDecoration(hintText: 'XÓA')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ValueListenableBuilder(
            valueListenable: confirmController,
            builder: (context, value, _) {
              return TextButton(
                onPressed: confirmController.text == 'XÓA' 
                  ? () async {
                      Navigator.pop(ctx);
                      final success = await context.read<DeckProvider>().deleteDeck(deck.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(success ? 'Đã xóa bộ đề' : 'Xóa thất bại'))
                        );
                      }
                    }
                  : null,
                child: const Text('Xác nhận xóa', style: TextStyle(color: Colors.red)),
              );
            },
          )
        ],
      ),
    );
  }
}
