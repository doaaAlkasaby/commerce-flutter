class SpecialRequestedItemModel {
  final String id;
  final String name;
  final int quantity;
  final String? specifications;
  final String? productId;
  final String? variantId;

  const SpecialRequestedItemModel({
    required this.id,
    required this.name,
    required this.quantity,
    this.specifications,
    this.productId,
    this.variantId,
  });

  factory SpecialRequestedItemModel.fromJson(Map<String, dynamic> json) {
    return SpecialRequestedItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Requested Product',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      specifications: json['specifications']?.toString(),
      productId: json['productId']?.toString(),
      variantId: json['variantId']?.toString(),
    );
  }
}

class SpecialOrderAttachmentModel {
  final String id;
  final String fileKey;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final bool isPrescription;

  const SpecialOrderAttachmentModel({
    required this.id,
    required this.fileKey,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.isPrescription,
  });

  factory SpecialOrderAttachmentModel.fromJson(Map<String, dynamic> json) {
    return SpecialOrderAttachmentModel(
      id: json['id']?.toString() ?? '',
      fileKey: json['fileKey']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? 'Attachment',
      mimeType: json['mimeType']?.toString() ?? 'application/octet-stream',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      isPrescription: json['isPrescription'] == true,
    );
  }
}

class SpecialOrderRequestModel {
  final String id;
  final String requestNumber;
  final String status;
  final String? contactPhone;
  final String? notes;
  final String? rejectionReason;
  final String? finalOrderId;
  final String createdAt;
  final String? updatedAt;
  final List<SpecialRequestedItemModel> items;
  final List<SpecialOrderAttachmentModel> attachments;

  const SpecialOrderRequestModel({
    required this.id,
    required this.requestNumber,
    required this.status,
    this.contactPhone,
    this.notes,
    this.rejectionReason,
    this.finalOrderId,
    required this.createdAt,
    this.updatedAt,
    this.items = const [],
    this.attachments = const [],
  });

  int get totalRequestedQuantity {
    if (items.isEmpty) return 0;
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  factory SpecialOrderRequestModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    final itemsList = rawItems
        .map((item) => SpecialRequestedItemModel.fromJson(item as Map<String, dynamic>))
        .toList();

    final rawAttachments = json['attachments'] as List? ?? [];
    final attachmentsList = rawAttachments
        .map((att) => SpecialOrderAttachmentModel.fromJson(att as Map<String, dynamic>))
        .toList();

    final finalOrder = json['finalOrder'] as Map<String, dynamic>?;
    final finalOrderIdStr = json['finalOrderId']?.toString() ?? finalOrder?['id']?.toString();

    return SpecialOrderRequestModel(
      id: json['id']?.toString() ?? '',
      requestNumber:
          json['requestNumber']?.toString() ??
          json['number']?.toString() ??
          'REQ',
      status: json['status']?.toString() ?? 'NEW',
      contactPhone: json['contactPhone']?.toString(),
      notes: json['notes']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
      finalOrderId: finalOrderIdStr,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString(),
      items: itemsList,
      attachments: attachmentsList,
    );
  }
}
