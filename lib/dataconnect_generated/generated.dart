library;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'add_new_car.dart';

part 'get_available_cars.dart';

part 'update_car_availability.dart';

part 'get_rental_history_for_user.dart';







class ExampleConnector {
  
  
  AddNewCarVariablesBuilder addNewCar ({required String make, required String model, required int year, required double rentalPricePerDay, required bool isAvailable, required String licensePlate, }) {
    return AddNewCarVariablesBuilder(dataConnect, make: make,model: model,year: year,rentalPricePerDay: rentalPricePerDay,isAvailable: isAvailable,licensePlate: licensePlate,);
  }
  
  
  GetAvailableCarsVariablesBuilder getAvailableCars () {
    return GetAvailableCarsVariablesBuilder(dataConnect, );
  }
  
  
  UpdateCarAvailabilityVariablesBuilder updateCarAvailability ({required String id, required bool isAvailable, }) {
    return UpdateCarAvailabilityVariablesBuilder(dataConnect, id: id,isAvailable: isAvailable,);
  }
  
  
  GetRentalHistoryForUserVariablesBuilder getRentalHistoryForUser ({required String userId, }) {
    return GetRentalHistoryForUserVariablesBuilder(dataConnect, userId: userId,);
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-east4',
    'example',
    'gulflimousinetravel',
  );

  ExampleConnector({required this.dataConnect});
  static ExampleConnector get instance {
    return ExampleConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
