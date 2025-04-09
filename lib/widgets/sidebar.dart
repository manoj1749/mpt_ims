import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Map<int, List<String>> sectionSubpages;
  final int selectedSubIndex;
  final ValueChanged<int> onSubItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isExpanded,
    required this.onToggle,
    required this.sectionSubpages,
    required this.selectedSubIndex,
    required this.onSubItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {'icon': Icons.shopping_cart, 'label': 'Planning & Purchase'},
      {'icon': Icons.store, 'label': 'Stores'},
      {'icon': Icons.verified, 'label': 'Inspection / Quality'},
      {'icon': Icons.receipt_long, 'label': 'Accounts & Billing'},
      {'icon': Icons.attach_money, 'label': 'Salary & Expense'},
    ];

    return Container(
      width: isExpanded ? 250 : 40,
      color: const Color.fromARGB(255, 255, 255, 255),
      child: Column(
        crossAxisAlignment:
            isExpanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          IconButton(
            icon: Icon(
              isExpanded ? Icons.close : Icons.arrow_forward_ios,
              color: Colors.black,
            ),
            onPressed: onToggle,
          ),
          const SizedBox(height: 20),
          for (int i = 0; i < items.length; i++) ...[
            InkWell(
              onTap: () => onItemSelected(i),
              child: Container(
                color: selectedIndex == i ? Colors.blueGrey : Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  children: [
                    Icon(items[i]['icon'], color: Colors.black),
                    if (isExpanded)
                      const SizedBox(width: 12),
                    if (isExpanded)
                      Expanded(
                        child: Text(
                          items[i]['label'],
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (selectedIndex == i && isExpanded)
              Padding(
                padding: const EdgeInsets.only(left: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int j = 0; j < sectionSubpages[i]!.length; j++)
                      GestureDetector(
                        onTap: () => onSubItemSelected(j),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: const BoxDecoration(
                            // color: selectedSubIndex == j
                            //     ? Colors.blue.withOpacity(0.2)
                            //     : Colors.transparent,
                          ),
                          child: Text(
                            sectionSubpages[i]![j],
                            style: TextStyle(color:selectedSubIndex == j ? Colors.grey: Colors.black),
                          ),
                        ),
                      )
                  ],
                ),
              )
          ],
        ],
      ),
    );
  }
}
