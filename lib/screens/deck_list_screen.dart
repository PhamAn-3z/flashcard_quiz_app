import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/deck_provider.dart';
import '../models/deck.dart';
import '../utils/constants.dart';
import 'bulk_import_screen.dart';
import 'create_deck_screen.dart';
import 'deck_overview_screen.dart';
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
          author: deck.author,
          ankiStats: deck.ankiStats,
          subDecks: filteredSubs,
        ));
      }
    }

    // 2. Filter by Active Filter Tab (Favorite)
    if (_activeFilter == 'Yêu thích') {
      processed = processed.where((d) => d.isFavorite || d.subDecks.isNotEmpty).toList();
    }

    // 3. Sort
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Thư viện Anki", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 24, color: Colors.black54),
            onPressed: () => _showAddOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bộ đề...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // 2. Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: ['Tất cả', 'Yêu thích ⭐', 'Gần đây 🕒'].map((filter) {
                final label = filter.split(' ')[0];
                final isSelected = _activeFilter == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 12)),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _activeFilter = label);
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide.none,
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(color: Colors.black12, height: 1),
          const DeckHeaderWidget(),

          // 3. Tree View Area
          Expanded(
            child: deckProvider.isLoading && deckProvider.decks.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : displayDecks.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => deckProvider.fetchDecks(),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: displayDecks.length,
                          itemBuilder: (context, index) {
                            return AnkiDeckTreeWidget(
                              deck: displayDecks[index],
                              activeFilter: _activeFilter,
                            );
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
          Icon(Icons.library_books_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "Thư viện trống",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black38),
          ),
        ],
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_note, color: Colors.blueAccent),
            title: const Text('Tạo bộ đề thủ công'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateDeckScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.paste, color: Colors.orangeAccent),
            title: const Text('Bulk Import (Quizlet)'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkImportScreen()));
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class DeckHeaderWidget extends StatelessWidget {
  const DeckHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.black12, width: 1)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'BỘ ĐỀ',
              style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
          _buildHeaderCol('New', Colors.blue),
          _buildHeaderCol('Learn', Colors.red),
          _buildHeaderCol('Due', Colors.green),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildHeaderCol(String label, Color color) {
    return SizedBox(
      width: 45,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(color: color.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class AnkiDeckTreeWidget extends StatefulWidget {
  final Deck deck;
  final int depth;
  final String activeFilter;

  const AnkiDeckTreeWidget({
    super.key,
    required this.deck,
    this.activeFilter = 'Tất cả',
    this.depth = 0
  });

  @override
  State<AnkiDeckTreeWidget> createState() => _AnkiDeckTreeWidgetState();
}

class _AnkiDeckTreeWidgetState extends State<AnkiDeckTreeWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    bool hasSubDecks = widget.deck.subDecks.isNotEmpty;

    return Column(
      children: [
        DeckRowWidget(
          deck: widget.deck,
          depth: widget.depth,
          isExpanded: _isExpanded,
          activeFilter: widget.activeFilter,
          onExpandToggle: () => setState(() => _isExpanded = !_isExpanded),
          onSettingsPressed: () => _showItemActions(context),
        ),
        if (hasSubDecks && _isExpanded)
          ...widget.deck.subDecks.map((sub) => AnkiDeckTreeWidget(
            deck: sub,
            depth: widget.depth + 1,
            activeFilter: widget.activeFilter,
          )),
      ],
    );
  }

  void _showItemActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              widget.deck.isFavorite ? Icons.star : Icons.star_outline, 
              color: widget.deck.isFavorite ? Colors.orange : Colors.black45
            ),
            title: Text(widget.deck.isFavorite ? 'Bỏ yêu thích' : 'Yêu thích'),
            onTap: () async {
              Navigator.pop(ctx);
              await context.read<DeckProvider>().toggleFavorite(widget.deck.id, widget.deck.isFavorite);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text('Xóa vĩnh viễn', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(ctx);
              _showConfirmDelete(context);
            },
          ),
          const SizedBox(height: 16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Xóa bộ đề "${widget.deck.title}"?'),
            const SizedBox(height: 12),
            const Text('Nhập "XÓA" để xác nhận:', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                hintText: 'XÓA',
              ),
            ),
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
                      final success = await context.read<DeckProvider>().deleteDeck(widget.deck.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(success ? 'Đã xóa bộ đề' : 'Xóa thất bại'))
                        );
                      }
                    }
                  : null,
                child: const Text('Xác nhận xóa', style: TextStyle(color: Colors.redAccent)),
              );
            },
          )
        ],
      ),
    );
  }
}

class DeckRowWidget extends StatelessWidget {
  final Deck deck;
  final int depth;
  final bool isExpanded;
  final String activeFilter;
  final VoidCallback onExpandToggle;
  final VoidCallback onSettingsPressed;

  const DeckRowWidget({
    super.key,
    required this.deck,
    required this.depth,
    required this.isExpanded,
    required this.activeFilter,
    required this.onExpandToggle,
    required this.onSettingsPressed,
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

  @override
  Widget build(BuildContext context) {
    bool hasSubDecks = deck.subDecks.isNotEmpty;
    bool isDue = deck.ankiStats.dueCount > 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DeckOverviewScreen(
              deckId: deck.id,
              title: deck.title,
              ankiStats: {
                'newCount': deck.ankiStats.newCount,
                'learningCount': deck.ankiStats.learningCount,
                'dueCount': deck.ankiStats.dueCount,
              },
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.only(
          left: 16.0 + (depth * 20.0),
          right: 8.0,
          top: 10.0,
          bottom: 10.0,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: hasSubDecks
                        ? IconButton(
                            icon: Icon(
                              isExpanded ? Icons.remove_circle_outline : Icons.add_circle_outline,
                              size: 16,
                              color: Colors.grey,
                            ),
                            onPressed: onExpandToggle,
                            padding: EdgeInsets.zero,
                          )
                        : null,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    hasSubDecks ? Icons.folder_rounded : Icons.collections_bookmark_rounded,
                    size: 18,
                    color: isDue ? Colors.blueGrey : Colors.grey.shade300,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                deck.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDue ? Colors.black87 : Colors.black54,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                deck.isFavorite ? Icons.star : Icons.star_border,
                                color: deck.isFavorite ? Colors.amber : Colors.grey.shade300,
                                size: 16,
                              ),
                              onPressed: () => context.read<DeckProvider>().toggleFavorite(deck.id, deck.isFavorite),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        if (activeFilter == 'Gần đây' && deck.lastStudiedAt != null)
                          Text(
                            'Lần cuối: ${_formatLastStudied(deck.lastStudiedAt)}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          )
                        else if (deck.author != null)
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 7,
                                backgroundImage: deck.author!.avatarUrl != null ? NetworkImage(deck.author!.avatarUrl!) : null,
                                backgroundColor: Colors.grey.shade100,
                                child: deck.author!.avatarUrl == null ? const Icon(Icons.person, size: 8, color: Colors.grey) : null,
                              ),
                              const SizedBox(width: 4),
                              Text("Tác giả: ${deck.author!.username}", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildStatCol("${deck.ankiStats.newCount}", Colors.blue),
            _buildStatCol("${deck.ankiStats.learningCount}", Colors.red),
            _buildStatCol("${deck.ankiStats.dueCount}", Colors.green),
            SizedBox(
              width: 40,
              child: IconButton(
                icon: const Icon(Icons.settings, size: 18, color: Colors.grey),
                onPressed: onSettingsPressed,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCol(String count, Color color) {
    String text = (count == "" || count == "null" || count == "0") ? "0" : count;
    
    return SizedBox(
      width: 45,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
