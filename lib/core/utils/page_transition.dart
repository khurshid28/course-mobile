import 'package:flutter/material.dart';

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  FadePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           // Fade + slight slide up animation
           final fadeAnimation = CurvedAnimation(
             parent: animation,
             curve: Curves.easeInOut,
           );

           final slideAnimation =
               Tween<Offset>(
                 begin: const Offset(0.0, 0.03),
                 end: Offset.zero,
               ).animate(
                 CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
               );

           return FadeTransition(
             opacity: fadeAnimation,
             child: SlideTransition(position: slideAnimation, child: child),
           );
         },
       );
}

class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  ScalePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
             CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
           );

           final fadeAnimation = CurvedAnimation(
             parent: animation,
             curve: Curves.easeInOut,
           );

           return FadeTransition(
             opacity: fadeAnimation,
             child: ScaleTransition(scale: scaleAnimation, child: child),
           );
         },
       );
}

// Extension for easy navigation with fade transition
extension NavigatorExtension on BuildContext {
  Future<T?> pushWithFade<T>(Widget page) {
    return Navigator.of(this).push<T>(FadePageRoute(page: page));
  }

  Future<T?> pushWithScale<T>(Widget page) {
    return Navigator.of(this).push<T>(ScalePageRoute(page: page));
  }

  Future<T?> pushReplacementWithFade<T, TO>(Widget page) {
    return Navigator.of(this).pushReplacement<T, TO>(FadePageRoute(page: page));
  }

  Future<T?> pushAndRemoveUntilWithFade<T>(
    Widget page,
    bool Function(Route<dynamic>) predicate,
  ) {
    return Navigator.of(
      this,
    ).pushAndRemoveUntil<T>(FadePageRoute(page: page), predicate);
  }
}
