import 'package:flutter/material.dart';
import 'package:myberikan/extension/navigation.dart';

class AjukanCutiScreen extends StatefulWidget {
  const AjukanCutiScreen({super.key});
  static String id = "/AjukanCutiScreen";

  @override
  State<AjukanCutiScreen> createState() => _AjukanCutiScreenState();
}

class _AjukanCutiScreenState extends State<AjukanCutiScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3F8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () {
                        context.pop();
                      },
                      icon: Icon(Icons.arrow_back_ios_new),
                    ),
                  ),
                  Text(
                    "Pengajuan Cuti",
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: "Poppins_SemiBold",
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: AssetImage("assets/images/profile 1.png"),
                  ),
                  SizedBox(width: 20),
                  Text(
                    "Budi Santoso",
                    style: TextStyle(
                      fontFamily: "Poppins_SemiBold",
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(children: [
                
              ]),
            ),
          ],
        ),
      ),
    );
  }
  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 15, bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      );

  Widget _input(
    TextEditingController controller,
    String hint, {
    TextInputType keyboard = TextInputType.text,
  }) =>
      TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      );
}
