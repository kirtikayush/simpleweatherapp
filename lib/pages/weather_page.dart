import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:lottie/lottie.dart';
import 'package:weather_app/services/weather_service.dart';
import '../models/weather_model.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  ///API KEY
  final _weatherService = WeatherService(dotenv.env['WEATHER_API_KEY'] ?? '');
  Weather? _weather;

  /// FETCH WEATHER
  _fetchWeather() async {
    ///get current city
    String cityName = await _weatherService.getCurrentCity();

    /// get weather
    try {
      // Step 1: Get user’s current coordinates
      geolocator.Position position = await geolocator
          .Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.high,
      );

      double lat = position.latitude;
      double lon = position.longitude;

      // Step 2: Reverse geocode to get city name
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      String city = placemarks.first.locality ?? 'Unknown';

      // Step 3: Fetch weather using lat/lon
      final weather = await _weatherService.getWeatherByLocation(lat, lon);

      // Step 4: Save weather + city name to display
      setState(() {
        _weather = Weather(
          cityName: city,
          temperature: weather.temperature,
          mainCondition: weather.mainCondition,
          // Add other required fields if your Weather model has more
        );
      });
    } catch (e) {
      print('Error fetching location or weather: $e');
    }
  }

  /// WEATHER ANIMATION
  String getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) return 'images/sunny.json';
    switch (mainCondition.toLowerCase()) {
      case 'clouds':
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return 'images/cloudy.json';
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        return 'images/rainy.json';
      case 'thunderstorm':
        return 'images/rainthunder.json';
      case 'clear':
        return 'images/sunny.json';
      default:
        return 'images/sunny.json';
    }
  }

  ///initial state
  @override
  void initState() {
    super.initState();

    ///fetch weather on startup
    _fetchWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchWeather();
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(height: 140),
                  Icon(Icons.pin_drop, color: Colors.white, size: 40),

                  ///cityname
                  Text(
                    _weather?.cityName ?? 'Loading name',
                    style: TextStyle(
                      fontFamily: 'test1',
                      fontSize: 35,
                      color: Colors.white,
                    ),
                  ),
                  Spacer(),

                  //animation
                  Lottie.asset(getWeatherAnimation(_weather?.mainCondition)),

                  Text(
                    _weather != null
                        ? _weather!.mainCondition
                        : "Loading weather",
                    style: TextStyle(
                      fontFamily: 'test1',
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  Spacer(),

                  ///temperature
                  Text(
                    _weather != null
                        ? '${_weather!.temperature.round()}°C'
                        : 'Loading temperature',
                    style: TextStyle(
                      fontFamily: 'test1',
                      fontSize: 40,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
