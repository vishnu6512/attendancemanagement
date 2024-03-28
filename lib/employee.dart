import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

extension DateTimeExtension on DateTime {
  DateTime toLocalDate() {
    return DateTime(this.year, this.month, this.day);
  }
}

class EmployeePage extends StatefulWidget {
  const EmployeePage({Key? key}) : super(key: key);

  @override
  _EmployeePageState createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage> {
  late TextEditingController _reasonController;
  late DateTime _fromDate;
  late DateTime _toDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
    _fromDate = DateTime.now();
    _toDate = DateTime.now();
  }

  Future<void> _submitLeaveRequest(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final String reason = _reasonController.text.trim();

    // Save leave request in Firestore
    await FirebaseFirestore.instance.collection('leaverequest').add({
      'userId': userId,
      'reason': reason,
      'fromDate': _fromDate,
      'toDate': _toDate,
      'status': 'pending', // You can set an initial status
    });

    // Close the popup
    Navigator.of(context).pop();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Leave request submitted successfully'),
      ),
    );

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _showLeaveRequestPopup(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Request Leave'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _reasonController,
                decoration: InputDecoration(labelText: 'Reason'),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Text('From Date:'),
                  SizedBox(width: 10),
                  TextButton(
                    onPressed: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _fromDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _fromDate = pickedDate;
                        });
                      }
                    },
                    child: Text(
                      '${_fromDate.day}/${_fromDate.month}/${_fromDate.year}',
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text('To Date:'),
                  SizedBox(width: 10),
                  TextButton(
                    onPressed: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _toDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _toDate = pickedDate;
                        });
                      }
                    },
                    child: Text(
                      '${_toDate.day}/${_toDate.month}/${_toDate.year}',
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _submitLeaveRequest(context);
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markAttendance(BuildContext context, String type) async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final DateTime now = DateTime.now();
    final DateTime currentDate = DateTime(now.year, now.month, now.day);

    // Check if the user has already punched in or punched out for the current day
    final DocumentSnapshot attendanceSnapshot =
    await FirebaseFirestore.instance.collection('attendance').doc(userId).get();

    final Map<String, dynamic>? attendanceData = attendanceSnapshot.data() as Map<String, dynamic>?;

    final bool alreadyPunchedIn = attendanceData != null && attendanceData['punchIn'] != null;
    final bool alreadyPunchedOut = attendanceData != null && attendanceData['punchOut'] != null;

    // Check if the user has already punched in or punched out for the current day
    if ((type == 'Punch In' && alreadyPunchedIn) || (type == 'Punch Out' && alreadyPunchedOut)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You have already punched $type today'),
        ),
      );
      return;
    }

    // Save attendance in Firestore
    await FirebaseFirestore.instance.collection('attendance').doc(userId).set({
      'userId': userId,
      if (type == 'Punch In') 'punchIn': now,
      if (type == 'Punch Out') 'punchOut': now,
    }, SetOptions(merge: true));

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Attendance $type successfully'),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: () => _showLeaveRequestPopup(context),
              child: Text('Request Leave'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _markAttendance(context, 'Punch In'),
              child: Text('Punch In'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _markAttendance(context, 'Punch Out'),
              child: Text('Punch Out'),
            ),
          ],
        ),
      ),
    );
  }
}











