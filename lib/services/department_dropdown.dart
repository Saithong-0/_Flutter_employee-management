import 'package:flutter/material.dart';
import '../services/department_service.dart';

class DepartmentDropdown extends StatefulWidget {
  final String? initialValue;
  final Function(String) onChanged;
  final bool includeAllOption;

  const DepartmentDropdown({
    Key? key,
    this.initialValue,
    required this.onChanged,
    this.includeAllOption = false,
  }) : super(key: key);

  @override
  State<DepartmentDropdown> createState() => _DepartmentDropdownState();
}

class _DepartmentDropdownState extends State<DepartmentDropdown> {
  final DepartmentService _departmentService = DepartmentService();
  List<Department> _departments = [];
  String? _selectedDepartmentId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final departments = await _departmentService.getDepartments();
      setState(() {
        _departments = departments;
        _isLoading = false;

        if (widget.initialValue != null) {
          final exists = _departments.any((dept) => dept.id == widget.initialValue);
          if (exists) {
            _selectedDepartmentId = widget.initialValue;
          }
        }

        if (_selectedDepartmentId == null && _departments.isNotEmpty) {
          _selectedDepartmentId = widget.includeAllOption ? 'all' : _departments.first.id;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 60,
        child: Center(
          child: Text(
            'เกิดข้อผิดพลาด: $_error',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (_departments.isEmpty) {
      return const SizedBox(
        height: 60,
        child: Center(child: Text('ไม่มีข้อมูลแผนก')),
      );
    }

    List<DropdownMenuItem<String>> dropdownItems = [];

    if (widget.includeAllOption) {
      dropdownItems.add(const DropdownMenuItem<String>(
        value: 'all',
        child: Text('ทั้งหมด'),
      ));
    }

    dropdownItems.addAll(_departments.map((dept) {
      return DropdownMenuItem<String>(
        value: dept.id,
        child: Text(dept.title),
      );
    }).toList());

    return DropdownButtonFormField<String>(
      value: _selectedDepartmentId,
      items: dropdownItems,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedDepartmentId = newValue;
          });
          widget.onChanged(newValue);
        }
      },
      decoration: InputDecoration(
        labelText: 'แผนก',
        labelStyle: TextStyle(color: Colors.grey[800] , fontSize: 18,),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black87),
        ),
      ),
      style: TextStyle(color: Colors.black87,fontSize: 16),
      dropdownColor: Colors.white,
      iconEnabledColor: Colors.black54,
    );
  }
}
