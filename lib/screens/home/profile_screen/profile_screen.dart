import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/controllers/image_picker/image_pickerController.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? profilePicUrl;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    // Replace with your phone number logic
    final phoneNumber = Provider.of<ProfileProvider>(context, listen: false).phoneNumber;
    final doc = await FirebaseFirestore.instance.collection('users').doc(phoneNumber).get();
    if (doc.exists) {
      setState(() {
        profilePicUrl = doc.data()?['profilePic'];
      });
    }
  }

  void saveProfile(BuildContext context) async {
    final provider = Provider.of<ProfileProvider>(context, listen: false);

    if (!provider.validateProfile()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an image and enter your name"),
        ),
      );
      return;
    }

    try {
      if (provider.pickedImage == null || !File(provider.pickedImage!.path).existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No image selected or file not found")),
        );
        return;
      }

      final imageFile = File(provider.pickedImage!.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pics/${provider.phoneNumber}'); // No extension needed
      await storageRef.putFile(imageFile);
      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(provider.phoneNumber).set({
        'name': provider.nameController.text.trim(),
        'phone': provider.phoneNumber,
        'profilePic': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile Saved Successfully")),
      );

      provider.clear();

      // Reload profile data to update UI
      await loadProfile();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save profile: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProfileProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Profile"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => provider.pickImage(),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.blue.shade50,
                    backgroundImage:
                        provider.pickedImage != null
                            ? FileImage(File(provider.pickedImage!.path))
                            : profilePicUrl != null
                                ? NetworkImage(profilePicUrl!)
                                : null,
                    child:
                        provider.pickedImage == null && profilePicUrl == null
                            ? Icon(Icons.person, size: 70, color: Colors.grey)
                            : null,
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    radius: 20,
                    child: const Icon(
                      Icons.edit,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            if (provider.phoneNumber != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      provider.phoneNumber!,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: provider.nameController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: "Full Name",
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => saveProfile(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Save Profile",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
