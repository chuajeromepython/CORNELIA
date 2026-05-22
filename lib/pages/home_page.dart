import 'dart:async';
import 'dart:ui';
import 'package:firebase_ai/pages/sandbox.dart';
import 'package:firebase_ai/pages/user_profile.dart';
import 'package:firebase_ai/pages/analytics_page.dart';
import 'package:firebase_ai/pages/search_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  String? username;
  int _currentIndex = 0;
  bool isLoadingUsername = true;
  late final List<Widget> _pages;

  bool _navVisible = true;
  Timer? _hideTimer;

  void _resetHideTimer() {
    _hideTimer?.cancel();
    if (!_navVisible) setState(() => _navVisible = true);
    _hideTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _navVisible = false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  Future<void> loadUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => isLoadingUsername = true);
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      setState(() {
        username = doc['username'];
        isLoadingUsername = false;
      });
    } else {
      setState(() {
        username = "User";
        isLoadingUsername = false;
      });
    }
    setState(() {
      username = doc['username'];
    });
  }

  @override
  void initState() {
    super.initState();
    loadUsername();
    _resetHideTimer();

    _pages = [
      Analytics(key: ValueKey("page1")),
      Search(key: ValueKey("page2")),
      SandboxPage(key: ValueKey("page3")),
      UserProfile(key: ValueKey("page4")),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetHideTimer(),
      onPointerMove: (_) => _resetHideTimer(),
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _currentIndex >= _pages.length ? 0 : _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          offset: _navVisible ? Offset.zero : const Offset(0, 1),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _navVisible ? 1.0 : 0.0,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Material(
                    color: const Color.fromARGB(
                      255,
                      23,
                      23,
                      30,
                    ).withValues(alpha: 0.5),
                    child: BottomNavigationBar(
                      type: BottomNavigationBarType.fixed,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      currentIndex: _currentIndex,
                      selectedItemColor: Colors.white,
                      unselectedItemColor: Colors.white54,
                      onTap: (index) {
                        if (index < _pages.length) {
                          setState(() => _currentIndex = index);
                        }
                        _resetHideTimer();
                      },
                      items: [
                        const BottomNavigationBarItem(
                          icon: FaIcon(FontAwesomeIcons.chartLine),
                          label: "Dashboard",
                        ),
                        const BottomNavigationBarItem(
                          icon: FaIcon(FontAwesomeIcons.magnifyingGlass),
                          label: "Search",
                        ),
                        const BottomNavigationBarItem(
                          icon: FaIcon(FontAwesomeIcons.flask),
                          label: "Sandbox",
                        ),
                        BottomNavigationBarItem(
                          icon: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (isLoadingUsername)
                                const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              else
                                const FaIcon(FontAwesomeIcons.user),
                            ],
                          ),
                          label: isLoadingUsername ? "" : username ?? "User",
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
