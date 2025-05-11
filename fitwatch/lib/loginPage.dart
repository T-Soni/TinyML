// import 'package:flutter/material.dart';

// class Login extends StatefulWidget {
//   const Login({super.key});

//   @override
//   State<Login> createState() => _LoginState();
// }

// class _LoginState extends State<Login> {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//         decoration: BoxDecoration(
//             image: DecorationImage(
//                 image: AssetImage('assets/login.png'), fit: BoxFit.cover)),
//         child: Scaffold(
//           backgroundColor: Colors.transparent,
//           body: Stack(
//             children: [
//               Container(
//                 padding: EdgeInsets.only(left: 40, top: 130),
//                 child: Text(
//                   'Welcome\nBack',
//                   style: TextStyle(color: Colors.white, fontSize: 33),
//                 ),
//               ),
//               SingleChildScrollView(
//                 child: Container(
//                   padding: EdgeInsets.only(
//                       top: MediaQuery.of(context).size.height * 0.5,
//                       right: 35,
//                       left: 35),
//                   child: Column(
//                     children: [
//                       TextField(
//                         decoration: InputDecoration(
//                             hintText: 'Email',
//                             fillColor: Colors.grey.shade100,
//                             filled: true,
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             )),
//                       ),
//                       SizedBox(
//                         height: 30,
//                       ),
//                       TextField(
//                         obscureText: true,
//                         decoration: InputDecoration(
//                             hintText: 'Password',
//                             fillColor: Colors.grey.shade100,
//                             filled: true,
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             )),
//                       ),
//                       SizedBox(height: 30,),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text("Sign In",
//                             style: TextStyle(
//                               color: Color(0xff4c505b),
//                               fontSize: 27, fontWeight: FontWeight.w700
//                           ),),
//                           CircleAvatar(
//                             radius: 30,
//                             backgroundColor: Color(0xff4c505b),
//                             child: IconButton(
//                               color: Colors.white,
//                               onPressed: (){
//                                 Navigator.pushNamed(context, 'profile');
//                               },
//                               icon: Icon(Icons.arrow_forward)),
//                           )
//                         ],
//                       ),
//                       SizedBox(height: 30,),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           TextButton(
//                             onPressed: (){
//                               Navigator.pushNamed(context, 'register');
//                             }, 
//                             child: Text(
//                               'Sign Up',
//                               style: TextStyle(
//                                 decoration: TextDecoration.underline,
//                                 fontSize: 18,
//                                 color: Color(0xff4c505b),
//                               ),
//                             )),
//                             TextButton(
//                             onPressed: (){}, 
//                             child: Text(
//                               'Forgot Password',
//                               style: TextStyle(
//                                 decoration: TextDecoration.underline,
//                                 fontSize: 18,
//                                 color: Color(0xff4c505b),
//                               ),
//                             ))
//                         ],
//                       )
//                     ],
//                   ),
//                 ),
//               )
//             ],
//           ),
//         ));
//   }
// }

import 'package:flutter/material.dart';
import 'package:fitwatch/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:shared_preferences/';

class Login extends StatefulWidget{
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login>
{
  final uidController = TextEditingController();
  late String uid;
  
  @override
  void dispose() {
    uidController.dispose();
    super.dispose();
  }

  _saveUid() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('uid', uid);
  }

  bool verifyUid(){
    uid = uidController.text;
    uid = uid.trim();
    if(uid == "test1234"){
      _saveUid();
      return true;
    }
      
    return false;
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Color.fromRGBO(175, 221, 255, 1.0),
      body: Container(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Stack(
            children: [
              Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("NEW USER LOGIN",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold),),
                  SizedBox(height: 20,),
                  TextField(
                    controller: uidController,
                    decoration: InputDecoration(
                      hintText: "UID",
                      fillColor: Colors.white,
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        // borderSide: BorderSide(color: Color.fromRGBO(255, 236, 219, 1), width: 2)
                        borderSide: BorderSide(color: Colors.grey, width: 2)
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Color.fromRGBO(96, 181, 255, 1), width: 2)
                      )
                      
                    ),
                  ),
                  
                  
              ],
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
                    onPressed: (){
                      if (verifyUid()){
                        Navigator.pushNamed(context, 'profileSetUp');
                     
                      //   showDialog(
                      //   context: context,
                      //   builder: (context)  {
                      //     return AlertDialog(
                      //       content: Text(uidController.text),
                      //     );
                      //   }
                      // );
                      }
                      else {
                        showDialog(
                          context: context, 
                          builder: (context){
                            return AlertDialog(
                              content: Text("Please enter correct uid"),
                            );
                          }
                          );
                      }
                     
                    }, 
                    icon: Icon(Icons.arrow_forward),
                    iconSize: 28,
                    color: Color.fromRGBO(96, 181, 255, 1),
                    tooltip: "Set up Profile",
                    ),
                ),
              ),
              )
            ]
          ),
        ),
      ),
    );
  }
}