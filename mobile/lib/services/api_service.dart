import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // URL Backend Online (Vercel)
  static const String baseUrl = 'https://kasirsantribe.vercel.app/api';

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

  static Future<List<dynamic>> getCategories() async {
    final headers = await getHeaders();
    final res = await http.get(Uri.parse('$baseUrl/produk/categories'), headers: headers);
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return data['data'];
    } else {
      throw Exception('Gagal memuat kategori');
    }
  }

  static Future<void> createCategory(String name) async {
    final headers = await getHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/produk/categories'),
      headers: headers,
      body: jsonEncode({'nama': name}),
    );
    if (res.statusCode != 201) {
      final data = jsonDecode(res.body);
      throw Exception(data['message'] ?? 'Gagal membuat kategori');
    }
  }

  static Future<void> createProduct(Map<String, dynamic> product, File? imageFile) async {
    final token = await getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/produk'));
    
    request.headers['Authorization'] = 'Bearer $token';
    
    product.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        request.fields[key] = value.toString();
      }
    });

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'foto', 
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal membuat produk');
    }
  }

  static Future<void> updateProduct(dynamic id, Map<String, dynamic> product, File? imageFile) async {
    final token = await getToken();
    var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/produk/$id'));
    
    request.headers['Authorization'] = 'Bearer $token';
    
    product.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        request.fields[key] = value.toString();
      }
    });

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'foto', 
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal update produk');
    }
  }

  static Future<void> deleteProduct(dynamic id) async {
    final headers = await getHeaders();
    final res = await http.delete(Uri.parse('$baseUrl/produk/$id'), headers: headers);
    if (res.statusCode != 200) {
      throw Exception('Gagal menghapus produk');
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

  static Future<List<dynamic>> getTransactions({String? date}) async {
    final headers = await getHeaders();
    String url = '$baseUrl/transaksi?limit=100';
    if (date != null && date.isNotEmpty) {
      url += '&tanggal_mulai=$date&tanggal_akhir=$date';
    }
      
    final res = await http.get(Uri.parse(url), headers: headers);
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return data['data'];
    } else {
      throw Exception('Gagal memuat transaksi');
    }
  }

  static Future<Map<String, dynamic>> getTransactionDetail(dynamic id) async {
    final headers = await getHeaders();
    final res = await http.get(Uri.parse('$baseUrl/transaksi/$id'), headers: headers);
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return data['data'];
    } else {
      throw Exception('Gagal memuat detail transaksi');
    }
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    final headers = await getHeaders();
    final res = await http.get(Uri.parse('$baseUrl/laporan/dashboard'), headers: headers);
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return data['data'];
    } else {
      throw Exception('Gagal memuat dashboard');
    }
  }

  static Future<Map<String, dynamic>> getSalesReport({String periode = 'harian'}) async {
    final headers = await getHeaders();
    final res = await http.get(Uri.parse('$baseUrl/laporan/penjualan?periode=$periode'), headers: headers);
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return data['data'];
    } else {
      throw Exception('Gagal memuat laporan penjualan');
    }
  }

  static Future<Map<String, dynamic>> getProfitReport() async {
    final headers = await getHeaders();
    final res = await http.get(Uri.parse('$baseUrl/laporan/laba'), headers: headers);
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return data['data'];
    } else {
      throw Exception('Gagal memuat laporan laba');
    }
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> payload) async {
    final headers = await getHeaders();
    final res = await http.put(
      Uri.parse('$baseUrl/auth/profile'),
      headers: headers,
      body: jsonEncode(payload),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success']) {
      // Update local name if changed
      if (data['data'] != null && data['data']['nama'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', data['data']['nama']);
      }
      return data;
    } else {
      throw Exception(data['message'] ?? 'Gagal update profil');
    }
  }
}
