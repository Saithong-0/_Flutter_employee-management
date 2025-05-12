import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/employees.dart';
import '../services/database_services.dart';
import 'package:flutter/foundation.dart';

class EmployeeAddScreen extends StatefulWidget {
  const EmployeeAddScreen({Key? key}) : super(key: key);

  @override
  _EmployeeAddScreenState createState() => _EmployeeAddScreenState();
}

class _EmployeeAddScreenState extends State<EmployeeAddScreen> {
  String? _base64Image;
  final DatabaseService _databaseService = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  DateTime? _birthDate;
  DateTime? _startDate;
  File? _selectedImage;
  List<Map<String, dynamic>> _departments = [];
  String? _selectedDepartmentId;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      final departments = await _databaseService.getDepartments();
      setState(() {
        _departments = departments;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('โหลดข้อมูลแผนกล้มเหลว: $e')));
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile == null) return;

      final imageFile = File(pickedFile.path);
      final bytes = await imageFile.readAsBytes();

      // แสดง dialog preview พร้อม confirm
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Text('ยืนยันรูปภาพ'),
              content: Image.memory(bytes),
              actions: [
                TextButton(
                  child: Text('ยกเลิก'),
                  onPressed: () => Navigator.pop(context, false),
                ),
                ElevatedButton(
                  child: Icon(Icons.check),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
      );

      if (confirm == true) {
        setState(() {
          _selectedImage = imageFile;
          _base64Image = base64Encode(bytes);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกภาพ: $e')),
      );
    }
  }

  Future<void> _saveEmployee() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final employee = Employee(
          id: '',
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          birth: _birthDate ?? DateTime.now(),
          date: _startDate ?? DateTime.now(),
          photo: _base64Image ?? '',
          salary: int.tryParse(_salaryController.text) ?? 0,
          department: _selectedDepartmentId ?? '',
        );

        await _databaseService.addEmployee(employee);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เพิ่มข้อมูลพนักงานสำเร็จ!')));
        Navigator.pop(context, true);
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
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
      appBar: AppBar(
        title: Text('เพิ่มข้อมูลพนักงาน'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage:
                              _selectedImage != null
                                  ? FileImage(_selectedImage!)
                                  : null,
                          child:
                              _selectedImage == null
                                  ? Icon(Icons.person, size: 60)
                                  : null,
                        ),
                      ),
                      SizedBox(height: 24),
                      buildTextField(
                        'ชื่อ',
                        _firstNameController,
                        'กรุณากรอกชื่อ',
                      ),
                      SizedBox(height: 16),
                      buildTextField(
                        'นามสกุล',
                        _lastNameController,
                        'กรุณากรอกนามสกุล',
                      ),
                      SizedBox(height: 16),
                      buildTextField(
                        'เบอร์โทรศัพท์',
                        _phoneController,
                        null,
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 16),
                      buildTextField(
                        'เงินเดือน',
                        _salaryController,
                        'กรุณากรอกเงินเดือน',
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 16),
                      buildTextField(
                        'Email',
                        _emailController,
                        'กรุณากรอกอีเมล',
                        email: true,
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedDepartmentId,
                        onChanged:
                            (value) =>
                                setState(() => _selectedDepartmentId = value),
                        items:
                            _departments
                                .map(
                                  (d) => DropdownMenuItem<String>(
                                    value: d['dep_id'].toString(),
                                    child: Text(d['dep_title'] ?? ''),
                                  ),
                                )
                                .toList(),
                        decoration: InputDecoration(
                          labelText: 'แผนก',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณาเลือกแผนก';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'วันเกิด: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null)
                                setState(() => _birthDate = picked);
                            },
                            child: Text(
                              _birthDate == null
                                  ? 'เลือกวันที่'
                                  : '${_birthDate!.toLocal()}'.split(' ')[0],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'วันที่เริ่มงาน: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null)
                                setState(() => _startDate = picked);
                            },
                            child: Text(
                              _startDate == null
                                  ? 'เลือกวันที่'
                                  : '${_startDate!.toLocal()}'.split(' ')[0],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveEmployee,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('บันทึก'),
                        ),
                      ),
                    ],
                  ),
                ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: 'Value',
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (validatorMessage != null && (value == null || value.isEmpty)) {
              return validatorMessage;
            } else if (email && value != null && value.isNotEmpty) {
              final emailRegex = RegExp('@');
              if (!emailRegex.hasMatch(value)) {
                return 'กรุณากรอกอีเมลให้ถูกต้อง';
              }
            }
            return null;
          },
        ),
      ],
    );
  }
}
