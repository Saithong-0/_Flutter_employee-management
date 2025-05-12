import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/employees.dart';
import '../services/database_services.dart';
import 'employee_edit_screen.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final String? employeeId;

  const EmployeeDetailScreen({Key? key, required this.employeeId}) : super(key: key);

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  Employee? _employee;
  String _departmentTitle = '';

  @override
  void initState() {
    super.initState();
    if (widget.employeeId != null) {
      _loadData();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData() async {
    try {
      final employee = await _databaseService.getEmployeeById(widget.employeeId!);
      final departments = await _databaseService.getDepartments();
      final dep = departments.firstWhere(
        (d) => d['dep_id'].toString().trim() == employee.department.trim(),
        orElse: () => {'dep_title': 'ไม่ทราบแผนก'},
      );

      setState(() {
        _employee = employee;
        _departmentTitle = dep['dep_title'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
      );
    }
  }

  ImageProvider? _resolveImage(String url) {
    try {
      if (url.isEmpty) return null;
      if (url.startsWith('http')) {
        return NetworkImage(Uri.encodeFull(url));
      } else {
        return MemoryImage(base64Decode(url));
      }
    } catch (e) {
      debugPrint('Error decoding image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[800], fontSize: 16);
    final valueStyle = TextStyle(color: Colors.black87, fontSize: 15);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('รายละเอียดพนักงาน', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: _isLoading || _employee == null
          ? Center(
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('ไม่พบข้อมูลพนักงาน', style: TextStyle(color: Colors.grey)),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _resolveImage(_employee!.photo),
                    child: _employee!.photo.isEmpty
                        ? Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  SizedBox(height: 32),
                  Table(
                    columnWidths: const {
                      0: IntrinsicColumnWidth(),
                      1: FlexColumnWidth(),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      _buildTableRow('ชื่อ', _employee!.firstName, labelStyle, valueStyle),
                      _buildTableRow('นามสกุล', _employee!.lastName, labelStyle, valueStyle),
                      _buildTableRow('เบอร์โทร', _employee!.phone, labelStyle, valueStyle),
                      _buildTableRow('เงินเดือน', _employee!.salary.toString(), labelStyle, valueStyle),
                      _buildTableRow('อีเมล', _employee!.email, labelStyle, valueStyle),
                      _buildTableRow('แผนก', _departmentTitle, labelStyle, valueStyle),
                      _buildTableRow('วันเกิด', _employee!.birth.toLocal().toString().split(' ')[0], labelStyle, valueStyle),
                      _buildTableRow('วันที่เริ่มงาน', _employee!.date.toLocal().toString().split(' ')[0], labelStyle, valueStyle),
                    ],
                  ),
                  SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EmployeeEditScreen(employeeId: widget.employeeId!),
                          ),
                        );
                      },
                      icon: Icon(Icons.edit),
                      label: Text('แก้ไขข้อมูล'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600], // 🔵 สีฟ้าสำหรับปุ่มแก้ไข
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  TableRow _buildTableRow(String label, String value, TextStyle labelStyle, TextStyle valueStyle) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('$label:', style: labelStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(value, style: valueStyle),
        ),
      ],
    );
  }
}
