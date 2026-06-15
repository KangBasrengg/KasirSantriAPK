import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Ganti dengan URL backend Anda saat di-deploy (misalnya Render atau IP lokal saat test di emulator/HP)
  // 10.0.2.2 adalah localhost jika dari Android Emulator
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success']) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['data']['token']);
      await prefs.setString('user_name', data['data']['user']['nama']);
    } else {
      throw Exception(data['message'] ?? 'Login gagal');
    }
    return data;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_name');
  }

  static Future<List<dynamic>> getProducts({String search = ''}) async {
    final headers = await getHeaders();
    final url = search.isNotEmpty 
      ? '$baseUrl/produk?limit=50&search=$search'
      : '$baseUrl/produk?limit=50';
      
    final res = await http.get(Uri.parse(url), headers: headers);
    final data = jsonDecode(res.body);
    
    if (res.statusCode == 200) {
      return data['data'];
    } else {
      throw Exception('Gagal memuat produk');
    }
  }

  static Future<Map<String, dynamic>> createTransaction(List<Map<String, dynamic>> items, String metodeBayar, double bayar) async {
    final headers = await getHeaders();
    final payload = {
      'items': items,
      'metode_bayar': metodeBayar,
      'bayar': bayar
    };

    final res = await http.post(
      Uri.parse('$baseUrl/transaksi'),
      headers: headers,
      body: jsonEncode(payload),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode == 201) {
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Gagal membuat transaksi');
    }
  }
}
