import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Needed for web check
import 'package:dio/dio.dart' as dio; 
import '../services/api_service.dart';
import '../models/data_models.dart';
import '../models/location_model.dart'; 
import '../controllers/provider_controller.dart'; 
import '../controllers/location_controller.dart'; // Import LocationController
import 'document_controller.dart';
import 'banking_controller.dart'; // Import the new controller
import 'package:http_parser/http_parser.dart'; // For MediaType
import 'package:mime/mime.dart'; // To lookup mime type
import '../widgets/custom_center_dialog.dart';
import '../models/service_provider_service.dart';
import '../models/service_provider_location.dart';

class AddProviderController extends GetxController {
  final ApiService _apiService = ApiService();
  
  // Dependency Injection
  late final ProviderController providerListController;
  late final LocationController locationController; // NEW: Injected
  late final DocumentController documentController; // NEW
  late final BankingController bankingController; // NEW
  // true if bank details already exist
final RxBool isBankDetailsAvailable = false.obs;
var mappedServicesList = <ServiceProviderService>[].obs;
  var isServicesLoading = false.obs;


  // --- CALLBACKS ---
  Function? onProviderAdded; 

  // --- STATE ---
  var currentStep = 0.obs;
  var isLoading = false.obs;
  String? currentSpId;

  var isPersonalDetailsCompleted = false.obs; 
  var selectedProviderId = RxnString(); 
  
  // --- VIEW ONLY MODE ---
  var isViewOnly = false.obs;

  // --- STEP 0: PERSONAL ---
  final firstNameCtrl = TextEditingController();
  final middleNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final emailCtrl = TextEditingController(); 
  final aadharCtrl = TextEditingController();
  var selectedGender = "".obs;

  // --- STEP 1: ADDRESS (Manual) ---
  final careOfCtrl = TextEditingController();
  final localityCtrl = TextEditingController();
  final landmarkCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final districtCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final pincodeCtrl = TextEditingController();

  // --- STEP 2: LOCATION MAP (New Separate Step) ---
  var selectedLocation = Rxn<LocationModel>(); 
  
  // --- STEP 3: SERVICES ---
  var categories = <CategoryModel>[].obs;
  var serviceMap = <String, List<ServiceModel>>{}.obs; 
  var selectedServicesMap = <String, Set<String>>{}.obs;

  // --- STEP 4: FINANCIALS ---
  var selectedBankId = RxnString(); 
  final accHolderCtrl = TextEditingController();
  final accNumberCtrl = TextEditingController();
  final ifscCtrl = TextEditingController();
  final upiCtrl = TextEditingController();
  final panNumberCtrl = TextEditingController();
  var isPanAvailable = true.obs;
  Rx<PlatformFile?> passbookFile = Rx<PlatformFile?>(null);
  Rx<PlatformFile?> panCardFile = Rx<PlatformFile?>(null);

  // --- STEP 5: DOCUMENTS ---
  var selectedDocType = "".obs; 
  Rx<PlatformFile?> idProofFile = Rx<PlatformFile?>(null);
  Rx<PlatformFile?> profileImageFile = Rx<PlatformFile?>(null);
  var profileImageUrl = RxnString(); // To store URL if editing an existing provider

  @override
  void onInit() {
    super.onInit();
    // 1. Initialize Provider Controller
    if (Get.isRegistered<ProviderController>()) {
      providerListController = Get.find<ProviderController>();
    } else {
      providerListController = Get.put(ProviderController());
    }

    // 2. Initialize Location Controller
    if (Get.isRegistered<LocationController>()) {
      locationController = Get.find<LocationController>();
    } else {
      locationController = Get.put(LocationController());
    }
if (Get.isRegistered<DocumentController>()) {
      documentController = Get.find<DocumentController>();
    } else {
      documentController = Get.put(DocumentController());
    }

    if (Get.isRegistered<BankingController>()) {
      bankingController = Get.find<BankingController>();
    } else {
      bankingController = Get.put(BankingController());
    }
    loadInitialData();
  }

