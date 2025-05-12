import 'package:flutter/material.dart';
import 'package:empmanagement/screens/employee_add_screen.dart';
import 'package:empmanagement/services/department_dropdown.dart';
import 'package:empmanagement/models/employees.dart';
import 'package:empmanagement/services/database_services.dart';
import 'package:empmanagement/screens/employee_detail_screen.dart';
import 'package:empmanagement/services/department_service.dart';
import 'package:url_launcher/url_launcher.dart';

class EmployeeListScreen extends StatefulWidget {
  @override
  _EmployeeListScreenState createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final DepartmentService _departmentService = DepartmentService();
  List<Employee> _employees = [];
  String _selectedDepartment = 'all';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  Map<String, String> _departmentTitles = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadDepartments();
    await _loadEmployees();
  }

  Future<void> _loadDepartments() async {
    try {
      final departments = await _departmentService.getDepartments();
      setState(() {
        _departmentTitles = {
          for (var dep in departments) dep.id.trim(): dep.title,
        };
      });
    } catch (e) {
      debugPrint('ไม่สามารถโหลดข้อมูลแผนกได้: $e');
    }
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final employees = await _databaseService.getEmployees(
        searchTerm: _searchController.text,
        department: _selectedDepartment == 'all' ? null : _selectedDepartment,
      );

      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถโหลดข้อมูลพนักงานได้: $e')),
      );
    }
  }

  void _filterEmployees() {
    _loadEmployees();
  }

  void _deleteEmployee(String? employeeId) async {
    if (employeeId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('ยืนยันการลบ'),
            content: Text('คุณต้องการลบพนักงานคนนี้หรือไม่?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('ยกเลิก'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('ลบ'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _databaseService.deleteEmployee(employeeId);
      _loadEmployees();
    }
  }

  void launchPhone(String number) async {
  final Uri uri = Uri(scheme: 'tel', path: number);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ไม่สามารถเปิดแอปโทรศัพท์ได้')),
    );
  }
}


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorAccent = Color.fromARGB(255, 42, 156, 75);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'พนักงาน',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadEmployees,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 6,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ค้นหาชื่อพนักงาน...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => _filterEmployees(),
              ),
            ),
            SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DepartmentDropdown(
                initialValue: _selectedDepartment,
                includeAllOption: true,
                onChanged: (String newValue) {
                  setState(() {
                    _selectedDepartment = newValue;
                    _filterEmployees();
                  });
                },
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child:
                  _isLoading
                      ? Center(
                        child: CircularProgressIndicator(color: colorAccent),
                      )
                      : _employees.isEmpty
                      ? Center(
                        child: Text(
                          'ไม่พบข้อมูลพนักงาน',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                      : ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        separatorBuilder: (_, __) => SizedBox(height: 8),
                        itemCount: _employees.length,
                        itemBuilder: (context, index) {
                          final emp = _employees[index];
                          final depId = emp.department.trim();
                          final depTitle =
                              _departmentTitles[depId] ?? 'ไม่ทราบแผนก';

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: colorAccent.withOpacity(0.3),
                                radius: 38,
                                backgroundImage:
                                    emp.photo.isNotEmpty
                                        ? NetworkImage(emp.photo)
                                        : null,
                                child:
                                    emp.photo.isEmpty
                                        ? Icon(Icons.person, color: colorAccent)
                                        : null,
                              ),
                              title: Text(
                                '${emp.firstName} ${emp.lastName}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 17,
                                ),
                              ),
                              subtitle: Text(
                                depTitle,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.phone,
                                      color: Colors.green,
                                    ),
                                    onPressed: () => launchPhone(emp.phone),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _deleteEmployee(emp.id),
                                  ),
                                ],
                              ),

                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => EmployeeDetailScreen(
                                          employeeId: emp.id,
                                        ),
                                  ),
                                ).then((_) => _loadEmployees());
                              },
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EmployeeAddScreen()),
          ).then((_) => _loadEmployees());
        },
        child: Icon(Icons.add),
        backgroundColor: colorAccent,
        foregroundColor: Colors.white,
      ),
    );
  }
}
