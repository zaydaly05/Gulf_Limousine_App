part of 'generated.dart';

class AddNewCarVariablesBuilder {
  String make;
  String model;
  int year;
  double rentalPricePerDay;
  bool isAvailable;
  String licensePlate;

  String? imageUrl;
  String? color;
  int? seatingCapacity;

  final FirebaseDataConnect _dataConnect;

  AddNewCarVariablesBuilder imageUrlSetter(String? t) {
    imageUrl = t;
    return this;
  }

  AddNewCarVariablesBuilder colorSetter(String? t) {
    color = t;
    return this;
  }

  AddNewCarVariablesBuilder seatingCapacitySetter(int? t) {
    seatingCapacity = t;
    return this;
  }

  AddNewCarVariablesBuilder(
      this._dataConnect, {
        required this.make,
        required this.model,
        required this.year,
        required this.rentalPricePerDay,
        required this.isAvailable,
        required this.licensePlate,
      });

  Deserializer<AddNewCarData> dataDeserializer =
      (dynamic json) => AddNewCarData.fromJson(jsonDecode(json));

  Serializer<AddNewCarVariables> varsSerializer =
      (AddNewCarVariables vars) => jsonEncode(vars.toJson());

  Future<OperationResult<AddNewCarData, AddNewCarVariables>> execute() {
    return ref().execute();
  }

  MutationRef<AddNewCarData, AddNewCarVariables> ref() {
    final vars = AddNewCarVariables(
      make: make,
      model: model,
      year: year,
      rentalPricePerDay: rentalPricePerDay,
      isAvailable: isAvailable,
      licensePlate: licensePlate,
      imageUrl: imageUrl,
      color: color,
      seatingCapacity: seatingCapacity,
    );

    return _dataConnect.mutation(
      "AddNewCar",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class AddNewCarCarInsert {
  final String id;

  AddNewCarCarInsert.fromJson(dynamic json)
      : id = nativeFromJson<String>(json['id']);

  const AddNewCarCarInsert({required this.id});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AddNewCarCarInsert && id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() => {
    'id': nativeToJson<String>(id),
  };
}

@immutable
class AddNewCarData {
  final AddNewCarCarInsert car_insert;

  AddNewCarData.fromJson(dynamic json)
      : car_insert = AddNewCarCarInsert.fromJson(json['car_insert']);

  const AddNewCarData({required this.car_insert});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AddNewCarData && car_insert == other.car_insert;

  @override
  int get hashCode => car_insert.hashCode;

  Map<String, dynamic> toJson() => {
    'car_insert': car_insert.toJson(),
  };
}

@immutable
class AddNewCarVariables {
  final String make;
  final String model;
  final int year;
  final double rentalPricePerDay;
  final bool isAvailable;
  final String licensePlate;

  final String? imageUrl;
  final String? color;
  final int? seatingCapacity;

  const AddNewCarVariables({
    required this.make,
    required this.model,
    required this.year,
    required this.rentalPricePerDay,
    required this.isAvailable,
    required this.licensePlate,
    this.imageUrl,
    this.color,
    this.seatingCapacity,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AddNewCarVariables &&
              make == other.make &&
              model == other.model &&
              year == other.year &&
              rentalPricePerDay == other.rentalPricePerDay &&
              isAvailable == other.isAvailable &&
              licensePlate == other.licensePlate &&
              imageUrl == other.imageUrl &&
              color == other.color &&
              seatingCapacity == other.seatingCapacity;

  @override
  int get hashCode => Object.hash(
    make,
    model,
    year,
    rentalPricePerDay,
    isAvailable,
    licensePlate,
    imageUrl,
    color,
    seatingCapacity,
  );

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'make': nativeToJson<String>(make),
      'model': nativeToJson<String>(model),
      'year': nativeToJson<int>(year),
      'rentalPricePerDay': nativeToJson<double>(rentalPricePerDay),
      'isAvailable': nativeToJson<bool>(isAvailable),
      'licensePlate': nativeToJson<String>(licensePlate),
    };

    if (imageUrl != null) {
      json['imageUrl'] = nativeToJson<String>(imageUrl!);
    }
    if (color != null) {
      json['color'] = nativeToJson<String>(color!);
    }
    if (seatingCapacity != null) {
      json['seatingCapacity'] = nativeToJson<int>(seatingCapacity!);
    }

    return json;
  }
}
