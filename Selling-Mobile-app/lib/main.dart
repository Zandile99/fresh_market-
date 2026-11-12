import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const KwandaApp());
}

const green = Color(0xFF2E7D32);
const paleGreen = Color(0xFFE8F5E9);

typedef Product = Map<String, dynamic>;

// DEMO ONLY: shared while the app is running, not a database or push service.
class DemoStore {
  static final List<Map<String, dynamic>> orders = [];
  static final List<Map<String, String>> notifications = [];
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);
  static String currentEmail = '';
  static final Map<String, Map<String, String>> accounts = {};
  static void changed() => changes.value++;
  static Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    currentEmail = '';
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false);
  }

  static final List<Product> products = [
    {
      'name': 'Fresh Spinach',
      'price': 15.0,
      'category': 'Vegetables',
      'image': '🥬',
      'description': 'Fresh leafy spinach, one bunch'
    },
    {
      'name': 'Beetroot',
      'price': 20.0,
      'category': 'Vegetables',
      'image': '🫜',
      'description': 'Fresh garden beetroot, one bunch'
    },
    {
      'name': 'Potatoes',
      'price': 25.0,
      'category': 'Vegetables',
      'image': '🥔',
      'description': 'Fresh potatoes, one bag'
    },
    {
      'name': 'Cabbage',
      'price': 18.0,
      'category': 'Vegetables',
      'image': '🥬',
      'description': 'One fresh cabbage'
    },
    {
      'name': 'Carrots',
      'price': 12.0,
      'category': 'Vegetables',
      'image': '🥕',
      'description': 'Fresh carrots, one bunch'
    },
    {
      'name': 'Tomatoes',
      'price': 20.0,
      'category': 'Vegetables',
      'image': '🍅',
      'description': 'Fresh tomatoes, one pack'
    },
    {
      'name': 'Green Pepper',
      'price': 12.0,
      'category': 'Vegetables',
      'image': '🫑',
      'description': 'Fresh green bell pepper, each'
    },
    {
      'name': 'Red Pepper',
      'price': 15.0,
      'category': 'Vegetables',
      'image': '🫑',
      'description': 'Fresh red bell pepper, each'
    },
    {
      'name': 'Yellow Pepper',
      'price': 15.0,
      'category': 'Vegetables',
      'image': '🫑',
      'description': 'Fresh yellow bell pepper, each'
    },
    {
      'name': 'Pumpkin',
      'price': 40.0,
      'category': 'Pumpkin & Butternut',
      'image': '🎃',
      'description': 'Whole fresh pumpkin'
    },
    {
      'name': 'Butternut',
      'price': 25.0,
      'category': 'Pumpkin & Butternut',
      'image': '🎃',
      'description': 'Fresh butternut squash'
    },
    {
      'name': 'Ready-to-Cook Chicken',
      'price': 120.0,
      'category': 'Chicken',
      'image': '🍗',
      'description': 'Cleaned whole chicken ready for cooking; keep chilled'
    },
    {
      'name': 'Live Hen',
      'price': 150.0,
      'category': 'Chicken',
      'image': '🐔',
      'description': 'Adult live hen; suitable housing, feed and water required'
    },
    {
      'name': 'Baby Chick',
      'price': 30.0,
      'category': 'Chicken',
      'image': '🐣',
      'description':
          'Young live chick; needs a warm brooder, feed, water and daily care'
    },
    {
      'name': '6 Eggs',
      'price': 20.0,
      'category': 'Eggs',
      'image': '🥚',
      'description': 'Half dozen fresh eggs'
    },
    {
      'name': '12 Eggs',
      'price': 40.0,
      'category': 'Eggs',
      'image': '🥚',
      'description': 'One dozen fresh eggs'
    },
    {
      'name': 'Tray of 30 Eggs',
      'price': 95.0,
      'category': 'Eggs',
      'image': '🥚',
      'description': 'Tray of 30 fresh eggs'
    },
  ];
  static void notify(String message, {String? recipient}) {
    notifications
        .insert(0, {'message': message, 'email': recipient ?? currentEmail});
    changed();
  }
}

class MarketProducts {
  static final collection = FirebaseFirestore.instance.collection('products');
  static Stream<QuerySnapshot<Map<String, dynamic>>> watch() =>
      collection.snapshots();
  static Product fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) => {
        ...doc.data(),
        'productId': doc.id,
      };
  static List<Product> merge(QuerySnapshot<Map<String, dynamic>>? snapshot) {
    final saved = snapshot?.docs.map(fromDoc).toList() ?? <Product>[];
    final names = saved.map((p) => p['name'].toString().toLowerCase()).toSet();
    return [
      ...saved,
      ...DemoStore.products
          .where((p) => !names.contains(p['name'].toString().toLowerCase()))
          .map((p) => {...p, 'legacy': true}),
    ];
  }

  static String? get uid => FirebaseAuth.instance.currentUser?.uid;
  static bool ownedByMe(Product p) => uid != null && p['sellerId'] == uid;
}

Future<void> openCollectionMap(BuildContext context) async {
  final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=Mqanduli%20Centre%2C%20Eastern%20Cape%2C%20South%20Africa');
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps.')));
    }
  }
}

class KwandaApp extends StatelessWidget {
  const KwandaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Kwanda's Fresh Market",
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: green),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF5FAF5),
          appBarTheme: const AppBarTheme(
            backgroundColor: green,
            foregroundColor: Colors.white,
            centerTitle: false,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE4EFE3)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFCEE4CF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFCEE4CF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: green, width: 2),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              shape: const StadiumBorder(),
            ),
          ),
          chipTheme: ChipThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        home: const SplashScreen(),
      );
}

class KwandaBucketLogo extends StatelessWidget {
  final double height;
  const KwandaBucketLogo({super.key, this.height = 150});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: height,
          height: height,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: green.withOpacity(0.10),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Image.asset(
              'lib/assets/images/kwanda_bucket_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.eco, size: 56, color: green),
              ),
            ),
          ),
        ),
      );
}

class MarketPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const MarketPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.spa_outlined,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF246C37), Color(0xFF58A86B)],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(children: [
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.18),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 13),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  )),
            ],
          )),
        ]),
      );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF1FBF0),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Stack(
                  children: [
                    Positioned(
                      left: -65,
                      bottom: -70,
                      child: Container(
                        width: 190,
                        height: 190,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDDEFD9),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -65,
                      bottom: -85,
                      child: Container(
                        width: 210,
                        height: 210,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE3F2DF),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 55),
                          Container(
                            width: 176,
                            height: 176,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(36),
                              boxShadow: [
                                BoxShadow(
                                  color: green.withOpacity(0.12),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(31),
                              child: Image.asset(
                                'lib/assets/images/kwanda_bucket_logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                  child:
                                      Icon(Icons.eco, color: green, size: 80),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Icon(Icons.spa,
                              color: Color(0xFF8DBF64), size: 31),
                          const SizedBox(height: 10),
                          const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Kwanda's Fresh Market",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF17572A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Fresh, Local & Affordable',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14, color: Color(0xFF66766A)),
                          ),
                          const SizedBox(height: 44),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF236B34),
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()),
                              ),
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Get Started',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 65),
                        ],
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

class MarketAuth {
  static final auth = FirebaseAuth.instance;
  static final users = FirebaseFirestore.instance.collection('users');

