import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/add_provider_controller.dart';
import 'common_widgets.dart';

class TabAddress extends GetView<AddProviderController> {
  const TabAddress({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader("PERMANENT ADDRESS"),
        const SizedBox(height: 16),

        // --- CRITICAL FIX ---
        // API requires 'addressLine1'. Previously labeled 'Care Of', confusing users.
        // Renamed to 'House No / Building' so users don't leave it blank.
        CustomTextField(
            label: "House No / Building / Flat No *",
            controller:
                controller.careOfCtrl, // This controller maps to addressLine1
            hint: "e.g. Flat 101, Galaxy Apartments"),

        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: CustomTextField(
              label: "Locality / Area *",
              controller: controller.localityCtrl,
              enabled: !controller.isViewOnly.value,
            )),
            const SizedBox(width: 16),
            Expanded(
                child: CustomTextField(
              label: "Landmark *",
              controller: controller.landmarkCtrl,
              enabled: !controller.isViewOnly.value,
            )),
          ],
        ),

        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: CustomTextField(
              label: "City / Town *",
              controller: controller.cityCtrl,
              enabled: !controller.isViewOnly.value,
            )),
            const SizedBox(width: 16),
            Expanded(
                child: CustomTextField(
              label: "District *",
              controller: controller.districtCtrl,
              enabled: !controller.isViewOnly.value,
            )),
          ],
        ),

        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: CustomTextField(
              label: "State *",
              controller: controller.stateCtrl,
              enabled: !controller.isViewOnly.value,
            )),
            const SizedBox(width: 16),
            Expanded(
                child: CustomTextField(
              label: "Pincode *",
              controller: controller.pincodeCtrl,
              enabled: !controller.isViewOnly.value,
            )),
          ],
        ),
      ],
    );
  }
}
