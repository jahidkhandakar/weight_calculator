import 'package:flutter/material.dart';

class BottomNavBar extends StatefulWidget {
  final Function(int) onTabTapped;
  final int currentIndex;

  const BottomNavBar({
    Key? key,
    required this.onTabTapped,
    required this.currentIndex,
  }) : super(key: key);

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: widget.onTabTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color.fromARGB(255, 1, 104, 51),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Credits'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
