import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart'; 
import 'package:mime/mime.dart'; 
import '../models/location_model.dart';
import '../models/data_models.dart';
import 'dart:convert'; // Required for jsonEncode
import 'dart:io';
import '../models/document_type_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // To check web
import 'package:file_picker/file_picker.dart'; // Import this
import '../models/bank_model.dart';
import '../models/buffer_time_model.dart';
import '../models/service_provider_service.dart';
import '../models/service_provider_location.dart';
import '../models/discount_model.dart';
import '../models/slider_banner_model.dart';
import '../models/coupon_model.dart';
import '../models/customer_refundbank.dart';
import '../models/booking_report_model.dart';
import '../models/customer_models.dart';


class ApiService {
  // NO trailing slash
  static const String baseUrl = 'https://api.chayankaro.com'; 

  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Interceptor to add Token to requests
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (e, handler) {
        print("API Error: ${e.response?.statusCode} | ${e.response?.data}");
        return handler.next(e);
      }
    ));
  }
Future<dio.MultipartFile> getMultipart(PlatformFile file) async {
    // Determine Mime Type (e.g., 'image/png')
    // Defaults to 'image/jpeg' if detection fails to ensure backend accepts it
    final mimeTypeStr = lookupMimeType(file.name) ?? 'image/jpeg';
    final mimeSplit = mimeTypeStr.split('/');
    final mediaType = MediaType(mimeSplit[0], mimeSplit[1]);

    if (kIsWeb) {
      return dio.MultipartFile.fromBytes(
        file.bytes!,
        filename: file.name,
        contentType: mediaType, // Explicit Content-Type for Web
      );
    } else {
      return dio.MultipartFile.fromFile(
        file.path!,
        filename: file.name,
        contentType: mediaType, // Explicit Content-Type for Mobile
      );
    }
  }
  // --- HELPER ---
  Future<MultipartFile?> _prepareFile(Uint8List? fileBytes, String? fileName) async {
    if (fileBytes == null || fileName == null) return null;
    final mimeType = lookupMimeType(fileName);
    return MultipartFile.fromBytes(
      fileBytes,
      filename: fileName,
      contentType: mimeType != null ? MediaType.parse(mimeType) : null,
    );
  }

  // --- 1. AUTH ---
  // Returns LoginResponseModel or throws error
  Future<LoginResponseModel> login(String username, String password) async {
    try {
      final response = await _dio.post('/admin/adminLogin', data: {
        "username": username,
        "password": password
      });

      if (response.statusCode == 200 && response.data['result'] != null) {
        // We pass the whole JSON, the Model handles the nested 'result'
        return LoginResponseModel.fromJson(response.data);
      } else {
        throw Exception("Invalid Response: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Login Failed: $e");
    }
  }

  // --- 2. CATEGORIES ---
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _dio.get('/admin/getCategory');
      if (response.data['result'] is List) {
        return (response.data['result'] as List).map((x) => CategoryModel.fromJson(x)).toList();
      }
      return [];
    } catch (e) { return []; }
  }

Future<bool> addCategory({
  required String name, 
  required Uint8List iconBytes, 
  String? iconName,
  required Uint8List bannerBytes, // 👈 New param
  String? bannerName,            // 👈 New param
}) async {
  try {
    FormData formData = FormData.fromMap({
      "file": await _prepareFile(iconBytes, iconName ?? "icon.png"),
      "banner": await _prepareFile(bannerBytes, bannerName ?? "banner.png"), // 👈 Added banner
    });

    await _dio.post(
      '/admin/addCategories',
      queryParameters: {"request": '{"name": "$name"}'}, // Note: Swagger shows 'request' object
      data: formData,
    );
    return true;
  } on DioException catch (e) {
    print("❌ Add category failed: ${e.response?.data}");
    return false;
  }
}

