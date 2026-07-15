import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/deck_provider.dart';
import '../providers/auth_provider.dart';
import '../models/deck.dart';
import '../utils/constants.dart';
import 'bulk_import_screen.dart';
import 'create_deck_screen.dart';
import 'deck_overview_screen.dart';
import 'membership_screen.dart';
import 'package:intl/intl.dart';

class DeckListScreen extends StatefulWidget {
  final String? initialFilter;
  const DeckListScreen({super.key, this.initialFilter});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  String _searchQuery = '';
  late String _activeFilter; 
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter ?? 'Tất cả';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeckProvider>().fetchDecks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateNew(BuildContext context) async {
    final provider = context.read<DeckProvider>();
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final limitData = await provider.fetchMembershipLimit();
    
    if (context.mounted) {
      Navigator.pop(context); // Close loading

      if (limitData != null && limitData['canCreateMore'] == false) {
        _showUpgradeDialog(context, limitData);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateDeckScreen()),
        );
      }
    }
  }

  void _showUpgradeDialog(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Đạt giới hạn bộ đề', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Bạn đã tạo ${data['currentDecks']}/${data['maxDecks']} bộ đề. Vui lòng nâng cấp lên gói PRO để tạo không giới hạn!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => MembershipScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('NÂNG CẤP NGAY', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ĐỂ SAU', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipStatusBanner(DeckProvider provider) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: provider.fetchMembershipLimit(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!;
          final int current = data['currentDecks'];
          final int max = data['maxDecks'];
          final String rank = data['membershipName'];
          final bool isUnlimited = max == 0 || max >= 9999;

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.layers_outlined, 
                  size: 16, 
                  color: rank == 'Free' ? Colors.blue : Colors.amber.shade700
                ),
                const SizedBox(width: 8),
                Text(
                  'Hạn mức bộ đề ($rank): ',
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.w500, 
                    color: Colors.grey.shade600
                  ),
                ),
                Text(
                  isUnlimited ? '$current / ∞' : '$current / $max',
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.bold, 
                    color: (max > 0 && current >= max) ? Colors.redAccent : Colors.black87
                  ),
                ),
                const Spacer(),
                if (max > 0 && current >= max)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ĐÃ ĐẦY',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  List<Deck> _filterAndSortDecks(List<Deck> decks) {
    List<Deck> processed = [];
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    
    for (var deck in decks) {
      // 1. Tìm kiếm theo tên
      bool matchesSearch = normalizedQuery.isEmpty || deck.title.toLowerCase().contains(normalizedQuery);
      
      // Đệ quy lọc subDecks
      List<Deck> filteredSubs = _filterAndSortDecks(deck.subDecks);

      // 2. Lọc theo Tab Active
      bool matchesFilter = true;
      if (_activeFilter == 'Yêu thích') {
        matchesFilter = deck.isFavorite;
      }

      // Giữ lại nếu khớp tìm kiếm HOẶC có subDeck khớp
      if ((matchesSearch && matchesFilter) || filteredSubs.isNotEmpty) {
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

    // 3. Sắp xếp (Sorting)
    if (_activeFilter == 'Gần đây') {
      processed.sort((a, b) {
        if (a.lastStudiedAt == null && b.lastStudiedAt == null) return 0;
        if (a.lastStudiedAt == null) return 1;
        if (b.lastStudiedAt == null) return -1;
        return b.lastStudiedAt!.compareTo(a.lastStudiedAt!);
      });
    } else if (_activeFilter == 'Đến hạn') {
      // Ưu tiên bộ đề có nhiều thẻ "Due" nhất, sau đó đến "Learning", cuối cùng là "New"
      processed.sort((a, b) {
        if (a.ankiStats.dueCount != b.ankiStats.dueCount) {
          return b.ankiStats.dueCount.compareTo(a.ankiStats.dueCount);
        }
        if (a.ankiStats.learningCount != b.ankiStats.learningCount) {
          return b.ankiStats.learningCount.compareTo(a.ankiStats.learningCount);
        }
        return b.ankiStats.newCount.compareTo(a.ankiStats.newCount);
      });
    } else {
      // Mặc định A-Z
      processed.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }

    return processed;
  }

  Widget _buildFilterChip(String label, IconData icon, {Color? color}) {
    final isSelected = _activeFilter == label;
    return ChoiceChip(
      avatar: Icon(
        icon, 
        size: 14, 
        color: isSelected ? Colors.white : (color ?? Colors.grey)
      ),
      label: Text(
        label, 
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87, 
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
        )
      ),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _activeFilter = label);
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? AppColors.primary : Colors.black12, width: 0.5),
      ),
      showCheckmark: false,
    );
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
            onPressed: () => _handleCreateNew(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMembershipStatusBanner(deckProvider),
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bộ đề...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
              children: [
                _buildFilterChip('Tất cả', Icons.list_alt),
                _buildFilterChip('Đến hạn', Icons.alarm_on, color: Colors.green),
                _buildFilterChip('Yêu thích', Icons.star, color: Colors.amber),
                _buildFilterChip('Gần đây', Icons.history, color: Colors.blue),
              ].map((widget) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: widget,
              )).toList(),
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
    final authProvider = context.read<AuthProvider>();
    final isOwner = widget.deck.author?.username == authProvider.user?.username;

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
            leading: Icon(
              isOwner ? Icons.delete_forever : Icons.library_add_check, 
              color: isOwner ? Colors.redAccent : Colors.orange
            ),
            title: Text(
              isOwner ? 'Xóa vĩnh viễn' : 'Gỡ khỏi thư viện', 
              style: TextStyle(color: isOwner ? Colors.redAccent : Colors.orange)
            ),
            onTap: () {
              Navigator.pop(ctx);
              _showConfirmDelete(context, isOwner);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showConfirmDelete(BuildContext context, bool isOwner) {
    final TextEditingController confirmController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isOwner ? 'Xác nhận xóa' : 'Gỡ khỏi thư viện'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isOwner 
              ? 'Xóa vĩnh viễn bộ đề "${widget.deck.title}"? Thao tác này không thể hoàn tác.' 
              : 'Gỡ bộ đề "${widget.deck.title}" khỏi thư viện của bạn?'),
            if (isOwner) ...[
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
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ValueListenableBuilder(
            valueListenable: confirmController,
            builder: (context, value, _) {
              final canConfirm = !isOwner || confirmController.text == 'XÓA';
              return TextButton(
                onPressed: canConfirm 
                  ? () async {
                      Navigator.pop(ctx);
                      final bool success;
                      if (isOwner) {
                        success = await context.read<DeckProvider>().deleteDeck(widget.deck.id);
                      } else {
                        success = await context.read<DeckProvider>().unsaveDeck(widget.deck.id);
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(success 
                            ? (isOwner ? 'Đã xóa bộ đề' : 'Đã gỡ khỏi thư viện') 
                            : 'Thao tác thất bại'))
                        );
                      }
                    }
                  : null,
                child: Text(
                  isOwner ? 'Xác nhận xóa' : 'Gỡ bỏ', 
                  style: TextStyle(color: isOwner ? Colors.redAccent : Colors.orange)
                ),
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
          top: 12.0,
          bottom: 12.0,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: hasSubDecks
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: IconButton(
                        icon: Icon(
                          isExpanded ? Icons.remove_circle_outline : Icons.add_circle_outline,
                          size: 16,
                          color: Colors.grey,
                        ),
                        onPressed: onExpandToggle,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 4),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.style_rounded,
                size: 18,
                color: isDue ? const Color(0xFF64748B) : Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          deck.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDue ? Colors.black87 : Colors.black54,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => context.read<DeckProvider>().toggleFavorite(deck.id, deck.isFavorite),
                        child: Icon(
                          deck.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: deck.isFavorite ? Colors.amber : Colors.grey.shade300,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (deck.author != null) ...[
                        CircleAvatar(
                          radius: 7,
                          backgroundImage: deck.author!.avatarUrl != null ? NetworkImage(deck.author!.avatarUrl!) : null,
                          backgroundColor: Colors.grey.shade100,
                          child: deck.author!.avatarUrl == null ? const Icon(Icons.person, size: 8, color: Colors.grey) : null,
                        ),
                        const SizedBox(width: 4),
                        Text("${deck.author!.username}", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                      if (deck.lastStudiedAt != null) ...[
                        if (deck.author != null)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text("•", style: TextStyle(color: Colors.grey, fontSize: 10)),
                          ),
                        Text(_formatLastStudied(deck.lastStudiedAt), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  _buildStatCol("${deck.ankiStats.newCount}", Colors.blue),
                  _buildStatCol("${deck.ankiStats.learningCount}", Colors.red),
                  _buildStatCol("${deck.ankiStats.dueCount}", Colors.green),
                  SizedBox(
                    width: 32,
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 18, color: Colors.grey),
                      onPressed: onSettingsPressed,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
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
