import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // استيراد المكتبة

class OsmMapScreen extends StatefulWidget {
  const OsmMapScreen({Key? key}) : super(key: key);

  @override
  State<OsmMapScreen> createState() => _OsmMapScreenState();
}

class _OsmMapScreenState extends State<OsmMapScreen> {
  final MapController _mapController = MapController(); // للتحكم في الخريطة
  LatLng _initialCenter = const LatLng(24.7136, 46.6753); // الرياض افتراضياً
  LatLng? _pickedLocation;
  bool _isLoading = true; // لعرض مؤشر تحميل أثناء جلب الموقع

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // جلب الموقع فور فتح الشاشة
  }

  // دالة لجلب الموقع الحالي
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. التحقق من تفعيل خدمة الموقع
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // الخدمة غير مفعلة، يمكنك إظهار رسالة للمستخدم
      setState(() => _isLoading = false);
      return;
    }

    // 2. التحقق من الأذونات
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoading = false);
      return;
    }

    // 3. جلب الموقع الحالي
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final currentLatLng = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _pickedLocation = currentLatLng; // وضع العلامة مكان المستخدم
          _initialCenter = currentLatLng;  // تحديث المركز
          _isLoading = false;
        });
        
        // تحريك الكاميرا لموقع المستخدم
        _mapController.move(currentLatLng, 15.0);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error getting location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("حدد موقعك"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          // زر لإعادة تحديد الموقع الحالي يدوياً
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController, // ربط المتحكم
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 15.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _pickedLocation = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.yousiffares.linyora',
              ),
              if (_pickedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pickedLocation!,
                      width: 80,
                      height: 80,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          // مؤشر التحميل
          if (_isLoading)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text("جاري تحديد موقعك..."),
                    ],
                  ),
                ),
              ),
            ),

          if (_pickedLocation != null && !_isLoading)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(_pickedLocation);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF105C6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("تأكيد الموقع", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}