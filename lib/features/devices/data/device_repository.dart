import 'package:dio/dio.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import '../models/device_model.dart';

class DeviceRepository {
  final Dio _dio;

  DeviceRepository(this._dio);

  Future<DeviceDto> registerDevice(RegisterDeviceRequest request) async {
    final response = await _dio.post(
      ApiEndpoints.devices,
      data: request.toJson(),
    );
    final data = response.data['data'] ?? response.data;
    return DeviceDto.fromJson(data as Map<String, dynamic>);
  }

  Future<DeviceDto> deactivateDevice(String deviceId) async {
    final response = await _dio.patch(ApiEndpoints.deviceDeactivate(deviceId));
    final data = response.data['data'] ?? response.data;
    return DeviceDto.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteDevice(String deviceId) async {
    await _dio.delete(ApiEndpoints.deviceById(deviceId));
  }
}
