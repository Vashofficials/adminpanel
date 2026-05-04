import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'dart:js_util' as js_util;
import '../models/location_model.dart';
import '../widgets/custom_center_dialog.dart';
import '../models/service_provider_location.dart';

class LocationController extends GetxController {
  final ApiService _apiService = ApiService();
  
  var isLoading = false.obs;
  var isEditing = false.obs;
  String? _editingLocationId; // The database ID (primary key)
  String? _editingAreaId;
  var locationList = <LocationModel>[].obs;
  var filteredLocationList = <LocationModel>[].obs;

  // --- Form Inputs ---
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final areaNameCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final pinCodeCtrl = TextEditingController();
  
  // --- Search Controllers ---
  final searchCtrl = TextEditingController();
  final listSearchCtrl = TextEditingController();

  // --- Map & Polygon Logic ---
  var polygonPoints = <LatLng>[].obs;
  var mapMarkers = <Marker>{}.obs;
  var isMapFullScreen = false.obs; // NEW
  GoogleMapController? _mapController;

  @override
  void onInit() {
    super.onInit();
    fetchLocations();
  }

  @override
  void onClose() {
    areaNameCtrl.dispose();
    cityCtrl.dispose();
    stateCtrl.dispose();
    pinCodeCtrl.dispose();
    searchCtrl.dispose();
    listSearchCtrl.dispose();
    super.onClose();
  }

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void toggleFullScreen() {
    isMapFullScreen.value = !isMapFullScreen.value;
  }

  void fetchLocations() async {
    isLoading(true);
    locationList.value = await _apiService.getLocations();
    filteredLocationList.value = locationList;
    isLoading(false);
  }
// 1. Separate List just for the dropdown
  var providerLocationList = <ServiceProviderLocation>[].obs;
  var isProviderMapLoading = false.obs;

  // 2. Separate Fetch Method
Future<void> fetchServiceProviderMap(String serviceProviderId) async {
    if (serviceProviderId.isEmpty) return;

    isProviderMapLoading(true);
    providerLocationList.clear(); // Clear old data first

    try {
      // API Service now handles the List/Map parsing logic
      var data = await _apiService.getServiceProviderLocationMap(serviceProviderId);
      
      providerLocationList.value = data;
      
      if (data.isNotEmpty) {
        print("✅ Fetched ${data.length} mapped locations. First area: ${data.first.areaName}");
      } else {
        print("ℹ️ No mapped locations found for Provider ID: $serviceProviderId");
      }
    } catch (e) {
      print("❌ Error fetching provider map: $e");
    } finally {
      isProviderMapLoading(false);
    }
  }

