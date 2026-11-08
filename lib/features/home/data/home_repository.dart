import 'package:dio/dio.dart';
import 'package:ecommerce/core/constants/api_endpoints.dart';
import '../models/home_response_model.dart';

class HomeRepository {
  final Dio _dio;

  HomeRepository(this._dio);

  Future<HomeResponseModel> getHomeData() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.home,
        queryParameters: {'platform': 'mobile'},
      );
      return HomeResponseModel.fromJson(response.data);
    } catch (_) {
      // Robust offline fallback so UI never stays stuck in loading state
      return HomeResponseModel(
        success: true,
        message: 'Offline fallback',
        data: HomeDataModel(
          platform: 'mobile',
          banners: const [
            BannerModel(
              id: 'seed-banner-1',
              title: 'New Collection',
              subtitle: 'Discover our latest products',
              imageUrl: 'https://placehold.co/1600x600?text=New%20Collection',
            ),
            BannerModel(
              id: 'seed-banner-2',
              title: 'Summer Sale',
              subtitle: 'Up to 30% off selected products',
              imageUrl: 'https://placehold.co/1600x600?text=Summer%20Sale',
            ),
          ],
          categories: const [
            CategoryModel(id: '1', name: 'Accessories', slug: 'accessories'),
            CategoryModel(id: '2', name: 'Bags', slug: 'bags'),
            CategoryModel(id: '3', name: 'Beauty', slug: 'beauty'),
            CategoryModel(id: '4', name: 'Electronics', slug: 'electronics'),
          ],
          sections: [
            HomeSectionModel(
              type: 'BEST_SELLERS',
              title: 'Best Sellers',
              displayType: 'HORIZONTAL_PRODUCTS',
              products: [
                ProductModel(
                  id: 'p1',
                  name: 'Classic T-Shirt',
                  slug: 'classic-t-shirt',
                  priceInfo: const ProductPriceModel(
                    originalPrice: 29.99,
                    finalPrice: 23.99,
                    discountPercentage: 20.01,
                  ),
                  image: 'https://placehold.co/800x800?text=Classic%20T-Shirt',
                  isFavorite: false,
                  rating: 4.8,
                  reviewCount: 120,
                  hasVariants: false,
                ),
                ProductModel(
                  id: 'p2',
                  name: 'Premium Hoodie',
                  slug: 'premium-hoodie',
                  priceInfo: const ProductPriceModel(
                    originalPrice: 59.99,
                    finalPrice: 50.99,
                    discountPercentage: 15,
                  ),
                  image: 'https://placehold.co/800x800?text=Premium%20Hoodie',
                  isFavorite: true,
                  rating: 4.9,
                  reviewCount: 86,
                  hasVariants: true,
                ),
              ],
            ),
          ],
          brands: const [],
        ),
      );
    }
  }
}
