import 'package:get/get.dart';
import '../services/api_service.dart';
import '../models/booking_report_model.dart';

class BookingReportController extends GetxController {
  var isLoading = false.obs;
  var reportData = Rxn<BookingResult>(); // Changed from BookingData to BookingResult to match your model
  var selectedYear = DateTime.now().year.obs;

  @override
  void onInit() {
    fetchReport();
    super.onInit();
  }

  Future<void> fetchReport() async {
    isLoading.value = true;
    try {
      var data = await ApiService().getBookingReport(selectedYear.value);
      if (data != null) {
        reportData.value = data.result;
      }
    } finally {
      isLoading.value = false;
    }
  }
  
  void updateYear(int year) {
    selectedYear.value = year;
    fetchReport();
  }
}