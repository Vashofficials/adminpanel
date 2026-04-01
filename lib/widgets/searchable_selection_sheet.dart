import 'package:flutter/material.dart';

// A generic class to hold the data for each item in the list
class SelectionItem {
  final String id;
  final String title;
  final String? subtitle;
  final IconData? icon;

  SelectionItem(
      {required this.id, required this.title, this.subtitle, this.icon});
}

class SearchableSelectionSheet extends StatefulWidget {
  final String title;
  final List<SelectionItem> items;
  final Function(String)? onItemSelected;
  final Function(List<String>)? onMultiItemSelected;
  final Color primaryColor;
  final bool isMultiSelect;

  const SearchableSelectionSheet({
    Key? key,
    required this.title,
    required this.items,
    this.onItemSelected,
    this.onMultiItemSelected,
    this.primaryColor = Colors.blue,
    this.isMultiSelect = false,
  }) : super(key: key);

  // CHANGED: Use showDialog instead of showModalBottomSheet
  static void show(
    BuildContext context, {
    required String title,
    required List<SelectionItem> items,
    Function(String)? onItemSelected,
    Function(List<String>)? onMultiItemSelected,
    Color primaryColor = Colors.blue,
    bool isMultiSelect = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => SearchableSelectionSheet(
        title: title,
        items: items,
        onItemSelected: onItemSelected,
        onMultiItemSelected: onMultiItemSelected,
        primaryColor: primaryColor,
        isMultiSelect: isMultiSelect,
      ),
    );
  }

  @override
  State<SearchableSelectionSheet> createState() =>
      _SearchableSelectionSheetState();
}

class _SearchableSelectionSheetState extends State<SearchableSelectionSheet> {
  String _searchText = "";
  List<SelectionItem> _filteredItems = [];
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  void _filterItems(String text) {
    setState(() {
      _searchText = text;
      _filteredItems = widget.items
          .where((item) =>
              item.title.toLowerCase().contains(text.toLowerCase()) ||
              (item.subtitle != null &&
                  item.subtitle!.toLowerCase().contains(text.toLowerCase())))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Constrain Width (max 500px) & Height (max 600px or 70% screen)
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
      elevation: 5,
      insetPadding:
          const EdgeInsets.all(20), // Adds breathing room on small screens
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500, // Keeps it compact on wide screens
          maxHeight: MediaQuery.of(context).size.height * 0.7, // Limits height
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // Shrinks to fit content if list is short
          children: [
            // 2. Title Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.close, size: 20, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // 3. Search Bar (Compact)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 40, // Reduced height for search bar
                child: TextField(
                  onChanged: _filterItems,
                  decoration: InputDecoration(
                    hintText: "Search...",
                    hintStyle:
                        const TextStyle(fontSize: 13, color: Colors.grey),
                    prefixIcon:
                        const Icon(Icons.search, size: 18, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC), // Very light grey
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: widget.primaryColor)),
                  ),
                ),
              ),
            ),

            // 4. Scrollable List
            Flexible(
              // Uses Flexible instead of Expanded to allow shrinking
              child: _filteredItems.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text("No results found",
                          style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.separated(
                      shrinkWrap: true, // Important for MainAxisSize.min
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: _filteredItems.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 4),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                widget.primaryColor.withOpacity(0.1),
                            child: Icon(item.icon ?? Icons.person_outline,
                                size: 18, color: widget.primaryColor),
                          ),
                          title: Text(item.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: item.subtitle != null
                              ? Text(item.subtitle!,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12))
                              : null,
                          trailing: widget.isMultiSelect
                              ? Checkbox(
                                  value: _selectedIds.contains(item.id),
                                  activeColor: widget.primaryColor,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedIds.add(item.id);
                                      } else {
                                        _selectedIds.remove(item.id);
                                      }
                                    });
                                  })
                              : null,
                          onTap: () {
                            if (widget.isMultiSelect) {
                              setState(() {
                                if (_selectedIds.contains(item.id)) {
                                  _selectedIds.remove(item.id);
                                } else {
                                  _selectedIds.add(item.id);
                                }
                              });
                            } else {
                              if (widget.onItemSelected != null) {
                                widget.onItemSelected!(item.id);
                              }
                              Navigator.pop(context);
                            }
                          },
                        );
                      },
                    ),
            ),

            if (widget.isMultiSelect)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      if (widget.onMultiItemSelected != null) {
                        widget.onMultiItemSelected!(_selectedIds.toList());
                      }
                      Navigator.pop(context);
                    },
                    child: Text("Done (${_selectedIds.length} Selected)",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
