import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_page.dart';

class OrderSuccessPage extends StatelessWidget {
  final String orderId;

  const OrderSuccessPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final shortId = orderId.split('-').first.toUpperCase();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Circle check
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Thank you
                  const Text(
                    'Thank you',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                      fontFamily: 'Georgia',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your order has been placed successfully.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Order number
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFEEEEEE),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'ORDER NUMBER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2.5,
                            color: Color(0xFF999999),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '#$shortId',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Continue shopping
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomePage()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text(
                        'CONTINUE SHOPPING',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Copy order id (text button)
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: orderId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Order ID copied',
                            style: TextStyle(fontSize: 13, letterSpacing: 0.3),
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.black87,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.content_copy,
                      size: 14,
                      color: Color(0xFF666666),
                    ),
                    label: const Text(
                      'Copy full order ID',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Divider + note
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFEEEEEE),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'We will contact you soon to confirm your order.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                      height: 1.6,
                    ),
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
