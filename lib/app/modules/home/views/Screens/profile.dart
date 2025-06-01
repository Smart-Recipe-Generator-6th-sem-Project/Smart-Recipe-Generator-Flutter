import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:babstrap_settings_screen/babstrap_settings_screen.dart';
import 'package:smart_recipe_generator_flutter/app/modules/Authenticate/views/authenticate_view.dart';
import 'package:smart_recipe_generator_flutter/app/modules/home/views/Screens/CookedHistoryPage.dart';

class Profile extends StatefulWidget {
  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String userName = "Guest";
  String? storedToken = GetStorage().read('auth_token');
  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {

    final String apiUrl = "http://127.0.0.1:4000/users/me";
    final url = Uri.parse(apiUrl);
    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $storedToken",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      setState(() {
        userName = jsonResponse['data']['name'];
      });
    } else {
      print("Failed to fetch data: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = box.read('isDarkMode') ?? false;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: [
            // User card
            BigUserCard(
              backgroundColor: const Color.fromARGB(255, 110, 110, 110)!, // Light grey
              userName: userName,
              userProfilePic: AssetImage("assets/introduction_animation/introduction_image.png"),
              cardActionWidget: SettingsItem(
                icons: Icons.edit,
                iconStyle: IconStyle(
                  withBackground: true,
                  borderRadius: 50,
                  backgroundColor: Colors.yellow[600],
                ),
                title: "Modify",
                subtitle: "Tap to change your data",
                onTap: () {
                  print("Modify tapped");
                },
              ),
            ),

            SettingsGroup(
              backgroundColor: Colors.grey[200]!, // Light grey
              items: [
                if (storedToken != null)
                  SettingsItem(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CookedHistoryPage(),
                        ),
                      );
                    },
                    icons: Icons.history,
                    title: "My Cooked History",
                    subtitle: "See the recipes you've cooked till now.",
                  ),

                SettingsItem(
                  onTap: () {
                    setState(() {
                      isDarkMode = !isDarkMode;
                      box.write('isDarkMode', isDarkMode);
                      Get.changeThemeMode(isDarkMode ? ThemeMode.dark : ThemeMode.light);
                    });
                  },
                  icons: Icons.dark_mode_rounded,
                  iconStyle: IconStyle(
                    iconsColor: Colors.white,
                    withBackground: true,
                    backgroundColor: Colors.black,
                  ),
                  title: 'Dark mode',
                  subtitle: isDarkMode ? "On" : "Off",
                  trailing: Switch.adaptive(
                    value: isDarkMode,
                    onChanged: (value) {
                      setState(() {
                        isDarkMode = value;
                        box.write('isDarkMode', value);
                        Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                      });
                    },
                  ),
                ),
                SettingsItem(
                  onTap: () => _showAboutDialog(context),
                  icons: Icons.info_rounded,
                  iconStyle: IconStyle(backgroundColor: Colors.purple),
                  title: 'About',
                  subtitle: "Learn more about Smart Chef App",
                ),
              ],
            ),

            SettingsGroup(
              settingsGroupTitle: "Account",
              backgroundColor: Colors.grey[200]!, // Light grey
              items: [
                SettingsItem(
                  onTap: () => _showSignOutDialog(context),
                  icons: Icons.exit_to_app_rounded,
                  title: "Sign Out",
                ),
                SettingsItem(
                  onTap: () {},
                  icons: CupertinoIcons.delete_solid,
                  title: "Delete account",
                  titleStyle: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Sign Out"),
          content: Text("Are you sure you want to sign out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _logout(context);
              },
              child: Text("Yes", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    if (storedToken == null) {
      print("No token found, redirecting to login...");
      _navigateToLogin(context);
      return;
    }

    final url = Uri.parse("http://127.0.0.1:4000/logout");

    final response = await http.delete(
      url,
      headers: {
        "Authorization": "Bearer $storedToken",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      print("Logout successful");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Logged out successfully"),
          backgroundColor: Colors.green,
        ),
      );
      GetStorage().remove('auth_token');
      _navigateToLogin(context);
    } else {
      print("Logout failed: ${response.statusCode}");
    }
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthenticateView()),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("About Smart Chef"),
          content: const Text(
            "Smart Chef is an intelligent recipe suggestion app.\n\n"
            "It helps you find recipes based on what you already have in your pantry, "
            "helps reduce food waste, and improves your cooking experience with smart suggestions.\n"
            "B & N 6th Sem Project",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}
