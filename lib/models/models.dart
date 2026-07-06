import 'package:flutter/material.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String nationalId;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.nationalId,
  });
}

class Station {
  final String id;
  final String name;
  final double lat;
  final double lng;

  Station({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
  });
}

class TrainSchedule {
  final String id;
  final String trainNumber;
  final String trainName;
  final Station from;
  final Station to;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final List<Station> stops;
  final Map<String, int> prices;
  final Map<String, int> availableSeats;
  final TrainStatus? currentStatus;

  TrainSchedule({
    required this.id,
    required this.trainNumber,
    required this.trainName,
    required this.from,
    required this.to,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.stops,
    required this.prices,
    required this.availableSeats,
    this.currentStatus,
  });

  TrainSchedule copyWithStatus(TrainStatus newStatus) {
    return TrainSchedule(
      id: id,
      trainNumber: trainNumber,
      trainName: trainName,
      from: from,
      to: to,
      departureTime: departureTime,
      arrivalTime: arrivalTime,
      duration: duration,
      stops: stops,
      prices: prices,
      availableSeats: availableSeats,
      currentStatus: newStatus,
    );
  }
}

class IncidentReport {
  final String id;
  final String reportNumber;
  final String passengerName;
  final String nationalId;
  final String station;
  final String violationType;
  final String description;
  final DateTime createdAt;
  final bool resolved;
  final String trainNumber;

  IncidentReport({
    required this.id,
    required this.reportNumber,
    required this.passengerName,
    required this.nationalId,
    required this.station,
    required this.violationType,
    required this.description,
    required this.createdAt,
    this.resolved = false,
    required this.trainNumber,
  });
}

class Booking {
  final String bookingId;
  final String ticketNumber;
  final String passengerName;
  final String trainNumber;
  final String trainName;
  final Station from;
  final Station to;
  final String departureTime;
  final String arrivalTime;
  final String date;
  final String seatClass;
  final int seatNumber;
  final int price;
  final BookingStatus status;
  final List<Station> stops;
  final int currentStopIndex;

  Booking({
    required this.bookingId,
    required this.ticketNumber,
    required this.passengerName,
    required this.trainNumber,
    required this.trainName,
    required this.from,
    required this.to,
    required this.departureTime,
    required this.arrivalTime,
    required this.date,
    required this.seatClass,
    required this.seatNumber,
    required this.price,
    required this.status,
    required this.stops,
    required this.currentStopIndex,
  });
}

enum BookingStatus { valid, scanned, invalid }

class SampleData {
  static final Map<String, String> stationNameEn = {
    'القاهرة': 'Cairo',
    'الجيزة': 'Giza',
    'بنها': 'Banha',
    'طنطا': 'Tanta',
    'المنصورة': 'Mansoura',
    'الإسكندرية': 'Alexandria',
    'أسيوط': 'Asyut',
    'الأقصر': 'Luxor',
    'أسوان': 'Aswan',
    'بورسعيد': 'Port Said',
    'السويس': 'Suez',
    'سوهاج': 'Sohag',
    'طلخا': 'Talkha',
    'سمنود': 'Samanoud',
    'المحلة الكبرى': 'El Mahalla El Kubra',
    'محلة روح': 'Mahallat Ruh',
    'كفر الزيات': 'Kafr El Zayat',
    'إيتاي البارود': 'Itay El Barud',
    'دمنهور': 'Damanhur',
    'سيدي جابر': 'Sidi Gaber',
    'شبرا الخيمة': 'Shubra El Kheima',
    'قويسنا': 'Quesna',
    'بركة السبع': 'Barkat El Saba',
    'التوفيقية': 'El Tawfikeya',
    'أبو حمص': 'Abu Homos',
    'كفر الدوار': 'Kafr El Dawar',
    'الصعيد': 'El Saeeed',
    'بني سويف': 'Beni Suef',
    'المنيا': 'Minya',
    'أبو تيج': 'Abu Tig',
    'طيما': 'Tima',
    'طهطا': 'Tahta',
    'المراغة': 'El Maragha',
    'المنشأة': 'El Monshaah',
    'جرجا': 'Girga',
    'البلينا': 'El Balyana',
    'أبو تشت': 'Abu Tesht',
    'فرشوط': 'Farshout',
    'نجع حمادي': 'Nag Hammadi',
    'دشنا': 'Deshna',
    'قنا': 'Qena',
    'قفط': 'Qift',
    'قوص': 'Qus',
    'الرزيات': 'El Rizayat',
    'إسنا': 'Esna',
    'السباعية': 'El Sibaiya',
    'إدفو': 'Edfu',
    'سلوة البحري': 'Silwa El Bahari',
    'كلابشة': 'Kalabsha',
    'كوم أمبو': 'Kom Ombo',
    'دراو': 'Daraw',
    'أبو قرقاص': 'Abu Qurqas',
    'ملوي': 'Malawi',
    'دير مواس': 'Deir Mawas',
    'ديروط': 'Dayrut',
    'القوصية': 'El Quseyya',
    'منفلوط': 'Manfalut',
    'منقباد': 'Manqabad',
    'الطابق': 'El Tabaq',
    'الحوامدية': 'El Hawamdeya',
    'البدرشين': 'El Badrasheen',
    'طوره': 'Tora',
    'التبين': 'El Tebin',
  };

  static final Map<String, String> trainNameEn = {
    'خاص': 'Special',
    'روسي': 'Russian',
    'مكيف': 'AC',
    'مكيف روسي': 'AC Russian',
    'نوم': 'Sleeping',
    'تالجو': 'Talgo',
  };

