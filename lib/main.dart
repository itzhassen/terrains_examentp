import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Land Measure App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LandMeasureScreen(),
    );
  }
}

class LandMeasureScreen extends StatefulWidget {
  @override
  _LandMeasureScreenState createState() => _LandMeasureScreenState();
}

class _LandMeasureScreenState extends State<LandMeasureScreen> {
  List<Terrain> terrains = [];
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse('http://localhost:3000/terrains'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      List<Terrain> fetchedTerrains = data.map((json) => Terrain.fromJson(json)).toList();

      setState(() {
        terrains = fetchedTerrains;
      });
    } else {
      print('Erreur lors de la récupération des terrains: ${response.statusCode}');
    }
  }

  void editTerrain(Terrain terrain) {
    titleController.text = terrain.title;
    descriptionController.text = terrain.description;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Modifier le terrain'),
          content: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Titre'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  terrain.title = titleController.text;
                  terrain.description = descriptionController.text;
                });

                // You can also send an API request to update the data on the server
                // Uncomment the following line if you have an API for updating terrain
                // updateTerrainOnServer(terrain);

                Navigator.pop(context);
              },
              child: Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteTerrain(Terrain terrain) async {
    final response = await http.delete(Uri.parse('http://localhost:3000/terrains/${terrain.id}'));

    if (response.statusCode == 200) {
      setState(() {
        terrains.remove(terrain);
      });
    } else {
      print('Erreur lors de la suppression du terrain: ${response.statusCode}');
    }
  }

  void navigateToTerrainDetails(Terrain terrain) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TerrainDetailsPage(terrain: terrain),
      ),
    );
  }

  void addNewTerrain() async {
    TextEditingController newTitleController = TextEditingController();
    TextEditingController newDescriptionController = TextEditingController();
    TextEditingController newPhotoController = TextEditingController();
    TextEditingController newLatitudeController = TextEditingController();
    TextEditingController newLongitudeController = TextEditingController();

    // Function to launch the gallery and choose a picture
    Future<void> _pickImage() async {
      final picker = ImagePicker();
      final pickedFile = await picker.getImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        newPhotoController.text = pickedFile.path;
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Nouveau Terrain'),
          content: Column(
            children: [
              TextField(
                controller: newTitleController,
                decoration: InputDecoration(labelText: 'Titre'),
              ),
              TextField(
                controller: newDescriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: newLatitudeController,
                      decoration: InputDecoration(labelText: 'Latitude'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: newLongitudeController,
                      decoration: InputDecoration(labelText: 'Longitude'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  onPressed: () async {
                    await _pickImage(); // Launch gallery and choose a picture
                  },
                  child: Text('Choisir une photo'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Piquet newPiquet = Piquet(
                  latitude: double.parse(newLatitudeController.text),
                  longitude: double.parse(newLongitudeController.text),
                );

                Terrain newTerrain = Terrain(
                  id: terrains.length + 1,
                  title: newTitleController.text,
                  description: newDescriptionController.text,
                  photo: newPhotoController.text,
                  piquets: [newPiquet],
                );

                setState(() {
                  terrains.add(newTerrain);
                });

                // You can also send an API request to add the new terrain on the server
                // Uncomment the following line if you have an API for adding terrain
                // await http.post(
                //   Uri.parse('http://localhost:3000/terrains'),
                //   headers: {'Content-Type': 'application/json'},
                //   body: json.encode(newTerrain.toJson()),
                // );

                Navigator.pop(context);
              },
              child: Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  Future<String> getImage() async {
    return ''; // Replace with actual image selection implementation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mesure des Terrains'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: addNewTerrain,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: terrains.length,
        itemBuilder: (context, index) {
          Terrain terrain = terrains[index];
          return ListTile(
            title: Text(terrain.title),
            subtitle: Text(terrain.description),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => editTerrain(terrain),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => deleteTerrain(terrain),
                ),
              ],
            ),
            onTap: () => navigateToTerrainDetails(terrain),
          );
        },
      ),
    );
  }
}

class TerrainDetailsPage extends StatelessWidget {
  final Terrain terrain;

  TerrainDetailsPage({required this.terrain});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(terrain.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${terrain.description}'),
            SizedBox(height: 16),
            Text('Photo: ${terrain.photo}'),
            SizedBox(height: 16),
            Text('Piquets:'),
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(33.79825963780426, 10.88317931060649),
                  zoom: 10.0,
                ),
                layers: [
                  TileLayerOptions(
                    urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: ['a', 'b', 'c'],
                  ),
                  MarkerLayerOptions(
                    markers: terrain.piquets
                        .map(
                          (piquet) => Marker(
                        width: 30.0,
                        height: 30.0,
                        point: LatLng(piquet.latitude, piquet.longitude),
                        builder: (context) => Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Terrain {
  final int id;
  String title;
  String description;
  final String photo;
  final List<Piquet> piquets;

  Terrain({
    required this.id,
    required this.title,
    required this.description,
    required this.photo,
    required this.piquets,
  });

  factory Terrain.fromJson(Map<String, dynamic> json) {
    List<dynamic> piquetsJson = json['piquets'];
    List<Piquet> parsedPiquets = piquetsJson.map((piquetJson) => Piquet.fromJson(piquetJson)).toList();

    return Terrain(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      photo: json['photo'],
      piquets: parsedPiquets,
    );
  }
}

class Piquet {
  final double longitude;
  final double latitude;

  Piquet({
    required this.longitude,
    required this.latitude,
  });

  factory Piquet.fromJson(Map<String, dynamic> json) {
    return Piquet(
      longitude: json['longitude'],
      latitude: json['latitude'],
    );
  }
}
