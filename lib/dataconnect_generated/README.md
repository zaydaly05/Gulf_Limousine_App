# dataconnect_generated SDK

## Installation
```sh
flutter pub get firebase_data_connect
flutterfire configure
```
For more information, see [Flutter for Firebase installation documentation](https://firebase.google.com/docs/data-connect/flutter-sdk#use-core).

## Data Connect instance
Each connector creates a static class, with an instance of the `DataConnect` class that can be used to connect to your Data Connect backend and call operations.

### Connecting to the emulator

```dart
String host = 'localhost'; // or your host name
int port = 9399; // or your port number
ExampleConnector.instance.dataConnect.useDataConnectEmulator(host, port);
```

You can also call queries and mutations by using the connector class.
## Queries

### GetAvailableCars
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.getAvailableCars().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetAvailableCarsData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getAvailableCars();
GetAvailableCarsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.getAvailableCars().ref();
ref.execute();

ref.subscribe(...);
```


### GetRentalHistoryForUser
#### Required Arguments
```dart
String userId = ...;
ExampleConnector.instance.getRentalHistoryForUser(
  userId: userId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetRentalHistoryForUserData, GetRentalHistoryForUserVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getRentalHistoryForUser(
  userId: userId,
);
GetRentalHistoryForUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String userId = ...;

final ref = ExampleConnector.instance.getRentalHistoryForUser(
  userId: userId,
).ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### AddNewCar
#### Required Arguments
```dart
String make = ...;
String model = ...;
int year = ...;
double rentalPricePerDay = ...;
bool isAvailable = ...;
String licensePlate = ...;
ExampleConnector.instance.addNewCar(
  make: make,
  model: model,
  year: year,
  rentalPricePerDay: rentalPricePerDay,
  isAvailable: isAvailable,
  licensePlate: licensePlate,
).execute();
```

#### Optional Arguments
We return a builder for each query. For AddNewCar, we created `AddNewCarBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class AddNewCarVariablesBuilder {
  ...
   AddNewCarVariablesBuilder imageUrl(String? t) {
   _imageUrl.value = t;
   return this;
  }
  AddNewCarVariablesBuilder color(String? t) {
   _color.value = t;
   return this;
  }
  AddNewCarVariablesBuilder seatingCapacity(int? t) {
   _seatingCapacity.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.addNewCar(
  make: make,
  model: model,
  year: year,
  rentalPricePerDay: rentalPricePerDay,
  isAvailable: isAvailable,
  licensePlate: licensePlate,
)
.imageUrl(imageUrl)
.color(color)
.seatingCapacity(seatingCapacity)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<AddNewCarData, AddNewCarVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.addNewCar(
  make: make,
  model: model,
  year: year,
  rentalPricePerDay: rentalPricePerDay,
  isAvailable: isAvailable,
  licensePlate: licensePlate,
);
AddNewCarData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String make = ...;
String model = ...;
int year = ...;
double rentalPricePerDay = ...;
bool isAvailable = ...;
String licensePlate = ...;

final ref = ExampleConnector.instance.addNewCar(
  make: make,
  model: model,
  year: year,
  rentalPricePerDay: rentalPricePerDay,
  isAvailable: isAvailable,
  licensePlate: licensePlate,
).ref();
ref.execute();
```


### UpdateCarAvailability
#### Required Arguments
```dart
String id = ...;
bool isAvailable = ...;
ExampleConnector.instance.updateCarAvailability(
  id: id,
  isAvailable: isAvailable,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateCarAvailabilityData, UpdateCarAvailabilityVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateCarAvailability(
  id: id,
  isAvailable: isAvailable,
);
UpdateCarAvailabilityData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
bool isAvailable = ...;

final ref = ExampleConnector.instance.updateCarAvailability(
  id: id,
  isAvailable: isAvailable,
).ref();
ref.execute();
```

