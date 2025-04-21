import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/models/employee.dart';
import 'package:mpt_ims/provider/employee_provider.dart';
import 'add_employee_page.dart';

class EmployeeListPage extends ConsumerWidget {
  const EmployeeListPage({super.key});

  void _confirmDelete(BuildContext context, WidgetRef ref, Employee employee) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${employee.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () {
              ref.read(employeeListProvider.notifier).deleteEmployee(employee);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Employee deleted')),
              );
            },
            style: FilledButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = ref.watch(employeeListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Master'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
            tooltip: 'Search Employees',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEmployeePage()),
        ),
        child: const Icon(Icons.add),
      ),
      body: employees.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No employees yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddEmployeePage()),
                    ),
                    child: const Text('Add New Employee'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${employees.length} Employees',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 16),
                      FilledButton.tonal(
                        onPressed: () {
                          // TODO: Implement filtering
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.filter_list, size: 20),
                            SizedBox(width: 8),
                            Text('Filter'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 32,
                        child: PaginatedDataTable(
                          source: _EmployeeDataSource(
                            employees: employees,
                            context: context,
                            ref: ref,
                            onDelete: (employee) => _confirmDelete(context, ref, employee),
                          ),
                          header: null,
                          rowsPerPage: employees.length,
                          showFirstLastButtons: true,
                          showCheckboxColumn: false,
                          horizontalMargin: 16,
                          columnSpacing: 20,
                          availableRowsPerPage: const [20, 50, 100, 200],
                          columns: const [
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Employee Code')),
                            DataColumn(label: Text('Aadhaar Number')),
                            DataColumn(label: Text('ESI Number')),
                            DataColumn(label: Text('PF Number')),
                            DataColumn(label: Text('Account Number')),
                            DataColumn(label: Text('IFSC Code')),
                            DataColumn(label: Text('Bank Name')),
                            DataColumn(label: Text('Branch')),
                            DataColumn(label: Text('Per Day Salary')),
                            DataColumn(label: Text('OT Salary/Hour')),
                            DataColumn(label: Text('Actions')),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _EmployeeDataSource extends DataTableSource {
  final List<Employee> employees;
  final BuildContext context;
  final WidgetRef ref;
  final Function(Employee) onDelete;

  _EmployeeDataSource({
    required this.employees,
    required this.context,
    required this.ref,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= employees.length) return null;
    final employee = employees[index];

    return DataRow(
      cells: [
        DataCell(
          Text(
            employee.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(
          Text(
            employee.employeeCode,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        DataCell(Text(employee.aadhaarNumber)),
        DataCell(Text(employee.esiNumber)),
        DataCell(Text(employee.pfNumber)),
        DataCell(Text(employee.accountNumber)),
        DataCell(Text(employee.ifscCode)),
        DataCell(Text(employee.bankName)),
        DataCell(Text(employee.branch)),
        DataCell(
          Text(
            '₹${employee.perDaySalary}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(
          Text(
            '₹${employee.otSalaryPerHour}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEmployeePage(
                        employeeToEdit: employee,
                      ),
                    ),
                  );
                },
                color: Colors.blue,
                tooltip: 'Edit',
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => onDelete(employee),
                color: Colors.red[400],
                tooltip: 'Delete',
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => employees.length;

  @override
  int get selectedRowCount => 0;
} 