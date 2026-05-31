class Config {
  static const String apiBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:7114/api',
  );

  static const String paypalReturnUrl = String.fromEnvironment(
    'PAYPAL_RETURN_URL',
    defaultValue: 'eknjiga://paypal-return',
  );

  static const String paypalCancelUrl = String.fromEnvironment(
    'PAYPAL_CANCEL_URL',
    defaultValue: 'eknjiga://paypal-cancel',
  );
}
