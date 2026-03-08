import 'package:flutter/material.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> with SingleTickerProviderStateMixin {
  // Form State
  final _formKey = GlobalKey<FormState>();
  String? _selectedUserType;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // History Tab Controller
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // All, Customer, Provider
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Helper Widgets ---
  Widget _buildLabel(String text, {bool isRequired = false, String? infoText}) {
    return Row(
      children: [
        RichText(
          text: TextSpan(
            text: text,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            children: [
              if (isRequired)
                const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        if (infoText != null) ...[
          const SizedBox(width: 6),
          Tooltip(
            message: infoText,
            child: const Icon(Icons.info_outline, size: 16, color: Colors.grey),
          ),
        ]
      ],
    );
  }

  InputDecoration _buildInputDecoration({String? hintText, String? counterText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      counterText: counterText,
      counterStyle: const TextStyle(fontSize: 12, color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEB5725)),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Main Header ---
            Row(
              children: const [
                Icon(Icons.notifications_active, color: Color(0xFFEB5725), size: 28),
                SizedBox(width: 12),
                Text(
                  'Push Notification Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Send new notifications and manage sent history.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // --- Warning Banner ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                border: Border.all(color: const Color(0xFFFFEDD5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info, color: Color(0xFFEA580C)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Setup Push Notification Messages for customer. Must setup Firebase Configuration page to work notifications.',
                      style: TextStyle(color: Color(0xFF9A3412), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // =================================================================
            // SECTION 1: SEND NOTIFICATION FORM (from image_5.png)
            // =================================================================
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Send New Notification',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Form
                      Expanded(
                        flex: 3,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Title', isRequired: true, infoText: 'Enter notification title'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _titleController,
                                maxLength: 100,
                                decoration: _buildInputDecoration(hintText: 'Type title', counterText: '0/100'),
                              ),
                              const SizedBox(height: 20),
                              _buildLabel('Description', isRequired: true, infoText: 'Enter notification body'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _descriptionController,
                                maxLength: 200,
                                maxLines: 4,
                                decoration: _buildInputDecoration(hintText: 'Type about the description', counterText: '0/200'),
                              ),
                              const SizedBox(height: 20),
                              _buildLabel('Targeted User', isRequired: true, infoText: 'Select who receives this'),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedUserType,
                                decoration: _buildInputDecoration(hintText: 'Select users'),
                                items: const [
                                  DropdownMenuItem(value: 'all', child: Text('All Users')),
                                  DropdownMenuItem(value: 'customer', child: Text('Customers Only')),
                                  DropdownMenuItem(value: 'provider', child: Text('Providers Only')),
                                ],
                                onChanged: (val) => setState(() => _selectedUserType = val),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),
                      // Right Image Upload
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            const Text('Image', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            const Text('Upload your cover Image', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () { /* Implement Image Picker */ },
                              child: Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey.shade400),
                                      const SizedBox(height: 12),
                                      Text('Add Image', style: TextStyle(color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text('Image format - png, jpg, jpeg, gif', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const Text('Image Size - Maximum size 2MB', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const Text('Image Ratio - 2:1', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          elevation: 0,
                        ),
                        child: const Text('Reset', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEB5725),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.send, size: 18),
                        label: const Text('Save & Send', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            Divider(color: Colors.grey.shade300, thickness: 1),
            const SizedBox(height: 30),

            // =================================================================
            // SECTION 2: NOTIFICATION HISTORY (from image_4.png)
            // =================================================================
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notification History',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                const Text('Manage all sent push notifications.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                // Tabs (Serviceman Removed)
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: const Color(0xFFEB5725),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFFEB5725),
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Customer'),
                    Tab(text: 'Provider'),
                  ],
                ),
                const SizedBox(height: 20),
                // Table Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      // Search & Download Bar
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Notification List', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            Row(
                              children: [
                                SizedBox(
                                  width: 250,
                                  child: TextField(
                                    decoration: _buildInputDecoration(hintText: 'Search by title').copyWith(
                                      suffixIcon: const Icon(Icons.search, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.download, size: 16, color: Colors.black87),
                                  label: const Text('Download', style: TextStyle(color: Colors.black87)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                    side: BorderSide(color: Colors.grey.shade300),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Table Header
                      Container(
                        color: const Color(0xFFF8FAFC),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        child: Row(
                          children: const [
                            Expanded(flex: 1, child: Text('SL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B)))),
                            Expanded(flex: 2, child: Text('COVER IMAGE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B)))),
                            Expanded(flex: 4, child: Text('TITLE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B)))),
                            Expanded(flex: 6, child: Text('DESCRIPTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B)))),
                            Expanded(flex: 3, child: Text('SEND TO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B)))),
                            Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B)))),
Expanded(
  flex: 2, 
  child: Text(
    'ACTION', 
    textAlign: TextAlign.end, // <--- MOVED HERE (Inside Text, outside style)
    style: TextStyle(
      fontWeight: FontWeight.bold, 
      fontSize: 12, 
      color: Color(0xFF64748B)
    ),
  )
),                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Table Row Example
                      _buildHistoryRow(
                        sl: '1',
                        title: 'Provider settings updated',
                        description: 'Service at provider place has been actived',
                        sendTo: ['provider-admin'],
                      ),
                      const Divider(height: 1),
                      _buildHistoryRow(
                        sl: '2',
                        title: 'You have Earned a Referral Reward!',
                        description: 'Great news! You have earned a reward for referring a new user...',
                        sendTo: ['customer'],
                      ),
                      // Pagination Footer
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Showing 1-6 of 45', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            Row(
                              children: [
                                _buildPageBtn(Icons.chevron_left),
                                _buildPageBtn(null, text: '1', isActive: true),
                                _buildPageBtn(null, text: '2'),
                                _buildPageBtn(null, text: '3'),
                                _buildPageBtn(Icons.chevron_right),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryRow({required String sl, required String title, required String description, required List<String> sendTo}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(sl, style: const TextStyle(fontSize: 13))),
          Expanded(
            flex: 2,
            child: Container(
              height: 40, width: 40,
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.image, color: Colors.grey),
            ),
          ),
          Expanded(flex: 4, child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          Expanded(flex: 6, child: Text(description, style: const TextStyle(fontSize: 13, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis)),
          Expanded(
            flex: 3,
            child: Wrap(
              spacing: 4,
              children: sendTo.map((tag) => Chip(
                label: Text(tag, style: const TextStyle(fontSize: 10, color: Color(0xFF1E40AF))),
                backgroundColor: const Color(0xFFDBEAFE),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
          ),
          Expanded(
            flex: 2,
            child: Transform.scale(
              scale: 0.7,
              child: Switch(
                value: true,
                activeColor: const Color(0xFFEB5725),
                onChanged: (v) {},
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionIcon(Icons.edit_outlined, const Color(0xFFEB5725)),
                const SizedBox(width: 8),
                _buildActionIcon(Icons.delete_outline, const Color(0xFFEF4444)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color) {
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildPageBtn(IconData? icon, {String? text, bool isActive = false}) {
    return Container(
      width: 32, height: 32,
      margin: const EdgeInsets.only(left: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEB5725) : Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: icon != null
          ? Icon(icon, size: 16, color: Colors.grey)
          : Text(text!, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
    );
  }
}