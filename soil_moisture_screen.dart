import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'login.dart';

class SoilMoistureScreen extends StatefulWidget {
  final String username;

  SoilMoistureScreen({required this.username});

  @override
  _SoilMoistureScreenState createState() => _SoilMoistureScreenState();
}

class _SoilMoistureScreenState extends State<SoilMoistureScreen> {
  String soilMoisture = 'Loading...';
  bool isLoading = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    fetchSoilMoisture(); // Fetch initial soil moisture data
    // Schedule periodic data refresh every 15 seconds
    _timer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (!isLoading) {
        fetchSoilMoisture(); // Fetch soil moisture data periodically
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer to avoid memory leaks
    super.dispose();
  }

  Future<void> fetchSoilMoisture() async {
    // Fetch soil moisture data from the server
    final url = Uri.parse('https://iot-639m.onrender.com/data/latest');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        soilMoisture = data['soil_moisture'].toString();
      });
    } else {
      setState(() {
        soilMoisture = 'Error fetching data';
      });
    }
  }

  String getWateringRecommendation() {
    double? moisture = double.tryParse(soilMoisture);
    if (moisture != null) {
      if (moisture < 40.0) {
        return "Water needed soon!";
      } else if (moisture > 80.0) {
        return "Moisture level optimal.";
      } else {
        return "Monitor moisture in next few hours.";
      }
    } else {
      return "Moisture data unavailable.";
    }
  }

  Color _getTextColor() {
    final backgroundColor = Colors.black;
    final brightness = backgroundColor.computeLuminance();
    return brightness > 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Farm'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // Implement logout functionality
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/tomato.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.7),
              BlendMode.darken,
            ),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(),
              )
                  : Center(
                child: SfRadialGauge(
                  axes: <RadialAxis>[
                    RadialAxis(
                      minimum: 0.0,
                      maximum: 100.0,
                      ranges: <GaugeRange>[
                        GaugeRange(
                          startValue: 0.0,
                          endValue: 40.0,
                          color: Colors.red,
                        ),
                        GaugeRange(
                          startValue: 40.0,
                          endValue: 80.0,
                          color: Colors.yellow,
                        ),
                        GaugeRange(
                          startValue: 80.0,
                          endValue: 100.0,
                          color: Colors.red,
                        ),
                      ],
                      pointers: <GaugePointer>[
                        NeedlePointer(
                          value: double.tryParse(soilMoisture) ?? 0.0,
                        ),
                      ],
                      axisLabelStyle: GaugeTextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      axisLineStyle: AxisLineStyle(
                        thickness: 20,
                        color: Colors.white,
                      ),
                      majorTickStyle: MajorTickStyle(
                        length: 20,
                        thickness: 2,
                        color: Colors.white,
                      ),
                      minorTickStyle: MinorTickStyle(
                        length: 10,
                        thickness: 1,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: fetchSoilMoisture,
                child: Text('Refresh'),
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () async {
                  setState(() {
                    isLoading = true;
                  });
                  await fetchSoilMoisture();
                  setState(() {
                    isLoading = false;
                  });
                },
              ),
              Text(
                soilMoisture,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _getTextColor(),
                ),
              ),
              Text(
                getWateringRecommendation(),
                style: TextStyle(
                  fontSize: 16,
                  color: _getTextColor(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
        currentIndex: 0,
        selectedItemColor: Colors.blue,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => GraphScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AccountDetailsScreen(username: widget.username)),
            );
          }
        },
      ),
    );
  }
}

class AccountDetailsScreen extends StatefulWidget {
  final String username;

  AccountDetailsScreen({required this.username});

  @override
  _AccountDetailsScreenState createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  late Future<Map<String, dynamic>> _futureUserDetails;

  @override
  void initState() {
    super.initState();
    _futureUserDetails = _fetchUserDetails();
  }

  Future<Map<String, dynamic>> _fetchUserDetails() async {
    final url = Uri.parse('https://iot-639m.onrender.com/users/${widget.username}');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Details'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: _futureUserDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            Map<String, dynamic> userDetails = snapshot.data as Map<String, dynamic>;
            return ListView(
              padding: EdgeInsets.all(16.0),
              children: [
                ListTile(
                  title: Text('Name'),
                  subtitle: Text(userDetails['name']),
                ),
                ListTile(
                  title: Text('Email'),
                  subtitle: Text(userDetails['email']),
                ),
                ListTile(
                  title: Text('Address'),
                  subtitle: Text(userDetails['address']),
                ),
                ListTile(
                  title: Text('Contact'),
                  subtitle: Text(userDetails['contact']),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class GraphScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // Implement logout functionality
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: FutureBuilder(
            future: fetchHistoricalData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                List<DataPoint> dataPoints = snapshot.data as List<DataPoint>;
                return SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: SfCartesianChart(
                    primaryXAxis: DateTimeAxis(),
                    series: <CartesianSeries>[
                      LineSeries<DataPoint, DateTime>(
                        dataSource: dataPoints,
                        xValueMapper: (DataPoint data, _) => data.timestamp,
                        yValueMapper: (DataPoint data, _) => data.soilMoisture,
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Future<List<DataPoint>> fetchHistoricalData() async {
    final url = Uri.parse('https://iot-639m.onrender.com/data/historical');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      return responseData.map((data) => DataPoint.fromJson(data)).toList();
    } else {
      throw Exception('Failed to fetch historical data');
    }
  }
}

class DataPoint {
  final DateTime timestamp;
  final double soilMoisture;

  DataPoint({
    required this.timestamp,
    required this.soilMoisture,
  });

  factory DataPoint.fromJson(Map<String, dynamic> json) {
    return DataPoint(
      timestamp: DateTime.parse(json['timestamp']),
      soilMoisture: json['soil_moisture'].toDouble(),
    );
  }
}

