import 'dart:async';
import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:users_app/assistants/request_assistant.dart';
import 'package:users_app/global/global.dart';
import 'package:users_app/global/map_key.dart';
import 'package:users_app/models/direction_details_info.dart';
import 'package:users_app/models/directions.dart';
import 'package:users_app/models/trip_history_model.dart';

import '../InfoHandler/app_info.dart';
import '../models/user_model.dart';

class AssistantMethods{

  static Future<String> searchAddressForGeographicCoordinates(Position position,context) async{
    String humanReadableAddress = "Error";

    // Creating connection to Geocode / Geolocation Api
    String apiUrl = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";

    // Sending the api Url to the static method to use the url to fetch the Readable Address
    var requestResponse = await RequestAssistant.ReceiveRequest(apiUrl);

    if (requestResponse!="Error fetching the request"){
      humanReadableAddress = requestResponse["results"][0]["formatted_address"]; // Human Readable Address

      // Creating instance of Direction and assigning the values
      Directions userPickupAddress = Directions();
      userPickupAddress.locationLatitude = position.latitude;
      userPickupAddress.locationLongitude = position.longitude;
      userPickupAddress.locationName = humanReadableAddress;

      Provider.of<AppInfo>(context,listen: false).updatePickupLocationAddress(userPickupAddress);

    }

    return humanReadableAddress;

  }
  

  static void readOnlineUserCurrentInfo(){
    currentFirebaseUser = firebaseAuth.currentUser;
    DatabaseReference reference = FirebaseDatabase.instance.ref()
        .child("Users")
        .child(currentFirebaseUser!.uid);

    reference.once().then((snap){

      final DataSnapshot snapshot = snap.snapshot;
      if(snapshot.exists){
        currentUserInfo = UserModel.fromSnapshot(snapshot);
      }

    });
  }

  static Future<DirectionDetailsInfo?> getOriginToDestinationDirectionDetails(LatLng originPosition,LatLng destinationPosition) async{
    // Create connection to direction Api
    String urlOriginToDestinationDirectionDetails = "https://maps.googleapis.com/maps/api/directions/json?origin=${originPosition.latitude},${originPosition.longitude}&destination=${destinationPosition.latitude},${destinationPosition.longitude}&key=$mapKey";
    // Sending the api Url to the static method to use the url to fetch the driving directions in Json format.
    var response = await RequestAssistant.ReceiveRequest(urlOriginToDestinationDirectionDetails);

    if(response == "Error fetching the request"){
      return null;
    }

    DirectionDetailsInfo directionDetailsInfo = DirectionDetailsInfo();
    directionDetailsInfo.e_points = response["routes"][0]["overview_polyline"]["points"]; // Poly/Encoded points from Current Location to destination

    directionDetailsInfo.distance_value = response["routes"][0]["legs"][0]["distance"]["value"];
    directionDetailsInfo.distance_text = response["routes"][0]["legs"][0]["distance"]["text"];

    directionDetailsInfo.duration_value = response["routes"][0]["legs"][0]["duration"]["value"];
    directionDetailsInfo.duration_text = response["routes"][0]["legs"][0]["duration"]["text"];

    return directionDetailsInfo;

  }

  static double calculateFareAmountFromSourceToDestination(DirectionDetailsInfo directionDetailsInfo, String vehicleType)
  {
    double baseFare,FareAmountPerMinute,FareAmountPerKilometer;
    if (vehicleType == "UberX"){
      baseFare = 3.5;
     
      FareAmountPerKilometer = (directionDetailsInfo.distance_value! / 1000) * 20;
    }

    else if (vehicleType == "Uber Premier"){
      baseFare = 3.5;
     
      FareAmountPerKilometer = (directionDetailsInfo.distance_value! / 1000) * 25;
    }

    else{
      baseFare = 20;
      
      FareAmountPerKilometer = (directionDetailsInfo.distance_value! / 1000) * 10;
    }

    
    double totalFareAmount = baseFare * directionDetailsInfo.distance_value!;
    return double.parse(totalFareAmount.toStringAsFixed(1));
  }

