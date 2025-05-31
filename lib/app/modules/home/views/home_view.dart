import 'package:flutter/material.dart';
import 'package:flashy_tab_bar2/flashy_tab_bar2.dart';
import 'package:get_storage/get_storage.dart';
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
  int _selectedIndex = 1;
  String?
  storedToken; // Assume this gets set somewhere (e.g. from secure storage)

  @override
  void initState() {
    super.initState();
    // Simulate getting token, replace this with your actual logic
    // Example: SharedPreferences or SecureStorage
    storedToken = null; // or your actual token-fetching logic
  }

  @override
  Widget build(BuildContext ctx) {
    final List<Widget> _screens = [
      _buildTabNavigator(firstTab.Pantry()),
      _buildTabNavigator(secondTab.Home()),
      if (storedToken != null) _buildTabNavigator(thirdTab.Favorite()),
      if (storedToken != null) _buildTabNavigator(fifthTab.Cart()),
      _buildTabNavigator(fourthTab.Profile()),
    ];

    final List<FlashyTabBarItem> tabItems = [
      FlashyTabBarItem(icon: Icon(Icons.food_bank), title: Text('Pantry')),
      FlashyTabBarItem(icon: Icon(Icons.home), title: Text('Home')),
      if (storedToken != null)
        FlashyTabBarItem(icon: Icon(Icons.bookmark), title: Text('Favorites')),
      if (storedToken != null)
        FlashyTabBarItem(icon: Icon(Icons.shopping_cart), title: Text('Cart')),
      FlashyTabBarItem(
        icon: Icon(Icons.account_circle_outlined),
        title: Text('Profile'),
      ),
    ];

    // Ensure selectedIndex stays within the valid tab range
    if (_selectedIndex >= tabItems.length) _selectedIndex = 0;

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
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: FlashyTabBar(
        selectedIndex: _selectedIndex,
        showElevation: true,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: tabItems,
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
