import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileProvider with ChangeNotifier {
  XFile? _pickedImage;
  TextEditingController nameController = TextEditingController();
  String? phoneNumber;
  bool _isPickingImage = false; // <-- Add this

  XFile? get pickedImage => _pickedImage;
  String get name => nameController.text.trim();

  Future<void> pickImage() async {
    if (_isPickingImage) return; // <-- Prevent double tap
    _isPickingImage = true;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        _pickedImage = image;
        notifyListeners();
      }
    } finally {
      _isPickingImage = false;
    }
  }

  bool validateProfile() {
    if (name.isEmpty || _pickedImage == null) {
      return false;
    }
    return true;
  }

  void clear() {
    _pickedImage = null;
    nameController.clear();
    notifyListeners();
  }

  void setPhoneNumber(String number) {
    phoneNumber = number;
    notifyListeners();
  }
}
