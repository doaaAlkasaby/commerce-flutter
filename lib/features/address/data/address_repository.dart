import 'package:dio/dio.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import 'package:ecommerce/core/network/api_response.dart';
import '../models/address_model.dart';

class AddressRepository {
  final Dio _dio;

  AddressRepository(this._dio);

  Future<List<AddressModel>> getAddresses() async {
    try {
      final response = await _dio.get(ApiEndpoints.addresses);
      final apiResponse = ApiListResponse.fromJson(
        response.data,
        (json) {
          final item = json as Map<String, dynamic>;
          return AddressModel(
            id: item['id']?.toString() ?? '',
            title: item['title']?.toString() ?? 'HOME',
            fullName: item['fullName']?.toString() ?? '',
            streetAddress: item['streetAddress']?.toString() ?? '',
            city: item['city']?.toString() ?? '',
            postalCode: item['postalCode']?.toString() ?? '',
            phoneNumber: item['phoneNumber']?.toString() ?? '',
            isDefault: item['isDefault'] ?? false,
          );
        },
      );
      if (apiResponse.success && apiResponse.data.isNotEmpty) {
        return apiResponse.data;
      }
    } catch (_) {}

    return [
      const AddressModel(
        id: '1',
        title: 'HOME',
        fullName: 'Amelia Wood',
        streetAddress: '12 Rosewood Lane, Apt 4B',
        city: 'Singapore',
        postalCode: '238461',
        phoneNumber: '+65 8123 4567',
        isDefault: true,
      ),
      const AddressModel(
        id: '2',
        title: 'WORK',
        fullName: 'Amelia Wood',
        streetAddress: '8 Marina Boulevard, Level 12',
        city: 'Singapore',
        postalCode: '018981',
        phoneNumber: '+65 8123 4567',
        isDefault: false,
      ),
    ];
  }

  Future<void> addAddress(AddressModel address) async {
    await _dio.post(ApiEndpoints.addresses, data: {
      'title': address.title,
      'fullName': address.fullName,
      'streetAddress': address.streetAddress,
      'city': address.city,
      'postalCode': address.postalCode,
      'phoneNumber': address.phoneNumber,
      'isDefault': address.isDefault,
    });
  }

  Future<void> updateAddress(AddressModel address) async {
    await _dio.patch(ApiEndpoints.addressById(address.id), data: {
      'title': address.title,
      'fullName': address.fullName,
      'streetAddress': address.streetAddress,
      'city': address.city,
      'postalCode': address.postalCode,
      'phoneNumber': address.phoneNumber,
      'isDefault': address.isDefault,
    });
  }

  Future<void> deleteAddress(String id) async {
    await _dio.delete(ApiEndpoints.addressById(id));
  }

  Future<void> setDefaultShipping(String id) async {
    await _dio.post(ApiEndpoints.addressDefaultShipping(id));
  }
}