  static final Map<String, String> classNameEn = {
    'درجة أولى': 'First Class',
    'درجة ثانية': 'Second Class',
    'درجة ثالثة': 'Third Class',
  };

  static List<String> getTrainNumbers() {
    return _allTrains.map((train) => train.trainNumber).toList();
  }

  static List<Map<String, String>> getTrainsList(bool isArabic) {
    final List<Map<String, String>> result = [];
    final seenNumbers = <String>{};

    for (var train in _allTrains) {
      if (!seenNumbers.contains(train.trainNumber)) {
        seenNumbers.add(train.trainNumber);
        result.add({
          'number': train.trainNumber,
          'name': getTrainName(train.trainName, isArabic),
          'display':
              '${train.trainNumber} - ${getTrainName(train.trainName, isArabic)}',
        });
      }
    }
    return result;
  }

  static TrainSchedule? getTrainByNumber(String trainNumber) {
    try {
      return _allTrains.firstWhere((train) => train.trainNumber == trainNumber);
    } catch (e) {
      return null;
    }
  }

  static final List<Station> mainStations = [
    Station(id: 's1', name: 'القاهرة', lat: 30.0626, lng: 31.2497),
    Station(id: 's2', name: 'الجيزة', lat: 30.0126, lng: 31.2119),
    Station(id: 's3', name: 'بنها', lat: 30.4667, lng: 31.1833),
    Station(id: 's4', name: 'طنطا', lat: 30.7865, lng: 30.9973),
    Station(id: 's5', name: 'المنصورة', lat: 31.0364, lng: 31.3807),
    Station(id: 's6', name: 'الإسكندرية', lat: 31.2001, lng: 29.9187),
    Station(id: 's7', name: 'أسيوط', lat: 27.1783, lng: 31.1859),
    Station(id: 's8', name: 'الأقصر', lat: 25.6872, lng: 32.6396),
    Station(id: 's9', name: 'أسوان', lat: 24.0889, lng: 32.8998),
    Station(id: 's10', name: 'بورسعيد', lat: 31.2653, lng: 32.3019),
    Station(id: 's11', name: 'السويس', lat: 29.9668, lng: 32.5498),
    Station(id: 's12', name: 'سوهاج', lat: 26.5591, lng: 31.6956),
  ];

  static final List<Station> allStations = [
    Station(id: 's1', name: 'القاهرة', lat: 30.0626, lng: 31.2497),
    Station(id: 's2', name: 'الجيزة', lat: 30.0126, lng: 31.2119),
    Station(id: 's3', name: 'بنها', lat: 30.4667, lng: 31.1833),
    Station(id: 's4', name: 'طنطا', lat: 30.7865, lng: 30.9973),
    Station(id: 's5', name: 'المنصورة', lat: 31.0364, lng: 31.3807),
    Station(id: 's6', name: 'الإسكندرية', lat: 31.2001, lng: 29.9187),
    Station(id: 's7', name: 'أسيوط', lat: 27.1783, lng: 31.1859),
    Station(id: 's8', name: 'الأقصر', lat: 25.6872, lng: 32.6396),
    Station(id: 's9', name: 'أسوان', lat: 24.0889, lng: 32.8998),
    Station(id: 's10', name: 'بورسعيد', lat: 31.2653, lng: 32.3019),
    Station(id: 's11', name: 'السويس', lat: 29.9668, lng: 32.5498),
    Station(id: 's12', name: 'سوهاج', lat: 26.5591, lng: 31.6956),
    Station(id: 's13', name: 'طلخا', lat: 31.0500, lng: 31.3667),
    Station(id: 's14', name: 'سمنود', lat: 30.9500, lng: 31.2500),
    Station(id: 's15', name: 'المحلة الكبرى', lat: 30.9667, lng: 31.1667),
    Station(id: 's16', name: 'محلة روح', lat: 30.9500, lng: 31.0833),
    Station(id: 's17', name: 'كفر الزيات', lat: 30.8167, lng: 30.8167),
    Station(id: 's18', name: 'إيتاي البارود', lat: 30.8833, lng: 30.6667),
    Station(id: 's19', name: 'دمنهور', lat: 31.0500, lng: 30.4667),
    Station(id: 's20', name: 'سيدي جابر', lat: 31.2167, lng: 29.9167),
    Station(id: 's21', name: 'شبرا الخيمة', lat: 30.1333, lng: 31.2500),
    Station(id: 's22', name: 'قويسنا', lat: 30.5667, lng: 31.1667),
    Station(id: 's23', name: 'بركة السبع', lat: 30.6333, lng: 31.0833),
    Station(id: 's24', name: 'التوفيقية', lat: 30.8667, lng: 30.9000),
    Station(id: 's25', name: 'أبو حمص', lat: 30.9500, lng: 30.5500),
    Station(id: 's26', name: 'كفر الدوار', lat: 31.1333, lng: 30.1333),
    Station(id: 's27', name: 'الصعيد', lat: 30.0500, lng: 31.2000),
    Station(id: 's28', name: 'بني سويف', lat: 29.0667, lng: 31.0833),
    Station(id: 's29', name: 'المنيا', lat: 28.1167, lng: 30.7500),
    Station(id: 's30', name: 'أبو تيج', lat: 27.0333, lng: 31.3167),
    Station(id: 's31', name: 'طيما', lat: 26.9167, lng: 31.4500),
    Station(id: 's32', name: 'طهطا', lat: 26.7667, lng: 31.5000),
    Station(id: 's33', name: 'المراغة', lat: 26.7167, lng: 31.6000),
    Station(id: 's34', name: 'المنشأة', lat: 26.4833, lng: 31.7333),
    Station(id: 's35', name: 'جرجا', lat: 26.3333, lng: 31.9000),
    Station(id: 's36', name: 'البلينا', lat: 26.2333, lng: 31.9667),
    Station(id: 's37', name: 'أبو تشت', lat: 26.1167, lng: 32.1000),
    Station(id: 's38', name: 'فرشوط', lat: 26.0500, lng: 32.1667),
    Station(id: 's39', name: 'نجع حمادي', lat: 26.0500, lng: 32.2833),
    Station(id: 's40', name: 'دشنا', lat: 26.0000, lng: 32.4000),
    Station(id: 's41', name: 'قنا', lat: 26.1667, lng: 32.7167),
    Station(id: 's42', name: 'قفط', lat: 26.0000, lng: 32.8167),
    Station(id: 's43', name: 'قوص', lat: 25.9167, lng: 32.8167),
    Station(id: 's44', name: 'الرزيات', lat: 25.6500, lng: 32.5333),
    Station(id: 's45', name: 'إسنا', lat: 25.3000, lng: 32.5500),
    Station(id: 's46', name: 'السباعية', lat: 25.1667, lng: 32.7333),
    Station(id: 's47', name: 'إدفو', lat: 25.0000, lng: 32.8667),
    Station(id: 's48', name: 'سلوة البحري', lat: 24.9167, lng: 32.9500),
    Station(id: 's49', name: 'كلابشة', lat: 24.8667, lng: 32.9500),
    Station(id: 's50', name: 'كوم أمبو', lat: 24.4667, lng: 32.9500),
    Station(id: 's51', name: 'دراو', lat: 24.4167, lng: 32.9167),
    Station(id: 's52', name: 'أبو قرقاص', lat: 27.9333, lng: 30.8333),
    Station(id: 's53', name: 'ملوي', lat: 27.7333, lng: 30.8333),
    Station(id: 's54', name: 'دير مواس', lat: 27.6333, lng: 30.8500),
    Station(id: 's55', name: 'ديروط', lat: 27.5500, lng: 30.8167),
    Station(id: 's56', name: 'القوصية', lat: 27.4500, lng: 30.8167),
    Station(id: 's57', name: 'منفلوط', lat: 27.3167, lng: 30.9667),
    Station(id: 's58', name: 'منقباد', lat: 27.1833, lng: 31.1333),
    Station(id: 's59', name: 'الطابق', lat: 31.1000, lng: 30.9500),
    Station(id: 's60', name: 'الحوامدية', lat: 30.0000, lng: 31.2333),
    Station(id: 's61', name: 'البدرشين', lat: 29.8667, lng: 31.3167),
    Station(id: 's62', name: 'طوره', lat: 30.0000, lng: 31.2333),
    Station(id: 's63', name: 'التبين', lat: 29.8667, lng: 31.3167),
  ];

