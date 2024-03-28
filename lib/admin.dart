import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Stream<QuerySnapshot> _leaveRequestsStream;
  late Stream<QuerySnapshot> _attendanceStream;

  @override
  void initState() {
    super.initState();
    _leaveRequestsStream = FirebaseFirestore.instance.collection('leaverequest').snapshots();
    _attendanceStream = FirebaseFirestore.instance.collection('attendance').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Page'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome, Admin!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              _buildLeaveRequestsSection(),
              SizedBox(height: 20),
              _buildApprovedRequestsSection(),
              SizedBox(height: 20),
              _buildRejectedRequestsSection(),
              SizedBox(height: 20),
              _buildAttendanceReportSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveRequestsSection() {
    return Column(
      children: [
        Center(
          child: Text(
            'Leave Requests',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 10),
        _buildRequestsList(status: 'pending'),
      ],
    );
  }

  Widget _buildApprovedRequestsSection() {
    return Column(
      children: [
        Center(
          child: Text(
            'Approved Requests',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 10),
        _buildRequestsList(status: 'approved'),
      ],
    );
  }

  Widget _buildRejectedRequestsSection() {
    return Column(
      children: [
        Center(
          child: Text(
            'Rejected Requests',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 10),
        _buildRequestsList(status: 'rejected'),
      ],
    );
  }

  Widget _buildAttendanceReportSection() {
    return Column(
      children: [
        Center(
          child: Text(
            'Attendance Report',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 10),
        _buildAttendanceReportList(),
      ],
    );
  }

  Widget _buildRequestsList({required String status}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _leaveRequestsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text('No leave requests found.');
        }

        var leaveRequests = snapshot.data!.docs.where((request) => request['status'] == status).toList();

        if (leaveRequests.isEmpty) {
          return Text('No $status leave requests found.');
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: leaveRequests.length,
          itemBuilder: (context, index) {
            var leaveRequest = leaveRequests[index];
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(leaveRequest['userId']).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (userSnapshot.hasError) {
                  return Text('Error: ${userSnapshot.error}');
                }
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return Text('User not found');
                }
                var userData = userSnapshot.data!;
                var username = userData['username'];
                var userId = leaveRequest['userId'].substring(0, 8); // Display only the first 8 characters of the userID
                return ListTile(
                  title: Text('User ID: $userId - $username'),
                  subtitle: Text('Reason: ${leaveRequest['reason']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (status == 'pending')
                        IconButton(
                          icon: Icon(Icons.check, color: Colors.green),
                          onPressed: () {
                            _approveLeaveRequest(leaveRequest.id);
                          },
                        ),
                      if (status == 'pending')
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            _rejectLeaveRequest(leaveRequest.id);
                          },
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAttendanceReportList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _attendanceStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text('No attendance data found.');
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var attendanceData = snapshot.data!.docs[index];
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(attendanceData['userId']).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (userSnapshot.hasError) {
                  return Text('Error: ${userSnapshot.error}');
                }
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return Text('User not found');
                }
                var userData = userSnapshot.data!;
                var username = userData['username'];
                var userId = attendanceData['userId'].substring(0, 8); // Display only the first 8 characters of the userID
                // Parse timestamps to DateTime format
                DateTime punchIn = (attendanceData['punchIn'] as Timestamp).toDate();
                DateTime punchOut = (attendanceData['punchOut'] as Timestamp).toDate();
                // Format DateTime as desired
                String formattedPunchIn = DateFormat('yyyy-MM-dd HH:mm:ss').format(punchIn);
                String formattedPunchOut = DateFormat('yyyy-MM-dd HH:mm:ss').format(punchOut);
                return ListTile(
                  title: Text('User ID: $userId - $username'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Punch In: $formattedPunchIn'),
                      Text('Punch Out: $formattedPunchOut'),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }



  void _approveLeaveRequest(String requestId) {
    FirebaseFirestore.instance.collection('leaverequest').doc(requestId).update({'status': 'approved'}).then((value) {
      setState(() {});
    });
  }

  void _rejectLeaveRequest(String requestId) {
    FirebaseFirestore.instance.collection('leaverequest').doc(requestId).update({'status': 'rejected'}).then((value) {
      setState(() {});
    });
  }
}




