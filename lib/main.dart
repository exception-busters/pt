import 'package:flutter/material.dart';

void main() {
  runApp(const PTApp());
}

class PTApp extends StatelessWidget {
  const PTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PT 앱',
      theme: ThemeData(
        // 연두색 파스텔톤 테마
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9ACD32), // 연한 연두색
          brightness: Brightness.light,
        ),
        // 파스텔톤 색상 팔레트
        scaffoldBackgroundColor: const Color(0xFFF0F8E8), // 매우 연한 연두색 배경
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE8F5E8), // 연한 연두색 앱바
          foregroundColor: Color(0xFF4A6741), // 어두운 녹색 텍스트
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9ACD32), // 연두색 버튼
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFB8D4B8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF9ACD32), width: 2),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return '올바른 이메일 형식을 입력해주세요';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요';
    }
    return null;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 로그인 시뮬레이션 (실제로는 서버 API 호출)
    await Future.delayed(const Duration(seconds: 1));

    // 임시 사용자 데이터 (실제로는 데이터베이스에서 조회)
    const String validEmail = 'test@example.com';
    const String validPassword = '123456';

    if (_emailController.text == validEmail && _passwordController.text == validPassword) {
      // 로그인 성공
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인 성공!'),
          backgroundColor: Color(0xFF9ACD32),
        ),
      );

      // 메인 대시보드로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainDashboard()),
      );
    } else {
      // 로그인 실패
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이메일 또는 비밀번호가 올바르지 않습니다'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _goToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // 로고 및 제목
              const Icon(
                Icons.fitness_center,
                size: 80,
                color: Color(0xFF9ACD32),
              ),
              const SizedBox(height: 16),
              const Text(
                'PT 앱',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A6741),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '당신의 건강한 라이프스타일을 시작하세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B8B6B),
                ),
              ),
              const SizedBox(height: 48),
              
              // 이메일 입력 필드
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  hintText: '이메일을 입력하세요',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              
              // 비밀번호 입력 필드
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  hintText: '비밀번호를 입력하세요',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 24),
              
              // 로그인 버튼
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        '로그인',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              
              // 회원가입 버튼
              OutlinedButton(
                onPressed: _goToSignUp,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF9ACD32)),
                  foregroundColor: const Color(0xFF9ACD32),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  '회원가입',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // 소셜 로그인 (선택사항)
              const Text(
                '또는',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6B8B6B),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              
              // 구글 로그인 버튼 (추후 구현)
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('구글 로그인 기능은 추후 구현됩니다'),
                      backgroundColor: Color(0xFF9ACD32),
                    ),
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('Google로 계속하기'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFB8D4B8)),
                  foregroundColor: const Color(0xFF6B8B6B),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return '올바른 이메일 형식을 입력해주세요';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요';
    }
    if (value.length < 6) {
      return '비밀번호는 최소 6자 이상이어야 합니다';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호 확인을 입력해주세요';
    }
    if (value != _passwordController.text) {
      return '비밀번호가 일치하지 않습니다';
    }
    return null;
  }

  void _signUp() {
    if (_formKey.currentState!.validate()) {
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('약관에 동의해주세요'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 회원가입 로직 (추후 구현)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('회원가입이 완료되었습니다!'),
          backgroundColor: Color(0xFF9ACD32),
        ),
      );
      
      // 로그인 화면으로 돌아가기
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: const Color(0xFFE8F5E8),
        foregroundColor: const Color(0xFF4A6741),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // 회원가입 제목
                const Text(
                  'PT 앱에 오신 것을 환영합니다!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A6741),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '몇 가지 정보를 입력해주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B8B6B),
                  ),
                ),
                const SizedBox(height: 32),
                
                // 이름 입력 필드
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '이름',
                    hintText: '이름을 입력하세요',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이름을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // 이메일 입력 필드
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    hintText: '이메일을 입력하세요',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                
                // 비밀번호 입력 필드
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    hintText: '6자 이상 입력하세요',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),
                
                // 비밀번호 확인 입력 필드
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: '비밀번호 확인',
                    hintText: '비밀번호를 다시 입력하세요',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: _validateConfirmPassword,
                ),
                const SizedBox(height: 24),
                
                // 약관 동의 체크박스
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
                      activeColor: const Color(0xFF9ACD32),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _agreeToTerms = !_agreeToTerms;
                          });
                        },
                        child: const Text(
                          '이용약관 및 개인정보처리방침에 동의합니다',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B8B6B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // 회원가입 버튼
                ElevatedButton(
                  onPressed: _signUp,
                  child: const Text(
                    '회원가입',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 로그인 화면으로 돌아가기
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    '이미 계정이 있으신가요? 로그인하기',
                    style: TextStyle(
                      color: Color(0xFF6B8B6B),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const DietScreen(),
    const WorkoutScreen(),
    const RecordsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFFE8F5E8),
        selectedItemColor: const Color(0xFF9ACD32),
        unselectedItemColor: const Color(0xFF6B8B6B),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: '식단',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: '운동',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: '기록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '프로필',
          ),
        ],
      ),
    );
  }
}