  static List<Station> get stations => mainStations;

  static List<String> getStationNames(bool isArabic) {
    return mainStations.map((s) => getStationName(s, isArabic)).toList();
  }

  static String getStationName(Station station, bool isArabic) {
    if (isArabic) {
      return station.name;
    } else {
      return stationNameEn[station.name] ?? station.name;
    }
  }

  static String getTrainName(String arabicName, bool isArabic) {
    if (isArabic) {
      return arabicName;
    } else {
      return trainNameEn[arabicName] ?? arabicName;
    }
  }

  static String getClassName(String arabicName, bool isArabic) {
    if (isArabic) {
      return arabicName;
    } else {
      return classNameEn[arabicName] ?? arabicName;
    }
  }

  static Station getStation(String name) {
    final station = allStations.firstWhere(
      (s) => s.name == name,
      orElse: () => mainStations.first,
    );
    return station;
  }

  static Station getStationByName(String name) {
    final station = allStations.firstWhere(
      (s) => s.name == name,
      orElse: () => mainStations.first,
    );
    return station;
  }

  static List<TrainSchedule> getTrains(String from, String to) {
    return _allTrains.where((train) {
      final fromAr = train.from.name;
      final toAr = train.to.name;

      final fromEn = stationNameEn[fromAr] ?? fromAr;
      final toEn = stationNameEn[toAr] ?? toAr;

      final fromMatches = (from == fromAr) || (from == fromEn);
      final toMatches = (to == toAr) || (to == toEn);

      return fromMatches && toMatches;
    }).toList();
  }

  static List<Station> _createStops(List<String> stopNames) {
    return stopNames.map((name) {
      final station = allStations.firstWhere(
        (s) => s.name == name,
        orElse: () => mainStations.first,
      );
      return station;
    }).toList();
  }