  // Filter locations based on search text
  void filterLocations(String query) {
    if (query.isEmpty) {
      filteredLocationList.value = locationList;
    } else {
      filteredLocationList.value = locationList.where((loc) {
        return loc.areaName.toLowerCase().contains(query.toLowerCase()) ||
               (loc.city?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
               (loc.state?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
               (loc.postCode?.toLowerCase().contains(query.toLowerCase()) ?? false);
      }).toList();
    }
  }

  // Caching for accurate search
  final Map<String, List<LatLng>> _searchCache = {};
  static const String _mapsApiKey = 'AIzaSyAJsorrGKIgn2WoWP22VDCF1Utr8-Y1eqI';

  // Dynamic search using Google Maps Geocoding API from index.html
  Future<void> searchAndMoveCamera(String placeName) async {
    if (placeName.isEmpty) return;

    try {
      // Call the geocodeAddress function from index.html
      final result = await _callJavaScriptGeocoding(placeName);
      
      if (result != null && result['lat'] != null && result['lng'] != null) {
        final lat = (result['lat'] as num).toDouble();
        final lng = (result['lng'] as num).toDouble();
        
        final neLat = result['northeastLat'] != null ? (result['northeastLat'] as num).toDouble() : null;
        final neLng = result['northeastLng'] != null ? (result['northeastLng'] as num).toDouble() : null;
        final swLat = result['southwestLat'] != null ? (result['southwestLat'] as num).toDouble() : null;
        final swLng = result['southwestLng'] != null ? (result['southwestLng'] as num).toDouble() : null;
        
        // Auto-fill form fields
        areaNameCtrl.text = placeName;
        String? targetLocality;
        String? targetPostalCode;
        if (result['city'] != null && result['city'].toString().isNotEmpty) {
          cityCtrl.text = result['city'];
          targetLocality = result['city'];
        }
        if (result['state'] != null && result['state'].toString().isNotEmpty) {
          stateCtrl.text = result['state'];
        }
        if (result['postalCode'] != null && result['postalCode'].toString().isNotEmpty) {
          pinCodeCtrl.text = result['postalCode'];
          targetPostalCode = result['postalCode'];
        } else {
          // If query looks like a pincode (6 digits), fill it
          final RegExp pinRegExp = RegExp(r'^\d{6}$');
          if (pinRegExp.hasMatch(placeName)) {
             pinCodeCtrl.text = placeName;
             targetPostalCode = placeName;
          }
        }
        
        // Generate refined polygon
        if (neLat != null && neLng != null && swLat != null && swLng != null) {
          clearPolygon();
          Get.snackbar("Processing...", "Generating highly accurate bounds for area.", duration: const Duration(seconds: 1));
          
          String cacheKey = '${neLat}_${neLng}_${swLat}_${swLng}_$placeName';
          List<LatLng> finalPoints = [];

          if (_searchCache.containsKey(cacheKey)) {
             finalPoints = _searchCache[cacheKey]!;
          } else {
             // 1. Grid Subdivision (3x3 grid = 9 points)
             List<LatLng> gridPoints = [];
             for (int i = 0; i < 3; i++) {
                double gLat = swLat + (neLat - swLat) * (i / 2);
                for (int j = 0; j < 3; j++) {
                   double gLng = swLng + (neLng - swLng) * (j / 2);
                   gridPoints.add(LatLng(gLat, gLng));
                }
             }

             // 2. Reverse Geocode Filter
             List<LatLng> validPoints = [];
             for (LatLng pt in gridPoints) {
                var rgRes = await _apiService.reverseGeocode(pt.latitude, pt.longitude, _mapsApiKey);
                if (rgRes != null && rgRes['results'] != null && (rgRes['results'] as List).isNotEmpty) {
                   bool matchFound = false;
                   for (var component in rgRes['results'][0]['address_components']) {
                      List types = component['types'];
                      if (targetLocality != null && types.contains('locality') && component['long_name'] == targetLocality) {
                         matchFound = true; break;
                      }
                      if (targetPostalCode != null && types.contains('postal_code') && component['long_name'] == targetPostalCode) {
                         matchFound = true; break;
                      }
                   }
                   if (matchFound) {
                      validPoints.add(pt);
                   }
                }
             }

             // 3. Convex Hull Generation
             if (validPoints.length >= 3) {
                 finalPoints = _getConvexHull(validPoints);
                 // close it
                 if(finalPoints.isNotEmpty && finalPoints.first != finalPoints.last) {
                    finalPoints.add(finalPoints.first);
                 }
             } else {
                 // Fallback to basic rectangle
                 finalPoints = [
                    LatLng(swLat, swLng),
                    LatLng(swLat, neLng),
                    LatLng(neLat, neLng),
                    LatLng(neLat, swLng),
                    LatLng(swLat, swLng)
                 ];
             }
             _searchCache[cacheKey] = finalPoints;
          }

          // Render
          for(LatLng p in finalPoints) {
             addPolygonPoint(p);
          }

          _mapController?.animateCamera(
             CameraUpdate.newLatLngBounds(
                LatLngBounds(
                   southwest: LatLng(swLat, swLng),
                   northeast: LatLng(neLat, neLng),
                ),
                50.0
             )
          );
        } else {
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(lat, lng),
                zoom: 14,
              ),
            ),
          );
        }
        
        Get.snackbar(
          "Location Found",
          "Generated accurate polygon and moved to $placeName",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          "Not Found",
          "Could not find location: $placeName",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to search location: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Convex Hull implementation (Monotone Chain)
  List<LatLng> _getConvexHull(List<LatLng> points) {
    if (points.length < 3) return points;

    List<LatLng> sorted = List.from(points);
    sorted.sort((a, b) {
      if (a.latitude == b.latitude) return a.longitude.compareTo(b.longitude);
      return a.latitude.compareTo(b.latitude);
    });

    double cross(LatLng o, LatLng a, LatLng b) {
      return (a.latitude - o.latitude) * (b.longitude - o.longitude) -
             (a.longitude - o.longitude) * (b.latitude - o.latitude);
    }

    List<LatLng> lower = [];
    for (LatLng p in sorted) {
      while (lower.length >= 2 && cross(lower[lower.length - 2], lower.last, p) <= 0) {
        lower.removeLast();
      }
      lower.add(p);
    }

    List<LatLng> upper = [];
    for (LatLng p in sorted.reversed) {
      while (upper.length >= 2 && cross(upper[upper.length - 2], upper.last, p) <= 0) {
        upper.removeLast();
      }
      upper.add(p);
    }

    upper.removeLast();
    lower.removeLast();
    return lower + upper;
  }

 Future<Map<String, dynamic>?> _callJavaScriptGeocoding(String address) async {
    try {
      // Small delay to ensure JS is ready
      await Future.delayed(const Duration(milliseconds: 500));

      // 1. Use js_util to access the global scope (window)
      if (!js_util.hasProperty(js_util.globalThis, 'geocodeAddress')) {
        print('JS function geocodeAddress not found');
        return null;
      }

      // 2. Call the function using js_util.callMethod
      final promise = js_util.callMethod(js_util.globalThis, 'geocodeAddress', [address]);

      // 3. Convert the raw Promise to a Dart Future
      final result = await js_util.promiseToFuture(promise);

      // 4. Parse JSON string
      if (result != null && result is String) {
        return jsonDecode(result) as Map<String, dynamic>;
      } else if (result != null) {
        // Fallback
        return {
          'lat': js_util.getProperty(result, 'lat'),
          'lng': js_util.getProperty(result, 'lng'),
        };
      }
      return null;
    } catch (e) {
      print('JS Geocoding error: $e');
      return null;
    }
  }
  // Map zoom controls
  void zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  // Called when user taps the map
  void addPolygonPoint(LatLng point) {
    polygonPoints.add(point);
    mapMarkers.add(
      Marker(
        markerId: MarkerId(point.toString()),
        position: point,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );
  }

  void undoLastPoint() {
    if (polygonPoints.isNotEmpty) {
      final lastPoint = polygonPoints.removeLast();
      mapMarkers.removeWhere((m) => m.position == lastPoint);
    }
  }

  void clearPolygon() {
    polygonPoints.clear();
    mapMarkers.clear();
  }

  // Convert polygon points to WKT (Well-Known Text) format
  String _convertToWKT(List<LatLng> points) {
    if (points.isEmpty) return '';
    
    // Ensure polygon is closed (first point = last point)
    List<LatLng> closedPoints = List.from(points);
    if (closedPoints.first.latitude != closedPoints.last.latitude ||
        closedPoints.first.longitude != closedPoints.last.longitude) {
      closedPoints.add(closedPoints.first);
    }
    
    // Format: POLYGON((lng lat, lng lat, ...))
    String coordinates = closedPoints
        .map((point) => '${point.longitude} ${point.latitude}')
        .join(',');
    
    return 'POLYGON(($coordinates))';
  }

  // Generate JSON payload showing all fields (null if not filled)
  String generateJsonPayload() {
    String? wktPolygon;
    
    if (polygonPoints.isNotEmpty) {
      wktPolygon = _convertToWKT(polygonPoints);
    }

    final payload = {
      "area_id": areaNameCtrl.text.isNotEmpty ? const Uuid().v4() : null,
      "area_name": areaNameCtrl.text.isNotEmpty ? areaNameCtrl.text : null,
      "city": cityCtrl.text.isNotEmpty ? cityCtrl.text : null,
      "state": stateCtrl.text.isNotEmpty ? stateCtrl.text : null,
      "post_code": pinCodeCtrl.text.isNotEmpty ? pinCodeCtrl.text : null,
      "geo_boundary": wktPolygon,
      "boundary_type": wktPolygon != null ? "POLYGON" : null,
    };

    // Pretty print JSON with indentation
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(payload);
  }

  // Copy payload to clipboard
  void copyPayloadToClipboard() {
    final payload = generateJsonPayload();
    Clipboard.setData(ClipboardData(text: payload));
  }

void prepareEdit(LocationModel loc) {
    // A. Populate Text Fields
    areaNameCtrl.text = loc.areaName;
    cityCtrl.text = loc.city ?? "";
    stateCtrl.text = loc.state ?? "";
    pinCodeCtrl.text = loc.postCode ?? "";

    // B. Set Edit Flags
    isEditing.value = true;
    _editingLocationId = loc.id;
    _editingAreaId = loc.areaId;

    // C. Draw Polygon on Map (Parse WKT)
    clearPolygon();
    if (loc.geoBoundary != null && loc.geoBoundary!.isNotEmpty) {
      final points = _parseWKT(loc.geoBoundary!);
      for (var p in points) {
        addPolygonPoint(p);
      }
      
      // Move camera to the first point of the polygon
      if (points.isNotEmpty && _mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(points.first, 14));
      }
    }
    
    // Scroll to top (optional, depending on your UI structure)
    // scrollController.animateTo(...) 
  }

  void cancelEdit() {
    isEditing.value = false;
    _editingLocationId = null;
    _editingAreaId = null;
    _clearForm();
  }

  // --------------------------------------------------------
  // 2. HELPER: Parse WKT (String -> List<LatLng>)
  // Input: "POLYGON((80.9 26.8, 81.0 26.9, ...))"
  // --------------------------------------------------------
  List<LatLng> _parseWKT(String wkt) {
    try {
      // Remove "POLYGON((" and "))"
      final content = wkt.replaceAll("POLYGON((", "").replaceAll("))", "");
      final pairs = content.split(",");
      
      List<LatLng> points = [];
      for (var pair in pairs) {
        final coords = pair.trim().split(" ");
        if (coords.length >= 2) {
          // WKT is usually "LONGITUDE LATITUDE"
          final double lng = double.parse(coords[0]);
          final double lat = double.parse(coords[1]);
          points.add(LatLng(lat, lng));
        }
      }
      // Remove the last point if it duplicates the first (closed loop)
      if (points.length > 1 && points.first == points.last) {
        points.removeLast();
      }
      return points;
    } catch (e) {
      print("⚠️ Error parsing WKT: $e");
      return [];
    }
  }

  // --------------------------------------------------------
  // 3. UPDATED SUBMIT (Handles Add AND Update)
  // --------------------------------------------------------
  Future<void> submitLocation() async {
    if (!formKey.currentState!.validate()) return;

    if (polygonPoints.length < 3) {
      CustomCenterDialog.show(
          Get.context!,
          title: "Incomplete Area",
          message: "Please draw a valid area on the map (at least 3 points).",
          type: DialogType.info, 
        );
      return;
    }

    isLoading(true);
    String wktPolygon = _convertToWKT(polygonPoints);

    bool success;

    if (isEditing.value) {
      // --- UPDATE LOGIC ---
      final updatePayload = {
        "locationId": _editingLocationId,
        "areaId": _editingAreaId,
        "areaName": areaNameCtrl.text,
        "geoPolygonType": "POLYGON",
        "geoBoundary": wktPolygon,
        "city": cityCtrl.text,
        "state": stateCtrl.text,
        "postCode": pinCodeCtrl.text
      };
      success = await _apiService.updateLocation(updatePayload);
    } else {
      // --- ADD LOGIC (Existing) ---
      final newLoc = LocationModel(
        areaId: const Uuid().v4(),
        areaName: areaNameCtrl.text,
        city: cityCtrl.text,
        state: stateCtrl.text,
        postCode: pinCodeCtrl.text,
        geoBoundary: wktPolygon,
      );
      success = await _apiService.addLocation(newLoc);
    }

    isLoading(false);

    if (success) {
   CustomCenterDialog.show(
          Get.context!,
          title: "Success",
          message: isEditing.value ? "Location Updated Successfully" : "Location Added Successfully",
          type: DialogType.success,
        );
      fetchLocations();
      
      if(isEditing.value) cancelEdit(); // Exit edit mode
      else _clearForm();
      
    } else {
      CustomCenterDialog.show(
          Get.context!,
          title: "Error",
          message: "Operation failed. Please try again.",
          type: DialogType.error,
        );
    }
  }

  void _clearForm() {
    areaNameCtrl.clear();
    cityCtrl.clear();
    stateCtrl.clear();
    pinCodeCtrl.clear();
    clearPolygon();
  }
  Future<void> deleteLocation(String locationId) async {
    // 1. Show Confirmation Dialog
    if (Get.context != null) {
      CustomCenterDialog.show(
        Get.context!,
        title: "Delete Location",
        message: "Are you sure you want to delete this location? This action cannot be undone.",
        type: DialogType.info, // Or warning/error style if you have one
        onConfirm: () async {
          // Close the confirmation dialog
          
          _performDelete(locationId);
        },
      );
    }
  }

  Future<void> _performDelete(String locationId) async {
    isLoading(true);
    
    // NOTE: Passing 'false' for isActive as this is a delete action
    // (Adjust this if your API logic requires 'true' to confirm deletion)
    bool success = await _apiService.deleteLocation(locationId, true);

    isLoading(false);

    if (success) {
      if (Get.context != null) {
        CustomCenterDialog.show(
          Get.context!,
          title: "Success",
          message: "Location deleted successfully",
          type: DialogType.success,
        );
      }
      fetchLocations(); // Refresh list
    } else {
      if (Get.context != null) {
        CustomCenterDialog.show(
          Get.context!,
          title: "Error",
          message: "Failed to delete location",
          type: DialogType.error,
        );
      }
    }
  }
}