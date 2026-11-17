enum ServerRentalStatus {
  pending,
  rented,
  returnRequested,
  returned,
  rejected,
  cancelled,
  expired,
}

class RentalResponse {
  const RentalResponse({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.rentedAt,
    required this.dueAt,
    required this.returnedAt,
    required this.status,
  });

  factory RentalResponse.fromJson(Map<String, dynamic> json) {
    final status = switch (json['status']) {
      'PENDING' => ServerRentalStatus.pending,
      'RENTED' => ServerRentalStatus.rented,
      'RETURN_REQUESTED' => ServerRentalStatus.returnRequested,
      'RETURNED' => ServerRentalStatus.returned,
      'REJECTED' => ServerRentalStatus.rejected,
      'CANCELLED' => ServerRentalStatus.cancelled,
      'EXPIRED' => ServerRentalStatus.expired,
      _ => throw const FormatException('알 수 없는 대여 상태입니다.'),
    };
    final returnedAt = json['returnedAt'];
    if (status == ServerRentalStatus.returned && returnedAt == null) {
      throw const FormatException('반납일이 누락되었습니다.');
    }
    return RentalResponse(
      id: json['id'] as int,
      itemId: json['itemId'] as int,
      itemName: json['itemName'] as String,
      rentedAt: DateTime.parse(json['rentedAt'] as String),
      dueAt: DateTime.parse(json['dueAt'] as String),
      returnedAt: returnedAt == null
          ? null
          : DateTime.parse(returnedAt as String),
      status: status,
    );
  }

  final int id;
  final int itemId;
  final String itemName;
  final DateTime rentedAt;
  final DateTime dueAt;
  final DateTime? returnedAt;
  final ServerRentalStatus status;
}