  static String errorText(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'This email is already registered.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Please choose a stronger password.';
        case 'wrong-password':
        case 'user-not-found':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'network-request-failed':
          return 'Please check your internet connection.';
        case 'requires-recent-login':
          return 'Log out and log in again before changing your password.';
      }
      return error.message ?? 'Authentication failed.';
    }
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'Firestore permission denied. Check your database security rules.';
    }
    return error.toString();
  }

  static Future<String?> signIn(String email, String password) async {
    final credential =
        await auth.signInWithEmailAndPassword(email: email, password: password);
    try {
      final user = credential.user!;
      final doc = await users.doc(user.uid).get();
      if (!doc.exists) throw StateError('No user profile found in Firestore.');
      final data = doc.data()!;
      final role = data['role']?.toString() ?? 'Customer';
      if (role == 'Seller' && data['rejected'] == true) {
        throw StateError('Your seller registration was rejected.');
      }
      if (role == 'Seller' && data['approved'] != true) {
        throw StateError('Your seller account is awaiting admin approval.');
      }
      if (role != 'Customer' && role != 'Seller' && role != 'Admin') {
        throw StateError('Account role is not valid.');
      }
      DemoStore.currentEmail = user.email ?? email;
      DemoStore.accounts[DemoStore.currentEmail] = {
        'name': data['name']?.toString() ?? '',
        'phone': data['phone']?.toString() ?? '',
        'role': role,
        'approved': (data['approved'] == true).toString(),
      };
      return role;
    } catch (_) {
      await auth.signOut();
      rethrow;
    }
  }

  static Future<void> register(
      String name, String email, String password, String role) async {
    if (role != 'Customer' && role != 'Seller') {
      throw StateError('Only Customer and Seller registration is allowed.');
    }
    final credential = await auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await credential.user!.sendEmailVerification();
    try {
      await users.doc(credential.user!.uid).set({
        'name': name,
        'email': email,
        'role': role,
        'approved': role == 'Customer',
      });
    } finally {
      await auth.signOut();
    }
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool busy = false;
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool showPassword = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF1FBF0),
        appBar: AppBar(
            title: const Text('Login'),
            backgroundColor: const Color(0xFFF1FBF0),
            foregroundColor: green),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const KwandaBucketLogo(height: 136),
                    const SizedBox(height: 20),
                    const Icon(Icons.spa, color: Color(0xFF8DBF64), size: 26),
                    const SizedBox(height: 8),
                    const Text('Welcome Back!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: green)),
                    const SizedBox(height: 8),
                    const Text("Login to Kwanda's Fresh Market",
                        textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder()),
                      validator: (v) => v == null ||
                              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(v.trim())
                          ? 'Enter a valid email'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: password,
                      obscureText: !showPassword,
                      decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(showPassword
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () =>
                                setState(() => showPassword = !showPassword),
                          )),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter your password' : null,
                    ),
                    Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                            onPressed: () async {
                              final address = email.text.trim();
                              if (address.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Enter your email address first.')));
                                return;
                              }
                              try {
                                await FirebaseAuth.instance
                                    .sendPasswordResetEmail(email: address);
                                if (mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Password reset email sent. Check your inbox.')));
                              } catch (e) {
                                if (mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text(MarketAuth.errorText(e))));
                              }
                            },
                            child: const Text('Forgot Password?'))),
                    const SizedBox(height: 15),
                    FilledButton(
                      onPressed: busy
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setState(() => busy = true);
                              try {
                                final role = await MarketAuth.signIn(
                                    email.text.trim().toLowerCase(),
                                    password.text);
                                if (!mounted) return;
                                final Widget screen = role == 'Seller'
                                    ? const SellerDashboard()
                                    : role == 'Admin'
                                        ? const AdminDashboard()
                                        : const HomeDashboard();
                                Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (_) => screen),
                                    (_) => false);
                              } catch (e) {
                                if (mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text(MarketAuth.errorText(e))));
                              } finally {
                                if (mounted) setState(() => busy = false);
                              }
                            },
                      child: const Padding(
                          padding: EdgeInsets.all(13), child: Text('Login')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen())),
                      child: const Text("Don't have an account? Register"),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                        'Use the email and password you registered with. Seller accounts need admin approval.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool busy = false;
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  String role = 'Customer';
  bool showPassword = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF1FBF0),
        appBar: AppBar(
            title: const Text('Create Account'),
            backgroundColor: const Color(0xFFF1FBF0),
            foregroundColor: green),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const KwandaBucketLogo(height: 126),
                      const SizedBox(height: 12),
                      const Icon(Icons.spa, color: Color(0xFF8DBF64), size: 26),
                      const SizedBox(height: 8),
                      const Text("Join Kwanda's Fresh Market",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: green)),
                      const SizedBox(height: 25),
                      TextFormField(
                          controller: name,
                          decoration: const InputDecoration(
                              labelText: 'Full Name',
                              border: OutlineInputBorder()),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter your name'
                              : null),
                      const SizedBox(height: 15),
                      TextFormField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                              labelText: 'Email Address',
                              border: OutlineInputBorder()),
                          validator: (v) => v == null ||
                                  !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                      .hasMatch(v.trim())
                              ? 'Enter a valid email'
                              : null),
                      const SizedBox(height: 15),
                      TextFormField(
                          controller: password,
                          obscureText: !showPassword,
                          decoration: InputDecoration(
                              labelText: 'Password',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                  icon: Icon(showPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off),
                                  onPressed: () => setState(
                                      () => showPassword = !showPassword))),
                          validator: (v) => v == null || v.length < 6
                              ? 'Use at least 6 characters'
                              : null),
                      const SizedBox(height: 15),
                      TextFormField(
                          controller: confirm,
                          obscureText: !showPassword,
                          decoration: const InputDecoration(
                              labelText: 'Confirm Password',
                              border: OutlineInputBorder()),
                          validator: (v) => v != password.text
                              ? 'Passwords do not match'
                              : null),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: role,
                        decoration: const InputDecoration(
                            labelText: 'Register As',
                            border: OutlineInputBorder()),
                        items: ['Customer', 'Seller']
                            .map((r) =>
                                DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => role = v ?? 'Customer'),
                      ),
                      if (role == 'Seller')
                        const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                                'An admin must approve your seller account before you can log in.',
                                style: TextStyle(color: green))),
                      const SizedBox(height: 22),
                      FilledButton(
                          onPressed: busy
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setState(() => busy = true);
                                  try {
                                    await MarketAuth.register(
                                        name.text.trim(),
                                        email.text.trim().toLowerCase(),
                                        password.text,
                                        role);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                '$role account created. Please log in.')));
                                    Navigator.pop(context);
                                  } catch (e) {
                                    if (mounted)
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  MarketAuth.errorText(e))));
                                  } finally {
                                    if (mounted) setState(() => busy = false);
                                  }
                                },
                          child: const Padding(
                              padding: EdgeInsets.all(13),
                              child: Text('Register'))),
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Already have an account? Login')),
                    ]),
              ),
            ),
          ),
        ),
      );
}

String productPhoto(Product product) {
  final name = product['name'].toString().toLowerCase();
  if (name.contains('beetroot')) {
    return 'https://commons.wikimedia.org/wiki/Special:FilePath/Beetroot2.jpg?width=600';
  }
  if (name.contains('cabbage')) {
    return 'https://commons.wikimedia.org/wiki/Special:FilePath/Green_Cabbage_%2824728872829%29.jpg?width=600';
  }
  if (name.contains('pumpkin')) {
    return 'https://commons.wikimedia.org/wiki/Special:FilePath/Baby_Pumpkin.jpg?width=600';
  }
  if (name.contains('butternut')) {
    return 'https://commons.wikimedia.org/wiki/Special:FilePath/Butternut.jpg?width=600';
  }
  if (name.contains('baby chick')) {
    return 'https://commons.wikimedia.org/wiki/Special:FilePath/Fuzzy_yellow_chicks_in_a_brooder.jpg?width=600';
  }
  if (name.contains('spinach')) {
    return 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=600&q=80';
  }
  if (name.contains('potato')) {
    return 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=600&q=80';
  }
  if (name.contains('carrot')) {
    return 'https://images.unsplash.com/photo-1445282768818-728615cc910a?w=600&q=80';
  }
  if (name.contains('tomato') || name.contains('pepper')) {
    return 'https://images.unsplash.com/photo-1546470427-e5b89e3f2a1e?w=600&q=80';
  }
  if (name.contains('egg')) {
    return 'https://images.unsplash.com/photo-1506976785307-8732e854ad03?w=600&q=80';
  }
  if (name.contains('chicken') ||
      name.contains('hen') ||
      name.contains('chick')) {
    return 'https://images.unsplash.com/photo-1587593810167-a84920ea0781?w=600&q=80';
  }
  return 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=600&q=80';
}

String productAssetPath(Product product) {
  const files = <String, String>{
    'Fresh Spinach': 'spinach.jpg',
    'Beetroot': 'beetroot.jpg',
    'Potatoes': 'potatoes.jpg',
    'Cabbage': 'cabbage.jpg',
    'Carrots': 'carrots.jpg',
    'Tomatoes': 'tomatoes.jpg',
    'Green Pepper': 'green_pepper.jpg',
    'Red Pepper': 'red_pepper.jpg',
    'Yellow Pepper': 'yellow_pepper.jpg',
    'Pumpkin': 'pumpkin.jpg',
    'Butternut': 'butternut.jpg',
    'Ready-to-Cook Chicken': 'ready_to_cook_chicken.jpg',
    'Live Hen': 'live_hen.jpg',
    'Baby Chick': 'baby_chick.jpg',
    '6 Eggs': 'six_eggs.jpg',
    '12 Eggs': 'twelve_eggs.jpg',
    'Tray of 30 Eggs': 'thirty_eggs.jpg',
  };
  final filename = files[product['name'].toString()];
  return filename == null ? '' : 'lib/assets/images/products/$filename';
}

class MarketProductPhoto extends StatelessWidget {
  final Product product;
  final double? height;
  const MarketProductPhoto({super.key, required this.product, this.height});

