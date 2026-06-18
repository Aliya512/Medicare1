import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecordsScreen extends StatelessWidget {
  final String patientId;
  final String patientName;
  final String doctorName;

  const RecordsScreen({
    Key? key,
    required this.patientId,
    required this.patientName,
    required this.doctorName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Records - $patientName"),
        backgroundColor: const Color(0xFF0F9B8E),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("records")
            .where("patientId", isEqualTo: patientId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No records found"));
          }

          // manual sorting
          final docs = snapshot.data!.docs.toList();
          docs.sort((a, b) {
            final Timestamp ta = a["createdAt"] as Timestamp;
            final Timestamp tb = b["createdAt"] as Timestamp;
            return tb.compareTo(ta);
          });

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final bool isLatest = index == 0;
              return Card(
                child: ListTile(
                  title: Text("Visit: ${data["visitDate"] ?? "Unknown"}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Symptoms: ${data["symptoms"] ?? ""}"),
                      Text("Doctor: ${data["doctorName"] ?? ""}"),
                      Text(
                        "Specialization: ${data["doctorSpecialization"] ?? ""}",
                      ),
                      Text("Paid: ${data["paid"] == true ? "Yes" : "No"}"),
                      if (data["paid"] == true)
                        Text("Amount: ${data["amountPaid"] ?? "0"}"),
                    ],
                  ),

                  trailing: data["paid"] == true
                      ? null
                      : ElevatedButton(
                          onPressed: () {
                            showPaidDialog(context, doc.id);
                          },
                          child: const Text("Paid"),
                        ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F9B8E),
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  RecordFormScreen(patientId: patientId, isUpdate: false),
            ),
          );
        },
      ),
    );
  }

  void showPaidDialog(BuildContext context, String recordId) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter Paid Amount"),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "Amount"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;

                await FirebaseFirestore.instance
                    .collection("records")
                    .doc(recordId)
                    .update({
                      "paid": true,
                      "amountPaid": amount,
                      "paidAt": Timestamp.now(),
                    });

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}

class RecordFormScreen extends StatefulWidget {
  final bool isUpdate;
  final String patientId;
  final String? recordId;
  final Map<String, dynamic>? existingData;

  const RecordFormScreen({
    Key? key,
    required this.isUpdate,
    required this.patientId,
    this.recordId,
    this.existingData,
  }) : super(key: key);

  @override
  State<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends State<RecordFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController symptomsController = TextEditingController();
  final TextEditingController prescriptionController = TextEditingController();
  final TextEditingController testsController = TextEditingController();
  final TextEditingController nextVisitController = TextEditingController();
  final TextEditingController visitDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.isUpdate && widget.existingData != null) {
      symptomsController.text = widget.existingData!["symptoms"] ?? "";
      prescriptionController.text = widget.existingData!["prescription"] ?? "";
      testsController.text = widget.existingData!["tests"] ?? "";
      nextVisitController.text = widget.existingData!["nextVisit"] ?? "";
      visitDateController.text = widget.existingData!["visitDate"] ?? "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isUpdate ? "Update Record" : "New Record"),
        backgroundColor: const Color(0xFF0F9B8E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: symptomsController,
                decoration: const InputDecoration(labelText: "Symptoms"),
              ),
              TextFormField(
                controller: prescriptionController,
                decoration: const InputDecoration(labelText: "Prescription"),
              ),
              TextFormField(
                controller: testsController,
                decoration: const InputDecoration(labelText: "Tests"),
              ),
              TextFormField(
                controller: nextVisitController,
                decoration: const InputDecoration(labelText: "Next Visit"),
              ),
              TextFormField(
                controller: visitDateController,
                decoration: const InputDecoration(labelText: "Visit Date"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final doctorDoc = await FirebaseFirestore.instance
                      .collection("doctors")
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .get();

                  final doctorName = doctorDoc.data()?["name"] ?? "Doctor";
                  final doctorSpec =
                      doctorDoc.data()?["specialization"] ?? "General";

                  final recordData = {
                    "patientId": widget.patientId,
                    "doctorId": FirebaseAuth.instance.currentUser!.uid,
                    "doctorName": doctorName,
                    "specialization": doctorSpec,
                    "symptoms": symptomsController.text,
                    "prescription": prescriptionController.text,
                    "tests": testsController.text,
                    "nextVisit": nextVisitController.text,
                    "visitDate": visitDateController.text,
                    "createdAt": Timestamp.now(),
                  };

                  if (widget.isUpdate) {
                    await FirebaseFirestore.instance
                        .collection("records")
                        .doc(widget.recordId)
                        .update(recordData);
                  } else {
                    await FirebaseFirestore.instance
                        .collection("records")
                        .add(recordData);
                  }

                  Navigator.pop(context);
                },
                child: Text(widget.isUpdate ? "Update" : "Create"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
