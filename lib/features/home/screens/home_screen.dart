import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../tasks/tasks_screen.dart';
import '../../skills/skills_screen.dart';
import '../../body/body_screen.dart';
import '../../profile/profile_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiClient = ApiClient();
  int _currentIndex = 0; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              AppColors.surface.withValues(alpha: 0.8),
              AppColors.background,
            ],
            radius: 1.5,
          ),
        ),
        child: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _buildHomeTab(),     
              const TasksScreen(), 
              const SkillsScreen(), 
              const BodyScreen(), 
            ],
          ),
        ),
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSub,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'المهام'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'المهارات'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'الجسد'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return FutureBuilder<Response>(
      future: _apiClient.getPlayerData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        
        if (snapshot.hasError) {
          return const Center(child: Text('حدث خطأ في جلب البيانات', style: TextStyle(color: Colors.white)));
        }

        final player = snapshot.data?.data;
        final xp = player['xp'] ?? 0;
        final level = player['level'] ?? 1;
        final rank = player['rank'] ?? 'E';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بطاقة اللاعب
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 👇 دائرة الرتبة (قابلة للضغط الآن)
                    GestureDetector(
                      onTap: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                       );
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            rank,
                            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'مرحباً بك، اللاعب',
                            style: TextStyle(fontSize: 16, color: AppColors.textSub),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'المستوى $level',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: (xp % 100) / 100,
                            backgroundColor: AppColors.background,
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                            minHeight: 8,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'XP $xp / 100',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSub),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              const Text(
                'التقدم الكلي',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 15),
              
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildStatCard('الدين', Icons.mosque, 0, () => _openTasksTab()), 
                  _buildStatCard('الجسد', Icons.fitness_center, 0, () => _openTasksTab()),
                  _buildStatCard('العقل', Icons.psychology, 0, () => _openTasksTab()),
                  _buildStatCard('العمل', Icons.work, 0, () => _openTasksTab()),
                  _buildStatCard('النفس', Icons.self_improvement, 0, () => _openTasksTab()),
                  _buildStatCard('العلاقات', Icons.people, 0, () => _openTasksTab()),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, IconData icon, int value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 5),
            Text(value.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }

  void _openTasksTab() {
    setState(() => _currentIndex = 1);
  }
}