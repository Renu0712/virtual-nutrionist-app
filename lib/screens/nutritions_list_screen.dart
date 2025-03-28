import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/nutrition_model.dart';
import '../services/api_service.dart';
import '../widgets/nav_drawer.dart';
import 'nutrition_chat_screen.dart';
import 'nutrition_edit_screen.dart';
import 'nutrition_entry_screen.dart';
import 'view_nutrition_screen.dart';

class NutritionListScreen extends StatefulWidget {
  const NutritionListScreen({super.key});

  @override
  State<NutritionListScreen> createState() => _NutritionListScreenState();
}

class _NutritionListScreenState extends State<NutritionListScreen> {
  final List<NutritionModel> _nutritionEntries = [];
  late final String userId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  _checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId').toString();
    await _loadNutritionsList();
  }

  Future<void> _loadNutritionsList() async {
    setState(() {
      _isLoading = true;
    });
    var apiResponse = await ApiService.get('nutritions/$userId');
    if (apiResponse.statusCode >= 200 && apiResponse.statusCode < 300) {
      final responseData = jsonDecode(apiResponse.body);
      setState(() {
        _nutritionEntries.clear();
        for (var nutrition in responseData) {
          if (nutrition['message'] == null) {
            _nutritionEntries.add(NutritionModel.fromJson(nutrition));
          }
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      final responseData = jsonDecode(apiResponse.body);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(responseData["message"])));
    }
  }

  Future<void> _deleteNutrition(String nutritionId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await ApiService.delete('nutrition/$nutritionId');
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Nutrition plan deleted successfully: $nutritionId');
        }
        setState(() {
          _isLoading = false;
        });
        _loadNutritionsList();
      } else {
        throw Exception('Failed to delete nutrition plan');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting nutrition plan: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete nutrition plan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => NutritionChatScreen()),
              );
            },
          ),
        ],

        title: const Text('Nutrition Plans'),
      ),
      drawer: const NavDrawer(selectedIndex: 2),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _nutritionEntries.length,
                itemBuilder: (context, index) {
                  final nutrition = _nutritionEntries[index];
                  DateTime dateTime =
                      DateTime.parse(nutrition.createdAt).toLocal();
                  var format = DateFormat('dd MMM, yyyy hh:MM a');
                  String formattedDate = format.format(
                    dateTime.toUtc().add(const Duration(hours: -8)),
                  );
                  return ListTile(
                    title: Text(nutrition.title),
                    subtitle: Text(formattedDate),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (context) => ViewNutritionScreen(
                                title: nutrition.title,
                                nutritionEntry: nutrition.nutritionEntry,
                                date: formattedDate,
                              ),
                        ),
                      );
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            // Handle edit action
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => NutritionEditScreen(
                                      nutritionId: nutrition.nutritionId,
                                      title: nutrition.title,
                                      nutritionEntry: nutrition.nutritionEntry,
                                    ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _deleteNutrition(nutrition.nutritionId);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const NutritionEntryScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}