  void loadInitialData() async {
    isLoading.value = true;
    try {
      // Fetch locations so dropdown is populated
      locationController.fetchLocations();
      // Ensure banks are loaded
      if (bankingController.bankList.isEmpty) {
        bankingController.fetchBanks();
      }

      if (providerListController.allProviders.isEmpty) {
        providerListController.fetchProviders();
      }

      final cats = await _apiService.getCategories();
      categories.value = cats;

      List<Future<List<ServiceModel>>> futures = [];
      for (var cat in cats) {
        futures.add(_apiService.getServices(categoryId: cat.id));
      }
      final results = await Future.wait(futures);

      Map<String, List<ServiceModel>> tempMap = {};
      for (int i = 0; i < cats.length; i++) {
        tempMap[cats[i].id] = results[i];
      }
      serviceMap.value = tempMap;

    } catch (e) {
      print("Error loading initial data: $e");
    } finally {
      isLoading.value = false;
    }
  }
  // --- LOGIC: HANDLE LOCATION SELECTION ---
  void onLocationSelected(LocationModel? loc) {
    selectedLocation.value = loc;
    if (loc != null) {
      // Auto-fill address fields based on selected location
      cityCtrl.text = loc.city ?? "";
      stateCtrl.text = loc.state ?? "";
      pincodeCtrl.text = loc.postCode ?? "";
      // Optional: fill locality if areaName is treated as locality
      localityCtrl.text = loc.areaName ?? ""; 
    }
  }

