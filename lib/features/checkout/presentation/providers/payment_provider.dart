import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/features/auth/presentation/providers/user_provider.dart';
import 'package:ecommerce/features/checkout/data/payment_repository.dart';
import 'package:ecommerce/features/checkout/models/payment_models.dart';
import 'package:ecommerce/features/orders/presentation/providers/orders_provider.dart';

part 'payment_provider.g.dart';

@Riverpod(keepAlive: true)
PaymentRepository paymentRepository(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return PaymentRepository(dio);
}

class OrderPaymentsStateData {
  final List<PaymentModel> payments;
  final Set<String> verifyingPaymentIds;
  final Map<String, String> verifyErrorMap;

  const OrderPaymentsStateData({
    required this.payments,
    this.verifyingPaymentIds = const {},
    this.verifyErrorMap = const {},
  });

  bool isVerifying(String paymentId) => verifyingPaymentIds.contains(paymentId);

  OrderPaymentsStateData copyWith({
    List<PaymentModel>? payments,
    Set<String>? verifyingPaymentIds,
    Map<String, String>? verifyErrorMap,
  }) {
    return OrderPaymentsStateData(
      payments: payments ?? this.payments,
      verifyingPaymentIds: verifyingPaymentIds ?? this.verifyingPaymentIds,
      verifyErrorMap: verifyErrorMap ?? this.verifyErrorMap,
    );
  }
}

@riverpod
class OrderPaymentsController extends _$OrderPaymentsController {
  int _requestRevision = 0;

  @override
  Future<OrderPaymentsStateData> build(String orderId) async {
    _requestRevision++;
    final currentRev = _requestRevision;

    final token = ref.watch(authTokenProvider);
    final userAsync = ref.watch(currentUserProvider);
    final requestTenantSlug = ref.watch(selectedTenantSlugProvider);
    final user = userAsync.value;

    if (userAsync.isLoading || user == null || token == null || token.isEmpty) {
      return const OrderPaymentsStateData(payments: []);
    }

    final requestUserId = user.id;
    final repository = ref.watch(paymentRepositoryProvider);
    final payments = await repository.getOrderPayments(orderId);

    if (!ref.mounted) {
      return const OrderPaymentsStateData(payments: []);
    }

    final currentUserId = ref.read(currentUserProvider).value?.id;

    if (_requestRevision != currentRev ||
        ref.read(selectedTenantSlugProvider) != requestTenantSlug ||
        ref.read(authTokenProvider) != token ||
        currentUserId != requestUserId) {
      return const OrderPaymentsStateData(payments: []);
    }

    return OrderPaymentsStateData(payments: payments);
  }

  Future<PaymentModel?> verifyPayment(String paymentId) async {
    final currentState = state.value;
    if (currentState == null || currentState.isVerifying(paymentId))
      return null;

    final token = ref.read(authTokenProvider);
    final user = ref.read(currentUserProvider).value;
    if (token == null || user == null) return null;

    final currentRev = _requestRevision;
    final requestTenantSlug = ref.read(selectedTenantSlugProvider);
    final requestUserId = user.id;

    final updatedVerifying = Set<String>.from(currentState.verifyingPaymentIds)
      ..add(paymentId);
    final updatedErrors = Map<String, String>.from(currentState.verifyErrorMap)
      ..remove(paymentId);

    state = AsyncValue.data(
      currentState.copyWith(
        verifyingPaymentIds: updatedVerifying,
        verifyErrorMap: updatedErrors,
      ),
    );

    try {
      final repository = ref.read(paymentRepositoryProvider);
      final verifiedPayment = await repository.verifyPayment(paymentId);

      if (!ref.mounted) return null;

      final currentUserId = ref.read(currentUserProvider).value?.id;

      if (_requestRevision != currentRev ||
          ref.read(selectedTenantSlugProvider) != requestTenantSlug ||
          ref.read(authTokenProvider) != token ||
          currentUserId != requestUserId) {
        return null;
      }

      final latestState = state.value;
      final finalVerifying = Set<String>.from(
        latestState?.verifyingPaymentIds ?? {},
      )..remove(paymentId);

      final updatedPayments = (latestState?.payments ?? []).map((p) {
        return p.id == paymentId ? verifiedPayment : p;
      }).toList();

      state = AsyncValue.data(
        (latestState ?? currentState).copyWith(
          payments: updatedPayments,
          verifyingPaymentIds: finalVerifying,
        ),
      );

      ref.invalidate(myOrdersProvider);
      ref.invalidate(orderDetailsProvider(orderId));

      return verifiedPayment;
    } catch (e) {
      if (!ref.mounted) return null;

      final currentUserId = ref.read(currentUserProvider).value?.id;

      if (_requestRevision != currentRev ||
          ref.read(selectedTenantSlugProvider) != requestTenantSlug ||
          ref.read(authTokenProvider) != token ||
          currentUserId != requestUserId) {
        return null;
      }

      final latestState = state.value;
      final finalVerifying = Set<String>.from(
        latestState?.verifyingPaymentIds ?? {},
      )..remove(paymentId);
      final finalErrors = Map<String, String>.from(
        latestState?.verifyErrorMap ?? {},
      )..[paymentId] = e.toString();

      state = AsyncValue.data(
        (latestState ?? currentState).copyWith(
          verifyingPaymentIds: finalVerifying,
          verifyErrorMap: finalErrors,
        ),
      );

      rethrow;
    }
  }

  Future<PaymentModel?> initiatePayment(String paymentId) async {
    final repository = ref.read(paymentRepositoryProvider);
    final initiatedPayment = await repository.initiatePayment(paymentId);

    if (!ref.mounted) return null;

    final currentState = state.value;
    if (currentState != null) {
      final updatedPayments = currentState.payments.map((p) {
        return p.id == paymentId ? initiatedPayment : p;
      }).toList();
      state = AsyncValue.data(currentState.copyWith(payments: updatedPayments));
    }

    return initiatedPayment;
  }

  Future<void> refresh() async {
    _requestRevision++;
    ref.invalidateSelf();
    await future;
  }
}