  // Postman work
  static sendNotificationToDriver(context, String? rideRequestID,String deviceRegistrationToken) async{
    print("Tokennnnnn///"+ cloudMessagingServerToken);
    Map<String,String> headerNotification = {
      'Content-Type' : 'application/json',
      'Authorization' : 'Bearer ya29.a0AfB_byBQsmMFh5pIO9mf8hsmH1HQUltRg8tdSN-Sot8WTKbCZKNc7A2j5kR35QZPDf0iiuJSqg11AqflZcCdUmvlPAg39X5w1mt9xrrWRqzIT2uKGXEuLmg-FR57VAncOVzgfjzfSAbng3A0t4h-9yTbA_9ktb4aCgYKAZUSARASFQHsvYlsEJ4fbBm4rDRdFev9GWVamw0166', 
      
      
    };

   

  

   Map<String, dynamic> bodyNotification = {
  "body": "You have a new ride request!",
  "title": "New Ride Request"
  
};
Map<String, dynamic> android =
  {
    "priority": "high",
  };
  Map<String, dynamic> dataMap = {
  "click_action": "FLUTTER_NOTIFICATION_CLICK",
  "id": "1",
  "status": "done",
  "rideRequestId": rideRequestID
}; 
Map<String, dynamic> message = {
  "token": deviceRegistrationToken,
   "data": dataMap,
  "notification": bodyNotification,
 
   "android": android,
};



Map<String, dynamic> officielNotificationFormat = {
  "notification": bodyNotification,
  
 
};


Map<String, dynamic> fcm = {
  "message": message,
};

    // Work of postman to send notification
    var responseNotification = await post(
      Uri.parse('https://fcm.googleapis.com/v1/projects/transport-app-36443/messages:send'),
      headers: headerNotification,
      body: jsonEncode(fcm),    
          );
print("hfjhyfghjf "+fcm.toString());

print("emchiiiiiiiiiiii brabiiiiiiiiiiiii:" + responseNotification.body.toString());
  }

  

  // For Trip history
  static void readRideRequestKeys(context){
    FirebaseDatabase.instance.ref()
        .child("AllRideRequests")
        .orderByChild("userName")
        .equalTo(currentUserInfo!.name)
        .once()
        .then((snapData) {
          DataSnapshot snapshot = snapData.snapshot;
          if(snapshot.exists){
            // Total trips taken by this user
            Map rideRequestKeys = snapshot.value as Map;
            int totalTripsCount = rideRequestKeys.length;

            // Updating total trips taken by this user
            Provider.of<AppInfo>(context,listen: false).updateTotalTrips(totalTripsCount);

            // Store all the rideRequest key/id in this list
            List<String> allRideRequestKeyList = [];
            rideRequestKeys.forEach((key, value) {
              allRideRequestKeyList.add(key);
            });

            // Storing the total trips taken list in provider
            Provider.of<AppInfo>(context,listen: false).updateTotalTripsList(allRideRequestKeyList);

            readTripHistoryInformation(context);

          }

    });
  }

  static void readTripHistoryInformation(context) {
    var historyTripsKeyList = Provider.of<AppInfo>(context,listen: false).historyTripsKeyList;
    for(String eachKey in historyTripsKeyList){
      FirebaseDatabase.instance.ref()
          .child("AllRideRequests")
          .child(eachKey)
          .once()
          .then((snapData){
            // convert each ride request information to TripHistoryModel
            var eachTripHistoryInformation = TripHistoryModel.fromSnapshot(snapData.snapshot);

            if((snapData.snapshot.value as Map)["status"] == "Ended"){
              // Add each TripHistoryModel to a  historyInformationList in AppInfo class
              Provider.of<AppInfo>(context,listen: false).updateTotalHistoryInformation(eachTripHistoryInformation);
            }

      });
    }

  }
}