  void safeSnackbar(String title, String message, {bool isError = false}) {
  if (Get.context == null) {
    debugPrint("⚠️ Snackbar skipped (no context): $title - $message");
    return;
  }

  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.TOP,
    backgroundColor: isError ? Colors.red : Colors.green,
    colorText: Colors.white,
    margin: const EdgeInsets.all(12),
    duration: const Duration(seconds: 3),
  );
}


  // --- IMMEDIATE ONBOARDING LOGIC ---
  Future<void> quickOnboardProvider(String mobileNumber) async {
    if (mobileNumber.length != 10) {
CustomCenterDialog.show(
  Get.context!,
  title: "Error",
  message: "Please enter a valid 10-digit mobile number",
  type: DialogType.error,
);      return;
    }

    try {
      isLoading.value = true;
      String? newId = await _apiService.onboardServiceProvider(mobileNumber);
      
      if (newId != null) {
        print("API Success: New Provider ID: $newId");
        await providerListController.fetchProviders();
        
        var provider = providerListController.allProviders.firstWhereOrNull((p) => p.id == newId);
        
        if (provider == null) {
          await Future.delayed(const Duration(milliseconds: 1500));
          await providerListController.fetchProviders(); 
          provider = providerListController.allProviders.firstWhereOrNull((p) => p.id == newId);
        }

        if (provider == null) {
          throw Exception("New provider ID returned by API, but not found in the list. Please try again.");
        }

        onSelectExistingProvider(newId);

        if (mobileCtrl.text.isEmpty) {
          mobileCtrl.text = mobileNumber;
        }
        
        CustomCenterDialog.show(
  Get.context!,
  title: "Success",
  message: "Provider onboarded! Please complete details.",
  type: DialogType.success,
);

      } else {
        throw Exception("API returned null ID");
      }

    } catch (e) {
      String userMessage = "Something went wrong";

      if (e is dio.DioException) {
        if (e.response?.data != null && e.response?.data is Map) {
          final data = e.response?.data;
          if (data['result'] != null) {
            userMessage = data['result'].toString(); 
          } else {
             userMessage = e.message ?? "Server Error";
          }
        } else if (e.response?.statusCode == 412) {
          userMessage = "This provider is already registered.";
        } else {
          userMessage = e.message ?? "Connection Error";
        }
      } else {
        userMessage = e.toString().replaceAll("Exception:", "").trim();
      }

      print("Final Error Message: $userMessage");

      Future.delayed(const Duration(milliseconds: 300), () {
        if (Get.context != null) {
          ScaffoldMessenger.of(Get.context!).showSnackBar(
            SnackBar(
              content: Text(userMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating, 
              margin: const EdgeInsets.all(10),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
      
    } finally {
      isLoading.value = false;
    }
  }

  // --- SELECTION LOGIC ---
// Inside AddProviderController
// Call this method when a provider is selected (inside onSelectExistingProvider)
  Future<void> fetchMappedServices(String spId) async {
    isServicesLoading.value = true;
    mappedServicesList.clear(); // Clear previous data
    try {
      final services = await _apiService.getServiceProviderServiceMap(spId);
      mappedServicesList.value = services;
      print("✅ Fetched ${services.length} mapped services.");
    } catch (e) {
      print("❌ Error fetching mapped services: $e");
    } finally {
      isServicesLoading.value = false;
    }
  }

// Inside AddProviderController

  void onSelectExistingProvider(String? spId) async { 
    print("🔻 Dropdown Selected Raw Value: $spId");
    selectedProviderId.value = spId;
    
    if (spId == null) {
      resetForms();
      print("ℹ️ Selection cleared");
    } else {
      final provider = providerListController.allProviders.firstWhereOrNull((p) => p.id == spId);
      
      if (provider != null) {
        currentSpId = provider.id;
        isPersonalDetailsCompleted.value = true; 
        profileImageFile.value = null;
        //profileImageUrl.value = provider.profilePic;
        
        // --- 1. Fill Personal & Address Data ---
        mobileCtrl.text = provider.mobileNo; 
        firstNameCtrl.text = provider.firstName ?? "";
        middleNameCtrl.text = provider.middleName ?? "";
        lastNameCtrl.text = provider.lastName ?? "";
        aadharCtrl.text = provider.aadharNo ?? "";
        
        careOfCtrl.text = provider.addressLine1 ?? "";
        landmarkCtrl.text = provider.addressLine2 ?? "";
        localityCtrl.text = provider.locality ?? "";
        cityCtrl.text = provider.city ?? "";
        stateCtrl.text = provider.state ?? "";
        pincodeCtrl.text = provider.zipCode ?? "";

        // --- 2. 🟢 FETCH & SET LOCATION MAP DIRECTLY ---
        try {
           // A. Fetch the map from API
           await locationController.fetchServiceProviderMap(currentSpId!);

           // B. Check if data exists
           if (locationController.providerLocationList.isNotEmpty) {
             var mappedLoc = locationController.providerLocationList.first;

             // 🟢 DIRECT ASSIGNMENT
             // We use the data directly from the mapping API.
             // We do NOT check the master list.
             selectedLocation.value = LocationModel(
               areaId: mappedLoc.areaId,
               areaName: mappedLoc.areaName, // Uses "location" string from API
               // These will be null as this specific API doesn't return them
               city: null, 
               state: null,
               postCode: null
             );
             
             print("📍 Location Map Set: ${mappedLoc.areaName}");
           } else {
             selectedLocation.value = null; 
           }
        } catch (e) {
           print("⚠️ Error syncing location map: $e");
        }

        // --- 3. SAFE DOCUMENT FETCH ---
        try {
           await documentController.fetchUploadedDocuments(currentSpId!);
        } catch (e) {
           // Ignore 404s
        }

        // --- 4. SAFE BANKING FETCH ---
        try {
          await bankingController.fetchProviderBankDetails(currentSpId!);
          fillBankDetailsIfAvailable();
        } catch (e) {
           // Ignore 404s, log others
        }

      } else {
        print("❌ Error: Provider ID not found in list.");
      }
      await fetchMappedServices(currentSpId!);
    }
  }
  void clearBankingForms() {
    print("🧹 Clearing Banking Forms...");

    // 1. Clear Text Controllers (Removes the ghost text)
    selectedBankId.value = null;
    accHolderCtrl.clear();
    accNumberCtrl.clear();
    ifscCtrl.clear();
    upiCtrl.clear();
    panNumberCtrl.clear();
    
    // 2. Reset Files & Toggles
    isPanAvailable.value = true;
    passbookFile.value = null;
    panCardFile.value = null;

    // 3. Force UI to switch from "Card View" to "Form View"
    bankingController.providerBankDetails.value = null;
  }
  // --- NAVIGATION & LOGIC ---
  Future<void> nextStep() async {
    print("👉 Attempting Next Step. CurrentSpId: $currentSpId | Step: ${currentStep.value}");

    if (isLoading.value) return;
    
    if (currentSpId == null) {
CustomCenterDialog.show(
  Get.context!, // Use Get.context!
  title: "Info",
  message: "Please select a provider or onboard a new number first.",
  type: DialogType.info,
);      return;
    }
    
    bool success = false;
    isLoading.value = true;

    try {
      switch (currentStep.value) {
        case 0: 
          success = await _handlePersonalDetails(); 
          // --- UPDATE: If Step 0 success, unlock tabs ---
          if(success) isPersonalDetailsCompleted.value = true; 
          break;
        case 1: success = await _handleAddress(); break;
        case 2: success = await _handleLocationMapping(); break;
        case 3: success = await _handleServices(); break;
        case 4: success = await _handleFinancials(); break;
        case 5: success = await _handleDocuments(); break;
      }

      if (success) {
  if (currentStep.value < 5) {
    currentStep.value++; // ✅ Move to next tab
  } else {
    await _finishOnboardingProcess(); // ✅ Only after documents
  }
}

    } catch (e) {
      String userMessage = "Something went wrong";
      
      if (e is dio.DioException) {
        final data = e.response?.data;
        if (data is Map && data['result'] != null) {
           userMessage = data['result'].toString(); 
        } else {
           userMessage = e.message ?? "Server Error";
        }
        print("❌ API Error: ${e.response?.statusCode} | ${e.response?.data}");
      } else {
        userMessage = e.toString().replaceAll("Exception:", "").trim();
      }

      Future.delayed(const Duration(milliseconds: 300), () {
        if (Get.context != null) {
          ScaffoldMessenger.of(Get.context!).showSnackBar(
            SnackBar(
              content: Text(userMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(10),
            ),
          );
        }
      });
      
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _finishOnboardingProcess() async {
    if (onProviderAdded != null) onProviderAdded!();
    providerListController.fetchProviders();
    
    Get.defaultDialog(
      title: "Success",
      middleText: "Provider process completed!",
      confirm: ElevatedButton(
        onPressed: () { Get.back(); resetForms(); selectedProviderId.value = null; },
        child: const Text("Okay"),
      ),
      barrierDismissible: false,
    );
  }

  void resetForms() {
    currentSpId = null;
    isPersonalDetailsCompleted.value = false;
    
    firstNameCtrl.clear(); middleNameCtrl.clear(); lastNameCtrl.clear();
    mobileCtrl.clear(); emailCtrl.clear(); aadharCtrl.clear();
    careOfCtrl.clear(); localityCtrl.clear(); landmarkCtrl.clear();
    cityCtrl.clear(); districtCtrl.clear(); stateCtrl.clear(); pincodeCtrl.clear();
    clearBankingForms();
    
   profileImageFile.value = null; // Clear local pick
    profileImageUrl.value = null;  // Clear network url

    
    selectedGender.value = "";
    selectedServicesMap.clear();
    idProofFile.value = null;
    currentStep.value = 0;
  }
  
  void prevStep() { if (currentStep.value > 0) currentStep.value--; }

  // --- UPDATED: Navigation Logic ---
  void setStep(int step) { 
    // If Step 0 is completed, user can tap ANY step
    if (isPersonalDetailsCompleted.value) {
      currentStep.value = step;
    } 
    // If Step 0 is NOT completed, revert to standard locking (can only go back)
    else if (step < currentStep.value) { 
      currentStep.value = step; 
    } 
  }

  // --- SERVICE TOGGLE ---
 // REPLACES your old local toggleService
  Future<void> toggleService(String categoryId, String serviceId, String serviceName) async {
    if (currentSpId == null) {
      CustomCenterDialog.show(
        Get.context!,
        title: "Error",
        message: "No Provider Selected",
        type: DialogType.error,
      );
      return;
    }

    // 1. SEARCH: Check if this service is already in our mapped list
    // We match by Name because the mapping API returns names, not the original serviceId
    final index = mappedServicesList.indexWhere((s) => s.service == serviceName);

    if (index != -1) {
      // ---------------------------------------------------------
      // SCENARIO A: SERVICE IS ALREADY MAPPED (Toggle Active/Inactive)
      // ---------------------------------------------------------
      final item = mappedServicesList[index];
      
      // Logic:
      // If currently Active (true) -> We want to DEACTIVATE. API expects 'true' to delete.
      // If currently Inactive (false) -> We want to ACTIVATE. API expects 'false' to restore.
      bool apiParam = item.isActive; 

      // 1. Optimistic Update: Update UI immediately
      item.isActive = !item.isActive; 
      mappedServicesList.refresh(); 

      try {
        // 2. Call API
        bool success = await _apiService.deleteProviderServiceMap(
          item.mappingId!, 
          currentSpId!, 
          apiParam 
        );

        // 3. Revert on Failure
        if (!success) {
          item.isActive = !item.isActive; // Flip back
          mappedServicesList.refresh();
          CustomCenterDialog.show(
            Get.context!,
            title: "Error",
            message: "Failed to update status",
            type: DialogType.error,
          );
        }
      } catch (e) {
        item.isActive = !item.isActive;
        mappedServicesList.refresh();
        print("Toggle Error: $e");
      }

    } else {
      // ---------------------------------------------------------
      // SCENARIO B: SERVICE IS NEW (Map It)
      // ---------------------------------------------------------
      
      // Call Map API
      bool success = await _apiService.mapProviderService(currentSpId!, categoryId, serviceId);
      
      if (success) {
        // Refresh the list to pull the new mapping ID and data
        await fetchMappedServices(currentSpId!);
        
        // Optional: Show success message
        // --- UPDATED: Show Custom Dialog for Success ---
        CustomCenterDialog.show(
          Get.context!,
          title: "Success",
          message: "$serviceName added successfully",
          type: DialogType.success,
        );
      } else {
        CustomCenterDialog.show(
          Get.context!,
          title: "Error",
          message: "Failed to map service",
          type: DialogType.error,
        );
      }
    }
  }
  bool isServiceSelected(String catId, String serviceId) => selectedServicesMap[catId]?.contains(serviceId) ?? false;

  // In AddProviderController
Future<void> pickFile(String type) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, 
        allowedExtensions: ['jpg', 'pdf', 'png', 'jpeg'],
        withData: true // 🔥 CRITICAL for Web: Loads bytes into memory
      );

      if (result != null) {
        // We directly store the PlatformFile. 
        // It contains .bytes (for web) and .path (for mobile/desktop)
        PlatformFile file = result.files.first;

        if (type == 'passbook') passbookFile.value = file;
        else if (type == 'pan') panCardFile.value = file;
        else if (type == 'idproof') idProofFile.value = file;
        
        // Force UI update
        update(); 
      }
    } catch (e) {
      print("Error picking file: $e");
    }
  }

  // --- API CALLS ---
  Future<bool> _handlePersonalDetails() async {
    // 1. Validation
    if (currentSpId == null) {
CustomCenterDialog.show(
  Get.context!, // Use Get.context!
  title: "Error",
  message: "No Service Provider Selected",
  type: DialogType.error,
);
      return false;
    }
    if (firstNameCtrl.text.isEmpty || lastNameCtrl.text.isEmpty) {
CustomCenterDialog.show(
  Get.context!, // Use Get.context!
  title: "Selection Required",
  message: "First Name and Last Name are mandatory",
  type: DialogType.required,
);      return false;
    }

    // 2. Prepare Payload
    final payload = {
      "spId": currentSpId,
      "firstName": firstNameCtrl.text.trim(),
      "middleName": middleNameCtrl.text.trim(),
      "lastName": lastNameCtrl.text.trim(),
      "gender": selectedGender.value,
      "aadharNo": aadharCtrl.text.trim(),
      "isAadharVerified": 0
    };

    // 3. Call API
    bool success = await _apiService.addPersonalDetails(payload);

    // 4. Real-Time Update Logic
    if (success) {
      print("✅ Personal details saved successfully.");
      
      // Refresh the global provider list immediately so the dropdowns 
      // and other screens show the new name/details instantly.
      await providerListController.fetchProviders();
      
      // Optional: If you need to keep the selection active after refresh
      // You might need to re-find the object in the new list, 
      // but usually the ID check in the UI handles this.
    } 

    return success;
  }

  Future<void> pickProfileImage() async {
    if (currentSpId == null) {
      CustomCenterDialog.show(
        Get.context!,
        title: "Error",
        message: "Please select or onboard a provider first.",
        type: DialogType.error,
      );
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true, // Important for Web
      );

      if (result != null) {
        profileImageFile.value = result.files.first;
        // Auto-upload immediately upon selection
        await _uploadProfileImage();
      }
    } catch (e) {
      print("Error picking profile image: $e");
    }
  }

  // 2. Upload Logic
  Future<void> _uploadProfileImage() async {
    if (profileImageFile.value == null || currentSpId == null) return;

    isLoading.value = true;
    try {
      // Convert PlatformFile to Dio MultipartFile
      final multipartFile = await getMultipart(profileImageFile.value!);

      bool success = await _apiService.uploadProviderProfilePic(
        currentSpId!, 
        multipartFile
      );

      if (success) {
        CustomCenterDialog.show(
          Get.context!,
          title: "Success",
          message: "Profile picture updated successfully!",
          type: DialogType.success,
        );
        // Optional: Refresh provider list to get the new URL if your API returns it
        await providerListController.fetchProviders();
      } else {
        CustomCenterDialog.show(
          Get.context!,
          title: "Error",
          message: "Failed to upload profile picture.",
          type: DialogType.error,
        );
      }
    } catch (e) {
      print("Upload Error: $e");
    } finally {
      isLoading.value = false;
    }
  }
  
Future<bool> _handleAddress() async {
  // 1. Validation: Prevent null errors
  if (currentSpId == null) {
CustomCenterDialog.show(
  Get.context!, // Use Get.context!
  title: "Error",
  message: "No Service Provider Selected",
  type: DialogType.error,
);    return false;
  }

  // 2. CRITICAL VALIDATION FIX:
  // The API previously failed because addressLine1 was empty. 
  // We MUST check careOfCtrl here.
  if (careOfCtrl.text.trim().isEmpty) {
    CustomCenterDialog.show(
  Get.context!, // Use Get.context!
  title: "Selection Required",
  message: "House No / Building Name is required",
  type: DialogType.required,
); 
    return false;
  }

  // 3. Validation: Other key fields
  if (cityCtrl.text.isEmpty || stateCtrl.text.isEmpty || pincodeCtrl.text.isEmpty) {
CustomCenterDialog.show(
  Get.context!, // Use Get.context!
  title: "Selection Required",
  message: "City, State, and Pincode are required fields",
  type: DialogType.required,
);     return false;
  }

  // 4. Prepare Payload
  final payload = {
    "spId": currentSpId,
    "addressLine1": careOfCtrl.text.trim(), // Validated above, safe to send
    "addressLine2": landmarkCtrl.text.trim(),
    "locality": localityCtrl.text.trim(),
    "city": cityCtrl.text.trim(),
    "state": stateCtrl.text.trim(),
    "postCode": pincodeCtrl.text.trim()
  };

  // 5. Call API
  bool success = await _apiService.addAddress(payload);

  // 6. Success Logic
  if (success) {
    print("✅ Address saved. Refreshing provider list...");
    
    // Refresh the list immediately so the UI reflects the new address
    await providerListController.fetchProviders(); 
    
CustomCenterDialog.show(
  Get.context!,
  title: "Success",
  message: "Address saved successfully!",
  type: DialogType.success,
);  } else {
    // If it failed, check the debug console for the specific error
    CustomCenterDialog.show(
  Get.context!, // Use Get.context!
  title: "Error",
  message: "Failed to save address.",
  type: DialogType.error,
);
  }

  return success;
}

  Future<bool> _handleServices() async {
    List<Future> tasks = [];
    bool anySelected = false;
    selectedServicesMap.forEach((catId, serviceIds) {
      for (var srvId in serviceIds) {
        anySelected = true;
        tasks.add(_apiService.mapProviderService(currentSpId!, catId, srvId));
      }
    });
if (!anySelected) {
  CustomCenterDialog.show(
    Get.context!, 
    title: "Selection Required",
    message: "Please select at least one service",
    type: DialogType.required, // Uses your orange warning style
  );
  return  false;
  }    await Future.wait(tasks);
    return true;
  }
Future<dio.MultipartFile> getMultipart(PlatformFile file) async {
  // 1. Determine Mime Type (e.g., "image/jpeg")
  // If you don't have mime package, default to image/jpeg or verify file extension
  final mimeType = lookupMimeType(file.name) ?? 'image/jpeg'; 
  final typeData = mimeType.split('/'); 
  
  if (kIsWeb) {
    return dio.MultipartFile.fromBytes(
      file.bytes!,
      filename: file.name,
      contentType: MediaType(typeData[0], typeData[1]), // <--- FIX HERE
    );
  } else {
    return dio.MultipartFile.fromFile(
      file.path!,
      filename: file.name,
      contentType: MediaType(typeData[0], typeData[1]), // <--- FIX HERE
    );
  }
}
void fillBankDetailsIfAvailable() {
  final data = bankingController.providerBankDetails.value;
  if (data == null) return;

  if (data.bankId != null) {
    selectedBankId.value = data.bankId;
  }

  accHolderCtrl.text = data.accountHolderName;
  accNumberCtrl.text = data.accountNo;
  ifscCtrl.text = data.ifscCode;
  upiCtrl.text = data.upiId ?? '';
  isPanAvailable.value = data.isPanAvailable;
  panNumberCtrl.text = data.panNo ?? '';
}


  // --- UPDATED: Handle Financials (Step 4) ---
Future<bool> _handleFinancials() async {
  // 🟢 1. CHECK: If details are already loaded/saved, skip upload logic.
  if (bankingController.providerBankDetails.value != null) {
    print("✅ Bank details already verified. Proceeding to next step.");
    return true; 
  }

  // --- EXISTING UPLOAD LOGIC STARTS HERE ---

  // 2. Validation
  if (selectedBankId.value == null) {
CustomCenterDialog.show(
  Get.context!, // Use Get.context!
  title: "Selection Required",
  message: "Please select a Bank",
  type: DialogType.required,
);     return false;
  }

  if (passbookFile.value == null) {
CustomCenterDialog.show(
  Get.context!, // Use Get.context!
  title: "Selection Required",
  message: "Passbook image required",
  type: DialogType.required,
);     return false;
  }

  if (isPanAvailable.value && panCardFile.value == null) {
CustomCenterDialog.show(
  Get.context!, // Use Get.context!
  title: "Selection Required",
  message: "PAN card image required",
  type: DialogType.required,
);     return false;
  }

  try {
    isLoading.value = true; // Show loader while uploading

    final formData = dio.FormData.fromMap({
      "passBookFile": await getMultipart(passbookFile.value!),
      if (panCardFile.value != null)
        "panCardFile": await getMultipart(panCardFile.value!),
    });

    final success = await _apiService.addBankDetails(
      spId: currentSpId!,
      bankId: selectedBankId.value!,
      accountHolderName: accHolderCtrl.text.trim(),
      accountNo: accNumberCtrl.text.trim(),
      ifscCode: ifscCtrl.text.trim(),
      upiId: upiCtrl.text.trim(),
      isPanAvailable: isPanAvailable.value,
      panNo: panNumberCtrl.text.trim(),
      formData: formData,
    );

    if (success) {
      // 🟢 Refresh banking details so the UI switches to "Read Only" mode
      await bankingController.fetchProviderBankDetails(currentSpId!);
CustomCenterDialog.show(
  Get.context!, // Use Get.context!
  title: "Success",
  message: "Bank details saved successfully!",
  type: DialogType.success,
);    }

    return success;
  } catch (e) {
    print("❌ Error adding financial details: $e");
CustomCenterDialog.show(
  Get.context!, // Use Get.context!
  title: "Error",
  message: "Failed to save bank details",
  type: DialogType.error,
);    return false;
  } finally {
    isLoading.value = false;
  }
}

// --- NEW: Handle Mapping Logic (Step 2) ---
  Future<bool> _handleLocationMapping() async {
    if (selectedLocation.value == null) {
CustomCenterDialog.show(
  Get.context!, // Use Get.context!
  title: "Info",
  message: "Please select a location area from the dropdown.",
  type: DialogType.info,
);      return false;
    }

    final loc = selectedLocation.value!;
    
    // Construct Payload
    final payload = {
      "serviceProviderId": currentSpId,
      "locationId": loc.id,    // Assuming 'id' is the location ID
      "areaId": loc.areaId     // Sending areaId as requested
    };

    print("📍 Sending Map Payload: $payload");

    return await _apiService.mapProviderLocation(payload);
  }
  
// --- 1. ADD NEW MAPPING (Called from Dropdown) ---
// --- 1. ADD NEW MAPPING (Called from Dropdown) ---
  // Updated to accept an optional argument to fix the error
  Future<void> addLocationFromDropdown([LocationModel? loc]) async {
    
    // 1. If a location is passed directly, set it as the selected one
    if (loc != null) {
      selectedLocation.value = loc;
    }

    // 2. Validation
    if (currentSpId == null) {
      CustomCenterDialog.show(
        Get.context!,
        title: "Error",
        message: "No Provider Selected",
        type: DialogType.error,
      );
      return;
    }

    if (selectedLocation.value == null) {
      CustomCenterDialog.show(
        Get.context!,
        title: "Info",
        message: "Please select a location area from the dropdown.",
        type: DialogType.info,
      );
      return;
    }

    final locationToAdd = selectedLocation.value!;

    // 3. Construct Payload
    final payload = {
      "serviceProviderId": currentSpId,
      "locationId": locationToAdd.id,    // Database ID
      "areaId": locationToAdd.areaId     // Logical Area ID
    };

    print("📍 Sending Map Payload: $payload");

    // 4. Call API
    bool success = await _apiService.mapProviderLocation(payload);

    // 5. Handle Result
    if (success) {
      // Refresh the list to show the new item
      await locationController.fetchServiceProviderMap(currentSpId!);
      
      // Clear the selection
      selectedLocation.value = null; 
      
      CustomCenterDialog.show(
        Get.context!,
        title: "Success",
        message: "${locationToAdd.areaName} added successfully",
        type: DialogType.success,
      );
    } else {
      CustomCenterDialog.show(
        Get.context!,
        title: "Error",
        message: "Failed to map location",
        type: DialogType.error,
      );
    }
  }

  // --- 2. TOGGLE STATUS (Called from List Icon) ---
  Future<void> toggleLocationStatus(ServiceProviderLocation item) async {
    if (currentSpId == null) return;

    // Logic: 
    // If currently Active (true) -> We want to DEACTIVATE. API expects 'true' (confirm delete).
    // If currently Inactive (false) -> We want to ACTIVATE. API expects 'false' (undo delete).
    bool apiParam = item.isActive; 

    // 1. Optimistic Update (Update UI immediately)
    item.isActive = !item.isActive; 
    locationController.providerLocationList.refresh(); 

    try {
      // 2. Call Delete/Toggle API
      bool success = await _apiService.deleteProviderLocationMap(
        item.mappingId!, // Requires the mapping ID, not location ID
        currentSpId!,
        apiParam
      );

      // 3. Revert on Failure
      if (!success) {
        item.isActive = !item.isActive;
        locationController.providerLocationList.refresh();
        
        CustomCenterDialog.show(
          Get.context!,
          title: "Error",
          message: "Failed to update status",
          type: DialogType.error,
        );
      }
    } catch (e) {
      // Revert on Exception
      item.isActive = !item.isActive;
      locationController.providerLocationList.refresh();
      print("Location Toggle Error: $e");
    }
  }
Future<bool> _handleDocuments() async {
  // 1. Ensure Service Provider ID exists
  if (currentSpId == null) {
CustomCenterDialog.show(
  Get.context!, // Use Get.context!
  title: "Error",
  message: "No Service Provider Selected",
  type: DialogType.error,
);    return false;
  }

  final docCtrl = documentController;

  // 2. Ensure document types are loaded
  if (docCtrl.docTypes.isEmpty) {
CustomCenterDialog.show(
  Get.context!, // Use Get.context!
  title: "Info",
  message: "No document types available.",
  type: DialogType.info,
);    return false;
  }

  // 3. Validate required documents
  // (Assuming ALL document types are mandatory – adjust if needed)
  final missingDocs = docCtrl.docTypes.where((docType) {
    return !docCtrl.isUploaded(docType.id);
  }).toList();

  if (missingDocs.isNotEmpty) {
    CustomCenterDialog.show(
  Get.context!, // Use Get.context!
  title: "Error",
  message: "Please upload all required documents before continuing.",
  type: DialogType.error,
);
    return false;
  }

  // 4. Ensure no uploads are still in progress
  if (docCtrl.uploadingDocIds.isNotEmpty) {
    CustomCenterDialog.show(
  Get.context!, // Use Get.context!
  title: "Please wait",
  message: "Documents are still uploading.",
  type: DialogType.info,
);
    return false;
  }

  // 5. Final server sync (safety)
  await docCtrl.fetchUploadedDocuments(currentSpId!);

  // 6. Final confirmation
CustomCenterDialog.show(
  Get.context!, // Use Get.context!
  title: "Success",
  message: "All documents verified successfully!",
  type: DialogType.success,
);  return true;
}

}