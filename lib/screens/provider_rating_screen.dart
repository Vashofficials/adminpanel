import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/provider_rating_controller.dart';
import '../widgets/searchable_selection_sheet.dart';

class ProviderRatingScreen extends StatelessWidget {
  ProviderRatingScreen({super.key});

  final ProviderRatingController controller = Get.put(ProviderRatingController());

  // --- Design System Colors ---
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
        title: Text("Provider Rating",
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
            Text("Service Provider Ratings & Reviews",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textDark)),
            const SizedBox(height: 8),
            Text("View real-time customer feedback and ratings for your service providers.",
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

              // 3. Check if there are results
              if (controller.ratingList.isEmpty) {
                return _buildNoRatingsState();
              }

              // 4. Display Ratings Card
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.ratingList.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final rating = controller.ratingList[index];
                  return _buildRatingCard(rating);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildSelectionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderGrey),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
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
                            : "Choose a service provider...",
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
        ],
      ),
    );
  }

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
          Icon(Icons.star_half_rounded, size: 64, color: primaryOrange.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text("No Provider Selected",
              style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Select a provider to view their customer reviews and ratings.",
              style: TextStyle(color: textGrey)),
        ],
      ),
    );
  }

  Widget _buildNoRatingsState() {
    return Container(
      height: 300,
      width: double.infinity,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.reviews_outlined, size: 48, color: textGrey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text("No Ratings Yet",
              style: TextStyle(color: textGrey, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("This provider hasn’t received any customer ratings yet.",
              style: TextStyle(color: textGrey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildRatingCard(dynamic rating) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: primaryOrange.withOpacity(0.1),
                backgroundImage: (rating['customerImage'] != null && rating['customerImage'].isNotEmpty)
                    ? NetworkImage(rating['customerImage'])
                    : null,
                child: (rating['customerName'] != null && 
                       (rating['customerImage'] == null || rating['customerImage'].isEmpty))
                    ? Text(rating['customerName'][0].toUpperCase(), 
                        style: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rating['customerName'] ?? "Anonymous",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark)),
                    const SizedBox(height: 4),
                    _buildStarRating(rating['rating'] ?? 0),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            rating['comment'] ?? "No comment provided.",
            style: TextStyle(fontSize: 14, color: textDark, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          color: index < rating ? Colors.amber : textGrey.withOpacity(0.3),
          size: 18,
        );
      }),
    );
  }
}
