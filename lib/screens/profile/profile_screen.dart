import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        _nameCtrl.text = user.name;
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profile & Settings',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Manage your account and preferences',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 20),

          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabs,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.black87,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              tabs: const [
                Tab(text: 'Profile'),
                Tab(text: 'Payment'),
                Tab(text: 'Preferences'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tab content
          AnimatedBuilder(
            animation: _tabs,
            builder: (context, _) {
              switch (_tabs.index) {
                case 0:
                  return _buildProfile(user);
                case 1:
                  return _buildWip('Payment');
                case 2:
                  return _buildWip('Preferences');
                default:
                  return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfile(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: Colors.black54, size: 20),
              const SizedBox(width: 8),
              const Text('Personal Information',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Update your personal details',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),

          _FieldLabel('Student ID'),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              user?.studentId ?? '—',
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),

          _FieldLabel('Full Name *'),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              hintText: 'Your full name',
            ),
          ),
          const SizedBox(height: 16),

          _FieldLabel('Email Address'),
          const SizedBox(height: 6),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'your.email@example.com',
              prefixIcon: Icon(Icons.email_outlined,
                  size: 18, color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(height: 16),

          _FieldLabel('Phone Number'),
          const SizedBox(height: 6),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '+855 12 345 678',
              prefixIcon: Icon(Icons.phone_outlined,
                  size: 18, color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
                final auth = context.read<AuthProvider>();
                final messenger = ScaffoldMessenger.of(context);
                final studentId = auth.user?.studentId ?? auth.user?.id ?? '';
                try {
                  await ApiService.updateStudentProfile(
                    studentId: studentId,
                    name: _nameCtrl.text.trim(),
                    email: _emailCtrl.text.trim().isEmpty
                        ? null
                        : _emailCtrl.text.trim(),
                    phone: _phoneCtrl.text.trim().isEmpty
                        ? null
                        : _phoneCtrl.text.trim(),
                  );
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(
                    content: const Text('Changes saved!'),
                    backgroundColor: kOrange,
                  ));
                } catch (_) {
                  if (!mounted) return;
                  messenger.showSnackBar(const SnackBar(
                    content: Text('Failed to save. Try again.'),
                    backgroundColor: Colors.red,
                  ));
                }
              },
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save Changes',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kOrange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWip(String label) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.construction_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('$label — Work in Progress',
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87));
  }
}