  static final List<TrainSchedule> _allTrains = [
    TrainSchedule(
      id: 'mans_alex_1',
      trainNumber: '584-585',
      trainName: 'مكيف روسي',
      from: getStationByName('المنصورة'),
      to: getStationByName('الإسكندرية'),
      departureTime: '05:15',
      arrivalTime: '08:20',
      duration: '03:05',
      stops: _createStops([
        'المنصورة',
        'طلخا',
        'سمنود',
        'المحلة الكبرى',
        'محلة روح',
        'طنطا',
        'كفر الزيات',
        'إيتاي البارود',
        'دمنهور',
        'سيدي جابر',
        'الإسكندرية'
      ]),
      prices: {'درجة أولى': 150, 'درجة ثانية': 95, 'درجة ثالثة': 55},
      availableSeats: {'درجة أولى': 25, 'درجة ثانية': 50, 'درجة ثالثة': 100},
      currentStatus: null,
    ),

    TrainSchedule(
      id: 'cai_alex_1',
      trainNumber: '1',
      trainName: 'روسي',
      from: getStationByName('القاهرة'),
      to: getStationByName('الإسكندرية'),
      departureTime: '03:00',
      arrivalTime: '06:45',
      duration: '03:45',
      stops: _createStops([
        'القاهرة',
        'شبرا الخيمة',
        'بنها',
        'قويسنا',
        'بركة السبع',
        'طنطا',
        'كفر الزيات',
        'التوفيقية',
        'إيتاي البارود',
        'دمنهور',
        'أبو حمص',
        'كفر الدوار',
        'سيدي جابر',
        'الإسكندرية'
      ]),
      prices: {'درجة أولى': 220, 'درجة ثانية': 140, 'درجة ثالثة': 85},
      availableSeats: {'درجة أولى': 20, 'درجة ثانية': 40, 'درجة ثالثة': 80},
      currentStatus: null,
    ),

    TrainSchedule(
      id: 'alex_cai_1',
      trainNumber: '2',
      trainName: 'روسي',
      from: getStationByName('الإسكندرية'),
      to: getStationByName('القاهرة'),
      departureTime: '03:05',
      arrivalTime: '06:55',
      duration: '03:50',
      stops: _createStops([
        'الإسكندرية',
        'سيدي جابر',
        'كفر الدوار',
        'أبو حمص',
        'دمنهور',
        'إيتاي البارود',
        'كفر الزيات',
        'طنطا',
        'بركة السبع',
        'قويسنا',
        'بنها',
        'الطابق',
        'القاهرة'
      ]),
      prices: {'درجة أولى': 220, 'درجة ثانية': 140, 'درجة ثالثة': 85},
      availableSeats: {'درجة أولى': 20, 'درجة ثانية': 40, 'درجة ثالثة': 80},
      currentStatus: null,
    ),

    TrainSchedule(
      id: 'cai_asw_1',
      trainNumber: '80',
      trainName: 'روسي',
      from: getStationByName('القاهرة'),
      to: getStationByName('أسوان'),
      departureTime: '08:00',
      arrivalTime: '22:25',
      duration: '14:25',
      stops: _createStops([
        'القاهرة',
        'الصعيد',
        'الجيزة',
        'بني سويف',
        'المنيا',
        'أسيوط',
        'أبو تيج',
        'طيما',
        'طهطا',
        'المراغة',
        'سوهاج',
        'المنشأة',
        'جرجا',
        'البلينا',
        'أبو تشت',
        'فرشوط',
        'نجع حمادي',
        'دشنا',
        'قنا',
        'قفط',
        'قوص',
        'الأقصر',
        'الرزيات',
        'إسنا',
        'السباعية',
        'إدفو',
        'سلوة البحري',
        'كلابشة',
        'كوم أمبو',
        'دراو',
        'أسوان'
      ]),
      prices: {'درجة أولى': 350, 'درجة ثانية': 220, 'درجة ثالثة': 130},
      availableSeats: {'درجة أولى': 30, 'درجة ثانية': 60, 'درجة ثالثة': 120},
      currentStatus: null,
    ),

    TrainSchedule(
      id: 'cai_asyt_1',
      trainNumber: '158',
      trainName: 'روسي',
      from: getStationByName('القاهرة'),
      to: getStationByName('أسيوط'),
      departureTime: '05:20',
      arrivalTime: '12:30',
      duration: '07:10',
      stops: _createStops([
        'القاهرة',
        'الصعيد',
        'الجيزة',
        'الحوامدية',
        'البدرشين',
        'الطابق',
        'التبين',
        'بني سويف',
        'المنيا',
        'أبو قرقاص',
        'ملوي',
        'دير مواس',
        'ديروط',
        'القوصية',
        'منفلوط',
        'منقباد',
        'أسيوط'
      ]),
      prices: {'درجة أولى': 250, 'درجة ثانية': 160, 'درجة ثالثة': 95},
      availableSeats: {'درجة أولى': 30, 'درجة ثانية': 60, 'درجة ثالثة': 120},
      currentStatus: null,
    ),

    TrainSchedule(
      id: 'cai_bnha_1',
      trainNumber: '15',
      trainName: 'روسي',
      from: getStationByName('القاهرة'),
      to: getStationByName('بنها'),
      departureTime: '06:00',
      arrivalTime: '06:55',
      duration: '00:55',
      stops: _createStops(['القاهرة', 'شبرا الخيمة', 'بنها']),
      prices: {'درجة أولى': 50, 'درجة ثانية': 35, 'درجة ثالثة': 25},
      availableSeats: {'درجة أولى': 40, 'درجة ثانية': 80, 'درجة ثالثة': 150},
      currentStatus: null,
    ),

    TrainSchedule(
      id: 'cai_alex_2',
      trainNumber: '2007',
      trainName: 'خاص',
      from: getStationByName('القاهرة'),
      to: getStationByName('الإسكندرية'),
      departureTime: '04:35',
      arrivalTime: '07:20',
      duration: '02:45',
      stops: _createStops(['القاهرة', 'شبرا الخيمة', 'بنها', 'الإسكندرية']),
      prices: {'درجة أولى': 220, 'درجة ثانية': 140, 'درجة ثالثة': 85},
      availableSeats: {'درجة أولى': 20, 'درجة ثانية': 40, 'درجة ثالثة': 80},
      currentStatus: null,
    ),
    TrainSchedule(
      id: 'cai_alex_3',
      trainNumber: '119',
      trainName: 'روسي',
      from: getStationByName('القاهرة'),
      to: getStationByName('الإسكندرية'),
      departureTime: '05:00',
      arrivalTime: '09:45',
      duration: '04:45',
      stops: _createStops(
          ['القاهرة', 'بنها', 'طنطا', 'كفر الزيات', 'دمنهور', 'الإسكندرية']),
      prices: {'درجة أولى': 180, 'درجة ثانية': 110, 'درجة ثالثة': 65},
      availableSeats: {'درجة أولى': 25, 'درجة ثانية': 50, 'درجة ثالثة': 100},
      currentStatus: null,
    ),
    TrainSchedule(
      id: 'cai_alex_4',
      trainNumber: '903',
      trainName: 'مكيف',
      from: getStationByName('القاهرة'),
      to: getStationByName('الإسكندرية'),
      departureTime: '06:00',
      arrivalTime: '09:30',
      duration: '03:30',
      stops: _createStops(['القاهرة', 'طنطا', 'دمنهور', 'الإسكندرية']),
      prices: {'درجة أولى': 200, 'درجة ثانية': 130, 'درجة ثالثة': 75},
      availableSeats: {'درجة أولى': 18, 'درجة ثانية': 35, 'درجة ثالثة': 70},
      currentStatus: null,
    ),
    TrainSchedule(
      id: 'cai_alex_5',
      trainNumber: '7',
      trainName: 'روسي',
      from: getStationByName('القاهرة'),
      to: getStationByName('الإسكندرية'),
      departureTime: '06:20',
      arrivalTime: '10:15',
      duration: '03:55',
      stops: _createStops(
          ['القاهرة', 'بنها', 'قويسنا', 'طنطا', 'دمنهور', 'الإسكندرية']),
      prices: {'درجة أولى': 190, 'درجة ثانية': 120, 'درجة ثالثة': 70},
      availableSeats: {'درجة أولى': 22, 'درجة ثانية': 45, 'درجة ثالثة': 90},
      currentStatus: null,
    ),
    TrainSchedule(
      id: 'cai_alex_6',
      trainNumber: '1131',
      trainName: 'مكيف روسي',
      from: getStationByName('القاهرة'),
      to: getStationByName('الإسكندرية'),
      departureTime: '07:00',
      arrivalTime: '09:55',
      duration: '02:55',
      stops: _createStops(['القاهرة', 'طنطا', 'الإسكندرية']),
      prices: {'درجة أولى': 230, 'درجة ثانية': 150, 'درجة ثالثة': 90},
      availableSeats: {'درجة أولى': 15, 'درجة ثانية': 30, 'درجة ثالثة': 60},
      currentStatus: null,
    ),
    TrainSchedule(
      id: 'cai_alex_7',
      trainNumber: '1083',
      trainName: 'نوم',
      from: getStationByName('القاهرة'),
      to: getStationByName('الإسكندرية'),
      departureTime: '07:20',
      arrivalTime: '10:05',
      duration: '02:45',
      stops: _createStops(['القاهرة', 'بنها', 'الإسكندرية']),
      prices: {'درجة أولى': 250, 'درجة ثانية': 160, 'درجة ثالثة': 95},
      availableSeats: {'درجة أولى': 12, 'درجة ثانية': 25, 'درجة ثالثة': 50},
      currentStatus: null,
    ),
    TrainSchedule(
      id: 'cai_alex_8',
      trainNumber: '2025',
      trainName: 'تالجو',
      from: getStationByName('القاهرة'),
      to: getStationByName('الإسكندرية'),
      departureTime: '08:00',
      arrivalTime: '10:30',
      duration: '02:30',
      stops: _createStops(['القاهرة', 'الإسكندرية']),
      prices: {'درجة أولى': 280, 'درجة ثانية': 180, 'درجة ثالثة': 110},
      availableSeats: {'درجة أولى': 10, 'درجة ثانية': 20, 'درجة ثالثة': 40},
      currentStatus: null,
    ),

    TrainSchedule(
      id: 'alex_cai_2',
      trainNumber: '2008',
      trainName: 'خاص',
      from: getStationByName('الإسكندرية'),
      to: getStationByName('القاهرة'),
      departureTime: '05:00',
      arrivalTime: '07:45',
      duration: '02:45',
      stops: _createStops(['الإسكندرية', 'بنها', 'القاهرة']),
      prices: {'درجة أولى': 220, 'درجة ثانية': 140, 'درجة ثالثة': 85},
      availableSeats: {'درجة أولى': 20, 'درجة ثانية': 40, 'درجة ثالثة': 80},
      currentStatus: null,
    ),
    TrainSchedule(
      id: 'alex_cai_3',
      trainNumber: '120',
      trainName: 'روسي',
      from: getStationByName('الإسكندرية'),
      to: getStationByName('القاهرة'),
      departureTime: '06:00',
      arrivalTime: '10:45',
      duration: '04:45',
      stops: _createStops(
          ['الإسكندرية', 'دمنهور', 'كفر الزيات', 'طنطا', 'بنها', 'القاهرة']),
      prices: {'درجة أولى': 180, 'درجة ثانية': 110, 'درجة ثالثة': 65},
      availableSeats: {'درجة أولى': 25, 'درجة ثانية': 50, 'درجة ثالثة': 100},
      currentStatus: null,
    ),
    TrainSchedule(
      id: 'alex_cai_4',
      trainNumber: '904',
      trainName: 'مكيف',
      from: getStationByName('الإسكندرية'),
      to: getStationByName('القاهرة'),
      departureTime: '07:00',
      arrivalTime: '10:30',
      duration: '03:30',
      stops: _createStops(['الإسكندرية', 'دمنهور', 'طنطا', 'القاهرة']),
      prices: {'درجة أولى': 200, 'درجة ثانية': 130, 'درجة ثالثة': 75},
      availableSeats: {'درجة أولى': 18, 'درجة ثانية': 35, 'درجة ثالثة': 70},
      currentStatus: null,
    ),
    TrainSchedule(
      id: 'alex_cai_5',
      trainNumber: '8',
      trainName: 'روسي',
      from: getStationByName('الإسكندرية'),
      to: getStationByName('القاهرة'),
      departureTime: '08:00',
      arrivalTime: '12:00',
      duration: '04:00',
      stops: _createStops(
          ['الإسكندرية', 'دمنهور', 'طنطا', 'قويسنا', 'بنها', 'القاهرة']),
      prices: {'درجة أولى': 190, 'درجة ثانية': 120, 'درجة ثالثة': 70},
      availableSeats: {'درجة أولى': 22, 'درجة ثانية': 45, 'درجة ثالثة': 90},
      currentStatus: null,
    ),
    TrainSchedule(
      id: 'alex_cai_6',
      trainNumber: '1132',
      trainName: 'مكيف روسي',
      from: getStationByName('الإسكندرية'),
      to: getStationByName('القاهرة'),
      departureTime: '09:00',
      arrivalTime: '11:55',
      duration: '02:55',
      stops: _createStops(['الإسكندرية', 'طنطا', 'القاهرة']),
      prices: {'درجة أولى': 230, 'درجة ثانية': 150, 'درجة ثالثة': 90},
      availableSeats: {'درجة أولى': 15, 'درجة ثانية': 30, 'درجة ثالثة': 60},
      currentStatus: null,
    ),

    TrainSchedule(
      id: 'cai_asw_2',
      trainNumber: '1004',
      trainName: 'مكيف روسي',
      from: getStationByName('القاهرة'),
      to: getStationByName('أسوان'),
      departureTime: '09:30',
      arrivalTime: '23:10',
      duration: '13:40',
      stops: _createStops([
        'القاهرة',
        'بني سويف',
        'المنيا',
        'أسيوط',
        'سوهاج',
        'قنا',
        'الأقصر',
        'أسوان'
      ]),
      prices: {'درجة أولى': 400, 'درجة ثانية': 260, 'درجة ثالثة': 150},
      availableSeats: {'درجة أولى': 25, 'درجة ثانية': 50, 'درجة ثالثة': 100},
      currentStatus: null,
    ),
    TrainSchedule(
      id: 'cai_asw_3',
      trainNumber: '2010',
      trainName: 'خاص',
      from: getStationByName('القاهرة'),
      to: getStationByName('أسوان'),
      departureTime: '10:00',
      arrivalTime: '22:55',
      duration: '12:55',
      stops: _createStops(['القاهرة', 'أسيوط', 'الأقصر', 'أسوان']),
      prices: {'درجة أولى': 450, 'درجة ثانية': 300, 'درجة ثالثة': 170},
      availableSeats: {'درجة أولى': 20, 'درجة ثانية': 40, 'درجة ثالثة': 80},
      currentStatus: null,
    ),
    TrainSchedule(
      id: 'cai_asw_4',
      trainNumber: '982',
      trainName: 'خاص',
      from: getStationByName('القاهرة'),
      to: getStationByName('أسوان'),
      departureTime: '12:00',
      arrivalTime: '02:24',
      duration: '14:24',
      stops: _createStops(['القاهرة', 'المنيا', 'سوهاج', 'الأقصر', 'أسوان']),
      prices: {'درجة أولى': 420, 'درجة ثانية': 280, 'درجة ثالثة': 160},
      availableSeats: {'درجة أولى': 18, 'درجة ثانية': 38, 'درجة ثالثة': 75},
      currentStatus: null,
    ),
    TrainSchedule(
      id: 'cai_asw_5',
      trainNumber: '164',
      trainName: 'روسي',
      from: getStationByName('القاهرة'),
      to: getStationByName('أسوان'),
      departureTime: '15:30',
      arrivalTime: '07:39',
      duration: '16:09',
      stops: _createStops([
        'القاهرة',
        'بنها',
        'طنطا',
        'المنيا',
        'أسيوط',
        'سوهاج',
        'قنا',
        'الأقصر',
        'أسوان'
      ]),
      prices: {'درجة أولى': 380, 'درجة ثانية': 240, 'درجة ثالثة': 140},
      availableSeats: {'درجة أولى': 22, 'درجة ثانية': 45, 'درجة ثالثة': 90},
      currentStatus: null,
    ),
    TrainSchedule(
      id: 'cai_asw_6',
      trainNumber: '2006',
      trainName: 'خاص',
      from: getStationByName('القاهرة'),
      to: getStationByName('أسوان'),
      departureTime: '17:15',
      arrivalTime: '06:00',
      duration: '12:45',
      stops: _createStops(['القاهرة', 'أسيوط', 'الأقصر', 'أسوان']),
      prices: {'درجة أولى': 480, 'درجة ثانية': 320, 'درجة ثالثة': 190},
      availableSeats: {'درجة أولى': 15, 'درجة ثانية': 30, 'درجة ثالثة': 60},
      currentStatus: null,
    ),

    TrainSchedule(
      id: 'asw_cai_1',
      trainNumber: '81',
      trainName: 'روسي',
      from: getStationByName('أسوان'),
      to: getStationByName('القاهرة'),
      departureTime: '10:00',
      arrivalTime: '03:05',
      duration: '17:05',
      stops: _createStops([
        'أسوان',
        'كوم أمبو',
        'إدفو',
        'الأقصر',
        'قنا',
        'سوهاج',
        'أسيوط',
        'المنيا',
        'بني سويف',
        'الجيزة',
        'القاهرة'
      ]),
      prices: {'درجة أولى': 350, 'درجة ثانية': 220, 'درجة ثالثة': 130},
      availableSeats: {'درجة أولى': 30, 'درجة ثانية': 60, 'درجة ثالثة': 120},
      currentStatus: null,
    ),

    TrainSchedule(
      id: 'mans_alex_2',
      trainNumber: '566-567',
      trainName: 'مكيف روسي',
      from: getStationByName('المنصورة'),
      to: getStationByName('الإسكندرية'),
      departureTime: '09:00',
      arrivalTime: '12:30',
      duration: '03:30',
      stops: _createStops([
        'المنصورة',
        'طلخا',
        'سمنود',
        'المحلة الكبرى',
        'طنطا',
        'كفر الزيات',
        'دمنهور',
        'سيدي جابر',
        'الإسكندرية'
      ]),
      prices: {'درجة أولى': 160, 'درجة ثانية': 100, 'درجة ثالثة': 60},
      availableSeats: {'درجة أولى': 22, 'درجة ثانية': 45, 'درجة ثالثة': 90},
      currentStatus: null,
    ),
    TrainSchedule(
      id: 'mans_alex_3',
      trainNumber: '516-517',
      trainName: 'مكيف روسي',
      from: getStationByName('المنصورة'),
      to: getStationByName('الإسكندرية'),
      departureTime: '17:15',
      arrivalTime: '20:10',
      duration: '02:55',
      stops: _createStops(
          ['المنصورة', 'المحلة الكبرى', 'طنطا', 'دمنهور', 'الإسكندرية']),
      prices: {'درجة أولى': 170, 'درجة ثانية': 110, 'درجة ثالثة': 65},
      availableSeats: {'درجة أولى': 20, 'درجة ثانية': 40, 'درجة ثالثة': 80},
      currentStatus: null,
    ),

    TrainSchedule(
      id: 'alex_mans_1',
      trainNumber: '586-587',
      trainName: 'مكيف روسي',
      from: getStationByName('الإسكندرية'),
      to: getStationByName('المنصورة'),
      departureTime: '06:00',
      arrivalTime: '09:05',
      duration: '03:05',
      stops: _createStops([
        'الإسكندرية',
        'سيدي جابر',
        'دمنهور',
        'كفر الزيات',
        'طنطا',
        'المحلة الكبرى',
        'سمنود',
        'طلخا',
        'المنصورة'
      ]),
      prices: {'درجة أولى': 150, 'درجة ثانية': 95, 'درجة ثالثة': 55},
      availableSeats: {'درجة أولى': 25, 'درجة ثانية': 50, 'درجة ثالثة': 100},
      currentStatus: null,
    ),
    TrainSchedule(
      id: 'alex_mans_2',
      trainNumber: '568-569',
      trainName: 'مكيف روسي',
      from: getStationByName('الإسكندرية'),
      to: getStationByName('المنصورة'),
      departureTime: '10:00',
      arrivalTime: '13:30',
      duration: '03:30',
      stops: _createStops([
        'الإسكندرية',
        'دمنهور',
        'كفر الزيات',
        'طنطا',
        'المحلة الكبرى',
        'المنصورة'
      ]),
      prices: {'درجة أولى': 160, 'درجة ثانية': 100, 'درجة ثالثة': 60},
      availableSeats: {'درجة أولى': 22, 'درجة ثانية': 45, 'درجة ثالثة': 90},
      currentStatus: null,
    ),
    TrainSchedule(
      id: 'alex_mans_3',
      trainNumber: '518-519',
      trainName: 'مكيف روسي',
      from: getStationByName('الإسكندرية'),
      to: getStationByName('المنصورة'),
      departureTime: '18:00',
      arrivalTime: '20:55',
      duration: '02:55',
      stops: _createStops(['الإسكندرية', 'طنطا', 'المحلة الكبرى', 'المنصورة']),
      prices: {'درجة أولى': 170, 'درجة ثانية': 110, 'درجة ثالثة': 65},
      availableSeats: {'درجة أولى': 20, 'درجة ثانية': 40, 'درجة ثالثة': 80},
      currentStatus: null,
    ),
  ];

