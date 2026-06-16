import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/deck_provider.dart';
import '../models/deck.dart';
import '../utils/constants.dart';
import 'bulk_import_screen.dart';
import 'deck_overview_screen.dart';
import 'flashcard_learning_screen.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  String _searchQuery = '';
  String _activeFilter = 'Tất cả'; 
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeckProvider>().fetchMyDecks();
      context.read<DeckProvider>().fetchPublicDecks();
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

    if (_activeFilter == 'Yêu thích') {
      processed.sort((a, b) => (a.isFavorite == b.isFavorite) ? a.title.compareTo(b.title) : (a.isFavorite ? -1 : 1));
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
    final displayDecks = _filterAndSortDecks(deckProvider.myDecks);

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

          Expanded(
            child: deckProvider.isLoading && deckProvider.myDecks.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => deckProvider.fetchMyDecks(),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        if (displayDecks.isNotEmpty)
                          ...displayDecks.map((d) => AnkiDeckTreeWidget(deck: d))
                        else if (_searchQuery.isEmpty)
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
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
    return Container(
      padding: const EdgeInsets.all(40),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.library_books_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text("Thư viện của bạn đang trống", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_note, color: Colors.blue),
            title: const Text('Tạo bộ đề thủ công'),
            onTap: () => Navigator.pop(ctx),
          ),
          ListTile(
            leading: const Icon(Icons.paste, color: Colors.orange),
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
      color: Colors.white,
      child: Row(
        children: [
          const Expanded(child: Text('BỘ ĐỀ', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))),
          _buildCol('Mới', Colors.blue),
          _buildCol('Học', Colors.red),
          _buildCol('Hẹn', Colors.green),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildCol(String label, Color color) {
    return SizedBox(width: 45, child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold)));
  }
}

class AnkiDeckTreeWidget extends StatefulWidget {
  final Deck deck;
  final int depth;
  const AnkiDeckTreeWidget({super.key, required this.deck, this.depth = 0});

  @override
  State<AnkiDeckTreeWidget> createState() => _AnkiDeckTreeWidgetState();
}

class _AnkiDeckTreeWidgetState extends State<AnkiDeckTreeWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DeckRowWidget(
          deck: widget.deck,
          depth: widget.depth,
          isExpanded: _isExpanded,
          onExpandToggle: () => setState(() => _isExpanded = !_isExpanded),
          onSettingsPressed: () => _showActions(context),
        ),
        if (_isExpanded)
          ...widget.deck.subDecks.map((s) => AnkiDeckTreeWidget(deck: s, depth: widget.depth + 1)),
      ],
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(widget.deck.isFavorite ? Icons.star : Icons.star_border, color: Colors.orange),
            title: Text(widget.deck.isFavorite ? 'Bỏ yêu thích' : 'Yêu thích'),
            onTap: () {
              Navigator.pop(ctx);
              context.read<DeckProvider>().toggleFavorite(widget.deck.id, !widget.deck.isFavorite);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Xóa bộ đề'),
            onTap: () {
              Navigator.pop(ctx);
              // Logic xóa
            },
          ),
        ],
      ),
    );
  }
}

class DeckRowWidget extends StatelessWidget {
  final Deck deck;
  final int depth;
  final bool isExpanded;
  final VoidCallback onExpandToggle;
  final VoidCallback onSettingsPressed;

  const DeckRowWidget({super.key, required this.deck, required this.depth, required this.isExpanded, required this.onExpandToggle, required this.onSettingsPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FlashcardLearningScreen(deckId: deck.id, deckName: deck.title))),
      child: Container(
        padding: EdgeInsets.only(left: 16 + (depth * 20), right: 8, top: 12, bottom: 12),
        decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5))),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  if (deck.subDecks.isNotEmpty)
                    GestureDetector(onTap: onExpandToggle, child: Icon(isExpanded ? Icons.remove_circle_outline : Icons.add_circle_outline, size: 16, color: Colors.grey))
                  else const SizedBox(width: 16),
                  const SizedBox(width: 8),
                  Text(deck.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            _stat("${deck.ankiStats.newCount}", Colors.blue),
            _stat("${deck.ankiStats.learningCount}", Colors.red),
            _stat("${deck.ankiStats.dueCount}", Colors.green),
            IconButton(icon: const Icon(Icons.settings, size: 18, color: Colors.grey), onPressed: onSettingsPressed),
          ],
        ),
      ),
    );
  }

  Widget _stat(String val, Color color) {
    return SizedBox(width: 45, child: Center(child: Text(val, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))));
  }
}
