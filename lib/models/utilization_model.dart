class UtilizationRecord {
  final String id;
  final String campaignName;
  final String campaignId;
  final String donationType; // 'fund', 'resource', 'both'
  final double fundAmountUsed;
  final List<UtilizedItem> itemsUtilized;
  final int beneficiaries;
  final String description;
  final String utilizationDate;
  final String status; // 'draft', 'completed'
  final List<String> impactImages;
  final List<ProofDocument> proofDocuments;
  final String createdAt;
  final String createdBy;

  UtilizationRecord({
    required this.id,
    required this.campaignName,
    required this.campaignId,
    required this.donationType,
    required this.fundAmountUsed,
    required this.itemsUtilized,
    required this.beneficiaries,
    required this.description,
    required this.utilizationDate,
    required this.status,
    required this.impactImages,
    required this.proofDocuments,
    required this.createdAt,
    required this.createdBy,
  });

  factory UtilizationRecord.fromMap(
      Map<String, dynamic> map, String id) {
    return UtilizationRecord(
      id: id,
      campaignName: map['campaignName'] ?? '',
      campaignId: map['campaignId'] ?? '',
      donationType: map['donationType'] ?? 'fund',
      fundAmountUsed:
      (map['fundAmountUsed'] ?? 0).toDouble(),
      itemsUtilized: (map['itemsUtilized'] as List? ?? [])
          .map((e) => UtilizedItem.fromMap(e))
          .toList(),
      beneficiaries: map['beneficiaries'] ?? 0,
      description: map['description'] ?? '',
      utilizationDate: map['utilizationDate'] ?? '',
      status: map['status'] ?? 'draft',
      impactImages: List<String>.from(
          map['impactImages'] ?? []),
      proofDocuments:
      (map['proofDocuments'] as List? ?? [])
          .map((e) => ProofDocument.fromMap(e))
          .toList(),
      createdAt: map['createdAt']?.toString() ?? '',
      createdBy: map['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'campaignName': campaignName,
      'campaignId': campaignId,
      'donationType': donationType,
      'fundAmountUsed': fundAmountUsed,
      'itemsUtilized':
      itemsUtilized.map((e) => e.toMap()).toList(),
      'beneficiaries': beneficiaries,
      'description': description,
      'utilizationDate': utilizationDate,
      'status': status,
      'impactImages': impactImages,
      'proofDocuments':
      proofDocuments.map((e) => e.toMap()).toList(),
      'createdBy': createdBy,
    };
  }
}

class UtilizedItem {
  final String itemName;
  final String category;
  final int quantity;

  UtilizedItem({
    required this.itemName,
    required this.category,
    required this.quantity,
  });

  factory UtilizedItem.fromMap(Map<String, dynamic> map) {
    return UtilizedItem(
      itemName: map['itemName'] ?? '',
      category: map['category'] ?? '',
      quantity: map['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'itemName': itemName,
    'category': category,
    'quantity': quantity,
  };
}

class ProofDocument {
  final String type; // 'bill', 'receipt', 'invoice', 'fee_slip', 'medical_bill'
  final String url;
  final String name;

  ProofDocument({
    required this.type,
    required this.url,
    required this.name,
  });

  factory ProofDocument.fromMap(Map<String, dynamic> map) {
    return ProofDocument(
      type: map['type'] ?? 'receipt',
      url: map['url'] ?? '',
      name: map['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type,
    'url': url,
    'name': name,
  };
}