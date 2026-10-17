import 'package:flutter/material.dart';
import 'package:rankset_core/rankset_core.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.indigo,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: AppColors.saffron, shape: BoxShape.circle),
                child: Text(
                  AppBrand.name.substring(0, 1),
                  style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                AppBrand.name,
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                AppBrand.tagline,
                style: TextStyle(fontSize: 14, color: Color(0xFFC9C8F0)),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  minHeight: 4,
                  color: AppColors.saffron,
                  backgroundColor: AppColors.indigoSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
