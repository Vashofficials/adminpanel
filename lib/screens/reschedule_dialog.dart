import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking_models.dart';
import '../services/api_service.dart';
import '../widgets/custom_center_dialog.dart'; // Ensure this exists

class RescheduleBookingDialog extends StatefulWidget {
  final BookingModel booking;
  final VoidCallback onBack;

  const RescheduleBookingDialog({
    Key? key,
    required this.booking,
    required this.onBack,
  }) : super(key: key);

  @override
  State<RescheduleBookingDialog> createState() =>
      _RescheduleBookingDialogState();
}

class _RescheduleBookingDialogState extends State<RescheduleBookingDialog> {
  final ApiService _apiService = ApiService();

  late TextEditingController dateCtrl;
  late TextEditingController timeCtrl;
  late TextEditingController reasonCtrl;
  final TextEditingController otherReasonCtrl = TextEditingController();

  List providers = [];
  List addresses = [];

  String? selectedProviderId;
  String? selectedProviderName;

  String? selectedAddressId;
  String? initialSelectedAddressId;
  String? selectedLocationId;

  String? selectedReasonDropdown;

  bool isLoadingProviders = false;
  bool isLoadingAddress = false;

  late DateTime earliestAllowedDate;
  late DateTime selectedDate;

  static const List<String> _rescheduleReasons = [
    'Customer Not Available',
    'Provider Not Available',
    'Customer Asked to Reschedule',
    'Change of Plan',
    'Wrong Booking',
    'Other',
  ];

  final List<String> timeSlots = [
    "08:30 AM",
    "09:00 AM",
    "09:30 AM",
    "10:00 AM",
    "10:30 AM",
    "11:00 AM",
    "11:30 AM",
    "12:00 PM",
    "12:30 PM",
    "01:00 PM",
    "01:30 PM",
    "02:00 PM",
    "02:30 PM",
    "03:00 PM",
    "03:30 PM",
    "04:00 PM",
    "04:30 PM",
    "05:00 PM",
    "05:30 PM",
    "06:00 PM",
    "06:30 PM",
    "07:00 PM"
  ];

  List<String> getAvailableTimeSlots() {
    final now = DateTime.now();
    if (selectedDate.year != now.year ||
        selectedDate.month != now.month ||
        selectedDate.day != now.day) {
      return timeSlots;
    }

    return timeSlots.where((time) {
      try {
        final format = DateFormat('hh:mm a');
        final timeDateTime = format.parse(time);
        final slotDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          timeDateTime.hour,
          timeDateTime.minute,
        );
        return slotDateTime.isAfter(now);
      } catch (e) {
        return true; 
      }
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    earliestAllowedDate = DateTime.now();

    // Parse current booking date or default to earliest allowed
    try {
      selectedDate = DateTime.parse(widget.booking.bookingDate.split('T')[0]);
      if (selectedDate.isBefore(earliestAllowedDate)) {
        selectedDate = earliestAllowedDate;
      }
    } catch (_) {
      selectedDate = earliestAllowedDate;
    }

    dateCtrl = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(selectedDate));
    timeCtrl = TextEditingController();
    reasonCtrl = TextEditingController();

    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    setState(() {
      isLoadingAddress = true;
    });

    try {
      final res =
          await _apiService.getCustomerAddresses(widget.booking.customerId);
      setState(() {
        addresses = res;
        if (addresses.isNotEmpty) {
          final defaultAddr = addresses.firstWhere(
            (a) => a['isDefault'] == true,
            orElse: () => addresses[0],
          );
          selectedAddressId = defaultAddr['id'];
          initialSelectedAddressId = defaultAddr['id'];
          selectedLocationId = defaultAddr['locationId'];
        }
      });
      // Fetch providers if we have a valid initial state
      if (canFetch()) {
        fetchProviders();
      }
    } catch (e) {
      debugPrint("Error fetching addresses: $e");
    } finally {
      setState(() {
        isLoadingAddress = false;
      });
    }
  }

  bool canFetch() {
    if (widget.booking.services.isEmpty) return false;
    if (selectedAddressId == null) return false;
    if (selectedLocationId == null) return false;
    if (dateCtrl.text.isEmpty) return false;
    if (timeCtrl.text.isEmpty) return false;
    return true;
  }