  @override
  Widget build(BuildContext context) {
    final path = productAssetPath(product);
    Widget fallback() => Image.network(
          productPhoto(product),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: paleGreen,
            alignment: Alignment.center,
            child: Text(product['image'].toString(),
                style: const TextStyle(fontSize: 62)),
          ),
        );
    return SizedBox(
      height: height,
      width: double.infinity,
      child: path.isEmpty
          ? fallback()
          : Image.asset(
              path,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback(),
            ),
    );
  }
}

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});
  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final search = TextEditingController();
  final ScrollController categoryScroll = ScrollController();
  String category = 'All';
  final List<Product> cart = [];
  List<Product> marketCatalogue = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? productSubscription;
  final categories = const [
    'All',
    'Vegetables',
    'Pumpkin & Butternut',
    'Chicken',
    'Eggs'
  ];

  List<Map<String, dynamic>> get orders => DemoStore.orders
      .where((o) => o['email'] == DemoStore.currentEmail)
      .toList();
  int get cartCount =>
      cart.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
  List<Product> get filteredProducts => marketCatalogue
      .where((p) =>
          p['name']
              .toString()
              .toLowerCase()
              .contains(search.text.toLowerCase()) &&
          (category == 'All' || p['category'] == category))
      .toList();

  @override
  void initState() {
    super.initState();
    marketCatalogue = MarketProducts.merge(null);
    productSubscription = MarketProducts.watch().listen((snapshot) {
      if (mounted)
        setState(() => marketCatalogue = MarketProducts.merge(snapshot));
    }, onError: (Object error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Cannot load market products: $error")));
    });
  }

  @override
  void dispose() {
    productSubscription?.cancel();
    search.dispose();
    categoryScroll.dispose();
    super.dispose();
  }

  void addToCart(String productName, [int quantity = 1]) {
    final product = marketCatalogue.firstWhere((p) => p['name'] == productName);
    final available = product['inStock'] != false &&
        ((product['stock'] is num) ? (product['stock'] as num) > 0 : true);
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('This product is currently out of stock.')));
      return;
    }
    final sellerId = product['sellerId']?.toString() ?? '';
    if (sellerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'This starter product is not assigned to a seller yet. Ask Admin to assign it.')));
      return;
    }
    if (cart.isNotEmpty && cart.first['sellerId'] != sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Please checkout products from one seller at a time.')));
      return;
    }
    setState(() {
      final index =
          cart.indexWhere((p) => p['productId'] == product['productId']);
      if (index >= 0) {
        cart[index]['quantity'] = (cart[index]['quantity'] as int) + quantity;
      } else {
        cart.add({
          'name': product['name'],
          'price': product['price'],
          'image': product['image'],
          'quantity': quantity,
          'productId': product['productId'],
          'sellerId': sellerId,
        });
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$quantity x $productName added to cart'),
      action: SnackBarAction(label: 'VIEW CART', onPressed: openCart),
      duration: const Duration(seconds: 2),
    ));
  }

  void openCart() => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShoppingCartScreen(
          cart: cart,
          onCartChanged: () => setState(() {}),
          onOrderPlaced: (order) => setState(() {
            DemoStore.orders.add(order);
            DemoStore.notify(
              'Order #${order['id']} placed successfully! Check Orders for updates.',
              recipient: DemoStore.currentEmail,
            );
          }),
        ),
      ));

  @override
  Widget build(BuildContext context) {
    final visible = filteredProducts;
    final customerName =
        DemoStore.accounts[DemoStore.currentEmail]?['name']?.split(' ').first ??
            'there';
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: green,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Kwanda's Fresh Market",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('Fresh • Local • Affordable',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          Stack(children: [
            IconButton(
              tooltip: 'Shopping cart',
              icon: const Icon(Icons.shopping_bag_outlined),
              onPressed: openCart,
            ),
            if (cartCount > 0)
              Positioned(
                top: 2,
                right: 2,
                child: CircleAvatar(
                  radius: 9,
                  backgroundColor: Colors.orange,
                  child: Text('$cartCount',
                      style:
                          const TextStyle(fontSize: 10, color: Colors.black)),
                ),
              ),
          ]),
          PopupMenuButton<String>(
            tooltip: 'More options',
            onSelected: (value) {
              if (value == 'map') openCollectionMap(context);
              if (value == 'logout') DemoStore.logout(context);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'map', child: Text('Collection map')),
              PopupMenuItem(value: 'logout', child: Text('Log out')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Hello, $customerName 👋',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF193D23))),
          const SizedBox(height: 4),
          const Text('What fresh food are you looking for today?',
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF246C37), Color(0xFF56A668)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('FRESH FROM OUR LOCAL MARKET',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 9),
                  const Text('Good food,\ncloser to home.',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          height: 1.2,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                    ),
                    onPressed: () => openCollectionMap(context),
                    icon: const Icon(Icons.location_on_outlined, size: 17),
                    label: const Text('Mqanduli Centre'),
                  ),
                ],
              )),
              const SizedBox(
                width: 112,
                child: KwandaBucketLogo(height: 126),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search vegetables, eggs, chicken...',
              prefixIcon: const Icon(Icons.search, color: green),
              suffixIcon: search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        search.clear();
                        setState(() {});
                      },
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Shop by category',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [
            IconButton(
                tooltip: 'Previous categories',
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  if (categoryScroll.hasClients)
                    categoryScroll.animateTo(
                        (categoryScroll.offset - 180).clamp(
                            0.0, categoryScroll.position.maxScrollExtent),
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut);
                }),
            Expanded(
                child: SizedBox(
                    height: 46,
                    child: ListView(
                      controller: categoryScroll,
                      scrollDirection: Axis.horizontal,
                      children: categories
                          .map((c) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(c),
                                  selected: category == c,
                                  selectedColor: paleGreen,
                                  onSelected: (_) =>
                                      setState(() => category = c),
                                ),
                              ))
                          .toList(),
                    ))),
            IconButton(
                tooltip: 'Next categories',
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  if (categoryScroll.hasClients)
                    categoryScroll.animateTo(
                        (categoryScroll.offset + 180).clamp(
                            0.0, categoryScroll.position.maxScrollExtent),
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut);
                }),
          ]),
          const SizedBox(height: 24),
          Row(children: [
            const Expanded(
                child: Text('Fresh picks for you',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            Text('${visible.length} products',
                style:
                    const TextStyle(color: green, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: Text('No matching products found.')),
            ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visible.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 285,
            ),
            itemBuilder: (context, index) {
              final product = visible[index];
              return Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailsScreen(
                            product: product, onAddToCart: addToCart),
                      )),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarketProductPhoto(product: product, height: 118),
                      Expanded(
                          child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product['name'].toString(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 3),
                            Text(product['category'].toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.black54)),
                            const Spacer(),
                            Text(
                                'R${(product['price'] as num).toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17)),
                            const SizedBox(height: 6),
                            SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: (product['inStock'] == false ||
                                          ((product['stock'] is num) &&
                                              (product['stock'] as num) <= 0))
                                      ? null
                                      : () =>
                                          addToCart(product['name'].toString()),
                                  icon: Icon(
                                      (product['inStock'] == false ||
                                              ((product['stock'] is num) &&
                                                  (product['stock'] as num) <=
                                                      0))
                                          ? Icons.remove_shopping_cart
                                          : Icons.add_shopping_cart,
                                      size: 16),
                                  label: Text(
                                      (product['inStock'] == false ||
                                              ((product['stock'] is num) &&
                                                  (product['stock'] as num) <=
                                                      0))
                                          ? 'Out of stock'
                                          : 'Add to cart',
                                      style: const TextStyle(fontSize: 11)),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                )),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          const Center(
              child: Text('Proudly serving Mqanduli 🌱',
                  style: TextStyle(color: Colors.black54, fontSize: 12))),
        ]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => OrderHistoryScreen(orders: orders)));
          } else if (index == 2) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  final void Function(String, int) onAddToCart;
  const ProductDetailsScreen(
      {super.key, required this.product, required this.onAddToCart});
  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final price = (product['price'] as num).toDouble();
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF5),
      appBar: AppBar(
          title: const Text('Product Details'),
          backgroundColor: green,
          foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: MarketProductPhoto(product: product, height: 220),
          ),
          const SizedBox(height: 25),
          Text(product['name'].toString(),
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: green)),
          const SizedBox(height: 8),
          Text(product['category'].toString()),
          const SizedBox(height: 20),
          Text(product['description'].toString(),
              style: const TextStyle(fontSize: 17)),
          const SizedBox(height: 22),
          Text('R${price.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: green)),
          const SizedBox(height: 22),
          const Text('Quantity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Row(children: [
            IconButton.filledTonal(
                onPressed:
                    quantity > 1 ? () => setState(() => quantity--) : null,
                icon: const Icon(Icons.remove)),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text('$quantity', style: const TextStyle(fontSize: 22))),
            IconButton.filledTonal(
                onPressed: () => setState(() => quantity++),
                icon: const Icon(Icons.add)),
          ]),
          const SizedBox(height: 18),
          Text('Total: R${(price * quantity).toStringAsFixed(2)}',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 25),
          if (product['inStock'] == false ||
              ((product['stock'] is num) && (product['stock'] as num) <= 0))
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('OUT OF STOCK',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            )
          else
            FilledButton.icon(
              onPressed: () {
                widget.onAddToCart(product['name'].toString(), quantity);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.shopping_cart),
              label: const Padding(
                  padding: EdgeInsets.all(13), child: Text('Add to Cart')),
            ),
        ]),
      ),
    );
  }
}

