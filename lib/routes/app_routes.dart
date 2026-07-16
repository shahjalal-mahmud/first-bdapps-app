/// Application route names. Used by GetX navigation.
abstract class AppRoutes {
  /// Splash screen is the initial route; it decides where to navigate next.
  static const initial = '/';

  /// Phone registration (only reached when no phone is cached locally).
  static const phoneRegistration = '/phone-registration';

  /// Subscription screen (offers Subscribe Now / unsubscribe redirect).
  static const subscription = '/subscription';

  /// OTP verification screen.
  static const otp = '/otp';

  /// Home screen - gated by an active subscription.
  static const home = '/home';

  /// Quiz screen.
  static const quiz = '/quiz';

  /// Quiz result screen.
  static const result = '/result';

  /// AI chat screen.
  static const aiChat = '/ai-chat';

  /// Settings screen with subscription management section.
  static const settings = '/settings';
}
