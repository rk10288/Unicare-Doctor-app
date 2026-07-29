import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo; // Alias geolocator
import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart' hide Position;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../components/app_scaffold.dart';
import '../../main.dart';
import '../../utils/colors.dart';
import '../../utils/app_common.dart';

class MapRouteViewController extends GetxController {
  final String patientAddress;
  final String patientName;
  final String? latitude;
  final String? longitude;

  MapRouteViewController({
    required this.patientAddress,
    required this.patientName,
    this.latitude,
    this.longitude,
  });

  Rx<bool> isLoading = true.obs;
  Rx<String> errorMessage = ''.obs;
  Rxn<geo.Position> doctorLocation = Rxn<geo.Position>(); // Use geo.Position
  Rxn<Point> patientLocation = Rxn<Point>();

  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;

  @override
  void onInit() {
    super.onInit();
    MapboxOptions.setAccessToken(appConfigs.value.mapboxKey);
    initializeData();
  }

  Future<void> initializeData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Check and request location permissions
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        errorMessage.value = locale.value.locationServicesDisabled;
        isLoading.value = false;
        return;
      }

      geo.LocationPermission permission =
          await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          errorMessage.value = locale.value.locationPermissionDenied;
          isLoading.value = false;
          return;
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        errorMessage.value = locale.value.locationPermissionDeniedForever;
        isLoading.value = false;
        return;
      }

      // Get doctor's current location
      geo.Position position = await geo.Geolocator.getCurrentPosition(
        locationSettings: geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ), // Updated API
      );
      doctorLocation.value = position;

      // Use provided coordinates if available, otherwise geocode address
      if (latitude.validate().isNotEmpty && longitude.validate().isNotEmpty) {
        patientLocation.value = Point(
          coordinates: Position(longitude!.toDouble(), latitude!.toDouble()),
        );
      } else {
        // Geocode patient address
        List<Location> locations = await locationFromAddress(patientAddress);
        if (locations.isNotEmpty) {
          patientLocation.value = Point(
            coordinates: Position(
              locations.first.longitude,
              locations.first.latitude,
            ),
          );
        }
      }

      if (patientLocation.value == null) {
        errorMessage.value = locale.value.addressNotFound;
      }

      isLoading.value = false;
    } catch (e) {
      errorMessage.value = e.toString();
      isLoading.value = false;
    }
  }

  void onMapCreated(MapboxMap map) async {
    mapboxMap = map;

    // Create annotation manager
    pointAnnotationManager = await map.annotations
        .createPointAnnotationManager();

    // Add markers if locations are available
    if (doctorLocation.value != null && patientLocation.value != null) {
      await _addMarkers();
      await _fitCamera();
    }
  }

  Future<void> _addMarkers() async {
    if (pointAnnotationManager == null) return;

    var doctorPoint = Point(
      coordinates: Position(
        doctorLocation.value!.longitude,
        doctorLocation.value!.latitude,
      ),
    );

    await pointAnnotationManager?.create(
      PointAnnotationOptions(
        geometry: doctorPoint,
        iconOffset: [0.0, -10.0],
        iconSize: 1.0,
      ),
    );

    await pointAnnotationManager?.create(
      PointAnnotationOptions(
        geometry: patientLocation.value!,
        iconOffset: [0.0, -10.0],
        iconSize: 1.0,
      ),
    );
  }

  Future<void> _fitCamera() async {
    if (mapboxMap == null ||
        doctorLocation.value == null ||
        patientLocation.value == null) {
      return;
    }

    // Calculate center point
    double centerLat =
        (doctorLocation.value!.latitude +
            patientLocation.value!.coordinates.lat.toDouble()) /
        2;
    double centerLng =
        (doctorLocation.value!.longitude +
            patientLocation.value!.coordinates.lng.toDouble()) /
        2;

    await mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(centerLng, centerLat)),
        zoom: 12.0, // Safe default zoom level
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  Future<void> openInMapsApp() async {
    if (patientLocation.value == null) return;

    // Construct Google Maps URL (External)
    final lat = patientLocation.value!.coordinates.lat;
    final lng = patientLocation.value!.coordinates.lng;

    final googleMapsUrl =
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';

    try {
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        toast(locale.value.cannotOpenMaps);
      }
    } catch (e) {
      toast(locale.value.cannotOpenMaps);
    }
  }

  double? getDistanceInKm() {
    if (doctorLocation.value == null || patientLocation.value == null) {
      return null;
    }
    return geo.Geolocator.distanceBetween(
          doctorLocation.value!.latitude,
          doctorLocation.value!.longitude,
          patientLocation.value!.coordinates.lat.toDouble(),
          patientLocation.value!.coordinates.lng.toDouble(),
        ) /
        1000; // Convert to kilometers
  }
}

class MapRouteViewScreen extends StatelessWidget {
  final String patientAddress;
  final String patientName;
  final String? latitude;
  final String? longitude;

  const MapRouteViewScreen({
    super.key,
    required this.patientAddress,
    required this.patientName,
    this.latitude,
    this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      MapRouteViewController(
        patientAddress: patientAddress,
        patientName: patientName,
        latitude: latitude,
        longitude: longitude,
      ),
    );

    return AppScaffoldNew(
      appBartitleText: locale.value.routeToPatient,
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: appColorPrimary),
                16.height,
                Text(locale.value.loadingMap, style: primaryTextStyle()),
              ],
            ),
          );
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  16.height,
                  Text(locale.value.error, style: boldTextStyle(size: 18)),
                  8.height,
                  Text(
                    controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: secondaryTextStyle(),
                  ),
                  16.height,
                  AppButton(
                    text: locale.value.retry,
                    color: appColorPrimary,
                    onTap: () {
                      controller.initializeData();
                    },
                  ),
                ],
              ),
            ),
          );
        }

        if (controller.patientLocation.value == null) {
          return Center(
            child: Text(
              locale.value.unableToLoadMap,
              style: secondaryTextStyle(),
            ),
          );
        }

        return Stack(
          children: [
            MapWidget(
              key: const ValueKey("mapWidget"),
              styleUri: MapboxStyles.MAPBOX_STREETS,
              onMapCreated: controller.onMapCreated,
              cameraOptions: CameraOptions(
                center: Point(
                  coordinates: Position(
                    controller.doctorLocation.value!.longitude,
                    controller.doctorLocation.value!.latitude,
                  ),
                ),
                zoom: 14.0,
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: boxDecorationDefault(
                  color: context.cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: appColorPrimary),
                        8.width,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patientName,
                                style: boldTextStyle(size: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                patientAddress,
                                style: secondaryTextStyle(size: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (controller.getDistanceInKm() != null) ...[
                      8.height,
                      Row(
                        children: [
                          Icon(
                            Icons.social_distance,
                            size: 18,
                            color: iconColor,
                          ),
                          8.width,
                          Text(
                            '${locale.value.distance}: ${controller.getDistanceInKm()!.toStringAsFixed(2)} km',
                            style: secondaryTextStyle(size: 12),
                          ),
                        ],
                      ),
                    ],
                    16.height,
                    AppButton(
                      width: double.infinity,
                      text: locale.value.openInMapsApp,
                      color: appColorPrimary,
                      textStyle: boldTextStyle(color: white),
                      onTap: () {
                        controller.openInMapsApp();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
