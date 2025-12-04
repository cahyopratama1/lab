import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hammer_test_result.dart';
import '../models/sand_cone_test_result.dart';
import '../models/uji_kuat_result.dart';
import '../models/konversi_result.dart';
import 'auth_service.dart';

class UnifiedReport {
  final String id;
  final String type; 
  final DateTime date;
  final String title;
  final String summary;
  final Map<String, dynamic> data;
  final String username; 
  
  UnifiedReport({
    required this.id,
    required this.type,
    required this.date,
    required this.title,
    required this.summary,
    required this.data,
    required this.username, 
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'date': date.toIso8601String(),
      'title': title,
      'summary': summary,
      'data': data,
      'username': username, 
    };
  }

  factory UnifiedReport.fromJson(Map<String, dynamic> json) {
    return UnifiedReport(
      id: json['id'],
      type: json['type'],
      date: DateTime.parse(json['date']),
      title: json['title'],
      summary: json['summary'],
      data: Map<String, dynamic>.from(json['data']),
      username: json['username'] ?? '', 
    );
  }
}

class UnifiedReportService {
  static const String _storageKey = 'unified_reports';
  final AuthService _authService = AuthService();
  
  
  Future<String> _getCurrentUsername() async {
    final username = await _authService.getCurrentUsername();
    return username ?? 'guest';
  }
  
  
  Future<void> saveKonversiBetonReport(KonversiResult result) async {
    final username = await _getCurrentUsername();
    
    final report = UnifiedReport(
      id: 'KB_${DateTime.now().millisecondsSinceEpoch}',
      type: 'konversi_beton',
      date: DateTime.now(),
      title: 'Konversi Umur Beton - ${result.umurBeton.toStringAsFixed(0)} Hari (${result.jenisBendaUjiDisplay})',
      summary: 'Kuat Tekan 28 Hari: ${result.hasilKonversi.toStringAsFixed(2)} ${result.satuanDisplay} • ${result.jenisBendaUjiDisplay} • Faktor: ${result.faktorKonversi.toStringAsFixed(3)} • ${result.karakteristik}',
      data: result.toJson(),
      username: username, 
    );
    
    await _saveReport(report);
  }
  
  
  Future<void> saveSandConeReport(SandConeTestResult result) async {
    final username = await _getCurrentUsername();
    
    String klasifikasi;
    if (result.persentaseKepadatan >= 95) {
      klasifikasi = 'Baik';
    } else if (result.persentaseKepadatan >= 90) {
      klasifikasi = 'Sedang';
    } else {
      klasifikasi = 'Kurang';
    }
    
    String photoInfo = result.hasDokumentasiFoto ? ' • ${result.jumlahFoto} foto' : '';
    
    final report = UnifiedReport(
      id: 'SC_${DateTime.now().millisecondsSinceEpoch}',
      type: 'sand_cone',
      date: DateTime.now(),
      title: 'Sand Cone Test',
      summary: 'Berat Isi Kering: ${result.beratIsiTanahKering.toStringAsFixed(3)} g/cm³ • Kepadatan: ${result.persentaseKepadatan.toStringAsFixed(1)}% • $klasifikasi$photoInfo',
      data: result.toJson(),
      username: username, 
    );
    
    await _saveReport(report);
  }
  
  
  Future<void> saveHammerTestReport(HammerTestResult result) async {
    final username = await _getCurrentUsername();
    
    String photoInfo = result.hasDokumentasiFoto ? ' • ${result.jumlahFoto} foto' : '';
    
    final report = UnifiedReport(
      id: 'HT_${DateTime.now().millisecondsSinceEpoch}',
      type: 'hammer_test',
      date: result.testDate,
      title: 'Hammer Test - ${result.location}',
      summary: 'Kuat Tekan: ${result.estimatedCompressiveStrength.toStringAsFixed(2)} MPa • ${result.qualityStatus}$photoInfo',
      data: result.toMap(),
      username: username, 
    );
    
    await _saveReport(report);
  }
  
