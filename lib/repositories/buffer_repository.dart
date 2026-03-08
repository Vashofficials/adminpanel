import '../services/api_service.dart';
import '../models/buffer_time_model.dart';

class BufferRepository {
  final ApiService _api = ApiService();
  // Fetch List
  Future<List<BufferTimeModel>> getBufferList() async {
    return await _api.getAllBufferTimes();
  }

  Future<bool> saveBufferSettings({
    required int distanceFrom,
    required int distanceTo,
    required int bufferBefore,
    required int bufferAfter,
  }) async {
    try {
      // 1. Prepare the JSON body
      final Map<String, dynamic> body = {
        "distanceFrom": distanceFrom,
        "distanceTo": distanceTo,
        "bufferBefore": bufferBefore,
        "bufferAfter": bufferAfter,
      };

      // 2. Call the API Service
      final response = await _api.addBufferTime(body);

      // 3. Check for success 
      // (Adjust logic based on whether your API returns a specific status code or boolean)
      if (response != null) {
        return true;
      }
      return false;
      
    } catch (e) {
      print("Buffer Repo Error: $e");
      return false; // Return false so UI knows it failed
    }
  }
  Future<bool> updateBufferSettings({
    required String bufferTimeId,
    required int distanceFrom,
    required int distanceTo,
    required int bufferBefore,
    required int bufferAfter,
  }) async {
    try {
      final Map<String, dynamic> body = {
        "bufferTimeId": bufferTimeId,
        "distanceFrom": distanceFrom,
        "distanceTo": distanceTo,
        "bufferBefore": bufferBefore,
        "bufferAfter": bufferAfter,
      };

      // Ensure your ApiService has a patch method or specific update function
      // e.g., await _dio.patch('/admin/updateBufferTime', data: body);
      final response = await _api.updateBufferTime(body); 
      
      return response != null;
    } catch (e) {
      print("Buffer Repo Error (Update): $e");
      return false;
    }
  }
  // DELETE
  Future<bool> deleteBufferSettings(String id) async {
    // Passing isActive = true as default for deletion action
    return await _api.deleteBufferTime(id, true);
  }
  Future<bool> toggleStatus(String id, bool newStatus) async {
  // Logic: 
  // To Activate (newStatus = true) -> Pass 'false' to API
  // To Deactivate (newStatus = false) -> Pass 'true' to API
  bool apiParam = !newStatus; 
  
  return await _api.deleteBufferTime(id, apiParam);
}
}