  Future<void> fetchProviders() async {
    if (!canFetch()) return;

    setState(() {
      isLoadingProviders = true;
      providers.clear();
      selectedProviderId = null;
      selectedProviderName = null;
    });

    final service = widget.booking.services.first;

    // Convert time to 24h format if needed by backend, assuming the UI displays AM/PM but backend might need HH:mm
    // Wait, the previous code just sent timeCtrl.text as is. We will format it properly.
    String formattedTime = "";
    try {
      DateTime parsedTime = DateFormat('hh:mm a').parse(timeCtrl.text);
      formattedTime = DateFormat('HH:mm').format(parsedTime);
    } catch (e) {
      formattedTime = timeCtrl.text; // fallback
    }

    final payload = {
      "categoryId": service.categoryId,
      "serviceId": service.serviceId,
      "locationId": selectedLocationId,
      "addressId": selectedAddressId,
      "bookingDate": dateCtrl.text,
      "bookingTime": formattedTime,
      "currentBookingDuration": widget.booking.totalDuration,
    };

    try {
      final result = await _apiService.getServiceProviders(payload);
      setState(() {
        providers = result;
        if (providers.isNotEmpty) {
          selectedProviderId = providers[0]['id'];
          selectedProviderName =
              "${providers[0]['firstName']} ${providers[0]['lastName']}";
        }
      });
    } catch (e) {
      debugPrint("Error fetching providers: $e");
    } finally {
      setState(() {
        isLoadingProviders = false;
      });
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      selectedDate = date;
      dateCtrl.text = DateFormat('yyyy-MM-dd').format(date);
    });
    fetchProviders();
  }

  void _onTimeSelected(String time) {
    setState(() {
      timeCtrl.text = time;
    });
    fetchProviders();
  }

  Future<void> _submitReschedule() async {
    if (dateCtrl.text.isEmpty) {
      CustomCenterDialog.show(context,
          title: "Required",
          message: "Please select a date",
          type: DialogType.required);
      return;
    }
    if (timeCtrl.text.isEmpty) {
      CustomCenterDialog.show(context,
          title: "Required",
          message: "Please select a time slot",
          type: DialogType.required);
      return;
    }
    if (selectedProviderId == null) {
      CustomCenterDialog.show(context,
          title: "Required",
          message: "Please select an Active Provider",
          type: DialogType.required);
      return;
    }
    if (reasonCtrl.text.trim().isEmpty) {
      CustomCenterDialog.show(context,
          title: "Required",
          message: "Please select a Reschedule Reason",
          type: DialogType.required);
      return;
    }

    // Format time for API
    String formattedTime = timeCtrl.text;
    try {
      DateTime parsedTime = DateFormat('hh:mm a').parse(timeCtrl.text);
      formattedTime = DateFormat('HH:mm').format(parsedTime);
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final adminName = prefs.getString('admin_name') ?? 'Admin';

    final payload = {
      "bookingId": widget.booking.id,
      "customerId": widget.booking.customerId,
      "spId": selectedProviderId,
      "addressId": selectedAddressId,
      "rescheduleDate": dateCtrl.text,
      "rescheduleTime": formattedTime,
      "rescheduleReason": reasonCtrl.text,
      "adminName": adminName,
      // backward compat
      "bookingDate": dateCtrl.text,
      "bookingTime": formattedTime,
    };

    final bool success = await _apiService.rescheduleBooking(payload);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      widget.onBack();
      if (mounted) {
        CustomCenterDialog.show(
          context,
          title: "Success",
          message: "Booking rescheduled successfully",
          type: DialogType.success,
        );
      }
    } else {
      CustomCenterDialog.show(
        context,
        title: "Failed",
        message: "Unable to reschedule. Please try again.",
        type: DialogType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate dates starting from earliestAllowedDate up to 4 days
    List<DateTime> dateOptions = List.generate(
      4,
      (index) => earliestAllowedDate.add(Duration(days: index)),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.grey[50], // Light background matching image
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 800),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Reschedule Booking",
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          Text("Update date & time, select provider.",
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("Booking ID",
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 12)),
                            Row(
                              children: [
                                Text(widget.booking.id,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: widget.booking.id));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                      content: Text('Booking ID copied to clipboard'),
                                      duration: Duration(seconds: 2),
                                    ));
                                  },
                                  child: const Icon(Icons.copy, size: 16, color: Colors.blue),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Container(
                            width: 1, height: 30, color: Colors.grey[300]),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("Current Date & Time",
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 12)),
                            Text(
                                "${DateFormat('dd MMM yyyy').format(DateTime.parse(widget.booking.bookingDate))}, ${widget.booking.bookingTime}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),

              // TWO COLUMNS
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT COLUMN
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle("1", "Select Address"),
                              const SizedBox(height: 12),
                              if (isLoadingAddress)
                                const Center(child: CircularProgressIndicator())
                              else
                                DropdownButtonFormField<String>(
                                  value: selectedAddressId,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.location_on,
                                        color: Colors.orange),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 14),
                                  ),
                                  items: addresses
                                      .map<DropdownMenuItem<String>>((addr) {
                                    String addressLine1 = addr['addressLine1'] ?? '';
                                    String addressLine2 = addr['addressLine2'] ?? '';
                                    String city = addr['city'] ?? '';
                                    String state = addr['state'] ?? '';
                                    String postcode = addr['postCode'] ?? addr['pincode'] ?? '';
                                    String addressType = addr['addressType'] ?? '';

                                    List<String> parts = [];
                                    if (addressLine1.isNotEmpty) parts.add(addressLine1);
                                    if (addressLine2.isNotEmpty) parts.add(addressLine2);
                                    if (city.isNotEmpty) parts.add(city);
                                    if (state.isNotEmpty) parts.add(state);
                                    if (postcode.isNotEmpty) parts.add(postcode);

                                    String fullAddress = parts.join(', ');
                                    if (addressType.isNotEmpty) {
                                      fullAddress += ' - $addressType';
                                    }

                                    return DropdownMenuItem<String>(
                                      value: addr['id'],
                                      child: Tooltip(
                                        message: fullAddress,
                                        child: Text(
                                          fullAddress,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null && val != initialSelectedAddressId) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Warning: The booking address has been changed.'),
                                          duration: Duration(seconds: 3),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                    setState(() {
                                      selectedAddressId = val;
                                      final addr = addresses
                                          .firstWhere((a) => a['id'] == val);
                                      selectedLocationId = addr['locationId'];
                                    });
                                    fetchProviders();
                                  },
                                ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSectionTitle("2", "Reschedule Date"),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 14),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey.shade300),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.calendar_today,
                                                  size: 20, color: Colors.grey),
                                              const SizedBox(width: 8),
                                              Text(DateFormat('dd MMM yyyy')
                                                  .format(selectedDate)),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSectionTitle(
                                            "3", "Reschedule Time"),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 14),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey.shade300),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.access_time,
                                                  size: 20, color: Colors.grey),
                                              const SizedBox(width: 8),
                                              Text(timeCtrl.text.isEmpty
                                                  ? "Select Time"
                                                  : timeCtrl.text),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _buildSectionTitle("4", "Active Provider"),
                              const SizedBox(height: 12),
                              if (isLoadingProviders)
                                const Center(child: CircularProgressIndicator())
                              else if (providers.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.orange.shade200),
                                  ),
                                  child: const Text(
                                      "No providers available for the selected slot.",
                                      style: TextStyle(color: Colors.orange)),
                                )
                              else
                                Column(
                                  children: providers.map((p) {
                                    bool isSelected =
                                        selectedProviderId == p['id'];
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedProviderId = p['id'];
                                          selectedProviderName =
                                              "${p['firstName']} ${p['lastName']}";
                                        });
                                      },
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.orange.shade50
                                              : Colors.white,
                                          border: Border.all(
                                              color: isSelected
                                                  ? Colors.orange
                                                  : Colors.grey.shade300),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Radio<String>(
                                              value: p['id'],
                                              groupValue: selectedProviderId,
                                              activeColor: Colors.orange,
                                              onChanged: (val) {
                                                setState(() {
                                                  selectedProviderId = val;
                                                  selectedProviderName =
                                                      "${p['firstName']} ${p['lastName']}";
                                                });
                                              },
                                            ),
                                            CircleAvatar(
                                              backgroundColor: Colors.purple.shade100,
                                              backgroundImage: p['imgLink'] != null && p['imgLink'] != ''
                                                  ? NetworkImage(p['imgLink'].toString().startsWith('http')
                                                      ? p['imgLink']
                                                      : '${ApiService.baseUrl}${p['imgLink']}')
                                                  : null,
                                              child: p['imgLink'] == null || p['imgLink'] == ''
                                                  ? Text(
                                                      p['firstName'] != null && p['firstName'].toString().isNotEmpty 
                                                        ? p['firstName'][0].toUpperCase() 
                                                        : '?',
                                                      style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                  "${p['firstName']} ${p['lastName']}",
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                            const Icon(Icons.star,
                                                color: Colors.orange, size: 16),
                                            const SizedBox(width: 4),
                                            Text("${p['averageRating'] ?? '4.8'}"),
                                            const SizedBox(width: 16),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text("Available",
                                                  style: TextStyle(
                                                      color: Colors.green,
                                                      fontSize: 12)),
                                            ),
                                            const SizedBox(width: 16),
                                            const Icon(Icons.phone,
                                                size: 16, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                                "${p['mobileNo'] ?? '+91 XXXXX XXXXX'}",
                                                style: const TextStyle(
                                                    color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              const SizedBox(height: 24),
                              _buildSectionTitle(
                                  "5", "Reason for Reschedule*"),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: selectedReasonDropdown,
                                decoration: InputDecoration(
                                  hintText: "Select reason for reschedule",
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                ),
                                items: _rescheduleReasons
                                    .map((r) => DropdownMenuItem(
                                        value: r, child: Text(r)))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    selectedReasonDropdown = val;
                                    if (val != 'Other') {
                                      reasonCtrl.text = val ?? '';
                                    } else {
                                      reasonCtrl.text =
                                          'Other: ' + otherReasonCtrl.text;
                                    }
                                  });
                                },
                              ),
                              if (selectedReasonDropdown == 'Other') ...[
                                const SizedBox(height: 12),
                                TextField(
                                  controller: otherReasonCtrl,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    hintText:
                                        "Type reason for rescheduling immediately...",
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onChanged: (val) {
                                    reasonCtrl.text = 'Other: $val';
                                  },
                                ),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // RIGHT COLUMN
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle("6", "Select New Date"),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 80,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: dateOptions.length,
                                    itemBuilder: (context, index) {
                                      DateTime date = dateOptions[index];
                                      bool isSelected = date.year ==
                                              selectedDate.year &&
                                          date.month == selectedDate.month &&
                                          date.day == selectedDate.day;
                                      return GestureDetector(
                                        onTap: () => _onDateSelected(date),
                                        child: Container(
                                          width: 70,
                                          margin:
                                              const EdgeInsets.only(right: 12),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.orange.shade50
                                                : Colors.white,
                                            border: Border.all(
                                                color: isSelected
                                                    ? Colors.orange
                                                    : Colors.grey.shade300),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                  DateFormat('MMM')
                                                      .format(date),
                                                  style: TextStyle(
                                                      color: isSelected
                                                          ? Colors.orange
                                                          : Colors.grey,
                                                      fontSize: 12)),
                                              Text(
                                                  DateFormat('dd').format(date),
                                                  style: TextStyle(
                                                      color: isSelected
                                                          ? Colors.orange
                                                          : Colors.black,
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              Text(
                                                  DateFormat('EEE')
                                                      .format(date),
                                                  style: TextStyle(
                                                      color: isSelected
                                                          ? Colors.orange
                                                          : Colors.grey,
                                                      fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildSectionTitle(
                                    "7", "Select New Start Time"),
                                const SizedBox(height: 16),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    childAspectRatio: 2.5,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: getAvailableTimeSlots().length,
                                  itemBuilder: (context, index) {
                                    String time = getAvailableTimeSlots()[index];
                                    bool isSelected = timeCtrl.text == time;
                                    return GestureDetector(
                                      onTap: () => _onTimeSelected(time),
                                      child: Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.orange.shade50
                                              : Colors.white,
                                          border: Border.all(
                                              color: isSelected
                                                  ? Colors.orange
                                                  : Colors.grey.shade300),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          time,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.orange
                                                : Colors.black,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          color: Colors.blue, size: 20),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "If no slots available on this date please select on other suitable date",
                                          style: TextStyle(
                                              color: Colors.blue, fontSize: 12),
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // FOOTER BUTTONS
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.black)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _submitReschedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Update Booking",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String number, String title) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            shape: BoxShape.circle,
          ),
          child: Text(number,
              style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
