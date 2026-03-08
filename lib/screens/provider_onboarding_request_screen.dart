import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/onboarding_request_controller.dart';

class ProviderOnboardingRequestScreen extends StatelessWidget {
  final OnboardingRequestController controller = Get.put(OnboardingRequestController());
  
  // 1. ADD: Callback function to notify Dashboard
  final Function(dynamic request)? onViewRequest;

  // 2. UPDATE: Constructor to accept the callback
  ProviderOnboardingRequestScreen({super.key, this.onViewRequest});

  // Theme Colors
  final Color primaryOrange = const Color(0xFFF97316);
  final Color textDark = const Color(0xFF1E293B);
  final Color textGrey = const Color(0xFF64748B);
  final Color bgLight = const Color(0xFFF1F5F9);
  final Color borderGrey = const Color(0xFFE2E8F0);
  final Color successGreen = const Color(0xFF22C55E);
  final Color dangerRed = const Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER & TABS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Onboarding Requests", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark)),
                    const SizedBox(height: 4),
                    Text("Review pending provider applications and document updates", style: TextStyle(color: textGrey, fontSize: 13)),
                  ],
                ),
                // Custom Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderGrey),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _buildTab("All", 3, true),
                      _buildTab("Pending", 3, false),
                      _buildTab("Approved", 0, false),
                      _buildTab("Rejected", 0, false),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),

            // --- TABLE HEADER ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                border: Border.all(color: borderGrey),
              ),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text("Provider Details", style: _headerStyle())),
                  Expanded(flex: 2, child: Text("Request Info", style: _headerStyle())),
                  Expanded(flex: 2, child: Text("Status", style: _headerStyle())),
                  Expanded(flex: 3, child: Text("Documents", style: _headerStyle())),
                  Expanded(flex: 2, child: Text("Actions", style: _headerStyle(), textAlign: TextAlign.end)),
                ],
              ),
            ),

            // --- REQUEST LIST ---
            Obx(() => ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.requestList.length,
              itemBuilder: (context, index) {
                final req = controller.requestList[index];
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: borderGrey),
                      left: BorderSide(color: borderGrey),
                      right: BorderSide(color: borderGrey),
                    ),
                  ),
                  child: Row(
                    children: [
                      // 1. Details
                      Expanded(flex: 3, child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.blue.shade50,
                            child: Text(req.name.substring(0, 1), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(req.name, style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                              Text(req.phone, style: TextStyle(fontSize: 12, color: textGrey)),
                              Text(req.email, style: TextStyle(fontSize: 12, color: textGrey)),
                            ],
                          ),
                        ],
                      )),
                      
                      // 2. Request Info
                      Expanded(flex: 2, child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 6, color: Colors.purple.shade400),
                                const SizedBox(width: 6),
                                Text(req.requestType, style: TextStyle(fontSize: 11, color: Colors.purple.shade700, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 12, color: textGrey),
                              const SizedBox(width: 4),
                              Text("${req.requestDate.year}-${req.requestDate.month}-${req.requestDate.day}", style: TextStyle(fontSize: 12, color: textGrey)),
                            ],
                          )
                        ],
                      )),

                      // 3. Status
                      Expanded(flex: 2, child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF9C3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, size: 8, color: Color(0xFFCA8A04)),
                                const SizedBox(width: 6),
                                Text(req.status, style: const TextStyle(color: Color(0xFFCA8A04), fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      )),

                      // 4. Documents
                      Expanded(flex: 3, child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: req.documents.map((doc) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: borderGrey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.description_outlined, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(doc, style: TextStyle(fontSize: 11, color: textDark)),
                            ],
                          ),
                        )).toList(),
                      )),

                      // 5. Actions
                      Expanded(flex: 2, child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _actionButton(Icons.check_circle_outline, successGreen, () => controller.approveRequest(req.id)),
                          const SizedBox(width: 8),
                          _actionButton(Icons.cancel_outlined, dangerRed, () => controller.rejectRequest(req.id)),
                          const SizedBox(width: 8),
                          
                          // 3. UPDATE: View Icon Tap Logic
                          _actionButton(Icons.visibility_outlined, textGrey, () {
                            if (onViewRequest != null) {
                              onViewRequest!(req);
                            }
                          }),
                        ],
                      )),
                    ],
                  ),
                );
              },
            )),

            // --- FOOTER / PAGINATION ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                border: Border.all(color: borderGrey),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Showing 1 to 3 of 3 results", style: TextStyle(color: textGrey, fontSize: 13)),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: (){}, 
                        style: OutlinedButton.styleFrom(side: BorderSide(color: borderGrey), foregroundColor: textGrey),
                        child: const Text("Previous")
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: (){}, 
                        style: OutlinedButton.styleFrom(side: BorderSide(color: borderGrey), foregroundColor: textGrey),
                        child: const Text("Next")
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---

  TextStyle _headerStyle() {
    return TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 13);
  }

  Widget _buildTab(String text, int count, bool isActive) {
    return InkWell(
      onTap: () => controller.setTab(text),
      child: Obx(() {
        bool active = controller.selectedTab.value == text; 
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFFF7ED) : Colors.transparent, 
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Text(text, style: TextStyle(
                color: active ? primaryOrange : textGrey, 
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                fontSize: 13
              )),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: active ? primaryOrange : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text("$count", style: TextStyle(fontSize: 10, color: active ? Colors.white : textGrey)),
                )
              ]
            ],
          ),
        );
      }),
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}