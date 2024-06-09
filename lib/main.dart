import 'package:clothes_app/admin/admin_upload_items.dart';
import 'package:clothes_app/users/fragments/dashboard_of_fragments.dart';
import 'package:clothes_app/users/userPreferences/user_preferences.dart';
import 'package:flutter/material.dart';
 import 'package:get/get.dart';

void main()
{
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Clothes App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: FutureBuilder(
        future: RememberUserPrefs.readUserInfo(),
        builder: (context, dataSnapShot)
        {
          if(dataSnapShot.data == null)
          {
          //  return const LoginScreen();
          return AdminUploadItemsScreen();
          }
          else
          {
            return DashboardOfFragments();
          }
        },
      ),
    );
  }
}


