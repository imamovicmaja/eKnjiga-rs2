class OrderResponse {
  final int id;
  final DateTime orderDate;
  final double totalPrice;
  final int orderStatus;
  final int paymentStatus;
  final int type;
  final DateTime createdAt;
  final UserResponse? user;
  final List<OrderItemResponse> orderItems;

  OrderResponse({
    required this.id,
    required this.orderDate,
    required this.totalPrice,
    required this.orderStatus,
    required this.paymentStatus,
    required this.type,
    required this.createdAt,
    required this.user,
    required this.orderItems,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      id: json['id'],
      orderDate: DateTime.parse(json['orderDate']),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      orderStatus: json['orderStatus'],      
      paymentStatus: json['paymentStatus'],  
      type: json['type'],                    
      createdAt: DateTime.parse(json['createdAt']),
      user: json['user'] != null ? UserResponse.fromJson(json['user']) : null,
      orderItems: (json['orderItems'] as List<dynamic>)
          .map((e) => OrderItemResponse.fromJson(e))
          .toList(),
    );
  }
}

class OrderItemResponse {
  final int id;
  final BookResponse? book;
  final int quantity;
  final double unitPrice;

  OrderItemResponse({
    required this.id,
    required this.book,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  factory OrderItemResponse.fromJson(Map<String, dynamic> json) {
    return OrderItemResponse(
      id: json['id'],
      book:
          json['book'] != null ? BookResponse.fromJson(json['book']) : null,
      quantity: json['quantity'],
      unitPrice: (json['unitPrice'] as num).toDouble(),
    );
  }
}

class BookResponse {
  final int id;
  final String name;
  final String description;
  final double price;

  BookResponse({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
  });

  factory BookResponse.fromJson(Map<String, dynamic> json) {
    return BookResponse(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
    );
  }
}

class UserResponse {
  final int id;
  final String firstName;
  final String lastName;

  UserResponse({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
    );
  }

  String get fullName => "$firstName $lastName";
}

String orderStatusText(int value) {
  switch (value) {
    case 0:
      return "Pending";
    case 1:
      return "Processing";
    case 2:
      return "Completed";
    default:
      return "Nepoznato";
  }
}

String paymentStatusText(int value) {
  switch (value) {
    case 0:
      return "Not Paid";
    case 1:
      return "Pending";
    case 2:
      return "Paid";
    default:
      return "Nepoznato";
  }
}

String orderTypeText(int value) {
  switch (value) {
    case 0:
      return "Purchase";
    case 1:
      return "Reservation";
    case 2:
      return "Archive";
    default:
      return "Nepoznato";
  }
}

enum OrderTypeDart { Purchase, Reservation, Archive }

int orderTypeToInt(OrderTypeDart type) {
  switch (type) {
    case OrderTypeDart.Purchase:
      return 0;
    case OrderTypeDart.Reservation:
      return 1;
    case OrderTypeDart.Archive:
      return 2;
  }
}
