import 'package:flutter/material.dart';
import 'package:flashy_tab_bar2/flashy_tab_bar2.dart';
import './Screens/pantry.dart' as firstTab;
import './Screens/home.dart' as secondTab;
import 'Screens/favorite.dart' as thirdTab;
import './Screens/profile.dart' as fourthTab;
import './Screens/cart.dart' as fifthTab;
import './dailog/alert.dart' as alert;

class HomeView extends StatefulWidget {
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeView> {
  int _selectedIndex = 1; // Track the selected tab

  @override
  Widget build(BuildContext ctx) {
     final List<Widget> _screens = [
    _buildTabNavigator(firstTab.Pantry()),
    _buildTabNavigator(secondTab.Home()),
    _buildTabNavigator(thirdTab.Favorite()),
    _buildTabNavigator(fifthTab.Cart()),
    _buildTabNavigator(fourthTab.Profile()),
  ];
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Smart Chef    "),
            Image(
              image: AssetImage('./assets/icons/applogo.png'),
              fit: BoxFit.contain,
              height: 35,
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex, // Keeps state of all screens
        children: _screens,
      ),
      bottomNavigationBar: FlashyTabBar(
        selectedIndex: _selectedIndex,
        showElevation: true,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          FlashyTabBarItem(icon: Icon(Icons.food_bank), title: Text('Pantry')),
          FlashyTabBarItem(icon: Icon(Icons.home), title: Text('Home')),
          FlashyTabBarItem(icon: Icon(Icons.bookmark), title: Text('Favorites')),
          FlashyTabBarItem(icon: Icon(Icons.shopping_cart), title: Text('Cart')), 
          FlashyTabBarItem(icon: Icon(Icons.account_circle_outlined), title: Text('Profile')),
        ],
      ),
      floatingActionButton: FloatingActionButton(
  backgroundColor: Colors.red,
  onPressed: () {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert.RecipeAlert(); 
      },
    );
  },
  child: const Icon(Icons.add),
),
floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
  Widget _buildTabNavigator(Widget child) {
  return Navigator(
    onGenerateRoute: (settings) => MaterialPageRoute(builder: (_) => child),
  );
}
}
