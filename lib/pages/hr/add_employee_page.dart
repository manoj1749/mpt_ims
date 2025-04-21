import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpt_ims/models/employee.dart';
import 'package:mpt_ims/provider/employee_provider.dart';

class AddEmployeePage extends ConsumerStatefulWidget {
  final Employee? employeeToEdit;

  const AddEmployeePage({
    super.key,
    this.employeeToEdit,
  });

  @override
  ConsumerState<AddEmployeePage> createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends ConsumerState<AddEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _nameController;
  late final TextEditingController _employeeCodeController;
  late final TextEditingController _aadhaarController;
  late final TextEditingController _esiController;
  late final TextEditingController _pfController;
  late final TextEditingController _accountController;
  late final TextEditingController _ifscController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _branchController;
  late final TextEditingController _perDaySalaryController;
  late final TextEditingController _otSalaryController;

  @override
  void initState() {
    super.initState();
    final employee = widget.employeeToEdit;
    
    _nameController = TextEditingController(text: employee?.name ?? '');
    _employeeCodeController = TextEditingController(text: employee?.employeeCode ?? '');
    _aadhaarController = TextEditingController(text: employee?.aadhaarNumber ?? '');
    _esiController = TextEditingController(text: employee?.esiNumber ?? '');
    _pfController = TextEditingController(text: employee?.pfNumber ?? '');
    _accountController = TextEditingController(text: employee?.accountNumber ?? '');
    _ifscController = TextEditingController(text: employee?.ifscCode ?? '');
    _bankNameController = TextEditingController(text: employee?.bankName ?? '');
    _branchController = TextEditingController(text: employee?.branch ?? '');
    _perDaySalaryController = TextEditingController(text: employee?.perDaySalary ?? '');
    _otSalaryController = TextEditingController(text: employee?.otSalaryPerHour ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _employeeCodeController.dispose();
    _aadhaarController.dispose();
    _esiController.dispose();
    _pfController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    _branchController.dispose();
    _perDaySalaryController.dispose();
    _otSalaryController.dispose();
    super.dispose();
  }

  void _saveEmployee() {
    if (!_formKey.currentState!.validate()) return;

    final employee = Employee(
      name: _nameController.text,
      employeeCode: _employeeCodeController.text,
      aadhaarNumber: _aadhaarController.text,
      esiNumber: _esiController.text,
      pfNumber: _pfController.text,
      accountNumber: _accountController.text,
      ifscCode: _ifscController.text,
      bankName: _bankNameController.text,
      branch: _branchController.text,
      perDaySalary: _perDaySalaryController.text,
      otSalaryPerHour: _otSalaryController.text,
    );

    if (widget.employeeToEdit != null) {
      ref.read(employeeListProvider.notifier).updateEmployee(employee);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee updated successfully')),
      );
    } else {
      ref.read(employeeListProvider.notifier).addEmployee(employee);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee added successfully')),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employeeToEdit != null ? 'Edit Employee' : 'Add Employee'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Basic Information',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _employeeCodeController,
                decoration: const InputDecoration(
                  labelText: 'Employee Code',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter employee code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Government IDs',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _aadhaarController,
                decoration: const InputDecoration(
                  labelText: 'Aadhaar Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Aadhaar number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _esiController,
                decoration: const InputDecoration(
                  labelText: 'ESI Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pfController,
                decoration: const InputDecoration(
                  labelText: 'PF Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Bank Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountController,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter account number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ifscController,
                decoration: const InputDecoration(
                  labelText: 'IFSC Code',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter IFSC code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter bank name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _branchController,
                decoration: const InputDecoration(
                  labelText: 'Branch',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter branch';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Salary Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _perDaySalaryController,
                decoration: const InputDecoration(
                  labelText: 'Per Day Salary',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter per day salary';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _otSalaryController,
                decoration: const InputDecoration(
                  labelText: 'OT Salary per Hour',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter OT salary per hour';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveEmployee,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      widget.employeeToEdit != null ? 'Update Employee' : 'Add Employee',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 