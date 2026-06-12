import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/deck_provider.dart';
import '../models/deck.dart';
import '../utils/constants.dart';
import 'flashcard_learning_screen.dart';
import 'bulk_import_screen.dart';

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

  List<Deck> _filterDecks(List<Deck> decks) {
    List<Deck> filtered = decks;

    if (_searchQuery.isNotEmpty) {
      filtered = _filterBySearch(filtered, _searchQuery);
    }

    if (_activeFilter == 'Yêu thích') {
      filtered = _filterByFavorite(filtered);
    } else if (_activeFilter == 'Gần đây') {
      filtered = List.from(filtered);
      filtered.sort((a, b) {
        if (a.lastStudiedAt == null) return 1;
        if (b.lastStudiedAt == null) return -1;
        return b.lastStudiedAt!.compareTo(a.lastStudiedAt!);
      });
    }

    return filtered;
  }

  List<Deck> _filterBySearch(List<Deck> source, String query) {
    List<Deck> result = [];
    for (var deck in source) {
      bool matches = deck.title.toLowerCase().contains(query.toLowerCase());
      List<Deck> matchingSubs = _filterBySearch(deck.subDecks, query);
      
      if (matches || matchingSubs.isNotEmpty) {
        result.add(Deck(
          id: deck.id,
          title: deck.title,
          parentId: deck.parentId,
          publicStatus: deck.publicStatus,
          isFavorite: deck.isFavorite,
          lastStudiedAt: deck.lastStudiedAt,
          subDecks: matchingSubs,
        ));
      }
    }
    return result;
  }

  List<Deck> _filterByFavorite(List<Deck> source) {
    List<Deck> result = [];
    for (var deck in source) {
      List<Deck> favoriteSubs = _filterByFavorite(deck.subDecks);
      if (deck.isFavorite || favoriteSubs.isNotEmpty) {
        result.add(Deck(
          id: deck.id,
          title: deck.title,
          parentId: deck.parentId,
          publicStatus: deck.publicStatus,
          isFavorite: deck.isFavorite,
          lastStudiedAt: deck.lastStudiedAt,
          subDecks: favoriteSubs,
        ));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final deckProvider = context.watch<DeckProvider>();
    final displayDecks = _filterDecks(deckProvider.decks);

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
            child: deckProvider.isLoading && deckProvider.decks.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : displayDecks.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => deckProvider.fetchDecks(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          itemCount: displayDecks.length,
                          itemBuilder: (context, index) {
                            return AnkiDeckTreeWidget(deck: displayDecks[index]);
                          },
                        ),
                      ),
          ),
        ],
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

  const AnkiDeckTreeWidget({
    super.key,
    required this.deck,
    this.depth = 0
  });

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
          title: Text(
            deck.title,
            style: TextStyle(
              fontWeight: depth == 0 ? FontWeight.bold : FontWeight.w500,
              fontSize: depth == 0 ? 16 : 14,
            ),
          ),
          trailing: _buildTrailingActions(context),
          children: deck.subDecks.map((subChild) {
            return AnkiDeckTreeWidget(deck: subChild, depth: depth + 1);
          }).toList(),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(left: leftPadding),
      child: ListTile(
        leading: const Icon(Icons.style, color: Colors.blue),
        title: Text(
          deck.title,
          style: TextStyle(fontSize: 14, color: Colors.black.withValues(alpha: 0.8)),
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
        Icon(
          deck.isFavorite ? Icons.star : Icons.star_border,
          size: 18,
          color: deck.isFavorite ? Colors.orange : Colors.grey,
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
