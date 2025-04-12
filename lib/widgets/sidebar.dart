import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final bool isExpanded;
  final Map<int, List<String>> sectionSubpages;
  final void Function(String) onSubsectionSelected;
  final String selectedSubsection;
  final VoidCallback onToggle;

  const Sidebar({
    super.key,
    required this.isExpanded,
    required this.sectionSubpages,
    required this.onSubsectionSelected,
    required this.selectedSubsection,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {'icon': Icons.admin_panel_settings, 'label': 'Admin'},
      {'icon': Icons.account_balance_wallet, 'label': 'Accounts'},
      {'icon': Icons.people_alt, 'label': 'HR'},
      {'icon': Icons.support_agent, 'label': 'Sales/Customer Management'},
      {'icon': Icons.design_services, 'label': 'Design'},
      {'icon': Icons.event_note, 'label': 'Planning'},
      {'icon': Icons.shopping_cart_checkout, 'label': 'Purchase'},
      {'icon': Icons.inventory_2, 'label': 'Stores'},
      {'icon': Icons.factory, 'label': 'Production'},
      {'icon': Icons.verified, 'label': 'Quality'},
    ];

    return Container(
      width: isExpanded ? 250 : 40,
      color: Colors.white,
      child: Column(
        crossAxisAlignment:
            isExpanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              isExpanded ? Icons.close_sharp : Icons.menu_open,
              color: Colors.black,
            ),
            onPressed: onToggle,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      color: Colors.grey.shade200,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Row(
                        mainAxisAlignment: isExpanded
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        children: [
                          Icon(items[i]['icon'], color: Colors.black),
                          if (isExpanded) const SizedBox(width: 10),
                          if (isExpanded)
                            Expanded(
                              child: Text(
                                items[i]['label'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isExpanded)
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 20, right: 8, bottom: 6, top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: sectionSubpages[i]!.map((sub) {
                            final bool isSelected =
                                sub == selectedSubsection;
                            return GestureDetector(
                              onTap: () => onSubsectionSelected(sub),
                              child: Container(
                                width: double.infinity,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 2),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.blueGrey
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  sub,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
