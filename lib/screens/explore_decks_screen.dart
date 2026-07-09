import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/deck_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import 'deck_overview_screen.dart';
import 'dart:async';

class ExploreDecksScreen extends StatefulWidget {
  final String? initialSearchQuery;
  const ExploreDecksScreen({super.key, this.initialSearchQuery});

  @override
  State<ExploreDecksScreen> createState() => _ExploreDecksScreenState();
}

class _ExploreDecksScreenState extends State<ExploreDecksScreen> {
  String _activeSort = 'views_today';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  int _currentPage = 1;
  bool _hasMore = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
      _searchQuery = widget.initialSearchQuery!;
      _searchController.text = widget.initialSearchQuery!;
    }

    // Thêm listener cho controller để cập nhật UI nút Clear ngay lập tức
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDecks();
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
        });
        _fetchDecks();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!context.read<DeckProvider>().isLoading && _hasMore) {
        _loadMore();
      }
    }
  }

  void _fetchDecks() async {
    _currentPage = 1;
    setState(() => _hasMore = true);
    
    // Cuộn lên đầu danh sách trước khi fetch dữ liệu mới
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    final count = await context.read<DeckProvider>().fetchExploreDecks(
      sortBy: _activeSort,
      filter: 'all',
      limit: 15,
      page: _currentPage,
      searchTerm: _searchQuery,
      append: false,
    );
    
    // Nếu số lượng trả về ít hơn Limit, nghĩa là không còn trang tiếp theo
    if (mounted && count < 15) {
      setState(() => _hasMore = false);
    }
  }

  Future<void> _loadMore() async {
    _currentPage++;
    final provider = context.read<DeckProvider>();
    final beforeCount = provider.exploreDecks.length;
    
    await provider.fetchExploreDecks(
      sortBy: _activeSort,
      filter: 'all',
      limit: 15,
      page: _currentPage,
      searchTerm: _searchQuery,
      append: true,
    );

    // Nếu sau khi load mà số lượng không tăng thêm, nghĩa là đã hết dữ liệu
    if (provider.exploreDecks.length == beforeCount) {
      setState(() => _hasMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Khám phá bộ đề cộng đồng', 
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // 1. YouTube-style Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bộ đề công khai...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.black54, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                        setState(() {});
                      },
                    )
                  : null,
                filled: true,
                fillColor: const Color(0xFFE2E8F0).withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1),
                ),
              ),
            ),
          ),

          // 2. Sort Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildSortChip('Hot hôm nay', 'views_today', Icons.whatshot),
                const SizedBox(width: 8),
                _buildSortChip('Yêu thích nhất', 'favorites', Icons.star),
                const SizedBox(width: 8),
                _buildSortChip('Lượt xem nhiều', 'views', Icons.visibility),
                const SizedBox(width: 8),
                _buildSortChip('Mới nhất', 'created_at', Icons.new_releases),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Results List
          Expanded(
            child: Consumer<DeckProvider>(
              builder: (context, provider, _) {
                final decks = provider.exploreDecks;
                
                if (provider.isLoading && decks.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (decks.isEmpty) {
                  return const Center(child: Text('Không tìm thấy bộ đề nào.'));
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: decks.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < decks.length) {
                      final deck = decks[index];
                      return _buildExploreCard(context, deck);
                    } else {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value, IconData icon) {
    final isSelected = _activeSort == value;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 12)),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() => _activeSort = value);
          _fetchDecks();
        }
      },
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
    );
  }

  void _navigateToOverview(BuildContext context, dynamic deck) {
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
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 30) return '${diff.inDays} ngày trước';
    return '${(diff.inDays / 30).floor()} tháng trước';
  }

  Widget _buildExploreCard(BuildContext context, dynamic deck) {
    final stats = deck.stats;
    final authProvider = context.read<AuthProvider>();
    final isOwner = deck.author?.username == authProvider.user?.username;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () => _navigateToOverview(context, deck),
        title: Row(
          children: [
            Expanded(child: Text(deck.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            if (isOwner)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('CỦA TÔI', style: TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text('${deck.totalCards} thẻ • Tác giả: ${isOwner ? "Bạn" : (deck.author?.username ?? "Ẩn danh")}', 
                  style: const TextStyle(fontSize: 12)),
                if (deck.createdAt != null) ...[
                  const Text(' • ', style: TextStyle(fontSize: 12)),
                  Text(_formatDate(deck.createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildSmallStat(Icons.visibility, '${stats?.totalViews ?? 0}', Colors.grey),
                const SizedBox(width: 12),
                _buildSmallStat(Icons.star, '${stats?.favoritesCount ?? 0}', Colors.amber),
                if (stats?.viewsToday != null && stats!.viewsToday > 0) ...[
                  const SizedBox(width: 12),
                  _buildSmallStat(Icons.whatshot, '${stats.viewsToday}', Colors.orange),
                ]
              ],
            ),
          ],
        ),
        trailing: isOwner
            ? InkWell(
                onTap: () => _navigateToOverview(context, deck),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.account_circle, color: Colors.blue, size: 28),
                ),
              )
            : deck.isInLibrary 
                ? IconButton(
                    icon: const Icon(Icons.library_add_check_rounded, color: Colors.green, size: 28),
                    onPressed: () => context.read<DeckProvider>().unsaveDeck(deck.id),
                    tooltip: 'Gỡ khỏi thư viện',
                  )
                : IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 28),
                    onPressed: () async {
                      final success = await context.read<DeckProvider>().saveDeck(deck.id);
                      if (context.mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã thêm vào thư viện'),
                            duration: Duration(seconds: 1),
                          )
                        );
                      }
                    },
                    tooltip: 'Lưu vào thư viện',
                  ),
      ),
    );
  }

  Widget _buildSmallStat(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
