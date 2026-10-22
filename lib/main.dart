import 'package:flutter/material.dart';
import 'api_service.dart';

void main() {
  runApp(const StudentApp());
}

class StudentApp extends StatelessWidget {
  const StudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student APP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 48, 83, 45),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

// ---------------- LOGIN SCREEN ----------------

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController =   TextEditingController();
  final TextEditingController _passController =   TextEditingController();

   bool _isLoading = false;
  String? _errorMessage;
 
  Future<void> _login() async {
  final username = _userController.text.trim();
  final password = _passController.text;

  if (username.isEmpty || password.isEmpty) {
    setState(() {
      _errorMessage = 'Please enter username and password.';
    });
    return;
  }

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final success = await ApiService.login(username, password);

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const StudentListScreen(),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Invalid username or password.';
      });
    }
  } catch (e) {
    if (!mounted) return;

    setState(() {
      
      debugPrint('API acutal error:+ $e');
      _errorMessage = 'Unable to connect to the API.';
    });
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Login'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.school,
                    size: 70,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Student Management Login',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _userController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    onSubmitted: (_) {
                      if (!_isLoading) _login();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _login,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.login),
                      label: Text(
                        _isLoading ? 'Logging in...' : 'Login',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Test username: emilys\n'
                    'Test password: emilyspass',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- STUDENT MODEL ----------------

class Student {
  final int id;
  final String name;
  final String grade;

  Student({
    required this.id,
    required this.name,
    required this.grade,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    final company = json['company'];

    return Student(
      id: (json['id'] as num).toInt(),
      name: json['firstName']?.toString() ?? 'Unknown',
      grade: company is Map
          ? company['title']?.toString() ?? 'N/A'
          : 'N/A',
    );
  }
}

// ---------------- STUDENT LIST SCREEN ----------------

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() =>
      _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final List<Student> _students = [];

  final TextEditingController _nameController =
      TextEditingController();
  final TextEditingController _gradeController =
      TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  // GET: Load sample users from DummyJSON
  Future<void> _loadStudents() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final data = await ApiService.getStudents();

      final loadedStudents = data.map((item) {
        return Student.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
      }).toList();

    if (!mounted) return;

    setState(() {
      _students
        ..clear()
          ..addAll(loadedStudents);
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
        _errorMessage = 'Failed to load students. Please retry.';
    });
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  // POST: Add a student through the test API
  Future<void> _addStudent() async {
    final name = _nameController.text.trim();
    final grade = _gradeController.text.trim();

    if (name.isEmpty || grade.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter student name and grade.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final result = await ApiService.addStudent(name, grade);

      if (!mounted) return;

      // DummyJSON simulates adding; preserve the result locally
      // so the new student appears on this screen.
      final student = Student.fromJson(result);

      setState(() {
        _students.insert(0, student);
      });

      _nameController.clear();
      _gradeController.clear();
      FocusScope.of(context).unfocus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Student added (test API; not permanently saved).',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add student'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // DELETE: Send delete request and remove from current UI
  Future<void> _deleteStudent(int index) async {
    final student = _students[index];

    try {
      final success = await ApiService.deleteStudent(student.id);

      if (!mounted) return;

      if (success) {
    setState(() {
          _students.removeWhere((s) => s.id == student.id);
    });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Student removed from the current list.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delete request failed'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete student'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Directory'),
        backgroundColor:
            Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            tooltip: 'Refresh students',
            onPressed: _isLoading ? null : _loadStudents,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Student input form
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Student Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _gradeController,
                      decoration: const InputDecoration(
                        labelText: 'Grade / Class',
                        prefixIcon: Icon(Icons.school),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed:
                          _isSaving ? null : _addStudent,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.add),
                      label: Text(
                        _isSaving ? 'Adding...' : 'Add Student',
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Student list heading
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Student List (${_students.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Student list, loading, and error states
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadStudents,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _students.isEmpty
                          ? const Center(
                              child: Text(
                                'No students found.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];

                        return Card(
                                  margin:
                                      const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                          child: ListTile(
                            leading: CircleAvatar(
                                      child: Text(
                                        student.name.isEmpty
                                            ? '?'
                                            : student.name[0]
                                                .toUpperCase(),
                                      ),
                            ),
                            title: Text(student.name),
                                    subtitle: Text(
                                      'Grade: ${student.grade}',
                                    ),
                            trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _deleteStudent(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
