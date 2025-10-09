import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mpt_ims/models/employee.dart';
import 'package:mpt_ims/models/increment_history.dart';
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

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _employeeCodeController = TextEditingController();
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _esiController = TextEditingController();
  final TextEditingController _pfController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _perDaySalaryController = TextEditingController();
  final TextEditingController _otSalaryController = TextEditingController();
  final TextEditingController _emergencyContactAddressController = TextEditingController();
  final TextEditingController _emergencyContactRelationController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _jobRoleController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _permanentAddressController = TextEditingController();
  final TextEditingController _temporaryAddressController = TextEditingController();
  bool _isRejoined = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _dateOfJoiningController =
      TextEditingController();
  final TextEditingController _lastIncrementDateController =
      TextEditingController();
  final TextEditingController _degreeController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _completionYearController =
      TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _dateOfResignationController =
      TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _emergencyContactNameController =
      TextEditingController();
  final TextEditingController _emergencyContactPhoneController =
      TextEditingController();
  final TextEditingController _rejoinedDateController = TextEditingController();
  final TextEditingController _newSalaryController = TextEditingController();
  final TextEditingController _incrementNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final employee = widget.employeeToEdit;

    _nameController.text = employee?.name ?? '';
    _employeeCodeController.text = employee?.employeeCode ??
        ref.read(employeeListProvider.notifier).generateNextEmployeeCode();
    _aadhaarController.text = employee?.aadhaarNumber ?? '';
    _esiController.text = employee?.esiNumber ?? '';
    _pfController.text = employee?.pfNumber ?? '';
    _accountController.text = employee?.accountNumber ?? '';
    _ifscController.text = employee?.ifscCode ?? '';
    _bankNameController.text = employee?.bankName ?? '';
    _branchController.text = employee?.branch ?? '';
    _perDaySalaryController.text = employee?.perDaySalary ?? '';
    _otSalaryController.text = employee?.otSalaryPerHour ?? '';
    _permanentAddressController.text = employee?.permanentAddress ?? '';
    _temporaryAddressController.text = employee?.temporaryAddress ?? '';
    _emailController.text = employee?.email ?? '';
    _phoneNumberController.text = employee?.phoneNumber ?? '';
    _dateOfJoiningController.text = employee?.dateOfJoining ?? '';
    _lastIncrementDateController.text = employee?.lastIncrementDate ?? '';
    _degreeController.text = employee?.degreeCourse ?? '';
    _institutionController.text = employee?.institution ?? '';
    _completionYearController.text = employee?.completionYear ?? '';
    _bloodGroupController.text = employee?.bloodGroup ?? '';
    _emergencyContactNameController.text = employee?.emergencyContactName ?? '';
    _emergencyContactPhoneController.text =
        employee?.emergencyContactPhone ?? '';
    _emergencyContactAddressController.text =
        employee?.emergencyContactAddress ?? '';
    _emergencyContactRelationController.text = employee?.emergencyContactRelation ?? '';
    _departmentController.text = employee?.department ?? '';
    _jobRoleController.text = employee?.jobRole ?? '';
    _isRejoined = employee?.isRejoined ?? false;
    _rejoinedDateController.text = employee?.rejoinedDate ?? '';
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
    _permanentAddressController.dispose();
    _temporaryAddressController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _departmentController.dispose();
    _jobRoleController.dispose();
    _dateOfJoiningController.dispose();
    _lastIncrementDateController.dispose();
    _degreeController.dispose();
    _institutionController.dispose();
    _completionYearController.dispose();
    _gradeController.dispose();
    _dateOfResignationController.dispose();
    _bloodGroupController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _emergencyContactAddressController.dispose();
    _emergencyContactRelationController.dispose();
    _rejoinedDateController.dispose();
    _newSalaryController.dispose();
    _incrementNotesController.dispose();
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
      permanentAddress: _permanentAddressController.text,
      temporaryAddress: _temporaryAddressController.text,
      email: _emailController.text,
      phoneNumber: _phoneNumberController.text,
      dateOfJoining: _dateOfJoiningController.text,
      lastIncrementDate: _lastIncrementDateController.text,
      dateOfResignation: _dateOfResignationController.text,
      bloodGroup: _bloodGroupController.text,
      emergencyContactName: _emergencyContactNameController.text,
      emergencyContactPhone: _emergencyContactPhoneController.text,
      emergencyContactAddress: _emergencyContactAddressController.text,
      emergencyContactRelation: _emergencyContactRelationController.text,
      rejoinedDate: _isRejoined ? _rejoinedDateController.text : '',
      isRejoined: _isRejoined,
      incrementHistory: widget.employeeToEdit?.incrementHistory ?? const [],
      degreeCourse: _degreeController.text,
      institution: _institutionController.text,
      completionYear: _completionYearController.text,
      gradeOrGPA: _gradeController.text,
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

  Widget _buildExpandableCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
    bool initiallyExpanded = false,
    required String key,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        key: Key(key),
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        initiallyExpanded: initiallyExpanded,
        childrenPadding: const EdgeInsets.all(16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildBasicInformationCard() {
    return _buildExpandableCard(
      title: 'Basic Information',
      subtitle: 'Name, Employee Code, Department, Job Role, Aadhaar, Date of Joining',
      icon: Icons.person,
      key: 'basic_info',
      initiallyExpanded: true,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_outline),
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
          readOnly: true, // Make it read-only since it's auto-generated
          decoration: InputDecoration(
            labelText: 'Employee Code',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter employee code';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Department
        TextFormField(
          controller: _departmentController,
          decoration: const InputDecoration(
            labelText: 'Department',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business_outlined),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter department';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Job Role
        TextFormField(
          controller: _jobRoleController,
          decoration: const InputDecoration(
            labelText: 'Job Role',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.work_outline),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter job role';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Aadhaar Number
        TextFormField(
          controller: _aadhaarController,
          decoration: InputDecoration(
            labelText: 'Aadhaar Number',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.credit_card),
            counterText: '', // This hides the default counter
            suffix: Text(
              '${_aadhaarController.text.length}/12',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            counter: null, // This ensures no counter is shown outside
          ),
          onChanged: (value) {
            setState(() {
              // This will trigger a rebuild to update the counter
            });
          },
          keyboardType: TextInputType.number,
          maxLength: 12,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (value.length != 12) {
                return 'Aadhaar number must be 12 digits';
              }
              if (!RegExp(r'^\d+$').hasMatch(value)) {
                return 'Aadhaar number must contain only digits';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _dateOfJoiningController.text.isNotEmpty
                  ? DateFormat('dd/MM/yyyy')
                      .parse(_dateOfJoiningController.text)
                  : DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              final formattedDate =
                  '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
              setState(() {
                _dateOfJoiningController.text = formattedDate;
              });
            }
          },
          child: AbsorbPointer(
            child: TextFormField(
              controller: _dateOfJoiningController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Date of Joining',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
                suffixIcon: Icon(Icons.calendar_month),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select date of joining';
                }
                return null;
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _dateOfResignationController.text.isNotEmpty
                        ? DateFormat('dd/MM/yyyy')
                            .parse(_dateOfResignationController.text)
                        : DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    final formattedDate =
                        '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                    setState(() {
                      _dateOfResignationController.text = formattedDate;
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateOfResignationController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Date of Resignation',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                      suffixIcon: Icon(Icons.calendar_month),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _bloodGroupController,
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.bloodtype_outlined),
                  hintText: 'e.g., A+',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text(
              'Rejoined?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Switch(
              value: _isRejoined,
              onChanged: (value) {
                setState(() {
                  _isRejoined = value;
                  if (!_isRejoined) {
                    _rejoinedDateController.clear();
                  }
                });
              },
            ),
          ],
        ),
        if (_isRejoined) ...[
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _rejoinedDateController.text.isNotEmpty
                    ? DateFormat('dd/MM/yyyy').parse(_rejoinedDateController.text)
                    : DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                final formattedDate =
                    '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                setState(() {
                  _rejoinedDateController.text = formattedDate;
                });
              }
            },
            child: AbsorbPointer(
              child: TextFormField(
                controller: _rejoinedDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Rejoined Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                  suffixIcon: Icon(Icons.calendar_month),
                ),
                validator: (value) {
                  if (_isRejoined && (value == null || value.isEmpty)) {
                    return 'Please select rejoined date';
                  }
                  return null;
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCommunicationCard() {
    return _buildExpandableCard(
      title: 'Communication Details',
      subtitle: 'Address, Email, Phone, Emergency Contact',
      icon: Icons.contact_mail,
      key: 'communication',
      children: [
        TextFormField(
          controller: _permanentAddressController,
          decoration: const InputDecoration(
            labelText: 'Permanent Address',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.home),
          ),
          maxLines: 1,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _temporaryAddressController,
          decoration: const InputDecoration(
            labelText: 'Temporary Address',
            hintText: 'Same as permanent (if applicable)',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          maxLines: 1,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    // Basic email pattern, anchored correctly
                    final emailRegex = RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,}$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Invalid email';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone_outlined),
                  counterText: '',
                  suffix: Text(
                    '${_phoneNumberController.text.length}/10',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                },
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (value.length != 10) {
                      return '10 digits';
                    }
                    if (!RegExp(r'^\d+$').hasMatch(value)) {
                      return 'Digits only';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(thickness: 1),
        const SizedBox(height: 8),
        const Text(
          'Emergency Contact',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _emergencyContactNameController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.emergency_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _emergencyContactPhoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone_outlined),
                  counterText: '',
                  suffix: Text(
                    '${_emergencyContactPhoneController.text.length}/10',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                onChanged: (value) {
                  setState(() {}); // Trigger rebuild to update counter
                },
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (value.length != 10) {
                    return '10 digits';
                  }
                  if (!RegExp(r'^\d+$').hasMatch(value)) {
                    return 'Digits only';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emergencyContactRelationController,
          decoration: const InputDecoration(
            labelText: 'Relationship',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.people_outline),
            hintText: 'e.g., Spouse, Parent, Sibling',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter relationship with contact';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emergencyContactAddressController,
          decoration: const InputDecoration(
            labelText: 'Emergency Contact Address',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.home_outlined),
          ),
          maxLines: 1,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter emergency contact address';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEducationDetailsCard() {
    return _buildExpandableCard(
      title: 'Education Details',
      subtitle: 'Degree, Institution, Year of Completion',
      icon: Icons.school,
      key: 'education_details',
      children: [
        TextFormField(
          controller: _degreeController,
          decoration: const InputDecoration(
            labelText: 'Degree / Course Name',
            hintText: 'e.g., Bachelor of Science in Computer Science',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.school_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _institutionController,
          decoration: const InputDecoration(
            labelText: 'Institution / University Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.account_balance),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _completionYearController,
          decoration: const InputDecoration(
            labelText: 'Year of Completion / Duration',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.calendar_today),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _gradeController,
          decoration: const InputDecoration(
            labelText: 'Grade / Percentage / GPA',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.grade_outlined),
          ),
          keyboardType: TextInputType.text,
        ),
      ],
    );
  }

  Widget _buildGovernmentBankingCard() {
    return _buildExpandableCard(
      title: 'ESI, PF and other Bank Details',
      subtitle: 'Employee Statutory and Financial Information',
      icon: Icons.account_balance,
      key: 'government_banking',
      children: [
        TextFormField(
          controller: _esiController,
          decoration: const InputDecoration(
            labelText: 'ESI Number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.local_hospital_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _pfController,
          decoration: const InputDecoration(
            labelText: 'PF Number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.savings_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _accountController,
          decoration: const InputDecoration(
            labelText: 'Account Number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.account_balance_wallet_outlined),
          ),
          keyboardType: TextInputType.number,
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
            prefixIcon: Icon(Icons.code),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter IFSC code';
            }
            if (value.length != 11) {
              return 'IFSC code must be 11 characters';
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
            prefixIcon: Icon(Icons.account_balance),
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
            prefixIcon: Icon(Icons.location_city),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter branch';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSalaryCard() {
    return _buildExpandableCard(
      title: 'Salary Details',
      subtitle: 'Salary, Overtime & Increment',
      icon: Icons.monetization_on,
      key: 'salary',
      children: [
        TextFormField(
          controller: _perDaySalaryController,
          decoration: const InputDecoration(
            labelText: 'Per Day Salary',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.currency_rupee),
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
            prefixIcon: Icon(Icons.schedule),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter OT salary per hour';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _lastIncrementDateController.text.isNotEmpty
                  ? DateFormat('dd/MM/yyyy')
                      .parse(_lastIncrementDateController.text)
                  : DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              final formattedDate =
                  '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
              setState(() {
                _lastIncrementDateController.text = formattedDate;
              });
            }
          },
          child: AbsorbPointer(
            child: TextFormField(
              controller: _lastIncrementDateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Last Increment Date',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.trending_up),
                suffixIcon: Icon(Icons.calendar_month),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _showIncrementDialog,
          icon: const Icon(Icons.add),
          label: const Text('Record Increment'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
        ),
        const SizedBox(height: 8),
        _buildIncrementHistoryList(),
      ],
    );
  }

  void _showIncrementDialog() {
    final currentSalary = double.tryParse(_perDaySalaryController.text) ?? 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Salary Increment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _newSalaryController,
                decoration: const InputDecoration(
                  labelText: 'New Per Day Salary',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _incrementNotesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newSalary = double.tryParse(_newSalaryController.text) ?? 0;
              if (newSalary <= 0) return;
              setState(() {
                final list = List<IncrementHistory>.from(
                    widget.employeeToEdit?.incrementHistory ?? const []);
                list.add(IncrementHistory(
                  date: DateTime.now(),
                  previousSalary: currentSalary,
                  newSalary: newSalary,
                  notes: _incrementNotesController.text.isEmpty
                      ? null
                      : _incrementNotesController.text,
                ));
                _perDaySalaryController.text = newSalary.toString();
                _lastIncrementDateController.text =
                    DateFormat('dd/MM/yyyy').format(DateTime.now());

                // Persist into model instance used on save
                if (widget.employeeToEdit != null) {
                  widget.employeeToEdit!.incrementHistory = list;
                }

                _newSalaryController.clear();
                _incrementNotesController.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildIncrementHistoryList() {
    final list = widget.employeeToEdit?.incrementHistory ?? const <IncrementHistory>[];
    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text('No increment history available'),
      );
    }

    // Show newest first
    final items = List<IncrementHistory>.from(list)..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Increment History',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final h = items[index];
            final diff = h.newSalary - h.previousSalary;
            final pct = h.previousSalary == 0
                ? 0
                : (diff / h.previousSalary * 100);
            final isUp = diff >= 0;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Icon(
                  isUp ? Icons.trending_up : Icons.trending_down,
                  color: isUp ? Colors.green : Colors.red,
                ),
                title: Text(
                  '₹${h.newSalary.toStringAsFixed(2)} (${pct.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    color: isUp ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From ₹${h.previousSalary.toStringAsFixed(2)} on ${DateFormat('dd MMM yyyy').format(h.date)}',
                    ),
                    if ((h.notes ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Notes: ${h.notes}',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.employeeToEdit != null ? 'Edit Employee' : 'Add Employee'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildBasicInformationCard(),
              _buildEducationDetailsCard(),
              _buildCommunicationCard(),
              _buildGovernmentBankingCard(),
              _buildSalaryCard(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveEmployee,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      widget.employeeToEdit != null
                          ? 'Update Employee'
                          : 'Add Employee',
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