class ShoppingCartScreen extends StatefulWidget {
  final List<Product> cart;
  final VoidCallback onCartChanged;
  final void Function(Map<String, dynamic>) onOrderPlaced;
  const ShoppingCartScreen(
      {super.key,
      required this.cart,
      required this.onCartChanged,
      required this.onOrderPlaced});
  @override
  State<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  double get totalPrice => widget.cart.fold<double>(
      0,
      (sum, item) =>
          sum + (item['price'] as num).toDouble() * (item['quantity'] as int));

  void changeQuantity(int index, int delta) {
    setState(() {
      final next = (widget.cart[index]['quantity'] as int) + delta;
      if (next >= 1) widget.cart[index]['quantity'] = next;
    });
    widget.onCartChanged();
  }

  void removeItem(int index) {
    setState(() => widget.cart.removeAt(index));
    widget.onCartChanged();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF5FAF5),
        appBar: AppBar(
            title: const Text('My Shopping Cart'),
            backgroundColor: green,
            foregroundColor: Colors.white),
        body: widget.cart.isEmpty
            ? const Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    Icon(Icons.shopping_cart_outlined,
                        size: 80, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Your cart is empty', style: TextStyle(fontSize: 20)),
                  ]))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: widget.cart.length,
                itemBuilder: (context, index) {
                  final item = widget.cart[index];
                  return Card(
                      child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(children: [
                      Text(item['image'].toString(),
                          style: const TextStyle(fontSize: 34)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(item['name'].toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(
                                'R${(item['price'] as num).toStringAsFixed(2)}'),
                            Row(children: [
                              IconButton(
                                  onPressed: () => changeQuantity(index, -1),
                                  icon: const Icon(Icons.remove)),
                              Text('${item['quantity']}'),
                              IconButton(
                                  onPressed: () => changeQuantity(index, 1),
                                  icon: const Icon(Icons.add)),
                            ]),
                          ])),
                      IconButton(
                          onPressed: () => removeItem(index),
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red)),
                    ]),
                  ));
                },
              ),
        bottomNavigationBar: widget.cart.isEmpty
            ? null
            : SafeArea(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Amount:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17)),
                              Text('R${totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 21,
                                      color: green)),
                            ]),
                        const SizedBox(height: 12),
                        SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => CheckoutScreen(
                                              cart: widget.cart,
                                              onOrderPlaced: (order) {
                                                widget.onOrderPlaced(order);
                                                setState(
                                                    () => widget.cart.clear());
                                                widget.onCartChanged();
                                              },
                                            )));
                              },
                              child: const Padding(
                                  padding: EdgeInsets.all(13),
                                  child: Text('Proceed to Checkout')),
                            )),
                      ],
                    )),
              ),
      );
}

class CheckoutScreen extends StatefulWidget {
  final List<Product> cart;
  final void Function(Map<String, dynamic>) onOrderPlaced;
  const CheckoutScreen(
      {super.key, required this.cart, required this.onOrderPlaced});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  String payment = 'Cash on Collection';

  double get total => widget.cart.fold<double>(
      0,
      (sum, item) =>
          sum + (item['price'] as num).toDouble() * (item['quantity'] as int));

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> placeOrder() async {
    if (!formKey.currentState!.validate() || widget.cart.isEmpty) return;
    final amount = total;
    final order = <String, dynamic>{
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'date': DateTime.now(),
      'customer': name.text.trim(),
      'email':
          FirebaseAuth.instance.currentUser?.email ?? DemoStore.currentEmail,
      'phone': phone.text.trim(),
      'payment': payment,
      'status': 'Received',
      'sellerId': widget.cart.first['sellerId'],
      'total': amount,
      'items':
          widget.cart.map((item) => Map<String, dynamic>.from(item)).toList(),
    };

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in before placing an order.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order['id'].toString())
          .set({
        ...order,
        'customerId': user.uid,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save your order: $e')),
      );
      return;
    }

    if (!mounted) return;
    widget.onOrderPlaced(order);
    await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
              title: const Text('Order Placed!'),
              content: Text('Your order has been placed.\n\n'
                  'Total: R${amount.toStringAsFixed(2)}\nPayment: $payment\n\n'
                  'Thank you for shopping with Kwanda!'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('OK'))
              ],
            ));
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF5FAF5),
        appBar: AppBar(
            title: const Text('Checkout'),
            backgroundColor: green,
            foregroundColor: Colors.white),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Order Summary',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: green)),
                    const SizedBox(height: 12),
                    ...widget.cart.map((item) => Card(
                            child: ListTile(
                          leading: Text(item['image'].toString(),
                              style: const TextStyle(fontSize: 27)),
                          title: Text(item['name'].toString()),
                          subtitle: Text('Quantity: ${item['quantity']}'),
                          trailing: Text(
                              'R${((item['price'] as num) * (item['quantity'] as int)).toStringAsFixed(2)}'),
                        ))),
                    const SizedBox(height: 12),
                    Text('Total: R${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: green)),
                    const SizedBox(height: 25),
                    const Text(
                        'Collection point: Mqanduli Centre, Eastern Cape',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: green)),
                    TextButton.icon(
                        onPressed: () => openCollectionMap(context),
                        icon: const Icon(Icons.map),
                        label: const Text(
                            'View collection location on Google Maps')),
                    const Text('Customer Details',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: name,
                        decoration: const InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder()),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Enter your name'
                            : null),
                    const SizedBox(height: 14),
                    TextFormField(
                        controller: phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder()),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Enter your phone number'
                            : null),
                    const SizedBox(height: 24),
                    const Text('Payment Method',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    RadioListTile<String>(
                        title: const Text('Cash on Collection'),
                        value: 'Cash on Collection',
                        groupValue: payment,
                        onChanged: (v) => setState(() => payment = v!)),
                    RadioListTile<String>(
                        title: const Text('Card (Demo Only)'),
                        value: 'Card (Demo Only)',
                        groupValue: payment,
                        onChanged: (v) => setState(() => payment = v!)),
                    const SizedBox(height: 20),
                    FilledButton(
                        onPressed: widget.cart.isEmpty ? null : placeOrder,
                        child: const Padding(
                            padding: EdgeInsets.all(13),
                            child: Text('Place Order'))),
                  ]),
            )),
      );
}

Future<void> cancelCustomerOrder(
    BuildContext context, String orderDocId) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Cancel Order?'),
      content: const Text(
        'Are you sure you want to cancel this order? This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Keep Order'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Cancel Order'),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    final ref = FirebaseFirestore.instance.collection('orders').doc(orderDocId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (!snapshot.exists || data == null || data['customerId'] != user.uid) {
        throw StateError('This order could not be found.');
      }
      if (data['status'] != 'Received') {
        throw StateError(
          'This order can no longer be cancelled because it is already being processed.',
        );
      }
      transaction.update(ref, {
        'status': 'Cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your order has been cancelled.')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not cancel order: $e')),
      );
    }
  }
}

class OrderDetailsScreen extends StatelessWidget {
  final String orderDocId;
  final Map<String, dynamic> order;

  const OrderDetailsScreen({
    super.key,
    required this.orderDocId,
    required this.order,
  });

