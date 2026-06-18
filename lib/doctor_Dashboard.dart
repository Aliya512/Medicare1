import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_Screen.dart';
import 'records_screen.dart';

class doctor_Dashboard extends StatefulWidget {
  const doctor_Dashboard({Key? key}) : super(key: key);

  @override
  State<doctor_Dashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<doctor_Dashboard> {
  bool isDarkMode = false;

  final uid = FirebaseAuth.instance.currentUser!.uid;
  DocumentSnapshot? doctorsDoc;
  DocumentSnapshot? usersDoc;

  @override
  void initState() {
    super.initState();
    loadDoctor();
  }

  // load doctor data
  Future<void> loadDoctor() async {
    // Fetch doctor info
    doctorsDoc = await FirebaseFirestore.instance
        .collection("doctors")
        .doc(uid)
        .get();

    // Fetch user info (for email)
    usersDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    setState(() {});
  }

  ThemeData appTheme(bool dark) {
    return dark
        ? ThemeData.dark()
        : ThemeData(
            primaryColor: const Color(0xFF0F9B8E),
            scaffoldBackgroundColor: Colors.grey[100],
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0F9B8E),
              foregroundColor: Colors.white,
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    if (doctorsDoc == null || usersDoc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme(isDarkMode),
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Doctor Dashboard"),
            backgroundColor: const Color(0xFF0F9B8E),
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.calendar_today), text: "Appointments"),
                Tab(icon: Icon(Icons.people), text: "Patients"),
                Tab(icon: Icon(Icons.schedule), text: "Schedule"),
              ],
            ),
          ),
          drawer: doctorDrawer(),
          body: Column(
            children: [
              Expanded(
                child: TabBarView(
                  children: [appointmentsTab(), patientsTab(), scheduleTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget appointmentsTab() {
    final String doctorId = uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("appointments")
          .where("doctorId", isEqualTo: doctorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No appointments"));
        }

        // Group by date
        Map<String, List<QueryDocumentSnapshot>> grouped = {};
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final date = data["date"] ?? "Unknown Date";

          grouped.putIfAbsent(date, () => []);
          grouped[date]!.add(doc);
        }

        final sortedDates = grouped.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final date = sortedDates[index];
            final list = grouped[date]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    date,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                ...list.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final patientId = data["patientId"] ?? "";
                  final time = data["time"] ?? "Unknown Time";
                  final status = data["status"] ?? "booked";

                  bool isPast = false;
                  try {
                    DateTime apptDate = DateTime.parse(data["date"]);
                    DateTime today = DateTime.now();

                    DateTime apptDay = DateTime(
                      apptDate.year,
                      apptDate.month,
                      apptDate.day,
                    );
                    DateTime todayDay = DateTime(
                      today.year,
                      today.month,
                      today.day,
                    );

                    if (apptDay.isBefore(
                      todayDay.subtract(const Duration(days: 1)),
                    )) {
                      isPast = true;
                    }
                  } catch (e) {
                    isPast = false;
                  }

                  Color tileColor = Colors.white;
                  if (status == "completed") tileColor = Colors.green.shade200;
                  if (status == "cancelled") tileColor = Colors.red.shade200;

                  // Only allow toggle if not cancelled and not past
                  bool canToggle = !isPast && status != "cancelled";

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection("patients")
                        .doc(patientId)
                        .get(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const ListTile(title: Text("Loading..."));
                      }

                      final patientData =
                          snap.data!.data() as Map<String, dynamic>;
                      final patientName =
                          patientData["name"] ?? "Unknown Patient";

                      return Card(
                        color: tileColor,
                        child: ListTile(
                          title: Text(patientName),
                          subtitle: Text("$date • $time"),
                          trailing: ElevatedButton(
                            onPressed:
                                (!isPast &&
                                    status != "cancelled" &&
                                    status != "completed")
                                ? () async {
                                    await FirebaseFirestore.instance
                                        .collection("appointments")
                                        .doc(doc.id)
                                        .update({"status": "completed"});
                                  }
                                : null,

                            child: Text(
                              status == "done" ? "Done" : "Mark as Done",
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ],
            );
          },
        );
      },
    );
  }

  Widget patientsTab() {
    String searchText = "";

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: "Search patient by name",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  setState(() {
                    searchText = val.toLowerCase();
                  });
                },
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("patients")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final patients = snapshot.data!.docs.where((doc) {
                    final name = (doc["name"] ?? "").toString().toLowerCase();
                    return name.contains(searchText);
                  }).toList();

                  if (patients.isEmpty) {
                    return const Center(child: Text("No patients found"));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: patients.length,
                    itemBuilder: (context, index) {
                      final patient = patients[index];
                      final patientId = patient.id;

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(patient["name"] ?? "Patient"),
                          subtitle: Text("ID: $patientId"),

                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RecordsScreen(
                                  patientId: patientId,
                                  patientName: patient["name"] ?? "Patient",
                                  doctorName:
                                      doctorsDoc?.get("name") ?? "Doctor",
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget scheduleTab() {
    final String doctorId = uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("schedules")
          .where("doctorid", isEqualTo: doctorId)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No schedule found for you"));
        }

        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;

        if (!data.containsKey("workingHours")) {
          return const Center(child: Text("Schedule format is incorrect"));
        }

        final Map<String, dynamic> workingHours = data["workingHours"];

        return ListView(
          padding: const EdgeInsets.all(12),
          children: workingHours.entries.map((entry) {
            final day = entry.key;
            final hours = entry.value;

            return Card(
              child: ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(day.toUpperCase()),
                subtitle: Text("${hours["start"]} - ${hours["end"]}"),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Drawer doctorDrawer() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Drawer(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("doctors")
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          final name = data?["name"] ?? "Doctor";
          final department = data?["department"] ?? "Department";
          final specialization = data?["specialization"] ?? "Specialization";
          final email = FirebaseAuth.instance.currentUser!.email ?? "";

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: const Color(0xFF0F9B8E),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      child: Icon(Icons.medical_services, size: 40),
                    ),
                    const SizedBox(height: 10),

                    // name
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // deptartment
                    Text(
                      department,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),

                    // specialization
                    Text(
                      specialization,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // email
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SwitchListTile(
                title: const Text("Dark Mode"),
                value: isDarkMode,
                onChanged: (v) => setState(() => isDarkMode = v),
              ),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Logout"),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => login_Screen()),
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
