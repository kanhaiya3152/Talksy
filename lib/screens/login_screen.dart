import 'package:chat_app/screens/chat_screen.dart';
import 'package:chat_app/screens/home_screen.dart';
import 'package:chat_app/screens/signup_screen.dart';
import 'package:chat_app/widgets/bottom_navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String password = "";
  String email = "";
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  final _formKey = GlobalKey<FormState>();

  Future<void> userLogin() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text("Login successfully"),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (ctx) => BottomNavigation(),
        ),
      );
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            top: screenHeight * 0.138,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  child: Image.asset(
                    "assets/text.png",
                    height: screenHeight * 0.2,
                    width: screenWidth * 0.5,
                  ),
                ),
                SizedBox(
                  height: screenHeight * 0.05,
                ),
                TextFormField(
                  controller: _emailController,
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !value.contains("@")) {
                      return "Please enter valid email";
                    }
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "Enter your email",
                    prefixIcon: Icon(Icons.email_outlined),
                    focusedBorder: OutlineInputBorder(
                      borderSide: Divider.createBorderSide(context),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: Divider.createBorderSide(context),
                    ),
                    filled: true,
                    contentPadding: const EdgeInsets.all(8),
                    border: OutlineInputBorder(
                      borderSide: Divider.createBorderSide(context),
                    ),
                  ),
                ),
                SizedBox(
                  height: screenHeight * 0.02,
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
                      borderSide: Divider.createBorderSide(context),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: Divider.createBorderSide(context),
                    ),
                    filled: true,
                    contentPadding: const EdgeInsets.all(8),
                    border: OutlineInputBorder(
                      borderSide: Divider.createBorderSide(context),
                    ),
                  ),
                ),
                SizedBox(
                  height: screenHeight * 0.03,
                ),
                GestureDetector(
                  onTap: () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        email = _emailController.text;
                        password = _passwordController.text;
                      });
                    }
                    userLogin();
                  },
                  child: Container(
                    height: screenHeight * 0.058,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isLoading
                        ? Center(
                            child: SizedBox(
                              height: screenHeight * 0.02,
                              width: screenHeight * 0.02,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              "Login",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: screenHeight * 0.018,
                              ),
                            ),
                          ),
                  ),
                ),
                SizedBox(
                  height: screenHeight * 0.05,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account ?",
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (ctx) => SignupScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                          color: Color(0XFF3797EF),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}