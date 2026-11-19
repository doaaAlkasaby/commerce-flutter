import 'package:dio/dio.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import '../models/address_model.dart';
import '../models/country_model.dart';

class AddressRepository {
  final Dio _dio;

  AddressRepository(this._dio);

  Future<List<AddressModel>> getAddresses() async {
    final response = await _dio.get(ApiEndpoints.addresses);
    final rawData = response.data['data'];
    final List list = rawData is List ? rawData : [];
    return list
        .map((item) => AddressModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<CountryModel>> getCountries() async {
    final response = await _dio.get(ApiEndpoints.countries);
    final rawData = response.data['data'];
    final List list = rawData is List ? rawData : [];
    return list
        .map((item) => CountryModel.fromJson(item as Map<String, dynamic>))
        .where((country) => country.isValidIso)
        .toList();
  }

  Future<AddressModel> addAddress(AddressModel address) async {
    final response = await _dio.post(
      ApiEndpoints.addresses,
      data: address.toJson(),
    );
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    return AddressModel.fromJson(data);
  }

  Future<AddressModel> updateAddress(AddressModel address) async {
    final response = await _dio.patch(
      ApiEndpoints.addressById(address.id),
      data: address.toJson(),
    );
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    return AddressModel.fromJson(data);
  }

  Future<void> deleteAddress(String id) async {
    await _dio.delete(ApiEndpoints.addressById(id));
  }

  Future<void> setDefaultShipping(String id) async {
    await _dio.post(ApiEndpoints.addressDefaultShipping(id));
  }

  Future<void> setDefaultBilling(String id) async {
    await _dio.post(ApiEndpoints.addressDefaultBilling(id));
  }
}
