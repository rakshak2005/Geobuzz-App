class AppStrings {
  static const String appName = 'GeoBuzz';
  static const String appTagline = 'Automate your world by location.';

  // Navigation
  static const String navHome = 'Dashboard';
  static const String navRules = 'Rules';
  static const String navHistory = 'History';
  static const String navSettings = 'Settings';

  // Rule Wizard
  static const String createRuleTitle = 'Create Automation';
  static const String editRuleTitle = 'Edit Automation';
  static const String stepLocation = '1. Select Location';
  static const String stepRadius = '2. Set Radius';
  static const String stepTrigger = '3. Choose Trigger';
  static const String stepAction = '4. Configure Action';
  static const String stepReview = '5. Save Rule';

  // Triggers
  static const String triggerEnter = 'ENTER';
  static const String triggerExit = 'EXIT';
  static const String triggerEnterExit = 'ENTER & EXIT';
  static const String triggerNear = 'NEAR';

  // Actions
  static const String actionAlarm = 'Alarm';
  static const String actionSoundProfile = 'Sound Profile';
  static const String actionWifi = 'WiFi Action';
  static const String actionBluetooth = 'Bluetooth Action';
  static const String actionReminder = 'Reminder';

  // Sound Profiles
  static const String soundSilent = 'Silent';
  static const String soundVibrate = 'Vibrate';
  static const String soundNormal = 'Normal (Ring)';

  // Tracking
  static const String trackingActive = 'Location Engine Active';
  static const String trackingPaused = 'Location Engine Paused';
  static const String trackingDesc = 'Continuous geofence evaluation running on device';
}