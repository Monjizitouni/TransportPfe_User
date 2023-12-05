import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smooth_star_rating_nsafe/smooth_star_rating.dart';
import 'package:users_app/assistants/assistant_methods.dart';
import 'package:users_app/global/global.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SelectActiveDriverScreen extends StatefulWidget {
  static DatabaseReference? referenceRideRequest;

  @override
  State<SelectActiveDriverScreen> createState() => _SelectActiveDriverScreenState();
}

class _SelectActiveDriverScreenState extends State<SelectActiveDriverScreen> {
  double? fareAmount;

  double? getFareAmountAccordingToVehicleType(int index) {
    String? vehicleType = driversList[index]?["carDetails"]?["carType"];
    return vehicleType != null
        ? AssistantMethods.calculateFareAmountFromSourceToDestination(tripDirectionDetailsInfo!, vehicleType)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          AppLocalizations.of(context)!.selectNearestDriver,
          style: TextStyle(fontSize: 18),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black,),
          onPressed: () {
            SelectActiveDriverScreen.referenceRideRequest!.remove();
            Fluttertoast.showToast(msg: AppLocalizations.of(context)!.youhavecancelledtheriderequest);
            SystemNavigator.pop();
          },
        ),
      ),
      body: ListView.builder(
        itemCount: driversList.length,
        itemBuilder: (BuildContext context, int index) {
          String? vehicleType = driversList[index]?["carDetails"]?["carType"];
          double? fareAmount = getFareAmountAccordingToVehicleType(index);

          return GestureDetector(
            onTap: () {
              setState(() {
                chosenDriverId = driversList[index]?["id"]?.toString() ?? "";
              });
              Navigator.pop(context, "Driver chosen");
            },
            child: Card(
              color: Colors.white,
              elevation: 3,
              shadowColor: Colors.black,
              margin: EdgeInsets.all(8),
              child: ListTile(
                leading: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Image.asset(
                     "${"images/" + driversList[index]["carDetails"]["carType"]}.png",
                  ),
                ),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      driversList[index]?["name"]?.toString() ?? "",
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                    Text(
                      vehicleType ?? "",
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                    SmoothStarRating(
                      rating: driversList[index]?["ratings"] == null
                          ? 0.0
                          : double.parse(driversList[index]?["ratings"]?.toString() ?? "0.0"),
                      allowHalfRating: true,
                      starCount: 5,
                      size: 15.0,
                      color: Colors.black,
                      borderColor: Colors.black,
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.dinar + getFareAmountAccordingToVehicleType(index).toString().substring(0,3),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      tripDirectionDetailsInfo != null ? (tripDirectionDetailsInfo!.duration_text!).toString() : "",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      tripDirectionDetailsInfo != null ? (tripDirectionDetailsInfo!.distance_text!).toString() : "",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