// 홈 화면
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        backgroundColor: const Color(0xFFE8F5E8),
        foregroundColor: const Color(0xFF4A6741),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('알림 기능은 추후 구현됩니다'),
                  backgroundColor: Color(0xFF9ACD32),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 환영 메시지
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9ACD32), Color(0xFF7CB342)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오늘도 화이팅! 💪',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '오늘의 운동과 식단을 확인해보세요',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 오늘의 목표
              const Text(
                '오늘의 목표',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A6741),
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildGoalCard(
                      '운동',
                      '30분',
                      Icons.fitness_center,
                      const Color(0xFF4CAF50),
                      '60%',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildGoalCard(
                      '칼로리',
                      '1,200kcal',
                      Icons.local_fire_department,
                      const Color(0xFFFF9800),
                      '80%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // 빠른 액션
              const Text(
                '빠른 액션',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A6741),
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      '운동 시작',
                      Icons.play_arrow,
                      const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionCard(
                      '식단 기록',
                      Icons.restaurant,
                      const Color(0xFF2196F3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCard(String title, String value, IconData icon, Color color, String progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A6741),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '진행률: $progress',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B8B6B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        // TODO: 각 액션에 맞는 화면으로 이동
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 식단 화면
class DietScreen extends StatelessWidget {
  const DietScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('식단'),
        backgroundColor: const Color(0xFFE8F5E8),
        foregroundColor: const Color(0xFF4A6741),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('식단 추가 기능은 추후 구현됩니다'),
                  backgroundColor: Color(0xFF9ACD32),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 칼로리 섭취 현황
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Column(
                  children: [
                    Text(
                      '오늘의 칼로리',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1,200 / 1,800 kcal',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '목표까지 600kcal 남음',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 식단 기록
              const Text(
                '식단 기록',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A6741),
                ),
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: ListView(
                  children: [
                    _buildMealCard('아침', '계란후라이, 토스트', '350kcal', Icons.wb_sunny),
                    _buildMealCard('점심', '닭가슴살 샐러드', '450kcal', Icons.wb_sunny_outlined),
                    _buildMealCard('저녁', '연어 구이, 현미밥', '400kcal', Icons.nightlight_round),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealCard(String meal, String food, String calories, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF2196F3)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A6741),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  food,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B8B6B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            calories,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2196F3),
            ),
          ),
        ],
      ),
    );
  }
}

// 운동 화면
class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('운동'),
        backgroundColor: const Color(0xFFE8F5E8),
        foregroundColor: const Color(0xFF4A6741),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 오늘의 운동
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Column(
                  children: [
                    Text(
                      '오늘의 운동',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '30분 / 45분',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '15분 더 운동하세요!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 운동 루틴
              const Text(
                '운동 루틴',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A6741),
                ),
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: ListView(
                  children: [
                    _buildWorkoutCard('웜업', '5분', Icons.accessibility_new, const Color(0xFFFF9800)),
                    _buildWorkoutCard('유산소', '20분', Icons.directions_run, const Color(0xFF4CAF50)),
                    _buildWorkoutCard('근력운동', '15분', Icons.fitness_center, const Color(0xFF2196F3)),
                    _buildWorkoutCard('쿨다운', '5분', Icons.self_improvement, const Color(0xFF9C27B0)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(String workout, String duration, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              workout,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A6741),
              ),
            ),
          ),
          Text(
            duration,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// 기록 화면
class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기록'),
        backgroundColor: const Color(0xFFE8F5E8),
        foregroundColor: const Color(0xFF4A6741),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 주간 목표
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Column(
                  children: [
                    Text(
                      '이번 주 목표 달성률',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '75%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '5일 중 4일 달성',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 통계 카드
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('운동 시간', '150분', Icons.timer, const Color(0xFF4CAF50)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard('소모 칼로리', '2,400kcal', Icons.local_fire_department, const Color(0xFFFF5722)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('체중 변화', '-1.2kg', Icons.trending_down, const Color(0xFF2196F3)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard('운동 일수', '4일', Icons.calendar_today, const Color(0xFF9C27B0)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // 최근 기록
              const Text(
                '최근 기록',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A6741),
                ),
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: ListView(
                  children: [
                    _buildRecordCard('어제', '운동 45분 완료', Icons.check_circle, const Color(0xFF4CAF50)),
                    _buildRecordCard('2일 전', '식단 목표 달성', Icons.check_circle, const Color(0xFF4CAF50)),
                    _buildRecordCard('3일 전', '운동 30분 완료', Icons.check_circle, const Color(0xFF4CAF50)),
                    _buildRecordCard('4일 전', '목표 미달성', Icons.cancel, const Color(0xFFFF5722)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B8B6B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(String date, String record, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B8B6B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  record,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A6741),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 프로필 화면
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        backgroundColor: const Color(0xFFE8F5E8),
        foregroundColor: const Color(0xFF4A6741),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('설정 기능은 추후 구현됩니다'),
                  backgroundColor: Color(0xFF9ACD32),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 프로필 정보
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Color(0xFF9C27B0),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '홍길동',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'PT 회원',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildProfileStat('목표', '체중감량'),
                        _buildProfileStat('PT', '김PT'),
                        _buildProfileStat('기간', '3개월'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 메뉴 리스트
              _buildProfileMenu('개인정보 수정', Icons.edit, () {}),
              _buildProfileMenu('운동 목표 설정', Icons.flag, () {}),
              _buildProfileMenu('식단 목표 설정', Icons.restaurant_menu, () {}),
              _buildProfileMenu('알림 설정', Icons.notifications, () {}),
              _buildProfileMenu('도움말', Icons.help, () {}),
              _buildProfileMenu('로그아웃', Icons.logout, () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileMenu(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF9C27B0)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A6741),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF6B8B6B)),
        onTap: onTap,
      ),
    );
  }
}
