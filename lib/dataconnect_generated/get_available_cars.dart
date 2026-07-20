part of 'generated.dart';

class GetAvailableCarsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetAvailableCarsVariablesBuilder(this._dataConnect, );
  Deserializer<GetAvailableCarsData> dataDeserializer = (dynamic json)  => GetAvailableCarsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetAvailableCarsData, void>> execute() {
    return ref().execute();
  }

  QueryRef<GetAvailableCarsData, void> ref() {
    
    return _dataConnect.query("GetAvailableCars", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetAvailableCarsCars {
  final String id;
  final String make;
  final String model;
  final int year;
  final double rentalPricePerDay;
  final String? imageUrl;
  final String? color;
  final int? seatingCapacity;
  GetAvailableCarsCars.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  make = nativeFromJson<String>(json['make']),
  model = nativeFromJson<String>(json['model']),
  year = nativeFromJson<int>(json['year']),
  rentalPricePerDay = nativeFromJson<double>(json['rentalPricePerDay']),
  imageUrl = json['imageUrl'] == null ? null : nativeFromJson<String>(json['imageUrl']),
  color = json['color'] == null ? null : nativeFromJson<String>(json['color']),
  seatingCapacity = json['seatingCapacity'] == null ? null : nativeFromJson<int>(json['seatingCapacity']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAvailableCarsCars otherTyped = other as GetAvailableCarsCars;
    return id == otherTyped.id && 
    make == otherTyped.make && 
    model == otherTyped.model && 
    year == otherTyped.year && 
    rentalPricePerDay == otherTyped.rentalPricePerDay && 
    imageUrl == otherTyped.imageUrl && 
    color == otherTyped.color && 
    seatingCapacity == otherTyped.seatingCapacity;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, make.hashCode, model.hashCode, year.hashCode, rentalPricePerDay.hashCode, imageUrl.hashCode, color.hashCode, seatingCapacity.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['make'] = nativeToJson<String>(make);
    json['model'] = nativeToJson<String>(model);
    json['year'] = nativeToJson<int>(year);
    json['rentalPricePerDay'] = nativeToJson<double>(rentalPricePerDay);
    if (imageUrl != null) {
      json['imageUrl'] = nativeToJson<String?>(imageUrl);
    }
    if (color != null) {
      json['color'] = nativeToJson<String?>(color);
    }
    if (seatingCapacity != null) {
      json['seatingCapacity'] = nativeToJson<int?>(seatingCapacity);
    }
    return json;
  }

  const GetAvailableCarsCars({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.rentalPricePerDay,
    this.imageUrl,
    this.color,
    this.seatingCapacity,
  });
}

@immutable
class GetAvailableCarsData {
  final List<GetAvailableCarsCars> cars;
  GetAvailableCarsData.fromJson(dynamic json):
  
  cars = (json['cars'] as List<dynamic>)
        .map((e) => GetAvailableCarsCars.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAvailableCarsData otherTyped = other as GetAvailableCarsData;
    return cars == otherTyped.cars;
    
  }
  @override
  int get hashCode => cars.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['cars'] = cars.map((e) => e.toJson()).toList();
    return json;
  }

  const GetAvailableCarsData({
    required this.cars,
  });
}

