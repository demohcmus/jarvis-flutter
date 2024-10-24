import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jarvis_application/models/account_plan_model.dart';
import 'package:jarvis_application/viewmodels/account_view_model.dart';
import 'package:provider/provider.dart';

class UpgradeAccountScreen extends StatefulWidget {
  const UpgradeAccountScreen({super.key});

  @override
  State<UpgradeAccountScreen> createState() => _UpgradeAccountScreenState();
}

class _UpgradeAccountScreenState extends State<UpgradeAccountScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade Account'),
      ),
      body: Consumer<AccountViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.availablePlans.isEmpty) {
            return const Center(child: Text('No plans available'));
          }
          return PageView.builder(
            controller: _pageController,
            itemCount: viewModel.availablePlans.length,
            itemBuilder: (context, index) {
              return _buildPlanPage(viewModel.availablePlans[index], viewModel);
            },
          );
        },
      ),
    );
  }

  Widget _buildPlanPage(AccountPlanModel plan, AccountViewModel viewModel) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          children: [
            // Plan header with wave effect
            Container(
              constraints: BoxConstraints(
                minHeight: 180,
                maxHeight: constraints.maxHeight * 0.3,
              ),
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(constraints.maxWidth, double.infinity),
                    painter: WavePainter(_getPlanColor(plan.name)),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _getPlanIcon(plan.name),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  plan.name,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (plan.name == 'Pro Annually') _buildHotPickBadge(),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildPriceSection(plan),
                          if (plan.name != 'Basic') ...[
                            const SizedBox(height: 8),
                            _buildSubscribeButton(plan),
                          ],
                          if (plan.name == 'Pro Annually') ...[
                            const SizedBox(height: 4),
                            _buildSavingsBadge(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Rest of the plan details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeatureSection('Basic features', plan.basicFeatures),
                  const SizedBox(height: 20),
                  _buildFeatureSection('Advanced Features', plan.advancedFeatures),
                  const SizedBox(height: 20),
                  _buildFeatureSection('Other Benefits', plan.otherBenefits),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _getPlanIcon(String planName) {
    switch (planName) {
      case 'Basic':
        return const Icon(Icons.brightness_5, color: Colors.white, size: 20);
      case 'Starter':
        return const Icon(Icons.all_inclusive, color: Colors.white, size: 20);
      case 'Pro Annually':
        return const FaIcon(FontAwesomeIcons.crown, color: Colors.white, size: 20);
      default:
        return const Icon(Icons.category, color: Colors.white, size: 20);
    }
  }

  Widget _buildHotPickBadge() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.thumb_up, color: Colors.orange, size: 12),
          SizedBox(width: 2),
          Text(
            'HOT PICK',
            style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(AccountPlanModel plan) {
    if (plan.name == 'Basic') {
      return const Text(
        'Free',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      );
    } else {
      return Column(
        children: [
          const Text(
            '1-month Free Trial',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'Then',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 2),
          Text(
            plan.name == 'Starter' ? '\$9.99/month' : '\$79.99/year',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      );
    }
  }

  Widget _buildSubscribeButton(AccountPlanModel plan) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Implement subscription logic
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _getPlanColor(plan.name),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text('Subscribe now', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSavingsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'SAVE 33% ON ANNUAL PLAN!',
        style: TextStyle(color: _getPlanColor('Pro Annually'), fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getPlanColor(String planName) {
    switch (planName) {
      case 'Basic':
        return Colors.blue;
      case 'Starter':
        return Colors.purple;
      case 'Pro Annually':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFeatureSection(String title, List<String> features) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        ...features.map((feature) => _buildFeatureItem(feature)),
      ],
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final Color color;

  WavePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    var path = Path();

    path.lineTo(0, size.height * 0.75);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.85,
        size.width * 0.5, size.height * 0.75);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.65,
        size.width, size.height * 0.75);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
