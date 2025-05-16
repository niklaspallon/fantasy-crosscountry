import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';

Widget flagWidget(String countryName) {
  // 🔹 Map för att konvertera från text till ISO 3166-1 kod
  final Map<String, String> countryCodes = {
    "sweden": "SE",
    "norway": "NO",
    "finland": "FI",
    "canada": "CA",
    "germany": "DE",
    "france": "FR",
    "italy": "IT",
    "switzerland": "CH",
    "united states": "US",
    "russia": "RU",
    "poland": "PL",
    "united kingdom": "gbr",
    "czech republic": "CZ",
    "slovakia": "SK",
    "austria": "AT",
    "slovenia": "SI",
    "estonia": "EE",
    "latvia": "LV",
    "lithuania": "LT",
    "kazakhstan": "KZ",
    "china": "CN",
    "japan": "JP",
    "south korea": "KR",
    "great britain": "GB",
    "spain": "ES",
    "andorra": "AD",
    "ukraine": "UA",
    "belarus": "BY",
    "australia": "AU",
    "new zealand": "NZ",
    "bulgaria": "BG",
    "romania": "RO",
    "greece": "GR",
    "portugal": "PT",
    "mongolia": "MN",
    "turkey": "TR",
    "argentina": "AR",
    "brazil": "BR",
    "chile": "CL",
    "mexico": "MX",
    "south africa": "ZA",
    "united arab emirates": "AE",
  };

  // 🔹 Standardvärde om landet inte finns i listan
  String isoCode =
      countryCodes[countryName.toLowerCase()] ?? "UN"; // "UN" = Okänt land

  return CountryFlag.fromCountryCode(
    isoCode,
    height: 30,
    width: 40,
  );
}
