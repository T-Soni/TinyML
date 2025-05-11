import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileSetUp extends StatefulWidget {
  const ProfileSetUp({super.key});

  @override
  State<ProfileSetUp> createState() => _ProfileSetUPState();
}

class _ProfileSetUPState extends State<ProfileSetUp> {
  TextEditingController nameController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  TextEditingController weightController = TextEditingController();

  final formkey = GlobalKey<FormState>();

  late String name, age, height, weight;

  
    Future<void> saveDetails() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();

  await prefs.setString('name', nameController.text);
  await prefs.setString('age', ageController.text);
  await prefs.setString('height', heightController.text);
  await prefs.setString('weight', weightController.text);
  print("values stored in shared prefs");
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(255, 236, 219, 1.0),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(15.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "ENTER USER DETAILS",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    Material(
                      color: Colors.white,
                      elevation: 12,
                      borderRadius: BorderRadius.circular(15),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            SizedBox(height: 20),
                            Form(
                              key: formkey,
                              child: Column(
                                children: [
                                  _buildTextField("Name", nameController),
                                  _buildTextField("Age", ageController),
                                  _buildTextField(
                                      "Height (ft)", heightController),
                                  _buildTextField(
                                      "Weight (kg)", weightController),
                                ],
                              ),
                            ),
                            SizedBox(height: 20), // Space for button
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 25,
            right: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 30,
              child: Material(
                shape: CircleBorder(),
                color: Colors.white,
                elevation: 4,
                child: IconButton(
                  onPressed: () async{
                    if(formkey.currentState!.validate()){
                      print("form validated");
                      saveDetails();
                    Navigator.pushNamed(context, 'home');
                    }
                    
                  },
                  icon: Icon(Icons.arrow_forward),
                  iconSize: 28,
                  color: Colors.black,
                  tooltip: "Set up Profile",
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'this is a required field';
          } else {
            return null;
          }
        },
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          // hintText: hint,
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: Color.fromRGBO(96, 181, 255, 1), width: 2),
          ),
        ),
        keyboardType:
            (label == 'Name') ? TextInputType.text : TextInputType.number,
      ),
    );
  }
}
