import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_Screen.dart';

class patient_Dashboard extends StatefulWidget {
  @override
  State<patient_Dashboard> createState() => _patient_DashboardState();
}

class _patient_DashboardState extends State<patient_Dashboard> {
  bool isDarkMode = false;
  String? selectedDepartment;
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme(isDarkMode),
      home: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Patient Dashboard"),
            centerTitle: true,
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(icon: Icon(Icons.history), text: "Appointments"),
                Tab(icon: Icon(Icons.medical_services), text: "Book"),
                Tab(icon: Icon(Icons.notifications), text: "Alerts"),
                Tab(icon: Icon(Icons.folder), text: "Records"),
              ],
            ),
          ),
          drawer: patientDrawer(),
          body: TabBarView(
            children: [
              myAppointmentsUI(),
              doctorsListUI(),
              notificationsUI(),
              medicalRecordsUI(),
            ],
          ),
        ),
      ),
    );
  }

  bool isPastAppointment(String dateStr, String timeStr) {
    final dateParts = dateStr.split("-");
    final timeParts = timeStr.split(":");

    final appointmentDateTime = DateTime(
      int.parse(dateParts[0]), // year
      int.parse(dateParts[1]), // month
      int.parse(dateParts[2]), // day
      int.parse(timeParts[0]), // hour
      int.parse(timeParts[1]), // minute
    );
    return appointmentDateTime.isBefore(DateTime.now());
  }

  Widget myAppointmentsUI() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("User not logged in"));
    }

    final uid = user.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("appointments")
          .where("patientId", isEqualTo: uid)
          .snapshots(), // realtime
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No appointments yet"));
        }

        final docs = snapshot.data!.docs.toList();

        docs.sort((a, b) {
          final ta = (a.data() as Map<String, dynamic>)["createdAt"];
          final tb = (b.data() as Map<String, dynamic>)["createdAt"];

          if (ta == null && tb == null) return 0;
          if (ta == null) return 1; // push nulls down
          if (tb == null) return -1;

          return (tb as Timestamp).compareTo(ta);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final bool isPast = isPastAppointment(data["date"], data["time"]);
            return Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(data["doctorName"]),
                subtitle: Text("${data["date"]} • ${data["time"]}"),

                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(
                        (data["status"] ?? "unknown").toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: data["status"] == "booked"
                          ? Colors.green
                          : data["status"] == "cancelled"
                          ? Colors.grey
                          : Colors.orange,
                    ),
                    if ((data["status"] ?? "") == "booked")
                      IconButton(
                        icon: const Icon(Icons.cancel),
                        color: isPast ? Colors.grey : Colors.red,
                        onPressed: isPast
                            ? null // disabled
                            : () {
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text("Cancel Appointment"),
                                    content: const Text(
                                      "Are you sure you want to cancel this appointment?",
                                    ),
                                    actions: [
                                      TextButton(
                                        child: const Text("No"),
                                        onPressed: () =>
                                            Navigator.pop(dialogContext),
                                      ),
                                      ElevatedButton(
                                        child: const Text("Yes, Cancel"),
                                        onPressed: () async {
                                          Navigator.pop(dialogContext);

                                          await cancelAppointment(
                                            docs[index].id,
                                            data["doctorId"],
                                            data["date"],
                                            data["time"],
                                          );

                                          if (!mounted) return;

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Appointment cancelled",
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget doctorsListUI() {
    return Column(
      children: [
        // search in book tab
        Padding(
          padding: const EdgeInsets.all(12),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("doctors")
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              // Extract UNIQUE departments
              final departments =
                  snapshot.data!.docs
                      .map(
                        (d) =>
                            (d.data() as Map<String, dynamic>)["department"]
                                as String,
                      )
                      .toSet()
                      .toList()
                    ..sort();
              return DropdownButtonFormField<String>(
                value: selectedDepartment,
                decoration: const InputDecoration(
                  labelText: "Search by Department",
                  border: OutlineInputBorder(),
                ),
                items: departments.map((dept) {
                  return DropdownMenuItem(value: dept, child: Text(dept));
                }).toList(),
                onChanged: (v) => setState(() => selectedDepartment = v),
              );
            },
          ),
        ),

        // DOCTOR LIST (UNCHANGED LOGIC)
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("doctors")
                .where("department", isEqualTo: selectedDepartment)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (selectedDepartment == null) {
                return const Center(
                  child: Text(
                    "Please select a department to view doctors",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              if (snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No doctors found"));
              }

              return ListView(
                padding: const EdgeInsets.all(12),
                children: snapshot.data!.docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final doctorId = doc.id;

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundImage: AssetImage(
                          d["image"] ?? "assets/images/doctor.png",
                        ),
                      ),
                      title: Text(
                        d["name"],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(d["department"]),
                      children: [
                        infoRow("Specialization", d["specialization"]),
                        infoRow("Experience", d["experience"]),
                        const Divider(),

                        doctorScheduleUI(doctorId),

                        const SizedBox(height: 10),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              child: const Text("Book Appointment"),
                              onPressed: () {
                                showBookingSheet(context, doctorId, d["name"]);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
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

  void showBookingSheet(
    BuildContext context,
    String doctorId,
    String doctorName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DoctorBookingSheet(doctorId: doctorId, doctorName: doctorName);
      },
    );
  }

  Widget doctorScheduleUI(String doctorId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("schedules")
          .where("doctorid", isEqualTo: doctorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Text("No schedule available"),
          );
        }

        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final Map<String, dynamic> workingHours = data["workingHours"];

        return Column(
          children: workingHours.entries.map((e) {
            return ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(e.key.toUpperCase()),
              subtitle: Text("${e.value["start"]} - ${e.value["end"]}"),
            );
          }).toList(),
        );
      },
    );
  }

  Widget infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget notificationsUI() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("notifications")
          .where("toUserId", isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No notifications"));
        }

        final docs = snapshot.data!.docs.toList();

        // Local sort (newest first)
        docs.sort((a, b) {
          final ta = (a.data() as Map<String, dynamic>)["createdAt"];
          final tb = (b.data() as Map<String, dynamic>)["createdAt"];

          if (ta == null && tb == null) return 0;
          if (ta == null) return 1;
          if (tb == null) return -1;

          return (tb as Timestamp).compareTo(ta);
        });

        return ListView(
          padding: const EdgeInsets.all(12),
          children: docs.map((doc) {
            final n = doc.data() as Map<String, dynamic>;
            final isRead = n["read"] ?? false;

            return Card(
              color: isRead
                  ? Colors.white
                  : Colors.grey[200], // unread highlight
              child: ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(n["title"]),
                subtitle: Text(n["message"]),
                trailing: isRead
                    ? const Text("Read")
                    : ElevatedButton(
                        child: const Text("Mark Read"),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection("notifications")
                              .doc(doc.id)
                              .update({"read": true});
                        },
                      ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // MEDICAL RECORDS
  Widget medicalRecordsUI() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("records")
          .where("patientId", isEqualTo: uid)
          .where("paid", isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No medical records yet"));
        }

        final docs = snapshot.data!.docs.toList();

        // Local sort newest first (NO index needed)
        docs.sort((a, b) {
          final ta = (a.data() as Map<String, dynamic>)["createdAt"];
          final tb = (b.data() as Map<String, dynamic>)["createdAt"];

          if (ta == null && tb == null) return 0;
          if (ta == null) return 1;
          if (tb == null) return -1;

          return (tb as Timestamp).compareTo(ta);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data["doctorName"] ?? "Doctor",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    //  ADD SPECIALIZATION HERE
                    Text(
                      data["specialization"] ?? "Specialization not found",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text("Visit Date: ${data["visitDate"] ?? "-"}"),
                    const SizedBox(height: 8),

                    const Divider(),

                    const SizedBox(height: 8),
                    Text("Symptoms: ${data["symptoms"] ?? "-"}"),
                    const SizedBox(height: 8),
                    Text("Prescription: ${data["prescription"] ?? "-"}"),
                    const SizedBox(height: 8),
                    Text("Tests Required: ${data["tests"] ?? "-"}"),
                    const SizedBox(height: 8),
                    Text("Next Visit: ${data["nextVisit"] ?? "Not needed"}"),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Drawer patientDrawer() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Drawer(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("patients")
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          final name = data?["name"] ?? "Patient";
          final allergy = data?["allergy"] ?? "";
          final bloodGroup = data?["bloodGroup"] ?? "";
          final age = data?["age"] ?? "";
          final gender = data?["gender"] ?? "";

          return Column(
            children: [
              Container(
                color: const Color(0xFF0F9B8E),
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      child: Icon(Icons.person, size: 40),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              ),

              // EDIT NAME
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Edit Name"),
                onTap: () =>
                    showEditDialog(context, "Edit Name", name, (value) async {
                      await FirebaseFirestore.instance
                          .collection("patients")
                          .doc(uid)
                          .set({"name": value}, SetOptions(merge: true));
                    }),
              ),

              // MEDICAL INFO (Allergy + Blood Group + Age + Gender)
              ListTile(
                leading: const Icon(Icons.medical_services),
                title: const Text("Medical Information"),
                subtitle: Text(
                  allergy.isEmpty &&
                          bloodGroup.isEmpty &&
                          age.isEmpty &&
                          gender.isEmpty
                      ? "Add medical details"
                      : "Allergy: $allergy\nBlood Group: $bloodGroup\nAge: $age\nGender: $gender",
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => showMedicalInfoDialog(
                  context,
                  allergy,
                  bloodGroup,
                  age,
                  gender,
                  (newAllergy, newBloodGroup, newAge, newGender) async {
                    await FirebaseFirestore.instance
                        .collection("patients")
                        .doc(uid)
                        .set({
                          "allergy": newAllergy,
                          "bloodGroup": newBloodGroup,
                          "age": newAge,
                          "gender": newGender,
                        }, SetOptions(merge: true));
                  },
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

  void showEditDialog(
    BuildContext context,
    String title,
    String initialValue,
    Function(String) onSave, {
    bool multiline = false,
  }) {
    final controller = TextEditingController(text: initialValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: multiline ? 5 : 1,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Enter here",
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Save"),
            onPressed: () async {
              await onSave(controller.text.trim());
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void showMedicalInfoDialog(
    BuildContext context,
    String allergy,
    String bloodGroup,
    String age,
    String gender,
    Function(String, String, String, String) onSave,
  ) {
    final allergyController = TextEditingController(text: allergy);
    final bloodGroupController = TextEditingController(text: bloodGroup);
    final ageController = TextEditingController(text: age);
    String selectedGender = gender.isEmpty ? "Male" : gender;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Medical Information"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: allergyController,
                decoration: const InputDecoration(
                  labelText: "Allergy",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bloodGroupController,
                decoration: const InputDecoration(
                  labelText: "Blood Group",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Age",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: selectedGender,
                items: ["Male", "Female", "Other"]
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) selectedGender = v;
                },
                decoration: const InputDecoration(
                  labelText: "Gender",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Save"),
            onPressed: () async {
              await onSave(
                allergyController.text.trim(),
                bloodGroupController.text.trim(),
                ageController.text.trim(),
                selectedGender,
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class DoctorBookingSheet extends StatefulWidget {
  final String doctorId;
  final String doctorName;

  const DoctorBookingSheet({
    super.key,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  State<DoctorBookingSheet> createState() => _DoctorBookingSheetState();
}

class _DoctorBookingSheetState extends State<DoctorBookingSheet> {
  DateTime? selectedDate;
  String? selectedDay;
  String? selectedTime;
  String getDayFromDate(DateTime date) {
    return [
      "sunday",
      "monday",
      "tuesday",
      "wednesday",
      "thursday",
      "friday",
      "saturday",
    ][date.weekday % 7];
  }

  List<String> generateSlots(String start, String end) {
    final slots = <String>[];

    TimeOfDay current = _parseTime(start);
    final endTime = _parseTime(end);

    while (_toMinutes(current) < _toMinutes(endTime)) {
      slots.add(_formatTime(current));
      current = _addMinutes(current, 30);
    }
    return slots;
  }

  bool isPastSlot(String slot) {
    if (selectedDate == null) return false;

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final selectedDayOnly = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
    );

    // Only block if booking TODAY
    if (selectedDayOnly != today) return false;

    final parts = slot.split(":");
    final slotMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);

    final nowMinutes = now.hour * 60 + now.minute;

    return slotMinutes <= nowMinutes;
  }

  Stream<Set<String>> bookedSlotsStream(String doctorId, String dateStr) {
    return FirebaseFirestore.instance
        .collection("doctor_slots")
        .where("doctorId", isEqualTo: doctorId)
        .where("date", isEqualTo: dateStr)
        .snapshots()
        .map((snap) {
          return snap.docs.map((d) => d["time"] as String).toSet();
        });
  }

  TimeOfDay _parseTime(String time) {
    final p = time.split(":");
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  TimeOfDay _addMinutes(TimeOfDay t, int minutes) {
    final total = _toMinutes(t) + minutes;
    return TimeOfDay(hour: total ~/ 60, minute: total % 60);
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        selectedDay = getDayFromDate(picked);
        selectedTime = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("schedules")
            .where("doctorid", isEqualTo: widget.doctorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final Map<String, dynamic> workingHours = data["workingHours"];

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Book with ${widget.doctorName}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  selectedDate == null
                      ? "Select Date"
                      : selectedDate!.toIso8601String().split("T").first,
                ),
                onPressed: pickDate,
              ),
              if (selectedDate != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "Day: ${selectedDay!.toUpperCase()}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

              const SizedBox(height: 12),

              if (selectedDay != null)
                Builder(
                  builder: (_) {
                    if (!workingHours.containsKey(selectedDay)) {
                      return const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          "Doctor not available on this day",
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final start = workingHours[selectedDay]["start"];
                    final end = workingHours[selectedDay]["end"];
                    final slots = generateSlots(start, end);

                    final dateStr = selectedDate!
                        .toIso8601String()
                        .split("T")
                        .first;

                    return StreamBuilder<Set<String>>(
                      stream: bookedSlotsStream(widget.doctorId, dateStr),
                      builder: (context, slotSnapshot) {
                        final bookedSlots = slotSnapshot.data ?? {};

                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: slots.map((slot) {
                            final isBooked = bookedSlots.contains(slot);
                            final isPast = isPastSlot(slot);
                            final isSelected = slot == selectedTime;

                            return ChoiceChip(
                              label: Text(
                                slot,
                                style: TextStyle(
                                  color: (isBooked || isPast)
                                      ? Colors.white70
                                      : Colors.black,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: Colors.green,
                              disabledColor: Colors.grey.shade400,
                              backgroundColor: (isBooked || isPast)
                                  ? Colors.grey
                                  : null,
                              onSelected: (isBooked || isPast)
                                  ? null // disables past + booked
                                  : (_) {
                                      setState(() => selectedTime = slot);
                                    },
                            );
                          }).toList(),
                        );
                      },
                    );
                  },
                ),

              const SizedBox(height: 20),

              //  CONFIRM
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (selectedTime == null || selectedDate == null)
                      ? null
                      : () => confirmBooking(
                          context,
                          widget.doctorId,
                          widget.doctorName,
                          selectedDate!,
                          selectedTime!,
                        ),
                  child: const Text("Confirm Appointment"),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String getDayFromDate(DateTime date) {
  return [
    "sunday",
    "monday",
    "tuesday",
    "wednesday",
    "thursday",
    "friday",
    "saturday",
  ][date.weekday % 7];
}

Future<void> confirmBooking(
  BuildContext context,
  String doctorId,
  String doctorName,
  DateTime date,
  String time,
) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final dateStr = date.toIso8601String().split("T").first;

  final slotRef = FirebaseFirestore.instance
      .collection("doctor_slots")
      .doc("$doctorId-$dateStr-$time");

  await FirebaseFirestore.instance.runTransaction((tx) async {
    if ((await tx.get(slotRef)).exists) {
      throw Exception("Slot already booked");
    }

    tx.set(slotRef, {
      "doctorId": doctorId,
      "date": dateStr,
      "time": time,
      "bookedBy": uid,
    });

    tx.set(FirebaseFirestore.instance.collection("appointments").doc(), {
      "patientId": uid,
      "doctorId": doctorId,
      "doctorName": doctorName,
      "date": dateStr,
      "day": getDayFromDate(date),
      "time": time,
      "status": "booked",
      "createdAt": FieldValue.serverTimestamp(),
    });

    // ADD THIS (Notification)
    tx.set(FirebaseFirestore.instance.collection("notifications").doc(), {
      "toUserId": uid,
      "title": "Appointment Booked",
      "message":
          "Your appointment with $doctorName is booked on $dateStr at $time.",
      "createdAt": FieldValue.serverTimestamp(),
      "read": false,
    });
  });

  Navigator.pop(context);
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text("Appointment confirmed")));
}

Future<void> cancelAppointment(
  String appointmentId,
  String doctorId,
  String date,
  String time,
) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final slotId = "$doctorId-$date-$time";

  await FirebaseFirestore.instance.runTransaction((tx) async {
    // Update appointment status
    tx.update(
      FirebaseFirestore.instance.collection("appointments").doc(appointmentId),
      {"status": "cancelled"},
    );

    // Free slot
    tx.delete(
      FirebaseFirestore.instance.collection("doctor_slots").doc(slotId),
    );
    // Notification
    tx.set(FirebaseFirestore.instance.collection("notifications").doc(), {
      "toUserId": uid,
      "title": "Appointment Cancelled",
      "message": "Your appointment on $date at $time has been cancelled.",
      "createdAt": FieldValue.serverTimestamp(),
      "read": false,
    });
  });
}
