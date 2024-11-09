Future<Map<String, String>> someApiCall() async {
  // Örnek bir API çağrısı simülasyonu
  await Future.delayed(
      const Duration(seconds: 1)); // API çağrısı simüle ediliyor
  return {'status': 'success', 'data': 'Sample data'};
}
