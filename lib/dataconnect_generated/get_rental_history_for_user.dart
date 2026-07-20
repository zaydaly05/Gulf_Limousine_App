part of 'generated.dart';

class GetRentalHistoryForUserVariablesBuilder {
  String userId;

  final FirebaseDataConnect _dataConnect;
  GetRentalHistoryForUserVariablesBuilder(this._dataConnect, {required  this.userId,});
  Deserializer<GetRentalHistoryForUserData> dataDeserializer = (dynamic json)  => GetRentalHistoryForUserData.fromJson(jsonDecode(json));
  Serializer<GetRentalHistoryForUserVariables> varsSerializer = (GetRentalHistoryForUserVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetRentalHistoryForUserData, GetRentalHistoryForUserVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetRentalHistoryForUserData, GetRentalHistoryForUserVariables> ref() {
    GetRentalHistoryForUserVariables vars= GetRentalHistoryForUserVariables(userId: userId,);
    return _dataConnect.query("GetRentalHistoryForUser", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetRentalHistoryForUserRentals {
  final String id;
  final GetRentalHistoryForUserRentalsCar car;
  final DateTime pickUpDate;
  final DateTime dropOffDate;
  final double totalPrice;
  final String status;
  GetRentalHistoryForUserRentals.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  car = GetRentalHistoryForUserRentalsCar.fromJson(json['car']),
  pickUpDate = nativeFromJson<DateTime>(json['pickUpDate']),
  dropOffDate = nativeFromJson<DateTime>(json['dropOffDate']),
  totalPrice = nativeFromJson<double>(json['totalPrice']),
  status = nativeFromJson<String>(json['status']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetRentalHistoryForUserRentals otherTyped = other as GetRentalHistoryForUserRentals;
    return id == otherTyped.id && 
    car == otherTyped.car && 
    pickUpDate == otherTyped.pickUpDate && 
    dropOffDate == otherTyped.dropOffDate && 
    totalPrice == otherTyped.totalPrice && 
    status == otherTyped.status;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, car.hashCode, pickUpDate.hashCode, dropOffDate.hashCode, totalPrice.hashCode, status.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['car'] = car.toJson();
    json['pickUpDate'] = nativeToJson<DateTime>(pickUpDate);
    json['dropOffDate'] = nativeToJson<DateTime>(dropOffDate);
    json['totalPrice'] = nativeToJson<double>(totalPrice);
    json['status'] = nativeToJson<String>(status);
    return json;
  }

  const GetRentalHistoryForUserRentals({
    required this.id,
    required this.car,
    required this.pickUpDate,
    required this.dropOffDate,
    required this.totalPrice,
    required this.status,
  });
}

@immutable
class GetRentalHistoryForUserRentalsCar {
  final String make;
  final String model;
  GetRentalHistoryForUserRentalsCar.fromJson(dynamic json):
  
  make = nativeFromJson<String>(json['make']),
  model = nativeFromJson<String>(json['model']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetRentalHistoryForUserRentalsCar otherTyped = other as GetRentalHistoryForUserRentalsCar;
    return make == otherTyped.make && 
    model == otherTyped.model;
    
  }
  @override
  int get hashCode => Object.hashAll([make.hashCode, model.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['make'] = nativeToJson<String>(make);
    json['model'] = nativeToJson<String>(model);
    return json;
  }

  const GetRentalHistoryForUserRentalsCar({
    required this.make,
    required this.model,
  });
}

@immutable
class GetRentalHistoryForUserData {
  final List<GetRentalHistoryForUserRentals> rentals;
  GetRentalHistoryForUserData.fromJson(dynamic json):
  
  rentals = (json['rentals'] as List<dynamic>)
        .map((e) => GetRentalHistoryForUserRentals.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetRentalHistoryForUserData otherTyped = other as GetRentalHistoryForUserData;
    return rentals == otherTyped.rentals;
    
  }
  @override
  int get hashCode => rentals.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['rentals'] = rentals.map((e) => e.toJson()).toList();
    return json;
  }

  const GetRentalHistoryForUserData({
    required this.rentals,
  });
}

@immutable
class GetRentalHistoryForUserVariables {
  final String userId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetRentalHistoryForUserVariables.fromJson(Map<String, dynamic> json):
  
  userId = nativeFromJson<String>(json['userId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetRentalHistoryForUserVariables otherTyped = other as GetRentalHistoryForUserVariables;
    return userId == otherTyped.userId;
    
  }
  @override
  int get hashCode => userId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    return json;
  }

  const GetRentalHistoryForUserVariables({
    required this.userId,
  });
}