  Future<void> saveUjiKuatReport(UjiKuatResult result, UjiKuatData data) async {
    final username = await _getCurrentUsername();
    
    String photoInfo = result.hasPhotos() ? ' • ${result.getPhotoCount()} foto' : '';
    int umurBeton = data.getUmurBeton();
    
    final report = UnifiedReport(
      id: 'UK_${DateTime.now().millisecondsSinceEpoch}',
      type: 'uji_kuat',
      date: result.tanggalPengujian,
      title: 'Uji Kuat Tekan - ${data.mutuBeton} (${umurBeton} hari)',
      summary: 'Kuat Tekan: ${result.kuatTekan.toStringAsFixed(2)} MPa • ${result.statusKualitas}$photoInfo',
      data: {
        'result': result.toMap(),
        'data': {
          'sisiKubus': data.sisiKubus,
          'diameter': data.diameter,
          'beban': data.beban,
          'tanggalPembuatan': data.tanggalPembuatan.toIso8601String(),
          'tanggalPengujian': data.tanggalPengujian.toIso8601String(),
          'umurBeton': umurBeton,
          'mutuBeton': data.mutuBeton,
          'beratBendaUji': data.beratBendaUji,
          'pekerjaan': data.pekerjaan,
          'lokasi': data.lokasi,
          'photoPaths': data.photoPaths,
        },
      },
      username: username,
    );
    
    await _saveReport(report);
  }
  
  
  Future<void> _saveReport(UnifiedReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final allReports = await _getAllReportsRaw(); 
    allReports.insert(0, report);
    
    
    if (allReports.length > 500) {
      allReports.removeRange(500, allReports.length);
    }
    
    final jsonList = allReports.map((r) => r.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }
  
  
  Future<List<UnifiedReport>> _getAllReportsRaw() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => UnifiedReport.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
  
  
  Future<List<UnifiedReport>> getAllReports() async {
    final username = await _getCurrentUsername();
    final allReports = await _getAllReportsRaw();
    
   
    return allReports.where((r) => r.username == username).toList();
  }
  
  
  Future<List<UnifiedReport>> getReportsByType(String type) async {
    final allReports = await getAllReports();
    return allReports.where((r) => r.type == type).toList();
  }
  
 
  Future<List<UnifiedReport>> getReportsByDateRange(DateTime start, DateTime end) async {
    final allReports = await getAllReports();
    return allReports.where((r) {
      return r.date.isAfter(start.subtract(const Duration(days: 1))) &&
             r.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }
  
  
  Future<void> deleteReport(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final username = await _getCurrentUsername();
    final allReports = await _getAllReportsRaw();
    
   
    allReports.removeWhere((r) => r.id == id && r.username == username);
    
    final jsonList = allReports.map((r) => r.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }
  
  
  Future<void> clearAllReports() async {
    final prefs = await SharedPreferences.getInstance();
    final username = await _getCurrentUsername();
    final allReports = await _getAllReportsRaw();
    
    
    allReports.removeWhere((r) => r.username == username);
    
    final jsonList = allReports.map((r) => r.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }
  
  
  Future<Map<String, int>> getReportStatistics() async {
    final reports = await getAllReports();
    return {
      'total': reports.length,
      'sand_cone': reports.where((r) => r.type == 'sand_cone').length,
      'hammer_test': reports.where((r) => r.type == 'hammer_test').length,
      'uji_kuat': reports.where((r) => r.type == 'uji_kuat').length,
      'konversi_beton': reports.where((r) => r.type == 'konversi_beton').length,
    };
  }
  
 
  KonversiResult getKonversiBetonResult(UnifiedReport report) {
    if (report.type != 'konversi_beton') {
      throw Exception('Report is not a Konversi Beton');
    }
    return KonversiResult.fromJson(report.data);
  }
  
  SandConeTestResult getSandConeResult(UnifiedReport report) {
    if (report.type != 'sand_cone') {
      throw Exception('Report is not a Sand Cone Test');
    }
    return SandConeTestResult.fromJson(report.data);
  }
  
  HammerTestResult getHammerTestResult(UnifiedReport report) {
    if (report.type != 'hammer_test') {
      throw Exception('Report is not a Hammer Test');
    }
    return HammerTestResult.fromMap(report.data);
  }
  
  UjiKuatResult getUjiKuatResult(UnifiedReport report) {
    if (report.type != 'uji_kuat') {
      throw Exception('Report is not an Uji Kuat Test');
    }
    return UjiKuatResult.fromMap(report.data['result']);
  }
  
  UjiKuatData getUjiKuatData(UnifiedReport report) {
    if (report.type != 'uji_kuat') {
      throw Exception('Report is not an Uji Kuat Test');
    }
    
    final dataJson = report.data['data'];
    return UjiKuatData(
      sisiKubus: dataJson['sisiKubus']?.toDouble(),
      diameter: dataJson['diameter']?.toDouble(),
      beban: dataJson['beban'].toDouble(),
      tanggalPembuatan: DateTime.parse(dataJson['tanggalPembuatan']),
      tanggalPengujian: DateTime.parse(dataJson['tanggalPengujian']),
      mutuBeton: dataJson['mutuBeton'],
      beratBendaUji: dataJson['beratBendaUji']?.toDouble(),
      pekerjaan: dataJson['pekerjaan'],
      lokasi: dataJson['lokasi'],
      photoPaths: dataJson['photoPaths'] != null 
          ? List<String>.from(dataJson['photoPaths']) 
          : null,
    );
  }
}