  static Booking getSampleBooking() {
    return Booking(
      bookingId: 'BK-2024-98712',
      ticketNumber: 'ENR-2007-A12',
      passengerName: 'أحمد محمد علي',
      trainNumber: '2007',
      trainName: 'خاص',
      from: getStationByName('القاهرة'),
      to: getStationByName('الإسكندرية'),
      departureTime: '07:00',
      arrivalTime: '11:30',
      date: '15 يناير 2025',
      seatClass: 'درجة ثانية',
      seatNumber: 14,
      price: 110,
      status: BookingStatus.valid,
      stops: [
        getStationByName('القاهرة'),
        getStationByName('بنها'),
        getStationByName('الإسكندرية')
      ],
      currentStopIndex: 1,
    );
  }

  static List<Booking> getAdminBookings() {
    return [
      Booking(
        bookingId: 'BK-2024-98712',
        ticketNumber: 'ENR-2007-A12',
        passengerName: 'أحمد محمد علي',
        trainNumber: '2007',
        trainName: 'خاص',
        from: getStationByName('القاهرة'),
        to: getStationByName('الإسكندرية'),
        departureTime: '07:00',
        arrivalTime: '11:30',
        date: '15 يناير 2025',
        seatClass: 'درجة ثانية',
        seatNumber: 14,
        price: 110,
        status: BookingStatus.valid,
        stops: [
          getStationByName('القاهرة'),
          getStationByName('بنها'),
          getStationByName('الإسكندرية')
        ],
        currentStopIndex: 1,
      ),
      Booking(
        bookingId: 'BK-2024-98713',
        ticketNumber: 'ENR-2007-B07',
        passengerName: 'فاطمة حسن',
        trainNumber: '2007',
        trainName: 'خاص',
        from: getStationByName('القاهرة'),
        to: getStationByName('الإسكندرية'),
        departureTime: '07:00',
        arrivalTime: '11:30',
        date: '15 يناير 2025',
        seatClass: 'درجة أولى',
        seatNumber: 7,
        price: 180,
        status: BookingStatus.scanned,
        stops: [
          getStationByName('القاهرة'),
          getStationByName('بنها'),
          getStationByName('الإسكندرية')
        ],
        currentStopIndex: 1,
      ),
      Booking(
        bookingId: 'BK-2024-98714',
        ticketNumber: 'ENR-2007-C03',
        passengerName: 'محمود إبراهيم',
        trainNumber: '2007',
        trainName: 'خاص',
        from: getStationByName('القاهرة'),
        to: getStationByName('الإسكندرية'),
        departureTime: '07:00',
        arrivalTime: '11:30',
        date: '15 يناير 2025',
        seatClass: 'درجة ثالثة',
        seatNumber: 22,
        price: 65,
        status: BookingStatus.invalid,
        stops: [
          getStationByName('القاهرة'),
          getStationByName('بنها'),
          getStationByName('الإسكندرية')
        ],
        currentStopIndex: 1,
      ),
      Booking(
        bookingId: 'BK-2024-98715',
        ticketNumber: 'ENR-2007-A08',
        passengerName: 'نور الدين سامي',
        trainNumber: '2007',
        trainName: 'خاص',
        from: getStationByName('القاهرة'),
        to: getStationByName('الإسكندرية'),
        departureTime: '07:00',
        arrivalTime: '11:30',
        date: '15 يناير 2025',
        seatClass: 'درجة ثانية',
        seatNumber: 31,
        price: 110,
        status: BookingStatus.valid,
        stops: [
          getStationByName('القاهرة'),
          getStationByName('بنها'),
          getStationByName('الإسكندرية')
        ],
        currentStopIndex: 1,
      ),
    ];
  }