Future<bool> updateCategory({
  required String id, 
  required String name, 
  Uint8List? iconBytes, // 👈 Change to nullable
  String? iconName,
  Uint8List? bannerBytes, // 👈 Change to nullable 
  String  ? bannerName,     // 👈 New Parameter
}) async {
  try {
    Map<String, dynamic> body = {};
    
    // Only add to FormData if a NEW file was actually picked
    if (iconBytes != null) {
      body["file"] = MultipartFile.fromBytes(iconBytes, filename: iconName ?? "icon.png");
    }
    
    if (bannerBytes != null) {
      body["banner"] = MultipartFile.fromBytes(bannerBytes, filename: bannerName ?? "banner.png");
    }

    FormData formData = FormData.fromMap(body);

    var response = await _dio.patch(
      '/admin/updateCategories',
      queryParameters: {
        "categoryId": id,
        "name": name, 
      },
      data: formData,
    );

    return response.statusCode == 200;
  } on DioException catch (e) {
    print("❌ Update failed: ${e.response?.data}");
    return false;
  }
}
  Future<bool> deleteCategory(String categoryId, bool isActive) async {
    try {
      await _dio.delete(
        '/admin/deleteCategory',
        queryParameters: {
          "categoryId": categoryId,
          "isActive": isActive,
        },
      );
      return true;
    } on DioException catch (e) {
      print("❌ Delete category failed: ${e.response?.data}");
      return false;
    }
  }

  // --- 3. SERVICE CATEGORIES ---
  // --- 3. SERVICE CATEGORIES ---
  Future<List<ServiceCategoryModel>> getServiceCategories(String? parentId) async {
    try {
      // If parentId is null, we can't fetch specific services based on current API design
      if (parentId == null) return [];

      final response = await _dio.get('/admin/getServiceCategory', 
        queryParameters: {'categoryId': parentId});
      
      if (response.data['result'] is List) {
        return (response.data['result'] as List).map((x) => 
          // PASS THE parentId HERE so the model knows its parent
          ServiceCategoryModel.fromJson(x, linkCategoryId: parentId)
        ).toList();
      }
      return [];
    } catch (e) { return []; }
  }

 Future<bool> addServiceCategory(
  String parentId,
  String name,
  Uint8List? imageBytes,
  String? imageName,
) async {
  try {
    FormData formData = FormData.fromMap({
      "categoryId": parentId,
      "name": name,
      if (imageBytes != null && imageName != null)
        "file": MultipartFile.fromBytes(
          imageBytes,
          filename: imageName,
          contentType: MediaType(
            "image", 
            imageName.split('.').last.toLowerCase() // png, jpg, svg, etc
          ),
        ),
    });

    await _dio.post(
      '/admin/addServiceCategory',
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
    return true;
  } catch (e, st) {
    print("Error in addServiceCategory: $e\n$st");
    return false;
  }
}

Future<bool> updateServiceCategory(String serviceCatId, String parentCatId, String name, Uint8List imageBytes, String imageName) async {
    try {
      // 1. Prepare FormData with the file
      FormData formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(
          imageBytes,
          filename: imageName,
        ),
      });

      // 2. Post Request
      // Sending data as direct query parameters instead of a JSON string
      var response = await _dio.patch(
        '/admin/updateServiceCategory',
        queryParameters: {
          "serviceCategoryId": serviceCatId,
          "categoryId": parentCatId,
          "name": name,
        },
        data: formData,
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      print("❌ Update service category failed: ${e.response?.data}");
      print("Status Code: ${e.response?.statusCode}");
      return false;
    }
  }
  Future<bool> updateService({
  required String serviceId,
  required String categoryId,
  required String serviceCategoryId,
  required String name,
  required double price,
  required String description,
  required int duration,
  Uint8List? imageBytes,
  String? imageName,
}) async {
  try {
    FormData formData = FormData.fromMap({
      if (imageBytes != null && imageName != null)
        "file": MultipartFile.fromBytes(
          imageBytes,
          filename: imageName,
        ),
    });

    final response = await _dio.patch(
      '/admin/updateService',
      queryParameters: {
        "serviceId": serviceId,
        "categoryId": categoryId,
        "serviceCategoryId": serviceCategoryId,
        "name": name,
        "price": price,
        "description": description,
        "duration": duration,
      },
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    return response.statusCode == 200;
  } catch (e) {
    if (e is DioException) {
      print("❌ ${e.response?.statusCode}");
      print(e.response?.data);
    }
    return false;
  }
}
Future<bool> deleteServiceCategory(String serviceCategoryId, bool isActive) async {
    try {
      await _dio.delete(
        '/admin/deleteServiceCategory',
        queryParameters: {
          "serviceCategoryId": serviceCategoryId,
          "isActive": isActive,
        },
      );
      return true;
    } on DioException catch (e) {
      print("❌ Delete service category failed: ${e.response?.data}");
      return false;
    }
  }

  // --- 4. SERVICES ---
 // --- 4. SERVICES ---
  // UPDATE THIS METHOD IN YOUR API SERVICE
  Future<List<ServiceModel>> getServices({String? categoryId}) async {
    try {
      final response = await _dio.get(
        '/admin/getServices',
        // Pass the categoryId if it exists
        queryParameters: categoryId != null ? {'categoryId': categoryId} : {},
      );

      if (response.data['result'] is List) {
        return (response.data['result'] as List)
            .map((x) => ServiceModel.fromJson(x))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }



// Inside your ApiService class...

Future<bool> addService(
  Map<String, dynamic> serviceData,
  Uint8List? imageBytes,
  String? imageName,
) async {
  try {
    // Map all service fields as form fields (like cURL)
    final Map<String, dynamic> formDataMap = Map.from(serviceData);

    // File part named "file"
    if (imageBytes != null && imageName != null) {
      final ext = imageName.split('.').last.toLowerCase();
      formDataMap['file'] = MultipartFile.fromBytes(
        imageBytes,
        filename: imageName,
        contentType: MediaType('image', ext), // png, jpg, etc.
      );
    }

    FormData formData = FormData.fromMap(formDataMap);

    final response = await _dio.post(
      '/admin/addServices',
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    print("Server Response: ${response.data}");
    return response.statusCode == 200 || response.statusCode == 201;
  } catch (e, st) {
    print("API Error: $e\n$st");
    if (e is DioException) {
      print("Server Response: ${e.response?.data}");
    }
    return false;
  }
}

Future<bool> deleteService(String serviceId, {required bool isActive}) async {
    try {
      final response = await _dio.delete(
        '/admin/deleteService',
        queryParameters: {
          "serviceId": serviceId,
          "isActive": isActive, // ✅ Dynamically sends true or false based on UI input
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Error updating service status: $e");
      return false;
    }
  }

  // --- 5. LOCATIONS ---

  Future<List<LocationModel>> getLocations() async {
    try {
      final response = await _dio.get('/admin/getLocation');
      if (response.data['result'] is List) {
        return (response.data['result'] as List)
            .map((x) => LocationModel.fromJson(x))
            .toList();
      }
      return [];
    } catch (e) {
      print("Get Location Error: $e");
      return [];
    }
  }
// In ApiService class
  Future<bool> updateLocation(Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/admin/updateLocation', data: data);
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Update Location Error: $e");
      return false;
    }
  }
  Future<bool> addLocation(LocationModel location) async {
    try {
      // We send the JSON body directly
      await _dio.post('/admin/addLocation', data: location.toJson());
      return true;
    } catch (e) {
      print("Add Location Error: $e");
      return false;
    }
  }
  Future<bool> deleteLocation(String locationId, bool isActive) async {
    try {
      final response = await _dio.delete(
        '/admin/deleteLocation',
        queryParameters: {
          'locationId': locationId,
          'isActive': isActive,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Delete Location Error: $e");
      return false;
    }
  }
  // inside your ApiService class
Future<dynamic> getAllCustomers({required int page, required int size}) async {
  try {
    // Replace 'dio' with your http client instance
    final response = await _dio.get(
      '/admin/getAllCustomer',
      queryParameters: {
        'page': page,
        'size': size,
      },
    );
    return response.data;
  } catch (e) {
    rethrow;
  }
}
// --- BOOKINGS ---
  Future<dynamic> getBookings({required int page, required int size}) async {
    try {
      final response = await _dio.get(
        '/admin/getBookings',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  // GET CUSTOMER BOOKINGS (Admin)
  Future<Map<String, dynamic>> getCustomerBookings(String customerId) async {
    try {
      final response = await _dio.get(
        '/admin/getCustomerBookings',
        queryParameters: {
          'customerId': customerId,
        },
      );
      
      // Return the raw data map so the Repository can parse it
      return response.data;
    } catch (e) {
      print("❌ Get Customer Bookings Error: $e");
      // Return empty result structure on error to prevent crashes
      return {'result': []}; 
    }
  }

  // GET BOOKING REPORT
  Future<BookingReportModel?> getBookingReport(String year, {String? providerId}) async {
    try {
      final queryParams = <String, dynamic>{'year': year};
      if (providerId != null && providerId.isNotEmpty && providerId != 'All Providers') {
        queryParams['serviceProviderId'] = providerId;
      }
      final response = await _dio.get('/admin/getBookingReport', queryParameters: queryParams);
      if (response.statusCode == 200 && response.data != null) {
        return BookingReportModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print("❌ Get Booking Report Error: $e");
      return null;
    }
  }
  
  // GET PROVIDER BOOKING PAYMENT REPORT
  Future<List<dynamic>?> getProviderBookingPayment(String fromDate, String toDate) async {
    try {
      final response = await _dio.get(
        '/admin/getProviderBookingPayment',
        queryParameters: {
          'fromDate': fromDate,
          'toDate': toDate,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data['result'] as List<dynamic>?;
      }
      return null;
    } catch (e) {
      print("❌ Get Provider Booking Payment Error: $e");
      return null;
    }
  }
  Future<dynamic> getAllServiceProviders() async {
    try {
      final response = await _dio.get('/admin/getAllServiceProvider');
      return response.data;
    } catch (e) {
      print("API Error (Get Providers): $e");
      rethrow; // Pass error to repo for handling
    }
  }
  // inside api_service.dart

  // --- BUFFER CONFIGURATION ---
  Future<dynamic> addBufferTime(Map<String, dynamic> configData) async {
    try {
      // POST request to the specific endpoint
      final response = await _dio.post('/admin/addBufferTime', data: configData);
      return response.data;
    } catch (e) {
      print("API Error (Add Buffer Time): $e");
      rethrow; // Pass error to repo
    }
  }
  // 1. GET ALL BUFFERS
  Future<List<BufferTimeModel>> getAllBufferTimes() async {
    try {
      final response = await _dio.get('/admin/getAllBufferTime');
      
      if (response.statusCode == 200 && response.data['result'] is List) {
        return (response.data['result'] as List)
            .map((e) => BufferTimeModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print("❌ Get All Buffer Error: $e");
      return [];
    }
  }
  Future<bool> deleteBufferTime(String id, bool isActive) async {
    try {
      final response = await _dio.delete(
        '/admin/deleteBufferTime',
        queryParameters: {
          'bufferTimeId': id,
          'isActive': isActive, 
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Delete Buffer Error: $e");
      return false;
    }
  }
  Future<dynamic> updateBufferTime(Map<String, dynamic> configData) async {
    try {
      // Using PATCH as requested
      final response = await _dio.patch('/admin/updateBufferTime', data: configData);
      
      // Return data so Repo knows it succeeded
      return response.data;
    } catch (e) {
      print("❌ Update Buffer Error: $e");
      // Return null so the Repo returns false
      return null; 
    }
  }


  Future<bool> addDocumentType(String name) async {
    try {
      final response = await _dio.post(
        '/admin/addDocumentType',
        data: {"name": name}, // JSON Body
      );

      print("✅ Add Document Type Response: ${response.statusCode}");
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("❌ Add Document Type Error: $e");
      if (e is dio.DioException) {
        print("Server Response: ${e.response?.data}");
      }
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // NEW: ADD BANK
  // Endpoint: /admin/addBank
  // Body: Multipart Form Data (name + file)
  // ---------------------------------------------------------------------------
  Future<bool> addBank(String name, PlatformFile? logoFile) async {
    try {
      // 1. Prepare Data Map
      Map<String, dynamic> formMap = {
        "name": name,
      };

      // 2. Handle File Logic (Matching your existing uploadSpDocument pattern)
      if (logoFile != null) {
        dio.MultipartFile multipartFile;

        if (kIsWeb) {
          // Web: Use Bytes
          multipartFile = dio.MultipartFile.fromBytes(
            logoFile.bytes!,
            filename: logoFile.name,
            contentType: MediaType('image', logoFile.name.split('.').last), // e.g. image/png
          );
        } else {
          // Mobile: Use Path
          multipartFile = await dio.MultipartFile.fromFile(
            logoFile.path!,
            filename: logoFile.name,
            contentType: MediaType('image', logoFile.name.split('.').last),
          );
        }
        // Add to map with key 'file' as expected by endpoint
        formMap['file'] = multipartFile;
      }

      // 3. Create FormData
      final formData = dio.FormData.fromMap(formMap);

      // 4. Send Request
      final response = await _dio.post(
        '/admin/addBank',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data', // Explicitly set content type
        ),
      );

      print("✅ Add Bank Response: ${response.statusCode}");
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("❌ Add Bank Error: $e");
      if (e is dio.DioException) {
        print("Server Response: ${e.response?.data}");
      }
      return false;
    }
  }
 // 1. Onboard Provider (Get SP ID)
 Future<dynamic> onboardServiceProvider(String mobileNo, String emailId) async {
    try {
      final response = await _dio.post('/admin/onboardServiceProvider', data: {
        "mobileNo": mobileNo,
        "emailId": emailId
      });
      return response.data;
    } catch (e) {
      throw Exception("Onboard Error: ${e.toString()}");
    }
  }

// In services/api_service.dart

Future<bool> addPersonalDetails(Map<String, dynamic> data) async {
  try {
    print("📤 Sending Personal Details: $data"); // Debug print
    
    final response = await _dio.post('/admin/addSpPersonalDetails', data: data);
    
    print("✅ API Response: ${response.statusCode}");
    return response.statusCode == 200 || response.statusCode == 201;
  } catch (e) {
    print("❌ API ERROR:"); 
    if (e is dio.DioException) {
      print("Status: ${e.response?.statusCode}");
      print("Data: ${e.response?.data}"); // This usually contains the specific validation error
    } else {
      print(e.toString());
    }
    return false; // Now you know why it returned false
  }
}
// UPLOAD PROVIDER PROFILE PIC
  Future<bool> uploadProviderProfilePic(String spId, dio.MultipartFile file) async {
    try {
      // API requires serviceProviderId as a Query Parameter and file as FormData
      final formData = dio.FormData.fromMap({
        "file": file, 
      });

      final response = await _dio.post(
        '/admin/uploadProviderProfilePic',
        queryParameters: {
          'serviceProviderId': spId,
        },
        data: formData,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("❌ Error uploading profile pic: $e");
      return false;
    }
  }

 Future<bool> addAddress(Map<String, dynamic> data) async {
  try {
    print("📤 Sending Address Data: $data"); // See exactly what you are sending
    
    final response = await _dio.post('/admin/addSpAddress', data: data);
    
    print("✅ Address API Success: ${response.statusCode}");
    return response.statusCode == 200 || response.statusCode == 201;
  } catch (e) {
    print("❌ Address API Failed:");
    if (e is dio.DioException) {
      print("Status: ${e.response?.statusCode}");
      print("Response Body: ${e.response?.data}"); // This tells you WHY it failed (e.g. invalid pincode)
    } else {
      print("Error: $e");
    }
    return false;
  }
}
// Inside ApiService

  Future<Map<String, dynamic>?> reverseGeocode(double lat, double lng, String apiKey) async {
    try {
      final response = await Dio().get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '$lat,$lng',
          'key': apiKey,
        },
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Reverse Geocode Error: $e');
      return null;
    }
  }

  Future<List<ServiceProviderLocation>> getServiceProviderLocationMap(String serviceProviderId) async {
    try {
      final response = await _dio.get(
        '/admin/getServiceProviderLocationMap',
        queryParameters: {
          "serviceProviderId": serviceProviderId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data == null) return [];

        // 1. Scenario: Standard Wrapper { "result": [...] }
        if (data is Map<String, dynamic> && data.containsKey('result')) {
          final resultList = data['result'];
          if (resultList is List) {
            return resultList.map((json) => ServiceProviderLocation.fromJson(json)).toList();
          }
        }

        // 2. Scenario: Direct List [...] (Just in case API format varies)
        if (data is List) {
          return data.map((json) => ServiceProviderLocation.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print("Error fetching mapped locations for provider: $e");
      return [];
    }
  }
  // Add this to your api_service.dart
Future<bool> mapProviderLocation(Map<String, dynamic> data) async {
  try {
    // Replace '/admin/providerLocationMap' with your actual full endpoint path if needed
    final response = await _dio.post('/admin/providerLocationMap', data: data);
    return response.statusCode == 200 || response.statusCode == 201;
  } catch (e) {
    print("Error mapping location: $e");
    return false; // Or rethrow based on your error handling preference
  }
}
// DELETE / TOGGLE PROVIDER LOCATION MAP
  Future<bool> deleteProviderLocationMap(String locationMapId, String spId, bool isActive) async {
    try {
      final response = await _dio.delete(
        '/admin/deleteProviderLocationMap',
        queryParameters: {
          'locationMapId': locationMapId,
          'serviceProviderId': spId,
          'isActive': isActive, // true = deactivate/delete, false = activate/restore
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Delete/Toggle Location Map Error: $e");
      return false;
    }
  }
Future<List<ServiceProviderService>> getServiceProviderServiceMap(String serviceProviderId) async {
    try {
      final response = await _dio.get(
        '/admin/getServiceProviderServiceMap',
        queryParameters: {
          "serviceProviderId": serviceProviderId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data == null) return [];

        // 1. Scenario: Standard Wrapper { "result": [...] }
        if (data is Map<String, dynamic> && data.containsKey('result')) {
          final resultList = data['result'];
          if (resultList is List) {
            return resultList.map((json) => ServiceProviderService.fromJson(json)).toList();
          }
        }
        
        // 2. Scenario: Direct List [...]
        if (data is List) {
          return data.map((json) => ServiceProviderService.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print("Error fetching mapped services for provider: $e");
      return [];
    }
  }
  // DELETE / TOGGLE PROVIDER SERVICE MAPPING
  Future<bool> deleteProviderServiceMap(String mappingId, String spId, bool isActive) async {
    try {
      final response = await _dio.delete(
        '/admin/deleteProviderServiceMap',
        queryParameters: {
          'serviceMapId': mappingId,
          'serviceProviderId': spId,
          'isActive': isActive, // true = deactivate/delete, false = activate/restore
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Delete/Toggle Service Map Error: $e");
      return false;
    }
  }

  Future<bool> mapProviderService(String spId, String catId, String srvId) async {
    try {
      await _dio.post('/admin/providerServiceMap', data: {
        "serviceProviderId": spId,
        "categoryId": catId,
        "serviceId": srvId
      });
      return true;
    } catch (e) { return false; }
  }

Future<bool> addBankDetails({
  required String spId,
  required String bankId,
  required String accountHolderName,
  required String accountNo,
  required String ifscCode,
  required String upiId,
  required bool isPanAvailable,
  required String panNo,
  required dio.FormData formData,
}) async {
  try {
    print("🚀 Sending Bank Details API");

    final response = await _dio.post(
      '/admin/addBankDetails',
      data: formData,
      queryParameters: {
        "spId": spId,
        "bankId": bankId,
        "accountHolderName": accountHolderName,
        "accountNo": accountNo,
        "ifscCode": ifscCode,
        "upiId": upiId,
        "isPanAvailable": isPanAvailable,
        "panNo": panNo,
      },
      options: Options(
        contentType: 'multipart/form-data', // MUST be multipart
      ),
    );

    print("✅ Status: ${response.statusCode}");
    print("✅ Response: ${response.data}");

    return response.statusCode == 200 || response.statusCode == 201;
  } catch (e) {
    if (e is dio.DioException) {
      print("❌ API FAILED");
      print("❌ URL: ${e.requestOptions.uri}");
      print("❌ Status: ${e.response?.statusCode}");
      print("❌ Response: ${e.response?.data}");
    }
    return false;
  }
}

Future<Map<String, dynamic>?> getProviderBankDetails(String spId) async {
  try {
    final response = await _dio.get(
      '/admin/getServiceProviderBankDetails',
      queryParameters: {
        'serviceProviderId': spId,
      },
    );

    if (response.statusCode == 200 && response.data != null) {
      return response.data;
    }
  } catch (e) {
    print("❌ Failed to fetch provider bank details: $e");
  }
  return null;
}


  Future<bool> addSpDocument(FormData formData) async {
    try {
      await _dio.post('/admin/addSpDocument', data: formData);
      return true;
    } catch (e) { return false; }
  }

  // 1. Fetch All Document Types
Future<List<DocumentTypeModel>> getDocumentTypes() async {
  try {
    final response = await _dio.get('/admin/getDocumentTypes');
    if (response.statusCode == 200 && response.data['result'] != null) {
      List<dynamic> list = response.data['result'];
      return list.map((e) => DocumentTypeModel.fromJson(e)).toList();
    }
    return [];
  } catch (e) {
    print("Error fetching doc types: $e");
    return [];
  }
}

// 2. Upload Single Document
Future<bool> uploadSpDocument({
    required String spId, 
    required String docTypeId, 
    required PlatformFile file 
  }) async {
    try {
      // 1. Prepare the File (Web vs Mobile)
      dio.MultipartFile multipartFile;

      if (kIsWeb) {
        // Web: Use Bytes
        multipartFile = dio.MultipartFile.fromBytes(
          file.bytes!, 
          filename: file.name
        );
      } else {
        // Mobile: Use Path
        multipartFile = await dio.MultipartFile.fromFile(
          file.path!,
          filename: file.name
        );
      }

      // 2. Body: File goes here (key: 'file')
      final formData = dio.FormData.fromMap({
        "file": multipartFile, 
      });

      // 3. URL: IDs go here
      final queryParams = {
        "documentTypeId": docTypeId,
        "spId": spId
      };

      print("📤 Uploading: $queryParams");

      final response = await _dio.post(
  '/admin/addSpDocument',
  data: formData,
  queryParameters: queryParams,
);

print("✅ Upload response: ${response.statusCode}");
print("📦 Response data: ${response.data}");

return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("❌ Upload Failed: $e");
      if (e is dio.DioException) {
         print("Server Response: ${e.response?.data}");
      }
      return false;
    }
  }
  Future<List<dynamic>> getServiceProviderDocuments(String spId) async {
  try {
    final response = await _dio.get(
      '/admin/getServiceProviderDocuments',
      queryParameters: {
        'serviceProviderId': spId,
      },
    );

    print("📄 Existing docs response: ${response.data}");
    return response.data['result'] ?? [];
  } catch (e) {
    print("❌ Fetch documents failed: $e");
    return [];
  }
}
Future<List<BankModel>> getAllBanks() async {
  try {
    // Replace with your actual Dio instance call
    final response = await _dio.get('/admin/getAllBank'); 
    
    if (response.statusCode == 200 && response.data['result'] != null) {
      final List<dynamic> list = response.data['result'];
      return list.map((e) => BankModel.fromJson(e)).toList();
    }
    return [];
  } catch (e) {
    print("Error fetching banks: $e");
    return [];
  }
}
// POST: Add Discount
  Future<bool> addServiceDiscount({
    required String serviceId,
    required double discountPercentage,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dio.post(
        '/admin/addServiceDiscount',
        data: {
          "serviceId": serviceId,
          "discountPercentage": discountPercentage,
          "startDate": startDate.toIso8601String(),
          "endDate": endDate.toIso8601String(),
        },
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("❌ Error adding discount: $e");
      return false;
    }
  }
Future<List<DiscountModel>> getAllDiscounts() async {
  try {
    // Replace with your actual endpoint path
    final response = await _dio.get('/admin/getAllServiceDiscount'); 
    
    if (response.statusCode == 200 && response.data['result'] != null) {
      List<dynamic> list = response.data['result'];
      return list.map((e) => DiscountModel.fromJson(e)).toList();
    }
    return [];
  } catch (e) {
    print("Error fetching discounts: $e");
    return [];
  }
}
Future<bool> deleteServiceDiscount(String id, bool isActive) async {
    try {
      final response = await _dio.delete(
        '/admin/deleteServiceDiscount',
        queryParameters: {
          'serviceDiscountId': id,
          'isActive': isActive, // Passing true based on your previous preference
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Delete Discount Error: $e");
      return false;
    }
  }
// POST: Update Document Type
  Future<bool> updateDocumentType(String id, String name) async {
    try {
      final response = await _dio.patch(
        '/admin/updateDocumentType',
        data: {
          "documentTypeId": id,
          "name": name,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("❌ Error updating document type: $e");
      return false;
    }
  }

  // POST: Update Bank
  Future<bool> updateBank(String id, String name, PlatformFile file) async {
    try {
      // 1. Prepare FormData (Multipart)
      // Handles both Web (bytes) and Mobile (path)
      dynamic fileEntry;
      if (kIsWeb) {
        fileEntry = MultipartFile.fromBytes(file.bytes!, filename: file.name);
      } else {
        fileEntry = await MultipartFile.fromFile(file.path!, filename: file.name);
      }

      FormData formData = FormData.fromMap({
        "bankId": id,
        "name": name,
        "file": fileEntry, 
      });

      final response = await _dio.patch('/admin/updateBank', data: formData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("❌ Error updating bank: $e");
      return false;
    }
  }
  Future<bool> deleteDocumentType(String id, bool isActive) async {
    try {
      final response = await _dio.delete(
        '/admin/deleteDocumentType',
        queryParameters: {
          "documentTypeId": id,
          "isActive": isActive,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Error deleting document type: $e");
      return false;
    }
  }

  // DELETE: Bank
  Future<bool> deleteBank(String id, bool isActive) async {
    try {
      final response = await _dio.delete(
        '/admin/deleteBank',
        queryParameters: {
          "bankId": id,
          "isActive": isActive,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Error deleting bank: $e");
      return false;
    }
  }
  // POST: Add Slider Banner
Future<bool> addSliderBanner({
  required String categoryId,
  required String serviceCategoryId,
  required String description,
  required Uint8List bannerBytes,
  String? bannerName,
}) async {
  try {
    // 1. Prepare FormData for the 'banner' file
    FormData formData = FormData.fromMap({
      "banner": MultipartFile.fromBytes(
        bannerBytes, 
        filename: bannerName ?? "banner.png"
      ),
    });

    // 2. Use flat query parameters to match the successful pattern of the update API
    await _dio.post(
      '/admin/addSliderBanner',
      queryParameters: {
        "categoryId": categoryId,
        "serviceCategoryId": serviceCategoryId,
        "description": description,
      },
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );
    
    return true;
  } catch (e) {
    if (e is DioException) {
      print("❌ Add Banner Error: ${e.response?.statusCode}");
      print(e.response?.data);
    } else {
      print("❌ Add Slider Banner failed: $e");
    }
    return false;
  }
}
// GET: Fetch all slider banners
Future<List<SliderBannerModel>> getAllSliderBanners() async {
  try {
    var response = await _dio.get('/admin/getAllSlideBanner');
    
    // Check if the data exists and is a list
    if (response.data != null && response.data['result'] is List) {
      final List<dynamic> rawList = response.data['result'];
      
      // MAP the raw JSON objects into your SliderBannerModel instances
      return rawList.map((json) => SliderBannerModel.fromJson(json)).toList();
    }
    
    return [];
  } catch (e) {
    // This will now catch mapping errors too if the JSON structure changes
    print("❌ Fetch Slider Banners failed: $e");
    return [];
  }
}
Future<bool> updateSliderBanner({
  required String bannerId,
  required String categoryId,
  required String serviceCategoryId,
  required String description,
  Uint8List? bannerBytes,
  String? bannerName,
}) async {
  try {
    // 1. Prepare the image as 'banner' (from your -F flag)
    FormData formData = FormData.fromMap({
      if (bannerBytes != null)
        "banner": MultipartFile.fromBytes(
          bannerBytes,
          filename: bannerName ?? "banner.png",
        ),
    });

    // 2. Use flat query parameters exactly like your successful curl
    final response = await _dio.patch(
      '/admin/updateSliderBanner',
      queryParameters: {
        "bannerId": bannerId,
        "categoryId": categoryId,
        "serviceCategoryId": serviceCategoryId,
        "description": description,
      },
      data: formData,
      options: Options(
        contentType: 'multipart/form-data', // Matches your curl -H
      ),
    );

    return response.statusCode == 200;
  } catch (e) {
    if (e is DioException) {
      print("❌ Update Failed: ${e.response?.statusCode}");
     // paintImage("Response Body: ${e.response?.data}");
    }
    return false;
  }
}
Future<bool> deleteSliderBanner({required String bannerId, required bool isActive}) async {
  try {
    final response = await _dio.delete(
      '/admin/deleteSlideBanner',
      queryParameters: {
        "bannerId": bannerId,
        "isActive": isActive, // Send true to make it false, and vice versa
      },
    );
    return response.statusCode == 200;
  } catch (e) {
    if (e is DioException) {
      debugPrint("❌ Delete Error: ${e.response?.statusCode} | ${e.response?.data}");
    }
    return false;
  }
}
Future<bool> addCoupon({
  required String categoryId, // Changed from List<String> serviceIdList
  required String couponType,
  required String couponCode,
  required String discountType,
  required String startDate,
  required String endDate,
  required double amount,
  required double minPurchaseAmount,
  required double discountPercentage,
  required int sameUserLimit,
}) async {
  try {
    final response = await _dio.post(
      '/admin/addCoupon',
      data: {
        "categoryId": categoryId, // Updated key
        "couponType": couponType,
        "couponCode": couponCode,
        "discountType": discountType,
        "startDate": startDate,
        "endDate": endDate,
        "amount": amount,
        "minPurchaseAmount": minPurchaseAmount,
        "discountPercentage": discountPercentage,
        "sameUserLimit": sameUserLimit
      },
      options: Options(
        contentType: Headers.jsonContentType,
      ),
    );
    return response.statusCode == 200;
  } catch (e) {
    if (e is DioException) {
      print("❌ Server Response: ${e.response?.data}");
    }
    return false;
  }
}
Future<List<CouponModel>> getAllCoupons() async {
  try {
    final response = await _dio.get('/admin/getAllCoupon');
    if (response.data != null && response.data['result'] is List) {
      final List<dynamic> rawList = response.data['result'];
      return rawList.map((json) => CouponModel.fromJson(json)).toList();
    }
    return [];
  } catch (e) {
    debugPrint("❌ Fetch Coupons Error: $e");
    return [];
  }
}
Future<bool> updateCouponStatus({
  required String couponId,
  required bool isActive,
}) async {
  try {
    // 1. MUST use .delete as per your curl
    // 2. Query parameters remain the same
    final response = await _dio.delete(
      '/admin/deleteCoupon', 
      queryParameters: {
        "couponId": couponId,
        "isActive": isActive, 
      },
    );
    
    // Check for 200 OK or 204 No Content depending on your API
    return response.statusCode == 200 || response.statusCode == 204;
  } catch (e) {
    if (e is DioException) {
      debugPrint("❌ API Error: ${e.response?.data}");
    }
    return false;
  }
}
Future<List<RefundBank>> getCustomerRefundBanks(String customerId) async {
  try {
    final response = await _dio.get(
      '/admin/getRefundBanks',
      queryParameters: {'customerId': customerId},
    );
    
    if (response.statusCode == 200) {
      final List data = response.data['result'];
      return data.map((json) => RefundBank.fromJson(json)).toList();
    }
    return [];
  } catch (e) {
    rethrow;
  }
}
Future<List<BookingReview>> getBookingRatings(String customerId) async {
  try {
    final response = await _dio.get(
      '/admin/getBookingRatingByCustomer',
      queryParameters: {'customerId': customerId},
    );
    
    if (response.statusCode == 200) {
      final List data = response.data['result'] ?? [];
      return data.map((json) => BookingReview.fromJson(json)).toList();
    }
    return [];
  } catch (e) {
    debugPrint("❌ Error fetching reviews: $e");
    return [];
  }
}

Future<List<ProviderRating>> getProviderRatingByCustomer(String customerId) async {
  try {
    final response = await _dio.get(
      '/admin/getProviderRatingByCustomer',
      queryParameters: {'customerId': customerId},
    );
    
    if (response.statusCode == 200) {
      final List data = response.data['result'] ?? [];
      return data.map((json) => ProviderRating.fromJson(json)).toList();
    }
    return [];
  } catch (e) {
    debugPrint("❌ Error fetching provider ratings: $e");
    return [];
  }
}
// Inside your ApiService class
Future<Response> deleteServiceProvider(String providerId, bool isActive) async {
  try {
    return await _dio.delete(
      '/admin/deleteServiceProvider',
      queryParameters: {
        "providerId": providerId,
        "isActive": isActive, // Sends true for Inactive, false for Active
      },
    );
  } catch (e) {
    rethrow;
  }
}
// Inside your ApiService class
Future<Response> getHolidays(String providerId) async {
  try {
    return await _dio.get(
      '/admin/getHolidays',
      queryParameters: {"providerId": providerId},
    );
  } catch (e) {
    rethrow;
  }
}
Future<Response> updateCustomerStatus({
  required String customerId, 
  required bool isActive,
}) async {
  try {
    return await _dio.delete(
      '/admin/deleteCustomer',
      queryParameters: {
        "customerId": customerId,
        "isActive": isActive, // Sends true/false as expected by the API
      },
    );
  } catch (e) {
    rethrow;
  }
}
Future<Response> getWithdrawRequests() async {
  try {
    return await _dio.get('/admin/getProviderSettlement');
  } catch (e) {
    rethrow;
  }
}

Future<Response> updateWithdrawStatus(String id, String status) async {
  try {
    return await _dio.patch(
      '/admin/updateWithdrawStatus',
      queryParameters: {
        "withdrawId": id,
        "status": status,
      },
    );
  } catch (e) {
    rethrow;
  }
}

// ---------------------------------------------------------------------------
// SERVICE TIMING
// ---------------------------------------------------------------------------

Future<List<ServiceTimingModel>> getServiceTimings() async {
  try {
    final response = await _dio.get('/admin/getAllServiceTiming');
    if (response.data['result'] is List) {
      return (response.data['result'] as List)
          .map((e) => ServiceTimingModel.fromJson(e))
          .toList();
    }
    return [];
  } catch (e) {
    print("❌ getServiceTimings Error: $e");
    return [];
  }
}

Future<bool> addServiceTiming(String categoryId, String startTime, String endTime) async {
  try {
    final response = await _dio.post(
      '/admin/addServiceTiming',
      data: {
        "categoryId": categoryId,
        "startTime": startTime,
        "endTime": endTime,
      },
    );
    return response.statusCode == 200 || response.statusCode == 201;
  } catch (e) {
    print("❌ addServiceTiming Error: $e");
    return false;
  }
}

Future<bool> updateServiceTiming(String serviceTimingId, String startTime, String endTime) async {
  try {
    final response = await _dio.patch(
      '/admin/updateServiceTiming',
      data: {
        "serviceTimingId": serviceTimingId,
        "startTime": startTime,
        "endTime": endTime,
      },
    );
    return response.statusCode == 200 || response.statusCode == 201;
  } catch (e) {
    print("❌ updateServiceTiming Error: $e");
    return false;
  }
}
Future<Response> addWithdrawRequest(Map<String, dynamic> data) async {
  try {
    // Replace with your actual base URL logic if not already handled in Dio interceptors
    final response = await _dio.post(
      '/admin/addWithdrawRequest', 
      data: data,
    );
    return response;
  } catch (e) {
    rethrow;
  }
}

}