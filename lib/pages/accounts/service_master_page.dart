// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/service_name.dart';
import '../../models/service_type.dart';
import '../../provider/service_name_provider.dart';
import '../../provider/service_type_provider.dart';

class ServiceMasterPage extends ConsumerStatefulWidget {
  const ServiceMasterPage({super.key});

  @override
  ConsumerState<ServiceMasterPage> createState() => _ServiceMasterPageState();
}

class _ServiceMasterPageState extends ConsumerState<ServiceMasterPage> {
  final _serviceNameController = TextEditingController();
  final _serviceTypeController = TextEditingController();

  ServiceName? _selectedServiceName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(serviceNameProvider.notifier).loadServiceNames();
        await ref.read(serviceTypeProvider.notifier).loadServiceTypes();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error loading services: $e')));
        }
      }
    });
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _serviceTypeController.dispose();
    super.dispose();
  }

  Future<void> _showAddServiceNameDialog() async {
    _serviceNameController.clear();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Service Name'),
        content: TextField(
          controller: _serviceNameController,
          decoration: const InputDecoration(
            labelText: 'Service Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final name = _serviceNameController.text.trim();
    if (name.isEmpty) return;

    await ref.read(serviceNameProvider.notifier).addServiceName(name);
  }

  Future<void> _showAddServiceTypeDialog() async {
    if (_selectedServiceName == null) return;
    _serviceTypeController.clear();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Service Type'),
        content: TextField(
          controller: _serviceTypeController,
          decoration: const InputDecoration(
            labelText: 'Service Type',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final typeName = _serviceTypeController.text.trim();
    if (typeName.isEmpty) return;

    await ref
        .read(serviceTypeProvider.notifier)
        .addServiceType(_selectedServiceName!.name, typeName);
  }

  Future<void> _confirmDeleteServiceName(ServiceName serviceName) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete service name "${serviceName.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final types = ref.read(serviceTypeProvider);
      for (final t in types.where((t) => t.serviceName == serviceName.name)) {
        await ref.read(serviceTypeProvider.notifier).deleteServiceType(t);
      }
      await ref.read(serviceNameProvider.notifier).deleteServiceName(serviceName);
      if (_selectedServiceName?.name == serviceName.name) {
        setState(() {
          _selectedServiceName = null;
        });
      }
    }
  }

  Future<void> _confirmDeleteServiceType(ServiceType type) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete service type "${type.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await ref.read(serviceTypeProvider.notifier).deleteServiceType(type);
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceNames = ref.watch(serviceNameProvider);
    final serviceTypes = ref.watch(serviceTypeProvider);
    final filteredTypes = _selectedServiceName == null
        ? <ServiceType>[]
        : serviceTypes
            .where((t) => t.serviceName == _selectedServiceName!.name)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Category Master'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              margin: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.black,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Service Names',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: _showAddServiceNameDialog,
                        ),
                      ],
                    ),
                  ),
                  if (serviceNames.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No service names added yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: serviceNames.length,
                      itemBuilder: (context, index) {
                        final serviceName = serviceNames[index];
                        return ListTile(
                          title: Text(serviceName.name),
                          selected: _selectedServiceName?.name == serviceName.name,
                          onTap: () {
                            setState(() {
                              _selectedServiceName = serviceName;
                            });
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _confirmDeleteServiceName(serviceName),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            if (_selectedServiceName != null)
              Card(
                margin: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.black,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Service Types (${_selectedServiceName!.name})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: _showAddServiceTypeDialog,
                          ),
                        ],
                      ),
                    ),
                    if (filteredTypes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No service types added yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredTypes.length,
                        itemBuilder: (context, index) {
                          final type = filteredTypes[index];
                          return ListTile(
                            title: Text(type.name),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDeleteServiceType(type),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
