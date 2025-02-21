import 'package:chat_app/model/users.dart';
import 'package:chat_app/screens/home_screen.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<SignupScreen> {
  String username = "";
  String email = "";
  String password = "";
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
  }

  final _formKey = GlobalKey<FormState>();

  Future<void> userSignup({
    required String username,
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      setState(() {
        _isLoading = true;
      });
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      String userId = userCredential.user!.uid;

      Users user = Users(uid: userId, username: username, email: email);

      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .set(user.toJson());

      setState(() {
        _isLoading = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.green,
          content: Text('Registered Successfully'),
        ));

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (ctx) => HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      print(e.code);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.code)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(left: 20, right: 20, top: 150),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Form(
                key: _formKey,
                child: Container(
                  child: Image.asset(
                    "assets/text.png",
                    height: 140,
                    width: 200,
                  ),
                ),
              ),
              SizedBox(
                height: 50,
              ),
              TextFormField(
                controller: _usernameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your name";
                  }
                  return null;
                },
                keyboardType: TextInputType.text,
                obscureText: false,
                decoration: InputDecoration(
                    hintText: "Enter your name",
                    prefixIcon: Icon(Icons.person),
                    focusedBorder: OutlineInputBorder(
                        borderSide: Divider.createBorderSide(context)),
                    enabledBorder: OutlineInputBorder(
                        borderSide: Divider.createBorderSide(context)),
                    filled: true,
                    contentPadding: const EdgeInsets.all(8),
                    border: OutlineInputBorder(
                        borderSide: Divider.createBorderSide(context))),
              ),
              SizedBox(
                height: 20,
              ),
              TextFormField(
                controller: _emailController,
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains("@")) {
                    return "Please enter valid email";
                  }
                  return null;
                },
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                    hintText: "Enter your email",
                    // fillColor: Colors.black54,
                    prefixIcon: Icon(Icons.email_outlined),
                    // hintStyle: TextStyle(color: Colors.white),
                    focusedBorder: OutlineInputBorder(
                        borderSide: Divider.createBorderSide(context)),
                    enabledBorder: OutlineInputBorder(
                        borderSide: Divider.createBorderSide(context)),
                    filled: true,
                    contentPadding: const EdgeInsets.all(8),
                    border: OutlineInputBorder(
                        borderSide: Divider.createBorderSide(context))),
              ),
              SizedBox(
                height: 20,
              ),
              TextFormField(
                controller: _passwordController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter password";
                  }
                  return null;
                },
                keyboardType: TextInputType.text,
                obscureText: true,
                decoration: InputDecoration(
                    hintText: "Enter your password",
                    prefixIcon: Icon(Icons.password_rounded),
                    focusedBorder: OutlineInputBorder(
                        borderSide: Divider.createBorderSide(context)),
                    enabledBorder: OutlineInputBorder(
                        borderSide: Divider.createBorderSide(context)),
                    filled: true,
                    contentPadding: const EdgeInsets.all(8),
                    border: OutlineInputBorder(
                        borderSide: Divider.createBorderSide(context))),
              ),
              SizedBox(
                height: 30,
              ),
              GestureDetector(
                onTap: () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      username = _usernameController.text;
                      email = _emailController.text;
                      password = _passwordController.text;
                    });
                  }
                  userSignup(
                      username: username,
                      email: email,
                      password: password,
                      context: context);
                },
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                      child: Text(
                    "Sign up",
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  )),
                ),
              ),
              SizedBox(
                height: 50,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account !",
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (ctx) => LoginScreen(),
                        ),
                      );
                    },
                    child: const Text('Login',
                        style:
                            TextStyle(color: Color(0XFF3797EF), fontSize: 14)),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
