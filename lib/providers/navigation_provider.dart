// lib/providers/navigation_provider.dart
import 'package:flutter/material.dart';

class NavigationProvider with ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void setCurrentIndexSafe(int index, int maxIndex) {
    _currentIndex = index.clamp(0, maxIndex);
    notifyListeners();
  }

  void resetToHome() {
    _currentIndex = 0;
    notifyListeners();
  }
}

