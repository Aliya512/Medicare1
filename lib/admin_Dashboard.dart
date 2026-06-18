import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_Screen.dart';

class admin_Dashboard extends StatefulWidget {
  @override
  State<admin_Dashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<admin_Dashboard> {
  bool isDarkMode = false;
  String selectedUserType = "Doctor";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Admin Dashboard"),
            backgroundColor: const Color.fromARGB(255, 250, 251, 251),
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: "Doctors", icon: Icon(Icons.medical_services)),
                Tab(text: "Users", icon: Icon(Icons.people)),
                Tab(text: "Schedule", icon: Icon(Icons.schedule)),
                Tab(text: "Appointments", icon: Icon(Icons.calendar_today)),
              ],
            ),
          ),
          drawer: adminDrawer(),
          body: TabBarView(
            children: [
              doctorsTab(),
              usersTab(),
              scheduleTab(),
              appointmentsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget doctorsTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F9B8E),
        child: const Icon(Icons.add),
        onPressed: addDoctorDialog,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('doctors')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading doctors"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No doctors found"));
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF1FC8DB),
                    child: Icon(Icons.medical_services, color: Colors.white),
                  ),
                  title: Text(data['name']),
                  subtitle: Text(data['specialization']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteDoctor(doc.id),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  //Add Doctor
  void addDoctorDialog() {
    final nameController = TextEditingController();
    final deptController = TextEditingController();
    final spController = TextEditingController();
    final expController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Doctor"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Doctor Name"),
            ),
            TextField(
              controller: deptController,
              decoration: const InputDecoration(labelText: "Department"),
            ),
            TextField(
              controller: spController,
              decoration: const InputDecoration(labelText: "Specialization"),
            ),
            TextField(
              controller: expController,
              decoration: const InputDecoration(labelText: "Experience"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            child: const Text("Add"),
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  deptController.text.isEmpty ||
                  deptController.text.isEmpty)
                return;

              await FirebaseFirestore.instance.collection('doctors').add({
                "name": nameController.text.trim(),
                "specialization": spController.text.trim(),
                "department": deptController.text.trim(),
                "experience": expController.text.trim(),
                "createdAt": Timestamp.now(),
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  //Delete Doctor
  Future<void> deleteDoctor(String docId) async {
    await FirebaseFirestore.instance.collection('doctors').doc(docId).delete();
  }

  //Users Tab
  Widget usersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField(
            value: selectedUserType,
            decoration: const InputDecoration(
              labelText: "Select User Type",
              border: OutlineInputBorder(),
            ),
            items: [
              "Doctor",
              "Patient",
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (value) {
              setState(() {
                selectedUserType = value.toString();
              });
            },
          ),
        ),
        // Firestore users list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .where(
                  "role",
                  isEqualTo: selectedUserType == "Doctor"
                      ? "doctor"
                      : "patient",
                )
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text("Error loading users"));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No users found"));
              }

              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF0F9B8E),
                        child: Icon(
                          selectedUserType == "Doctor"
                              ? Icons.medical_services
                              : Icons.person,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(data["username"] ?? "No Name"),
                      subtitle: Text(data["email"]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => confirmDeleteUser(doc.id),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  //Delete Users
  void confirmDeleteUser(String uid) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete User"),
        content: const Text(
          "This will remove the user from database. Continue?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            child: const Text("Delete"),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(uid)
                  .delete();

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  //Schedule Tab
  Widget scheduleTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F9B8E),
        child: const Icon(Icons.add),
        onPressed: addScheduleDialog,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("schedules").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No schedules available"));
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final Map<String, dynamic> workingHours = data["workingHours"];

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(data["doctorName"]),

                  children: workingHours.entries.map((entry) {
                    final day = entry.key;
                    final start = entry.value['start'];
                    final end = entry.value['end'];

                    return ListTile(
                      title: Text(day),
                      subtitle: Text("$start - $end"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              editScheduleDialog(
                                scheduleId: doc.id,
                                day: day,
                                oldStart: start,
                                oldEnd: end,
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              deleteDayFromSchedule(
                                scheduleId: doc.id,
                                day: day,
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  //addscheduleDialog
  void addScheduleDialog() async {
    String? selectedDoctorId;
    String? selectedDoctorName;
    String selectedDay = "monday";

    final startController = TextEditingController();
    final endController = TextEditingController();

    final doctorsSnapshot = await FirebaseFirestore.instance
        .collection("doctors")
        .get();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Schedule"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Doctor Dropdown
              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: "Doctor"),
                items: doctorsSnapshot.docs.map((doc) {
                  final data = doc.data();
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text(data["name"]),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedDoctorId = value.toString();
                  selectedDoctorName = doctorsSnapshot.docs
                      .firstWhere((d) => d.id == value)
                      .get("name");
                },
              ),

              // Day Dropdown
              DropdownButtonFormField(
                value: selectedDay,
                decoration: const InputDecoration(labelText: "Day"),
                items:
                    [
                      "monday",
                      "tuesday",
                      "wednesday",
                      "thursday",
                      "friday",
                      "saturday",
                      "sunday",
                    ].map((day) {
                      return DropdownMenuItem(value: day, child: Text(day));
                    }).toList(),
                onChanged: (value) => selectedDay = value.toString(),
              ),

              TextField(
                controller: startController,
                decoration: const InputDecoration(
                  labelText: "Start Time (HH:mm)",
                ),
              ),
              TextField(
                controller: endController,
                decoration: const InputDecoration(
                  labelText: "End Time (HH:mm)",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            child: const Text("Save"),
            onPressed: () async {
              if (selectedDoctorId == null ||
                  !isValidTime(startController.text) ||
                  !isValidTime(endController.text) ||
                  !isStartBeforeEnd(startController.text, endController.text)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Invalid schedule data")),
                );
                return;
              }

              final schedulesRef = FirebaseFirestore.instance.collection(
                "schedules",
              );

              final existingSchedule = await schedulesRef
                  .where("doctorId", isEqualTo: selectedDoctorId)
                  .limit(1)
                  .get();

              if (existingSchedule.docs.isEmpty) {
                // Create new schedule
                await schedulesRef.add({
                  "doctorId": selectedDoctorId,
                  "doctorName": selectedDoctorName,
                  "workingHours": {
                    selectedDay: {
                      "start": startController.text.trim(),
                      "end": endController.text.trim(),
                    },
                  },
                  "createdAt": Timestamp.now(),
                });
              } else {
                // Update existing schedule
                await schedulesRef.doc(existingSchedule.docs.first.id).update({
                  "workingHours.$selectedDay": {
                    "start": startController.text.trim(),
                    "end": endController.text.trim(),
                  },
                });
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void editScheduleDialog({
    required String scheduleId,
    required String day,
    required String oldStart,
    required String oldEnd,
  }) {
    final startController = TextEditingController(text: oldStart);
    final endController = TextEditingController(text: oldEnd);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Edit $day Schedule"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startController,
              decoration: const InputDecoration(
                labelText: "Start Time (HH:mm)",
              ),
            ),
            TextField(
              controller: endController,
              decoration: const InputDecoration(labelText: "End Time (HH:mm)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            child: const Text("Update"),
            onPressed: () async {
              if (!isValidTime(startController.text) ||
                  !isValidTime(endController.text) ||
                  !isStartBeforeEnd(startController.text, endController.text)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Invalid time values")),
                );
                return;
              }

              await FirebaseFirestore.instance
                  .collection("schedules")
                  .doc(scheduleId)
                  .update({
                    "workingHours.$day": {
                      "start": startController.text.trim(),
                      "end": endController.text.trim(),
                    },
                  });

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  //validation
  bool isValidTime(String time) {
    final regex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
    return regex.hasMatch(time);
  }

  bool isStartBeforeEnd(String start, String end) {
    final s = start.split(":");
    final e = end.split(":");

    final startMinutes = int.parse(s[0]) * 60 + int.parse(s[1]);
    final endMinutes = int.parse(e[0]) * 60 + int.parse(e[1]);

    return startMinutes < endMinutes;
  }

  Future<void> deleteDayFromSchedule({
    required String scheduleId,
    required String day,
  }) async {
    await FirebaseFirestore.instance
        .collection("schedules")
        .doc(scheduleId)
        .update({"workingHours.$day": FieldValue.delete()});
  }

  Widget appointmentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("appointments")
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No appointments found"));
        }

        return ListView(
          padding: const EdgeInsets.all(12),
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final date = data["date"] ?? "-";
            final time = data["time"] ?? "-";
            final doctor = data["doctorName"] ?? "Doctor";
            final status = data["status"] ?? "booked";

            final patientId = data["patientId"] ?? "";

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("patients")
                  .doc(patientId)
                  .get(),
              builder: (context, patientSnapshot) {
                String patientName = "Patient";

                if (patientSnapshot.connectionState == ConnectionState.done &&
                    patientSnapshot.hasData &&
                    patientSnapshot.data!.exists) {
                  final patientData =
                      patientSnapshot.data!.data() as Map<String, dynamic>;
                  patientName = patientData["name"] ?? "Patient";
                }

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text("$doctor → $patientName"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Date: $date"),
                        Text("Time: $time"),
                        Text("Status: ${status.toUpperCase()}"),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == "edit") {
                          editAppointmentDialog(
                            appointmentId: doc.id,
                            oldDate: date,
                            oldTime: time,
                          );
                        } else if (value == "delete") {
                          deleteAppointment(doc.id);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: "edit", child: Text("Edit")),
                        PopupMenuItem(value: "delete", child: Text("Delete")),
                      ],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  void editAppointmentDialog({
    required String appointmentId,
    required String oldDate,
    required String oldTime,
  }) {
    final dateController = TextEditingController(text: oldDate);
    final timeController = TextEditingController(text: oldTime);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Appointment"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: "Date (YYYY-MM-DD)"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(labelText: "Time (HH:mm)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            child: const Text("Update"),
            onPressed: () async {
              if (!isValidTime(timeController.text)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Invalid time format")),
                );
                return;
              }

              await FirebaseFirestore.instance
                  .collection("appointments")
                  .doc(appointmentId)
                  .update({
                    "date": dateController.text.trim(),
                    "time": timeController.text.trim(),
                  });

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> deleteAppointment(String appointmentId) async {
    await FirebaseFirestore.instance
        .collection("appointments")
        .doc(appointmentId)
        .delete();
  }

  //Helper widget for Reports
  Widget reportTile(String title, String role) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .where("role", isEqualTo: role)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return Card(
          child: ListTile(
            leading: const Icon(Icons.bar_chart),
            title: Text(title),
            trailing: Text(
              count.toString(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Widget reportAppointments() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("appointments").snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text("Appointments"),
            trailing: Text(
              count.toString(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  // Reports Tab

  Widget reportsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          reportTile("Doctors", "doctor"),
          reportTile("Patients", "patient"),
          reportAppointments(),
        ],
      ),
    );
  }

  Drawer adminDrawer() {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Drawer(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          // While fetching data
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // If no document found
          if (!snapshot.data!.exists) {
            return const Center(child: Text("Admin data not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF0F9B8E)),
                accountName: Text(data["username"] ?? "Admin Name"),
                accountEmail: Text(
                  currentUser.email ?? "Email cant be fetched now",
                ),
                currentAccountPicture: const CircleAvatar(
                  child: Icon(Icons.admin_panel_settings),
                ),
              ),
              SwitchListTile(
                value: isDarkMode,
                onChanged: (v) => setState(() => isDarkMode = v),
                title: const Text("Dark Mode"),
                secondary: const Icon(Icons.dark_mode),
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Logout"),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const login_Screen()),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