  String _dateText(dynamic value) {
    DateTime? date;
    if (value is Timestamp) date = value.toDate();
    if (value is DateTime) date = value;
    if (date == null) return 'Not available';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final items = order['items'] is List ? order['items'] as List : [];
    final total =
        order['total'] is num ? (order['total'] as num).toDouble() : 0.0;
    final status = order['status']?.toString() ?? 'Received';
    final canCancel = status == 'Received';

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF5),
      appBar: AppBar(
        title: Text('Order #${order['id'] ?? orderDocId}'),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order Information',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('Order number: ${order['id'] ?? orderDocId}'),
                  Text('Order date: ${_dateText(order['date'])}'),
                  Text('Status: $status',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: green)),
                  Text(
                      'Payment method: ${order['payment'] ?? 'Not available'}'),
                  Text('Customer: ${order['customer'] ?? 'Not available'}'),
                  Text('Email: ${order['email'] ?? 'Not available'}'),
                  Text('Phone: ${order['phone'] ?? 'Not available'}'),
                  const Text('Collection point: Mqanduli Centre, Eastern Cape'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Items Ordered',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (items.isEmpty) const Text('No item details available.'),
                  ...items.map((item) {
                    if (item is! Map) return Text(item.toString());
                    final quantity = item['quantity'] is num
                        ? (item['quantity'] as num).toInt()
                        : 0;
                    final price = item['price'] is num
                        ? (item['price'] as num).toDouble()
                        : 0.0;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(item['image']?.toString() ?? '🛒',
                          style: const TextStyle(fontSize: 26)),
                      title: Text(item['name']?.toString() ?? 'Product'),
                      subtitle: Text(
                          'Quantity: $quantity  •  R${price.toStringAsFixed(2)} each'),
                      trailing:
                          Text('R${(price * quantity).toStringAsFixed(2)}'),
                    );
                  }),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('R${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: green)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (status == 'Ready for collection')
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on, color: green),
                title: const Text('Your order is ready for collection'),
                subtitle: const Text('Collect at Mqanduli Centre.'),
                onTap: () => openCollectionMap(context),
              ),
            ),
          if (canCancel) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => cancelCustomerOrder(context, orderDocId),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel Order'),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'You can cancel an order before the seller accepts it.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class OrderHistoryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  const OrderHistoryScreen({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: Text('Please log in to view your orders.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('customerId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Could not load orders: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs.toList()
                  ..sort((a, b) {
                    final da = a.data()['date'];
                    final db = b.data()['date'];
                    final ta = da is Timestamp ? da.millisecondsSinceEpoch : 0;
                    final tb = db is Timestamp ? db.millisecondsSinceEpoch : 0;
                    return tb.compareTo(ta);
                  });
                if (docs.isEmpty) {
                  return const Center(child: Text('No orders placed yet.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final order = doc.data();
                    final status = order['status']?.toString() ?? 'Received';
                    final items =
                        order['items'] is List ? order['items'] as List : [];
                    final total = order['total'] is num
                        ? (order['total'] as num).toDouble()
                        : 0.0;
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long, color: green),
                        title: Text('Order #${order['id'] ?? doc.id}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Status: $status\n'
                          '${items.map((e) => e is Map ? "${e['name']} x${e['quantity']}" : e.toString()).join(', ')}\n'
                          'Total: R${total.toStringAsFixed(2)}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailsScreen(
                              orderDocId: doc.id,
                              order: order,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController currentPassword;
  late final TextEditingController newPassword;
  late final TextEditingController confirmPassword;
  final formKey = GlobalKey<FormState>();
  bool busy = false;

  @override
  void initState() {
    super.initState();
    final account = DemoStore.accounts[DemoStore.currentEmail] ?? {};
    name = TextEditingController(text: account['name'] ?? '');
    phone = TextEditingController(text: account['phone'] ?? '');
    currentPassword = TextEditingController();
    newPassword = TextEditingController();
    confirmPassword = TextEditingController();
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    currentPassword.dispose();
    newPassword.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('Please log in again.');

      if (newPassword.text.isNotEmpty) {
        final email = user.email;
        if (email == null)
          throw StateError('Your account email is unavailable.');
        final credential = EmailAuthProvider.credential(
          email: email,
          password: currentPassword.text,
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword.text);
      }

      await MarketAuth.users.doc(user.uid).update({
        'name': name.text.trim(),
        'phone': phone.text.trim(),
      });

      DemoStore.accounts[DemoStore.currentEmail]?['name'] = name.text.trim();
      DemoStore.accounts[DemoStore.currentEmail]?['phone'] = phone.text.trim();
      currentPassword.clear();
      newPassword.clear();
      confirmPassword.clear();
      DemoStore.changed();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(MarketAuth.errorText(e))),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF5FAF5),
        appBar: AppBar(
          title: const Text('My Profile'),
          backgroundColor: green,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: paleGreen,
                    child: Icon(Icons.person, size: 44, color: green),
                  ),
                ),
                const SizedBox(height: 16),
                Text(DemoStore.currentEmail, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Change Password',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextFormField(
                  controller: currentPassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) =>
                      newPassword.text.isNotEmpty && (v == null || v.isEmpty)
                          ? 'Enter your current password'
                          : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: newPassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New password (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_reset),
                  ),
                  validator: (v) => v != null && v.isNotEmpty && v.length < 6
                      ? 'Use at least 6 characters'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: confirmPassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.verified_user_outlined),
                  ),
                  validator: (v) {
                    if (newPassword.text.isEmpty && (v ?? '').isEmpty)
                      return null;
                    if (newPassword.text.isEmpty) {
                      return 'Enter a new password first';
                    }
                    if (v != newPassword.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: busy ? null : save,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_outlined),
                  label: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(busy ? 'Saving...' : 'Save Profile'),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Your profile details are saved in Firebase. To change your password, enter your current password and confirm the new one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      );
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notifications'),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: Text('Please log in.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('customerId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Could not load updates: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs.toList()
                  ..sort((a, b) {
                    final aDate = a.data()['date'];
                    final bDate = b.data()['date'];
                    final aMs =
                        aDate is Timestamp ? aDate.millisecondsSinceEpoch : 0;
                    final bMs =
                        bDate is Timestamp ? bDate.millisecondsSinceEpoch : 0;
                    return bMs.compareTo(aMs);
                  });
                if (docs.isEmpty) {
                  return const Center(child: Text('No order updates yet.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final order = doc.data();
                    final status = order['status']?.toString() ?? 'Received';
                    final message = status == 'Ready for collection'
                        ? 'Your order is ready for collection at Mqanduli Centre.'
                        : status == 'Collected'
                            ? 'Your order has been successfully collected.'
                            : status == 'Cancelled'
                                ? 'Your order has been cancelled.'
                                : 'Your order status is $status.';
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.notifications_active,
                            color: green),
                        title: Text('Order #${order['id'] ?? doc.id}'),
                        subtitle: Text(message),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailsScreen(
                              orderDocId: doc.id,
                              order: order,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});
  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  final db = FirebaseFirestore.instance;
  int selectedSection = 0;
  bool isSidebarCollapsed = false;
  String get sellerId => FirebaseAuth.instance.currentUser?.uid ?? '';

  final sectionNames = const [
    'Dashboard',
    'New Orders',
    'Ready for collection',
    'Collected Orders',
    'Products',
    'Notifications',
    'Profile',
  ];

  void message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
    }
  }

  Future<void> updateOrder(String orderId, String status) async {
    try {
      final ref = db.collection('orders').doc(orderId);
      final doc = await ref.get();
      if (doc.data()?['sellerId'] != sellerId) {
        throw StateError('This order is not assigned to your shop.');
      }
      final old = doc.data()?['status'];
      if (!((old == 'Received' &&
              (status == 'Accepted' || status == 'Rejected')) ||
          (old == 'Accepted' && status == 'Ready for collection') ||
          (old == 'Ready for collection' && status == 'Collected'))) {
        throw StateError('This order status cannot be changed.');
      }
      await ref.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      message('Order marked: $status');
    } catch (e) {
      message('Could not update order: $e');
    }
  }

  Future<void> setProductAvailability(Product product, bool inStock) async {
    if (!MarketProducts.ownedByMe(product)) return;
    final stock =
        product['stock'] is num ? (product['stock'] as num).toInt() : 0;
    if (inStock && stock <= 0) {
      message(
          'Update the stock quantity before marking this product in stock.');
      return;
    }
    try {
      await MarketProducts.collection
          .doc(product['productId'].toString())
          .update({
        'inStock': inStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      message(inStock
          ? 'Product is now available.'
          : 'Product marked out of stock.');
    } catch (e) {
      message('Could not update product availability: $e');
    }
  }

  Future<void> productDialog({Product? product}) async {
    final name =
        TextEditingController(text: product?['name']?.toString() ?? '');
    final price =
        TextEditingController(text: product?['price']?.toString() ?? '');
    final description =
        TextEditingController(text: product?['description']?.toString() ?? '');
    final stock =
        TextEditingController(text: product?['stock']?.toString() ?? '0');
    String category = product?['category']?.toString() ?? 'Vegetables';
    final form = GlobalKey<FormState>();
    final data = await showDialog<Product>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => AlertDialog(
                  title: Text(product == null ? 'Add Product' : 'Edit Product'),
                  content: SizedBox(
                      width: 360,
                      child: SingleChildScrollView(
                          child: Form(
                              key: form,
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextFormField(
                                        controller: name,
                                        decoration: const InputDecoration(
                                            labelText: 'Product name'),
                                        validator: (v) =>
                                            (v ?? '').trim().isEmpty
                                                ? 'Enter a name'
                                                : null),
                                    TextFormField(
                                        controller: price,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                            labelText: 'Price (R)'),
                                        validator: (v) =>
                                            (double.tryParse(v ?? '') ?? 0) <= 0
                                                ? 'Enter a valid price'
                                                : null),
                                    TextFormField(
                                        controller: stock,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                            labelText: 'Stock quantity'),
                                        validator: (v) =>
                                            (int.tryParse(v ?? '') ?? -1) < 0
                                                ? 'Enter valid stock'
                                                : null),
                                    TextFormField(
                                        controller: description,
                                        decoration: const InputDecoration(
                                            labelText: 'Description')),
                                    DropdownButtonFormField<String>(
                                        value: category,
                                        items: [
                                          'Vegetables',
                                          'Pumpkin & Butternut',
                                          'Chicken',
                                          'Eggs'
                                        ]
                                            .map((c) => DropdownMenuItem(
                                                value: c, child: Text(c)))
                                            .toList(),
                                        onChanged: (v) => update(
                                            () => category = v ?? category)),
                                  ])))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () {
                          if (form.currentState!.validate()) {
                            final quantity = int.parse(stock.text);
                            Navigator.pop(ctx, {
                              'name': name.text.trim(),
                              'price': double.parse(price.text),
                              'stock': quantity,
                              'inStock': quantity > 0,
                              'description': description.text.trim(),
                              'category': category,
                              'image': product?['image'] ??
                                  (category == 'Chicken'
                                      ? '🐔'
                                      : category == 'Eggs'
                                          ? '🥚'
                                          : '🥬'),
                            });
                          }
                        },
                        child: const Text('Save')),
                  ],
                )));
    if (data == null) return;
    try {
      if (product == null) {
        await MarketProducts.collection.add({
          ...data,
          'sellerId': sellerId,
          'sellerEmail': FirebaseAuth.instance.currentUser?.email ?? '',
          'createdAt': FieldValue.serverTimestamp()
        });
      } else {
        if (!MarketProducts.ownedByMe(product)) {
          throw StateError('Not your product');
        }
        await MarketProducts.collection
            .doc(product['productId'].toString())
            .update(data);
      }
      message('Product saved.');
    } catch (e) {
      message('Could not save product: $e');
    }
  }

  Future<void> deleteProduct(Product product) async {
    if (!MarketProducts.ownedByMe(product)) return;
    final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Delete product?'),
                content: Text('Remove ${product['name']} from the market?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'))
                ]));
    if (yes != true) return;
    try {
      await MarketProducts.collection
          .doc(product['productId'].toString())
          .delete();
      message('Product deleted.');
    } catch (e) {
      message('Could not delete product: $e');
    }
  }

  Widget orderList({required String status, required String emptyMessage}) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db
          .collection('orders')
          .where('sellerId', isEqualTo: sellerId)
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Cannot load orders: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs.toList()
          ..sort((a, b) => b.id.compareTo(a.id));
        if (docs.isEmpty) {
          return Center(
              child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Text(emptyMessage)));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: docs.map((doc) {
            final o = doc.data();
            final items = o['items'] is List ? o['items'] as List : [];
            final total = o['total'] is num ? o['total'] as num : 0;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order #${o['id'] ?? doc.id}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 6),
                      Text('Customer: ${o['customer'] ?? ''}'),
                      Text(
                          'Items: ${items.map((i) => i is Map ? "${i['name']} x${i['quantity']}" : i.toString()).join(', ')}'),
                      Text('Total: R${total.toStringAsFixed(2)}'),
                      Text('Status: $status'),
                      if (status == 'Received')
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.icon(
                              onPressed: () => updateOrder(doc.id, 'Accepted'),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Accept Order'),
                            ),
                          ),
                        ),
                      if (status == 'Ready for collection')
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.icon(
                              onPressed: () => updateOrder(doc.id, 'Collected'),
                              icon: const Icon(Icons.shopping_bag, size: 18),
                              label: const Text('Mark as Collected'),
                            ),
                          ),
                        ),
                    ]),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget productsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
          child: Row(children: [
            const Expanded(
                child: Text('My Products',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
            FilledButton.icon(
                onPressed: () => productDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Product')),
          ]),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: MarketProducts.collection
                .where('sellerId', isEqualTo: sellerId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text('Cannot load products: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final products =
                  snapshot.data!.docs.map(MarketProducts.fromDoc).toList();
              if (products.isEmpty) {
                return const Center(
                    child: Text(
                        'No products yet. Tap Add Product to create one.'));
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: products.map((p) {
                  final inStock = p['inStock'] != false &&
                      ((p['stock'] is num) ? (p['stock'] as num) > 0 : true);
                  final stock = p['stock'] ?? 0;
                  return Card(
                    child: ListTile(
                      leading: Text('${p['image'] ?? '🥬'}',
                          style: const TextStyle(fontSize: 28)),
                      title: Text('${p['name']}'),
                      subtitle: Text(
                          '${p['category']} · R${(p['price'] as num).toStringAsFixed(2)} · Stock: $stock · ${inStock ? 'In stock' : 'Out of stock'}'),
                      isThreeLine: true,
                      trailing: Wrap(
                        spacing: 0,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          IconButton(
                              tooltip: inStock
                                  ? 'Mark out of stock'
                                  : 'Mark in stock',
                              icon: Icon(
                                  inStock
                                      ? Icons.inventory_2_outlined
                                      : Icons.add_box_outlined,
                                  color: inStock ? green : Colors.red),
                              onPressed: () =>
                                  setProductAvailability(p, !inStock)),
                          IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => productDialog(product: p)),
                          IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => deleteProduct(p)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget notificationsPage() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db
          .collection('orders')
          .where('sellerId', isEqualTo: sellerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Cannot load notifications: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs.toList()
          ..sort((a, b) => b.id.compareTo(a.id));
        if (docs.isEmpty) {
          return const Center(child: Text('No notifications yet.'));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text('Order Notifications',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            ...docs.map((doc) {
              final order = doc.data();
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_active, color: green),
                  title: Text('Order #${order['id'] ?? doc.id}'),
                  subtitle: Text(
                      'Customer: ${order['customer'] ?? 'Customer'} · Status: ${order['status'] ?? 'Received'}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailsScreen(
                        orderDocId: doc.id,
                        order: order,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  String _money(num value) => 'R${value.toStringAsFixed(2)}';

  Widget dashboardPage() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db
          .collection('orders')
          .where('sellerId', isEqualTo: sellerId)
          .snapshots(),
      builder: (context, orderSnapshot) {
        if (orderSnapshot.hasError) {
          return Center(
              child: Text('Cannot load analytics: ${orderSnapshot.error}'));
        }
        if (!orderSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = orderSnapshot.data!.docs
            .map((d) => {...d.data(), 'docId': d.id})
            .toList();

        int countStatus(String s) =>
            orders.where((o) => o['status'] == s).length;

        final received = countStatus('Received');
        final accepted = countStatus('Accepted');
        final ready = countStatus('Ready for collection');
        final collected = countStatus('Collected');
        final rejected = countStatus('Rejected');
        final cancelled = countStatus('Cancelled');

        final completedOrders = orders.where(
            (o) => o['status'] != 'Cancelled' && o['status'] != 'Rejected');

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final weekDays =
            List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
        int ordersOn(DateTime day) => orders.where((o) {
              final d = o['date'];
              DateTime? parsed;
              if (d is Timestamp) parsed = d.toDate();
              if (d is DateTime) parsed = d;
              if (parsed == null) return false;
              return parsed.year == day.year &&
                  parsed.month == day.month &&
                  parsed.day == day.day;
            }).length;
        final weekCounts = weekDays.map(ordersOn).toList();
        final weekMax = weekCounts.fold<int>(1, (a, b) => a > b ? a : b);

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: MarketProducts.collection
              .where('sellerId', isEqualTo: sellerId)
              .snapshots(),
          builder: (context, productSnapshot) {
            final products = productSnapshot.hasData
                ? productSnapshot.data!.docs
                    .map(MarketProducts.fromDoc)
                    .toList()
                : <Product>[];

            final lowStock = products.where((p) {
              final stock = p['stock'];
              return stock is num && stock > 0 && stock <= 5;
            }).toList();

            final sold = <String, int>{};
            final revenue = <String, double>{};
            for (final o in completedOrders) {
              final items = o['items'];
              if (items is! List) continue;
              for (final item in items) {
                if (item is! Map) continue;
                final name = item['name']?.toString() ?? 'Unknown';
                final qty = item['quantity'] is num
                    ? (item['quantity'] as num).toInt()
                    : 0;
                final price = item['price'] is num
                    ? (item['price'] as num).toDouble()
                    : 0.0;
                sold[name] = (sold[name] ?? 0) + qty;
                revenue[name] = (revenue[name] ?? 0) + (price * qty);
              }
            }
            final topSellers = sold.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            final topFive = topSellers.take(5).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const MarketPageHeader(
                  title: 'Seller Dashboard',
                  subtitle: 'A quick look at your shop performance',
                  icon: Icons.insights_outlined,
                ),
                const SizedBox(height: 18),
                const Text('Order status breakdown',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: Column(children: [
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.inbox_outlined,
                          color: Colors.orange),
                      title: const Text('Received'),
                      trailing: Text('$received'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      dense: true,
                      leading:
                          const Icon(Icons.check_circle_outline, color: green),
                      title: const Text('Accepted'),
                      trailing: Text('$accepted'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.inventory_outlined,
                          color: Colors.blue),
                      title: const Text('Ready for collection'),
                      trailing: Text('$ready'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.done_all_outlined,
                          color: Colors.purple),
                      title: const Text('Collected'),
                      trailing: Text('$collected'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      dense: true,
                      leading:
                          const Icon(Icons.cancel_outlined, color: Colors.red),
                      title: const Text('Rejected'),
                      trailing: Text('$rejected'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.remove_circle_outline,
                          color: Colors.grey),
                      title: const Text('Cancelled'),
                      trailing: Text('$cancelled'),
                    ),
                  ]),
                ),
                const SizedBox(height: 18),
                const Text('Orders this week',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (i) {
                        final count = weekCounts[i];
                        final barHeight = 12 + (count / weekMax) * 60;
                        return Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$count',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Container(
                                height: barHeight,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color:
                                      i == 6 ? green : green.withOpacity(0.45),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                [
                                  'M',
                                  'T',
                                  'W',
                                  'T',
                                  'F',
                                  'S',
                                  'S'
                                ][weekDays[i].weekday - 1],
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.black54),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                if (lowStock.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Text('Low stock (5 or fewer)',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...lowStock.map((p) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.warning_amber_outlined,
                              color: Colors.orange),
                          title: Text('${p['name']}'),
                          subtitle: Text(
                              '${p['category']} · Only ${p['stock']} left'),
                          trailing: IconButton(
                            tooltip: 'Edit product',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => productDialog(product: p),
                          ),
                        ),
                      )),
                ],
                const SizedBox(height: 18),
                const Text('Top selling products',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (topFive.isEmpty)
                  const Card(
                    child: ListTile(
                      leading:
                          Icon(Icons.bar_chart_outlined, color: Colors.black45),
                      title: Text('No sales data yet'),
                    ),
                  )
                else
                  Card(
                    child: Column(children: [
                      ...topFive.asMap().entries.map((entry) {
                        final i = entry.key;
                        final e = entry.value;
                        return Column(children: [
                          ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 12,
                              backgroundColor: paleGreen,
                              child: Text('${i + 1}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: green)),
                            ),
                            title: Text(e.key),
                            subtitle: Text('${e.value} sold'),
                            trailing: Text(
                              _money(revenue[e.key] ?? 0),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, color: green),
                            ),
                          ),
                          if (i != topFive.length - 1) const Divider(height: 1),
                        ]);
                      }),
                    ]),
                  ),
                const SizedBox(height: 24),
              ],
            );
          },
        );
      },
    );
  }

  Widget selectedPage() {
    switch (selectedSection) {
      case 0:
        return dashboardPage();
      case 1:
        return orderList(
            status: 'Received', emptyMessage: 'You have no new orders.');
      case 2:
        return orderList(
            status: 'Ready for collection',
            emptyMessage: 'There are no orders ready for collection.');
      case 3:
        return orderList(
            status: 'Collected',
            emptyMessage: 'There are no collected orders yet.');
      case 4:
        return productsPage();
      case 5:
        return notificationsPage();
      default:
        return const ProfileScreen();
    }
  }

  Widget navigationPanel({required bool inDrawer}) {
    final userName = FirebaseAuth.instance.currentUser?.displayName ?? 'Seller';
    final collapsed = !inDrawer && isSidebarCollapsed;
    const icons = [
      Icons.insights_outlined,
      Icons.shopping_bag_outlined,
      Icons.inventory_outlined,
      Icons.done_all_outlined,
      Icons.storefront_outlined,
      Icons.notifications_none,
      Icons.person_outline,
    ];

    return Container(
      color: const Color(0xFFE8F5E9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(collapsed ? 12 : 18, 12, 8, 12),
            child: Column(
              crossAxisAlignment: collapsed
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: collapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.spaceBetween,
                  children: [
                    if (!collapsed)
                      const Icon(Icons.storefront, color: green, size: 34),
                    if (!inDrawer)
                      IconButton(
                        tooltip: collapsed
                            ? 'Expand navigation'
                            : 'Collapse navigation',
                        icon: Icon(collapsed ? Icons.menu : Icons.menu_open),
                        onPressed: () => setState(() {
                          isSidebarCollapsed = !isSidebarCollapsed;
                        }),
                      ),
                  ],
                ),
                if (!collapsed) ...[
                  const SizedBox(height: 8),
                  const Text("Kwanda's Fresh Market",
                      style: TextStyle(
                          color: green,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Welcome, $userName',
                      style: const TextStyle(color: Colors.black54)),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          ...List.generate(sectionNames.length, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: ListTile(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: collapsed ? 16 : 12),
                selected: selectedSection == index,
                selectedTileColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                leading: Icon(icons[index],
                    color: selectedSection == index ? green : Colors.black54),
                title: collapsed
                    ? null
                    : Text(sectionNames[index],
                        style: TextStyle(
                            color: selectedSection == index
                                ? green
                                : Colors.black87,
                            fontWeight: selectedSection == index
                                ? FontWeight.bold
                                : FontWeight.normal)),
                onTap: () {
                  setState(() => selectedSection = index);
                  if (inDrawer) Navigator.of(context).pop();
                },
              ),
            );
          }),
          const Spacer(),
          const Divider(height: 1),
          ListTile(
            contentPadding:
                EdgeInsets.symmetric(horizontal: collapsed ? 16 : 12),
            leading: const Icon(Icons.logout, color: Colors.red),
            title: collapsed
                ? null
                : const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => DemoStore.logout(context),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        if (isMobile) {
          return Scaffold(
            appBar: AppBar(
              title: Text(sectionNames[selectedSection]),
              backgroundColor: Colors.white,
              foregroundColor: green,
            ),
            drawer: Drawer(
              width: 280,
              child: SafeArea(child: navigationPanel(inDrawer: true)),
            ),
            body: SafeArea(child: selectedPage()),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  width: isSidebarCollapsed ? 76 : 238,
                  child: navigationPanel(inDrawer: false),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 18),
                        color: Colors.white,
                        child: Text(sectionNames[selectedSection],
                            style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                                color: green)),
                      ),
                      Expanded(child: selectedPage()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedTab = 0;
  final ScrollController tabScrollController = ScrollController();
  int pendingSellersCount = 0;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _approvalsSub;

  @override
  void initState() {
    super.initState();

    _approvalsSub = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Seller')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      final pending = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['approved'] != true && data['rejected'] != true;
      }).length;
      setState(() {
        pendingSellersCount = pending;
      });
    });
  }

  @override
  void dispose() {
    _approvalsSub?.cancel();
    tabScrollController.dispose();
    super.dispose();
  }

  void selectTab(int index) {
    setState(() => selectedTab = index);
    if (tabScrollController.hasClients) {
      tabScrollController.animateTo(
        (index * 105.0)
            .clamp(0.0, tabScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  final tabs = const [
    'Overview',
    'Users',
    'Approvals',
    'Products',
    'Orders',
    'Reports'
  ];

  String money(num value) => 'R${value.toStringAsFixed(2)}';

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> assignStarterProduct(Product p) async {
    final sellers =
        await MarketAuth.users.where('role', isEqualTo: 'Seller').get();
    if (!mounted) return;
    final approved =
        sellers.docs.where((d) => d.data()['approved'] == true).toList();
    if (approved.isEmpty) {
      showMessage('Approve a seller first.');
      return;
    }
    final chosen = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
            title: Text('Assign ${p['name']} to seller'),
            children: approved
                .map((d) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, d.id),
                    child: Text(d.data()['name']?.toString() ??
                        d.data()['email']?.toString() ??
                        'Seller')))
                .toList()));
    if (chosen == null) return;
    final seller = approved.firstWhere((d) => d.id == chosen);
    try {
      await MarketProducts.collection.add({
        ...p,
        'sellerId': chosen,
        'sellerEmail': seller.data()['email'] ?? '',
        'stock': 100,
        'createdAt': FieldValue.serverTimestamp(),
      }..remove('legacy'));
      showMessage('Product assigned. Seller can now edit it.');
    } catch (e) {
      showMessage('Could not assign product: $e');
    }
  }

  Widget orderDataBuilder(Widget Function(List<Map<String, dynamic>>) content) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Cannot load orders: ${snapshot.error}');
        }
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final orders = snapshot.data!.docs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                })
            .toList();
        orders.sort((a, b) => b['id'].toString().compareTo(a['id'].toString()));
        return content(orders);
      },
    );
  }

  Widget overview() => orderDataBuilder((orders) {
        final orderValue = orders
            .where(
                (o) => o['status'] != 'Cancelled' && o['status'] != 'Rejected')
            .fold<double>(
                0, (sum, o) => sum + ((o['total'] as num?)?.toDouble() ?? 0));
        return Column(children: [
          const ListTile(
              title: Text('Market Overview',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          Card(
              child: ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('Products'),
                  onTap: () => selectTab(3),
                  trailing: const Icon(Icons.chevron_right))),
          Card(
              child: ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: const Text('Users'),
                  onTap: () => selectTab(1))),
          Card(
              child: ListTile(
                  leading: const Icon(Icons.storefront),
                  title: const Text('Sellers'),
                  onTap: () => selectTab(2))),
          Card(
              child: ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: const Text('Orders'),
                  onTap: () => selectTab(4),
                  trailing: Text('${orders.length}'))),
          Card(
              child: ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title:
                      const Text('Order value (excluding rejected/cancelled)'),
                  onTap: () => selectTab(5),
                  trailing: Text(money(orderValue)))),
        ]);
      });

  Widget users() => Column(children: [
        const ListTile(
            title: Text('Manage Users',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: MarketAuth.users.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return Text('Cannot load users: ${snapshot.error}');
            if (!snapshot.hasData) return const CircularProgressIndicator();
            return Column(
                children: snapshot.data!.docs.map((doc) {
              final data = doc.data();
              return Card(
                  child: ListTile(
                title: Text(data['name']?.toString() ?? 'User'),
                subtitle:
                    Text('${data['email'] ?? ''} • ${data['role'] ?? ''}'),
              ));
            }).toList());
          },
        ),
      ]);

  Widget approvals() => Column(children: [
        const ListTile(
            title: Text('Approve Sellers',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream:
              MarketAuth.users.where('role', isEqualTo: 'Seller').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return Text('Cannot load sellers: ${snapshot.error}');
            if (!snapshot.hasData) return const CircularProgressIndicator();
            if (snapshot.data!.docs.isEmpty)
              return const Text('No sellers registered.');
            return Column(
                children: snapshot.data!.docs.map((doc) {
              final data = doc.data();
              final approved = data['approved'] == true;
              return Card(
                  child: ListTile(
                title: Text(data['name']?.toString() ?? 'Seller'),
                subtitle: Text(
                    '${data['email'] ?? ''}\n${approved ? 'Approved' : 'Awaiting approval'}'),
                isThreeLine: true,
                trailing: approved
                    ? const Icon(Icons.verified, color: green)
                    : Wrap(children: [
                        IconButton(
                            tooltip: 'Approve',
                            icon: const Icon(Icons.check_circle, color: green),
                            onPressed: () async {
                              try {
                                await doc.reference.update({'approved': true});
                                if (mounted) showMessage('Seller approved.');
                              } catch (e) {
                                if (mounted)
                                  showMessage(MarketAuth.errorText(e));
                              }
                            }),
                        IconButton(
                            tooltip: 'Reject',
                            icon: const Icon(Icons.cancel_outlined,
                                color: Colors.red),
                            onPressed: () async {
                              try {
                                await doc.reference.update(
                                    {'rejected': true, 'approved': false});
                                if (mounted) showMessage('Seller rejected.');
                              } catch (e) {
                                if (mounted)
                                  showMessage(MarketAuth.errorText(e));
                              }
                            }),
                      ]),
              ));
            }).toList());
          },
        ),
      ]);

  Widget products() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: MarketProducts.watch(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Text('Cannot load products: ${snapshot.error}');
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final all = MarketProducts.merge(snapshot.data);
        return Column(children: [
          const ListTile(
              title: Text('Manage Products',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          const Text(
              'Assign starter products to an approved seller. Sellers then edit their own products.'),
          ...all.map((p) => Card(
                  child: ListTile(
                title: Text('${p['name']}'),
                subtitle: Text(
                    '${p['category']} · ${money((p['price'] as num?) ?? 0)} · ${p['legacy'] == true ? 'Unassigned starter product' : 'Seller: ${p['sellerEmail'] ?? p['sellerId']}'}'),
                trailing: p['legacy'] == true
                    ? IconButton(
                        tooltip: 'Assign seller',
                        icon: const Icon(Icons.person_add_alt),
                        onPressed: () => assignStarterProduct(p))
                    : const SizedBox(), // Admin cannot delete products
              ))),
        ]);
      });

  Widget orders() => orderDataBuilder((allOrders) {
        final pending =
            allOrders.where((o) => o['status'] == 'Received').toList();
        final other =
            allOrders.where((o) => o['status'] != 'Received').toList();
        Widget orderCard(Map<String, dynamic> o) {
          final items = o['items'];
          final itemText = items is List
              ? items
                  .map((e) => e is Map
                      ? '${e['name']} x${e['quantity']}'
                      : e.toString())
                  .join(', ')
              : 'No items listed';
          return Card(
              child: Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Order #${o['id']}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Customer: ${o['customer'] ?? 'Unknown'}'),
              Text('Status: ${o['status'] ?? 'Unknown'}'),
              Text('Items: $itemText'),
              Text('Total: ${money((o['total'] as num?) ?? 0)}'),
              Text('Seller: ${o['sellerId'] ?? 'Not assigned (older order)'}'),
            ]),
          ));
        }

        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ListTile(
                  title: Text('Manage Orders',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold))),
              Text('Pending / unaccepted (${pending.length})',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              if (pending.isEmpty)
                const ListTile(title: Text('No pending orders')),
              ...pending.map(orderCard),
              const SizedBox(height: 16),
              Text('Other orders (${other.length})',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              ...other.map(orderCard),
            ]);
      });

  Widget reports() => orderDataBuilder((orders) {
        final ready =
            orders.where((o) => o['status'] == 'Ready for collection').toList();
        final readyValue = ready.fold<double>(
            0, (sum, o) => sum + ((o['total'] as num?)?.toDouble() ?? 0));

        final collected =
            orders.where((o) => o['status'] == 'Collected').toList();
        final collectedValue = collected.fold<double>(
            0, (sum, o) => sum + ((o['total'] as num?)?.toDouble() ?? 0));

        int count(String status) =>
            orders.where((o) => o['status'] == status).length;
        Widget reportRow(String label, String value) =>
            Card(child: ListTile(title: Text(label), trailing: Text(value)));
        return Column(children: [
          const ListTile(
              title: Text('Order Reports',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          reportRow('Total orders', '${orders.length}'),
          reportRow('New orders', '${count('Received')}'),
          reportRow('Accepted orders', '${count('Accepted')}'),
          reportRow('Rejected orders', '${count('Rejected')}'),
          reportRow('Cancelled orders', '${count('Cancelled')}'),
          reportRow('Ready for collection', '${ready.length}'),
          reportRow('Value of ready orders', money(readyValue)),
          reportRow('Collected orders', '${collected.length}'),
          reportRow('Value of collected orders', money(collectedValue)),
          const Padding(
              padding: EdgeInsets.all(8),
              child:
                  Text('Order values do not confirm payment or actual sales.')),
        ]);
      });

  @override
  Widget build(BuildContext context) {
    final pages = [
      overview(),
      users(),
      approvals(),
      products(),
      orders(),
      reports()
    ];
    return Scaffold(
      appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: green,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
                tooltip: 'Logout',
                icon: const Icon(Icons.logout),
                onPressed: () => DemoStore.logout(context))
          ]),
      body: Column(children: [
        const Padding(
            padding: EdgeInsets.all(5),
            child: Text(
                'Use the arrows or swipe the tabs to view Orders and Reports',
                style: TextStyle(fontSize: 11, color: Colors.black54))),
        Container(
          color: paleGreen,
          child: Row(children: [
            IconButton(
              tooltip: 'Previous admin section',
              icon: const Icon(Icons.chevron_left),
              onPressed:
                  selectedTab > 0 ? () => selectTab(selectedTab - 1) : null,
            ),
            Expanded(
              child: SizedBox(
                height: 58,
                child: ListView.builder(
                  controller: tabScrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: tabs.length,
                  itemBuilder: (context, index) {
                    final isApprovalsTab = tabs[index] == 'Approvals';
                    final showBadge = isApprovalsTab && pendingSellersCount > 0;

                    Widget chip = ChoiceChip(
                      label: Text(tabs[index]),
                      selected: selectedTab == index,
                      onSelected: (_) => selectTab(index),
                    );

                    if (showBadge) {
                      chip = Badge(
                        label: Text('$pendingSellersCount'),
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        child: chip,
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 3, vertical: 8),
                      child: chip,
                    );
                  },
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next admin section',
              icon: const Icon(Icons.chevron_right),
              onPressed: selectedTab < tabs.length - 1
                  ? () => selectTab(selectedTab + 1)
                  : null,
            ),
          ]),
        ),
        Expanded(
            child: ListView(
                padding: const EdgeInsets.all(12),
                children: [pages[selectedTab]])),
      ]),
    );
  }
}
