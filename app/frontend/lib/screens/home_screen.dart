import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/navbar.dart';
import '../widgets/hero_section.dart';
import '../widgets/upload_section.dart';
import '../widgets/features_section.dart';
import '../widgets/footer_section.dart';
import '../widgets/how_it_works_section.dart';
import '../widgets/about_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedNav = 0;
  int _previousNav = 0;
  final List<String> _navItems = ['Detector', 'How It Works', 'About'];

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _selectedNav) return;
    setState(() => _previousNav = _selectedNav);
    _fadeController.reset();
    _slideController.reset();
    setState(() => _selectedNav = index);
    _fadeController.forward();
    _slideController.forward();
  }

  Widget _buildBody() {
    switch (_selectedNav) {
      case 1:
        return const SingleChildScrollView(child: HowItWorksSection());
      case 2:
        return const SingleChildScrollView(child: AboutSection());
      default:
        return const SingleChildScrollView(
          child: Column(
            children: [
              HeroSection(),
              UploadSection(),
              FeaturesSection(),
              FooterSection(),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          Navbar(
            selectedIndex: _selectedNav,
            navItems: _navItems,
            onNavTap: _onNavTap,
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: _buildBody(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}