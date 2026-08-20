import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  // ============================================================
  // CREATE ACCOUNT
  // ============================================================

  Future<void> createAccount() async {
    if (isLoading) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await AuthService.createAccount(
        username: usernameController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      // ========================================================
      // ACCOUNT CREATED
      // ========================================================

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created successfully. Please login."),
          backgroundColor: Colors.green,
        ),
      );

      // ========================================================
      // GO TO LOGIN
      // ========================================================

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      debugPrint("Create account error: $e");

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unable to create account: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [
                const SizedBox(height: 30),

                // ==================================================
                // ICON
                // ==================================================
                Center(
                  child: Container(
                    width: 90,
                    height: 90,

                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF6A5AE0)],
                      ),

                      borderRadius: BorderRadius.circular(28),
                    ),

                    child: const Icon(
                      Icons.person_add,
                      color: Colors.white,
                      size: 45,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // ==================================================
                // TITLE
                // ==================================================
                const Text(
                  "Create Your Account",
                  textAlign: TextAlign.center,

                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Create an account to continue",
                  textAlign: TextAlign.center,

                  style: TextStyle(fontSize: 15, color: Colors.grey),
                ),

                const SizedBox(height: 35),

                // ==================================================
                // USERNAME
                // ==================================================
                TextFormField(
                  controller: usernameController,

                  keyboardType: TextInputType.text,

                  textInputAction: TextInputAction.next,

                  decoration: const InputDecoration(
                    labelText: "Username",
                    hintText: "Enter username",

                    prefixIcon: Icon(Icons.person_outline),

                    border: OutlineInputBorder(),
                  ),

                  validator: (value) {
                    final username = value?.trim() ?? "";

                    if (username.isEmpty) {
                      return "Enter username";
                    }

                    if (username.length < 3) {
                      return "Username must be at least 3 characters";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ==================================================
                // PASSWORD
                // ==================================================
                TextFormField(
                  controller: passwordController,

                  obscureText: obscurePassword,

                  textInputAction: TextInputAction.next,

                  decoration: InputDecoration(
                    labelText: "Password",
                    hintText: "Enter password",

                    prefixIcon: const Icon(Icons.lock_outline),

                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },

                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),

                    border: const OutlineInputBorder(),
                  ),

                  validator: (value) {
                    final password = value ?? "";

                    if (password.isEmpty) {
                      return "Enter password";
                    }

                    if (password.length < 6) {
                      return "Password must be at least 6 characters";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ==================================================
                // CONFIRM PASSWORD
                // ==================================================
                TextFormField(
                  controller: confirmPasswordController,

                  obscureText: obscureConfirmPassword,

                  textInputAction: TextInputAction.done,

                  onFieldSubmitted: (_) {
                    createAccount();
                  },

                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    hintText: "Re-enter password",

                    prefixIcon: const Icon(Icons.lock),

                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },

                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),

                    border: const OutlineInputBorder(),
                  ),

                  validator: (value) {
                    final confirmPassword = value ?? "";

                    if (confirmPassword.isEmpty) {
                      return "Confirm your password";
                    }

                    if (confirmPassword != passwordController.text) {
                      return "Passwords do not match";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // ==================================================
                // CREATE ACCOUNT BUTTON
                // ==================================================
                SizedBox(
                  height: 55,

                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : createAccount,

                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,

                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.person_add),

                    label: Text(
                      isLoading ? "Creating Account..." : "Create Account",

                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,

                      disabledBackgroundColor: Colors.blue.shade300,

                      disabledForegroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // LOGIN
                // ==================================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    const Text("Already have an account?"),

                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },

                      child: const Text(
                        "Login",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }
}