  static List<TrainSchedule> getAllTrains() {
    return _allTrains;
  }
}

String formatTimeWithPeriod(String time, bool isArabic) {
  try {
    final parts = time.split(':');
    int hour = int.parse(parts[0]);
    final minute = parts[1];

    String period;
    if (isArabic) {
      period = hour >= 12 ? 'م' : 'ص';
    } else {
      period = hour >= 12 ? 'PM' : 'AM';
    }

    int displayHour = hour > 12 ? hour - 12 : hour;
    if (displayHour == 0) displayHour = 12;
    return '$displayHour:$minute $period';
  } catch (e) {
    return time;
  }
}

String getTimePeriod(String time, bool isArabic) {
  try {
    final parts = time.split(':');
    int hour = int.parse(parts[0]);
    if (isArabic) {
      if (hour >= 5 && hour < 12) return 'صباحي';
      if (hour >= 12 && hour < 17) return 'ظهري';
      if (hour >= 17 && hour < 21) return 'مسائي';
      return 'ليلي';
    } else {
      if (hour >= 5 && hour < 12) return 'Morning';
      if (hour >= 12 && hour < 17) return 'Afternoon';
      if (hour >= 17 && hour < 21) return 'Evening';
      return 'Night';
    }
  } catch (e) {
    return '';
  }
}

