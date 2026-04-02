import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/provider_rating_controller.dart';
import '../widgets/searchable_selection_sheet.dart';

class ProviderRatingScreen extends StatelessWidget {
  ProviderRatingScreen({super.key});

  final ProviderRatingController controller = Get.put(ProviderRatingController());

  // --- Design System Colors (Matching HolidayManagementScreen) ---
  final Color primaryOrange = const Color(0xFFF97316);
  final Color textDark = const Color(0xFF1E293B);
  final Color textGrey = const Color(0xFF64748B);
  final Color borderGrey = const Color(0xFFE2E8F0);
  final Color bgLight = const Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Provider Ratings",
            style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderGrey, height: 1),
        ),
        iconTheme: IconThemeData(color: textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Provider Performance & Feedback",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textDark)),
            const SizedBox(height: 8),
            Text("Monitor real-time customer ratings and detailed reviews for specifically selected providers.",
                style: TextStyle(color: textGrey, fontSize: 14)),
            const SizedBox(height: 32),

            _buildSelectionBar(context),
            const SizedBox(height: 32),

            // --- MAIN CONTENT AREA ---
            Obx(() {
              // 1. Check if Provider is Selected
              bool isSelected = controller.selectedProviderId.value != null;
              if (!isSelected) return _buildEmptyState();

              // 2. Check if API is loading
              if (controller.isLoadingRatings.value) {
                return const SizedBox(
                  height: 400,
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFF97316))),
                );
              }

              // 3. Check if list is empty
              if (controller.ratingsList.isEmpty) {
                return _buildNoDataState();
              }

              return Column(
                children: controller.ratingsList.map((rating) => _buildRatingCard(rating)).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildEmptyState() {
    return Container(
      height: 400,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: bgLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderGrey)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_outline_rounded, size: 64, color: primaryOrange.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text("No Provider Selected",
              style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Select a provider above to view their performance ratings and customer reviews.",
              style: TextStyle(color: textGrey)),
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return Container(
      height: 400,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: bgLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderGrey)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.feedback_outlined, size: 64, color: textGrey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text("No Ratings Yet",
              style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("This provider hasn't received any customer ratings or reviews yet.",
              style: TextStyle(color: textGrey)),
        ],
      ),
    );
  }

  Widget _buildSelectionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderGrey),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(() {
              final selectedId = controller.selectedProviderId.value;
              final selectedProvider = controller.providerController.allProviders
                  .firstWhereOrNull((p) => p.id == selectedId);

              return InkWell(
                onTap: () {
                  SearchableSelectionSheet.show(
                    context,
                    title: "Select Service Provider",
                    primaryColor: primaryOrange,
                    items: controller.providerController.allProviders.map((p) {
                      return SelectionItem(
                          id: p.id,
                          title: "${p.firstName} ${p.lastName}",
                          subtitle: p.mobileNo,
                          icon: Icons.person_outline);
                    }).toList(),
                    onItemSelected: (id) => controller.onProviderChanged(id),
                  );
                },
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                      color: bgLight,
                      border: Border.all(color: borderGrey),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 20, color: textGrey),
                      const SizedBox(width: 12),
                      Text(
                        selectedProvider != null
                            ? "${selectedProvider.fullName} (${selectedProvider.mobileNo})"
                            : "Choose a service provider to view ratings...",
                        style: TextStyle(color: selectedProvider != null ? textDark : textGrey),
                      ),
                      const Spacer(),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
                if(controller.selectedProviderId.value != null){
                   controller.fetchProviderRatings(controller.selectedProviderId.value!);
                }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              fixedSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Refresh List"),
          )
        ],
      ),
    );
  }

  Widget _buildRatingCard(dynamic rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderGrey),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Image
          CircleAvatar(
            radius: 30,
            backgroundColor: bgLight,
            backgroundImage: rating.customerImage != null ? NetworkImage(rating.customerImage) : null,
            child: rating.customerImage == null ? Icon(Icons.person, color: textGrey) : null,
          ),
          const SizedBox(width: 20),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(rating.customerName,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark)),
                    _buildStars(rating.rating),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  rating.comment,
                  style: TextStyle(color: textGrey, fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          color: const Color(0xFFFFB800),
          size: 20,
        );
      }),
    );
  }
}
