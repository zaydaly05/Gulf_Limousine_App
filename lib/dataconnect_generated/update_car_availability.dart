part of 'generated.dart';

class UpdateCarAvailabilityVariablesBuilder {
  String id;
  bool isAvailable;

  final FirebaseDataConnect _dataConnect;
  UpdateCarAvailabilityVariablesBuilder(this._dataConnect, {required  this.id,required  this.isAvailable,});
  Deserializer<UpdateCarAvailabilityData> dataDeserializer = (dynamic json)  => UpdateCarAvailabilityData.fromJson(jsonDecode(json));
  Serializer<UpdateCarAvailabilityVariables> varsSerializer = (UpdateCarAvailabilityVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateCarAvailabilityData, UpdateCarAvailabilityVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateCarAvailabilityData, UpdateCarAvailabilityVariables> ref() {
    UpdateCarAvailabilityVariables vars= UpdateCarAvailabilityVariables(id: id,isAvailable: isAvailable,);
    return _dataConnect.mutation("UpdateCarAvailability", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateCarAvailabilityCarUpdate {
  final String id;
  UpdateCarAvailabilityCarUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCarAvailabilityCarUpdate otherTyped = other as UpdateCarAvailabilityCarUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  const UpdateCarAvailabilityCarUpdate({
    required this.id,
  });
}

@immutable
class UpdateCarAvailabilityData {
  final UpdateCarAvailabilityCarUpdate? car_update;
  UpdateCarAvailabilityData.fromJson(dynamic json):
  
  car_update = json['car_update'] == null ? null : UpdateCarAvailabilityCarUpdate.fromJson(json['car_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCarAvailabilityData otherTyped = other as UpdateCarAvailabilityData;
    return car_update == otherTyped.car_update;
    
  }
  @override
  int get hashCode => car_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (car_update != null) {
      json['car_update'] = car_update!.toJson();
    }
    return json;
  }

  const UpdateCarAvailabilityData({
    this.car_update,
  });
}

@immutable
class UpdateCarAvailabilityVariables {
  final String id;
  final bool isAvailable;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateCarAvailabilityVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  isAvailable = nativeFromJson<bool>(json['isAvailable']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCarAvailabilityVariables otherTyped = other as UpdateCarAvailabilityVariables;
    return id == otherTyped.id && 
    isAvailable == otherTyped.isAvailable;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, isAvailable.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['isAvailable'] = nativeToJson<bool>(isAvailable);
    return json;
  }

  const UpdateCarAvailabilityVariables({
    required this.id,
    required this.isAvailable,
  });
}

