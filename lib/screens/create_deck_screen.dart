import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'bulk_import_screen.dart';

class CreateDeckScreen extends StatefulWidget {
  const CreateDeckScreen({super.key});

  @override
  State<CreateDeckScreen> createState() => _CreateDeckScreenState();
}

class _CreateDeckScreenState extends State<CreateDeckScreen> {
  // 1. THÔNG TIN CHUNG BỘ ĐỀ (Title, Description)
  final Map<String, dynamic> dbContext = {
    'title': TextEditingController(),
    'description': TextEditingController(),
  };

  // 2. CẤU HÌNH CỘT (HEADERS): Quản lý danh sách các thuộc tính động của Ma trận
  List<Map<String, String>> headers = [
    {'id': 'kanji', 'label': 'THUẬT NGỮ'},
    {'id': 'hiragana', 'label': 'ĐỊNH NGHĨA'},
  ];

  // 3. DỮ LIỆU MA TRẬN 2 CHIỀU: List các hàng, mỗi hàng là Map chứa Controllers
  List<Map<String, dynamic>> matrixRows = [];

  @override
  void initState() {
    super.initState();
    // Khởi tạo 2 hàng mặc định ban đầu
    _addNewRow();
    _addNewRow();
  }

  @override
  void dispose() {
    // Giải phóng bộ nhớ cho toàn bộ Controllers
    dbContext['title'].dispose();
    dbContext['description'].dispose();
    for (var row in matrixRows) {
      for (var header in headers) {
        (row[header['id']] as TextEditingController?)?.dispose();
      }
    }
    super.dispose();
  }

  // --- LOGIC XỬ LÝ MA TRẬN ---

  // Thêm cột mới: Cập nhật headers và bổ sung Controller cho tất cả các hàng hiện tại
  void _addNewColumn(String label) {
    if (label.isEmpty) return;
    setState(() {
      final String newId = 'col_${DateTime.now().millisecondsSinceEpoch}';
      headers.add({'id': newId, 'label': label.toUpperCase()});
      
      // Quan trọng: Phải bổ sung Controller cho cột mới này tại TẤT CẢ các hàng đang có
      for (var row in matrixRows) {
        row[newId] = TextEditingController();
      }
    });
  }

  // Thêm hàng mới: Khởi tạo Map chứa đầy đủ Controllers tương ứng với số lượng headers hiện tại
  void _addNewRow() {
    setState(() {
      Map<String, dynamic> newRow = {
        'image_url': null,
        'audio_url': null,
      };
      // Duyệt qua headers để tạo Controller cho từng ô trong hàng mới
      for (var header in headers) {
        newRow[header['id']!] = TextEditingController();
      }
      matrixRows.add(newRow);
    });
  }

  void _removeRow(int index) {
    setState(() {
      for (var header in headers) {
        (matrixRows[index][header['id']] as TextEditingController?)?.dispose();
      }
      matrixRows.removeAt(index);
    });
  }

  // Logic hứng dữ liệu từ màn hình Import
  Future<void> _goToBulkImport() async {
    final dynamic result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BulkImportScreen()),
    );

    if (result != null && result is List<List<String>>) {
      setState(() {
        for (var rowData in result) {
          if (rowData.isEmpty) continue;
          Map<String, dynamic> newRow = {'image_url': null, 'audio_url': null};
          
          for (int i = 0; i < headers.length; i++) {
            String val = (i < rowData.length) ? rowData[i] : "";
            newRow[headers[i]['id']!] = TextEditingController(text: val);
          }
          matrixRows.add(newRow);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mỗi ô nhập liệu chiếm 32% chiều ngang màn hình để hiển thị được ~3 ô cùng lúc
    final double cellWidth = MediaQuery.of(context).size.width * 0.32;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tạo bộ đề Ma trận', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () { /* Logic lưu vào DB */ },
            icon: const Icon(Icons.done, color: AppColors.primary, size: 28),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeckInfo(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildActionButton(
                        icon: Icons.add_rounded,
                        label: 'Nhập',
                        onPressed: _goToBulkImport,
                      ),
                      const SizedBox(width: 12),
                      _buildActionButton(
                        icon: Icons.view_column_rounded,
                        label: 'Thêm cột',
                        onPressed: _showAddColumnDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Danh sách Ma trận Thẻ bài
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: matrixRows.length,
                    itemBuilder: (context, index) => _buildMatrixCard(index, cellWidth),
                  ),

                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: _addNewRow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: const Text('+ THÊM THẺ MỚI', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET TẤM THẺ BÀI (MATRIX CARD) ---
  Widget _buildMatrixCard(int index, double cellWidth) {
    final row = matrixRows[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          // 1. Header: Chỉ số và Nhóm icon chức năng (Ghim cố định trên Card)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              Row(
                children: [
                  const Icon(Icons.file_download_outlined, size: 20, color: Colors.grey),
                  const SizedBox(width: 12),
                  const Icon(Icons.mic_none_rounded, size: 20, color: Colors.grey),
                  const SizedBox(width: 12),
                  const Icon(Icons.auto_fix_high_rounded, size: 20, color: Colors.amber),
                  const SizedBox(width: 12),
                  const Icon(Icons.menu, size: 20, color: Colors.grey),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => _removeRow(index),
                    child: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Body: Vùng nhập liệu (Cuộn ngang) + Hình ảnh (Cố định phải)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TRÁI: Vùng cuộn ngang chứa các ô nhập liệu động
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: headers.map((header) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: cellWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: row[header['id']] as TextEditingController?,
                                style: const TextStyle(fontSize: 15),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                header['label']!,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // PHẢI: Nút Hình ảnh ghim cố định không trượt theo nội dung
              Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.only(left: 12, top: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, size: 24, color: Colors.grey),
                    Text('Hình ảnh', style: TextStyle(fontSize: 8, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeckInfo() {
    return Column(
      children: [
        TextField(
          controller: dbContext['title'],
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: 'Tiêu đề',
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: dbContext['description'],
          decoration: const InputDecoration(hintText: 'Thêm mô tả...', border: InputBorder.none),
        ),
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showAddColumnDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm thuộc tính mới'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ví dụ: Âm Hán Việt, Ví dụ mẫu...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              _addNewColumn(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }
}
