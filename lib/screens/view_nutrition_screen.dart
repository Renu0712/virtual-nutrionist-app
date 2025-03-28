import 'package:flutter/material.dart';

class ViewNutritionScreen extends StatefulWidget {
  final String title;
  final String nutritionEntry;
  final String date;

  const ViewNutritionScreen({
    super.key,
    required this.title,
    required this.nutritionEntry,
    required this.date,
  });

  @override
  State<ViewNutritionScreen> createState() => _ViewNutritionScreenState();
}

class _ViewNutritionScreenState extends State<ViewNutritionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                widget.date.toString(),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  widget.nutritionEntry,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}