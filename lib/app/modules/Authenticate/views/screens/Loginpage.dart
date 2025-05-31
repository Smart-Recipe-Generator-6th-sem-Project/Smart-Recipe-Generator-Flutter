import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:smart_recipe_generator_flutter/app/modules/home/views/home_view.dart';
import 'package:smart_recipe_generator_flutter/app/modules/onboarding/views/introduction_animation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});
  final PageController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false; // For disabling button while making request
  String? _emailError;
  String? _passError;
  final box = GetStorage();

  Future<void> _loginUser() async {
    setState(() {
      _emailError =
          _emailController.text.trim().isEmpty
              ? "Please enter your email"
              : null;
      _passError =
          _passController.text.trim().isEmpty
              ? "Please enter your password"
              : null;
    });

    if (_emailError != null || _passError != null) {
      return; // Stop if there are frontend validation errors
    }

    final String apiUrl = "http://127.0.0.1:4000/login";
    final Map<String, dynamic> loginData = {
      "user": {
        "email": _emailController.text.trim(),
        "password": _passController.text.trim(),
      },
    };

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(loginData),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Login success
        final String token = responseData["token"];

        // if (token != null) {
          // Store the token securely using SharedPreferences
          // pref.SharedPreferences prefs = await pref.SharedPreferences.getInstance();
          // await prefs.setString('auth_token', token);

          box.write('auth_token', token);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Login successful"),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeView()),
          );
        // } else {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     const SnackBar(
        //       content: Text("Login Failed due to token failure."),
        //       backgroundColor: Colors.red,
        //     ),
        //   );
        // }
      } else {
        // Display backend error message
        String errorMessage = "An error occurred. Please try again.";
        if (responseData.containsKey("status") && responseData["status"]["message"] != null) {
          errorMessage = responseData["status"]["message"];
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => IntroductionAnimationScreen(startAtEnd: true)),
            );
          },
        ),
        title: Text("Login Page"),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                "assets/introduction_animation/boywithsauce.png",
                width: 258,
                height: 237,
              ),
              const SizedBox(height: 18),
              const Text(
                'Log In',
                style: TextStyle(
                  color: Color(0xFF755DC1),
                  fontSize: 27,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 30),

              // Email Input Field
               _buildTextField(
                _emailController,
                "Email",
                "Enter your email",
                _emailError,
              ),
              _buildTextField(
                _passController,
                "Password",
                "Enter your password",
                _passError,
                obscureText: true,
              ),

              // Sign In Button
              SizedBox(
                width: 329,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _loginUser, // Disable button while loading
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9F7BFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Log In',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 15),

              // Sign Up Option
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Don’t have an account?',
                    style: TextStyle(
                      color: Color(0xFF837E93),
                      fontSize: 13,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 5),
                  InkWell(
                    onTap: () {
                      widget.controller.animateToPage(1,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease);
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Color(0xFF755DC1),
                        fontSize: 13,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Forgot Password
              InkWell(
                onTap: () {
                  // TODO: Implement Forgot Password functionality
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Color(0xFF755DC1),
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // OR Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Color(0xFF837E93))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Or log in with',
                      style: TextStyle(
                        color: Color(0xFF837E93),
                        fontSize: 13,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Color(0xFF837E93))),
                ],
              ),
              const SizedBox(height: 15),

              // Login with Google Button
              SizedBox(
                width: 329,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement Google Login logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF837E93)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Image.asset(
                    'assets/icons/google.png', // Ensure you have this image in assets
                    width: 24,
                    height: 24,
                  ),
                  label: const Text(
                    'Log in with Google',
                    style: TextStyle(
                      color: Color(0xFF393939),
                      fontSize: 15,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    String? error, {
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 56,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            obscureText: obscureText,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF837E93),
                fontSize: 10,
              ),
              labelStyle: const TextStyle(
                color: Color(0xFF755DC1),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(width: 1, color: Color(0xFF837E93)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(width: 1, color: Color(0xFF9F7BFF)),
              ),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 12),
            child: Text(
              error,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        const SizedBox(height: 17),
      ],
    );
  }
}
