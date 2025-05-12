// นำเข้าเหมือนเดิม
import 'dart:convert';
import 'package:empmanagement/screens/employee_list_screen.dart';
import 'package:flutter/material.dart';
import '../models/employees.dart';
import '../services/database_services.dart';

class EmployeeEditScreen extends StatefulWidget {
  final String? employeeId;

  const EmployeeEditScreen({Key? key, this.employeeId}) : super(key: key);

  @override
  _EmployeeEditScreenState createState() => _EmployeeEditScreenState();
}

class _EmployeeEditScreenState extends State<EmployeeEditScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  DateTime? _birthDate;
  DateTime? _startDate;
  String _photoUrl = '';
  bool _isLoading = true;
  bool _isNew = false;

  List<Map<String, dynamic>> _departments = [];
  String? _selectedDepartmentId;

  @override
  void initState() {
    super.initState();
    _isNew = widget.employeeId == null;
    _loadDepartments();
    if (!_isNew) _loadEmployee();
    else setState(() => _isLoading = false);
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

  Future<void> _loadDepartments() async {
    try {
      final departments = await _databaseService.getDepartments();
      setState(() => _departments = departments);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('โหลดข้อมูลแผนกล้มเหลว: $e')),
      );
    }
  }

  Future<void> _loadEmployee() async {
    try {
      final employee = await _databaseService.getEmployeeById(widget.employeeId!);
      _firstNameController.text = employee.firstName;
      _lastNameController.text = employee.lastName;
      _emailController.text = employee.email;
      _salaryController.text = employee.salary.toString();
      _phoneController.text = employee.phone;
      _birthDate = employee.birth;
      _startDate = employee.date;
      _photoUrl = employee.photo;
      _selectedDepartmentId = employee.department;
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e')),
      );
    }
  }

  Future<void> _saveEmployee() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final employee = Employee(
          id: widget.employeeId,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          birth: _birthDate ?? DateTime.now(),
          date: _startDate ?? DateTime.now(),
          photo: _photoUrl,
          salary: int.tryParse(_salaryController.text) ?? 0,
          department: _selectedDepartmentId ?? '',
        );

        if (_isNew) {
          await _databaseService.addEmployee(employee);
        } else {
          await _databaseService.updateEmployee(employee);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isNew ? 'เพิ่มข้อมูลสำเร็จ' : 'อัปเดตข้อมูลสำเร็จ')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => EmployeeListScreen()),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _deleteEmployee() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบพนักงานคนนี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _databaseService.deleteEmployee(widget.employeeId!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ลบข้อมูลสำเร็จ')),
        );
        Navigator.pop(context, true);
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _salaryController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isNew ? 'เพิ่มพนักงาน' : 'แก้ไขข้อมูล'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _resolveImage(_photoUrl),
                      backgroundColor: Colors.grey[200],
                      child: _photoUrl.isEmpty ? Icon(Icons.person, size: 60, color: Colors.grey) : null,
                    ),
                    SizedBox(height: 24),
                    buildTextField('ชื่อ', _firstNameController, 'กรุณากรอกชื่อ'),
                    SizedBox(height: 16),
                    buildTextField('นามสกุล', _lastNameController, 'กรุณากรอกนามสกุล'),
                    SizedBox(height: 16),
                    buildTextField('เบอร์โทรศัพท์', _phoneController, null, keyboardType: TextInputType.phone),
                    SizedBox(height: 16),
                    buildTextField('เงินเดือน', _salaryController, 'กรุณากรอกเงินเดือน', keyboardType: TextInputType.number),
                    SizedBox(height: 16),
                    buildTextField('อีเมล', _emailController, 'กรุณากรอกอีเมล', email: true),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _departments.any((d) => d['dep_id'] == _selectedDepartmentId)
                          ? _selectedDepartmentId
                          : null,
                      onChanged: (val) => setState(() => _selectedDepartmentId = val),
                      items: _departments.map((d) {
                        return DropdownMenuItem<String>(
                          value: d['dep_id'].toString(),
                          child: Text(d['dep_title']),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        labelText: 'แผนก',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null ? 'กรุณาเลือกแผนก' : null,
                    ),
                    SizedBox(height: 16),
                    buildDateRow('วันเกิด', _birthDate, (picked) => _birthDate = picked),
                    buildDateRow('วันที่เริ่มงาน', _startDate, (picked) => _startDate = picked),
                    SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: !_isNew
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveEmployee,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('บันทึก'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _deleteEmployee,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('ลบผู้ใช้'),
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              
            ),
    );
  }

  Widget buildTextField(
    String label,
    TextEditingController controller,
    String? validatorMessage, {
    TextInputType keyboardType = TextInputType.text,
    bool email = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (validatorMessage != null && (value == null || value.isEmpty)) {
          return validatorMessage;
        }
        if (email && value != null && value.isNotEmpty) {
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegex.hasMatch(value)) {
            return 'กรุณากรอกอีเมลให้ถูกต้อง';
          }
        }
        return null;
      },
    );
  }

  Widget buildDateRow(String label, DateTime? date, Function(DateTime) onDatePicked) {
    return Row(
      children: [
        Text('$label: ', style: TextStyle(fontWeight: FontWeight.w500)),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => onDatePicked(picked));
          },
          child: Text(date == null ? 'เลือกวันที่' : date.toLocal().toString().split(' ')[0]),
        ),
      ],
    );
  }
}
