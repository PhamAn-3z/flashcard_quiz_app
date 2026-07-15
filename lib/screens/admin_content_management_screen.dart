import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/deck.dart';
import '../utils/constants.dart';

class AdminContentManagementScreen extends StatefulWidget {
  const AdminContentManagementScreen({super.key});

  @override
  State<AdminContentManagementScreen> createState() => _AdminContentManagementScreenState();
}

class _AdminContentManagementScreenState extends State<AdminContentManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Quản lý Nội dung', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<Deck>>(
        future: context.read<AdminProvider>().fetchAllDecks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final decks = snapshot.data ?? [];
          if (decks.isEmpty) return const Center(child: Text('Không có bộ đề nào trong hệ thống.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: decks.length,
            itemBuilder: (context, index) {
              final deck = decks[index];
              return _buildDeckTile(deck);
            },
          );
        },
      ),
    );
  }

  Widget _buildDeckTile(Deck deck) {
    bool isPublic = deck.publicStatus == 'public';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: ListTile(
        title: Text(deck.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Author ID: ${deck.parentId == null ? "Root" : deck.parentId} • ${deck.totalCards} thẻ'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isPublic ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isPublic ? 'Public' : 'Private',
            style: TextStyle(color: isPublic ? Colors.green : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