enum TrainStatus {
  running,
  delayed,
  cancelled,
  accident,
}

extension TrainStatusExtension on TrainStatus {
  String getName(bool isArabic) {
    switch (this) {
      case TrainStatus.running:
        return isArabic ? 'يعمل بشكل طبيعي' : 'Running Normally';
      case TrainStatus.delayed:
        return isArabic ? 'متأخر' : 'Delayed';
      case TrainStatus.cancelled:
        return isArabic ? 'ملغي' : 'Cancelled';
      case TrainStatus.accident:
        return isArabic ? 'حادث / عطل' : 'Accident / Breakdown';
    }
  }

  Color getColor() {
    switch (this) {
      case TrainStatus.running:
        return Colors.green;
      case TrainStatus.delayed:
        return Colors.orange;
      case TrainStatus.cancelled:
        return Colors.red;
      case TrainStatus.accident:
        return Colors.red.shade900;
    }
  }

  IconData getIcon() {
    switch (this) {
      case TrainStatus.running:
        return Icons.check_circle_outline;
      case TrainStatus.delayed:
        return Icons.access_time;
      case TrainStatus.cancelled:
        return Icons.cancel_outlined;
      case TrainStatus.accident:
        return Icons.warning_amber_rounded;
    }
  }

  static fromString(String statusStr) {}
}

class TrainStatusLog {
  final String id;
  final String trainNumber;
  final TrainStatus status;
  final String reason;
  final DateTime createdAt;
  final int? delayMinutes;

  TrainStatusLog({
    required this.id,
    required this.trainNumber,
    required this.status,
    required this.reason,
    required this.createdAt,
    this.delayMinutes,
  });
}

class TrainNotification {
  final String id;
  final String userId;
  final String userEmail;
  final String trainNumber;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  TrainNotification({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.trainNumber,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });
}
