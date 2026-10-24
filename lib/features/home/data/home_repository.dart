import 'package:dio/dio.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import '../models/home_response_model.dart';

class HomeRepository {
  final Dio _dio;

  HomeRepository(this._dio);

  Future<HomeResponseModel> getHomeData() async {
    final response = await _dio.get(ApiEndpoints.home, queryParameters: {'platform': 'mobile'});
    return HomeResponseModel.fromJson(response.data);
  }
}
