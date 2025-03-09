import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:country_code_picker_plus/src/constants.dart';
import 'package:flutter/material.dart';
import 'package:country_code_picker_plus/src/country.dart';
import 'package:flutter/services.dart';
import 'package:libphonenumber_plugin/libphonenumber_plugin.dart';

class PhoneService {
  late final List<Country> countries;

  PhoneService() {
    List<Country> elements =
        countryCodes.map((json) => Country.fromJson(json)).toList();
    countries = elements;
  }

  Country? countryBy({required String dialCode}) {
    return countries
        .firstWhereOrNull((element) => element.dialCode.contains(dialCode));
  }

  Country? countryByCode({required String code}) {
    return countries.firstWhereOrNull((element) => element.code == code);
  }

  static List<Country> getPotentialCountries(
      String number, List<Country> countries) {
    List<Country> result = [];
    if (number.isNotEmpty && number.length < 5) {
      List<String> potentialCodes =
          generatePotentialDialCodes(number, 0, number.length);
      for (var code in potentialCodes) {
        for (var country in countries) {
          if (code == country.dialCode) {
            result.add(country);
          }
        }
      }
    }
    if (number.length >= 5) {
      String intlCode = number.substring(0, 4);
      List<String> potentialCodes = generatePotentialDialCodes(intlCode, 0, 4);
      for (var code in potentialCodes) {
        for (var country in countries) {
          if (code == country.dialCode) {
            result.add(country);
          }
        }
      }
    }
    return result;
  }

  static List<String> generatePotentialDialCodes(
      String number, int index, int length) {
    List<String> digits = number.split('');
    List<String> potentialCodes = [];
    String aggregate = '+${digits[index]}';
    potentialCodes.add(aggregate);
    while (index < length - 1) {
      index += 1;
      aggregate = aggregate + digits[index];
      potentialCodes.add(aggregate);
    }
    return potentialCodes;
  }

  static Future<bool?> parsePhoneNumber(String number, String iso) async {
    try {
      return await PhoneNumberUtil.isValidPhoneNumber(number, iso);
    } on PlatformException {
      return false;
    }
  }

  static Future<String?> getNormalizedPhoneNumber(
      String number, String iso) async {
    try {
      return await PhoneNumberUtil.normalizePhoneNumber(number, iso);
    } catch (e) {
      return null;
    }
  }

  static Future<List<Country>> fetchCountryData(
      BuildContext context, String jsonFile) async {
    var list = await DefaultAssetBundle.of(context).loadString(jsonFile);
    List<Country> elements = [];
    var jsonList = json.decode(list);
    jsonList.forEach((s) {
      Map elem = Map.from(s);
      elements.add(Country(
          name: elem['en_short_name'],
          code: elem['alpha_2_code'],
          dialCode: elem['dial_code'],
          flagUri: 'assets/flags/${elem['alpha_2_code'].toLowerCase()}.png'));
    });
    return elements;
  }
}
