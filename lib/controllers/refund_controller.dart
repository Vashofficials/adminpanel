import 'package:get/get.dart';
import '../services/api_service.dart';
import '../widgets/custom_center_dialog.dart';

class RefundController extends GetxController {
  var isLoading = false.obs;
  var refundList = <dynamic>[].obs;
  final ApiService _apiService = ApiService();

  @override
  void onInit() {
    fetchRefunds();
    super.onInit();
  }

  Future<void> fetchRefunds() async {
    try {
      isLoading(true);
      var response = await _apiService.getAllRefundRequests();
      if (response.statusCode == 200) {
        // Assuming the response structure has a 'result' or 'data' key
        refundList.value = response.data['result'] ?? response.data;
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load refunds: $e");
    } finally {
      isLoading(false);
    }
  }

 Future<void> updateRefundStatus(
  String id, {
  String? remark,
  String? transactionNo,
  String? refundedDate,
}) async {
  try {
    isLoading(true);
    var response = await _apiService.updateRefundStatus(
      id,
      remark: remark,
      transactionNo: transactionNo,
      refundedDate: refundedDate,
    );

    if (response.statusCode == 200) {
      await fetchRefunds(); // Refresh list
      if (Get.context != null) {
        CustomCenterDialog.show(
          Get.context!,
          title: "Success",
          message: "Refund Payment Status Updated!",
          type: DialogType.success,
        );
      }
    }
  } catch (e) {
    if (Get.context != null) {
      CustomCenterDialog.show(
        Get.context!,
        title: "Update Failed",
        message: e.toString(),
        type: DialogType.error,
      );
    }
  } finally {
    isLoading(false);
  }
}
}