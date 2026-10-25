/// Application route name constants
abstract class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  static const String home = '/home';
  static const String search = '/search';
  static const String reportLost = '/report-lost';
  static const String reportFound = '/report-found';
  static const String myReports = '/my-reports';
  static const String itemDetails = '/item-details/:id';
  static const String claimItem = '/claim-item/:id';
  static const String profile = '/profile';

  // Admin Dashboard Routes (Web)
  static const String adminLogin = '/admin/login';
  static const String adminDashboard = '/admin';
  static const String adminOverview = '/admin/overview';
  static const String adminUsers = '/admin/users';
  static const String adminReports = '/admin/lost-reports';
  static const String adminLostReports = '/admin/lost-reports';
  static const String adminFoundReports = '/admin/found-reports';
  static const String adminClaims = '/admin/claims';
  static const String adminClaimed = '/admin/claimed';
  static const String adminUnclaimed = '/admin/unclaimed';
  static const String adminActivity = '/admin/activity';
  static const String adminAnalytics = '/admin/analytics';
}
