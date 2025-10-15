class MumbaiEmergencyDirectory {
  // Canonical locality to local station numbers (sample and generic helplines)
  static const Map<String, List<String>> localityToNumbers = {
    'andheri west': [
      '112 — India Emergency (ERSS)',
      '100 — Police Control Room',
      '101 — Fire Brigade',
      '108 — Ambulance',
      '022-2632-1076 — Andheri Police Station',
    ],
    'andheri east': [
      '112 — India Emergency (ERSS)',
      '100 — Police Control Room',
      '101 — Fire Brigade',
      '108 — Ambulance',
      '022-2683-0284 — MIDC Police Station',
    ],
    'bandra west': [
      '112 — India Emergency (ERSS)',
      '100 — Police Control Room',
      '101 — Fire Brigade',
      '108 — Ambulance',
      '022-2642-0164 — Bandra Police Station',
    ],
    'bandra east': [
      '112 — India Emergency (ERSS)',
      '100 — Police Control Room',
      '101 — Fire Brigade',
      '108 — Ambulance',
      '022-2659-2300 — Nirmal Nagar Police Station',
    ],
    'dadar': [
      '112 — India Emergency (ERSS)',
      '100 — Police Control Room',
      '101 — Fire Brigade',
      '108 — Ambulance',
      '022-2413-4000 — Dadar Police Station',
    ],
    'colaba': [
      '112 — India Emergency (ERSS)',
      '100 — Police Control Room',
      '101 — Fire Brigade',
      '108 — Ambulance',
      '022-2215-3515 — Colaba Police Station',
    ],
    'powai': [
      '112 — India Emergency (ERSS)',
      '100 — Police Control Room',
      '101 — Fire Brigade',
      '108 — Ambulance',
      '022-2570-3026 — Powai Police Station',
    ],
    'borivali west': [
      '112 — India Emergency (ERSS)',
      '100 — Police Control Room',
      '101 — Fire Brigade',
      '108 — Ambulance',
      '022-2893-2400 — Borivali Police Station',
    ],
    'borivali east': [
      '112 — India Emergency (ERSS)',
      '100 — Police Control Room',
      '101 — Fire Brigade',
      '108 — Ambulance',
      '022-2808-3777 — MHB Colony Police Station',
    ],
    'ghatkopar': [
      '112 — India Emergency (ERSS)',
      '100 — Police Control Room',
      '101 — Fire Brigade',
      '108 — Ambulance',
      '022-2511-0374 — Ghatkopar Police Station',
    ],
    'malad': [
      '112 — India Emergency (ERSS)',
      '100 — Police Control Room',
      '101 — Fire Brigade',
      '108 — Ambulance',
      '022-2882-2299 — Malad Police Station',
    ],
 
    'vile parle east': [
      '112 — India Emergency (ERSS)',
      '100 — Police Control Room',
      '101 — Fire Brigade',
      '108 — Ambulance',
      '022-2610-7123 — Vile Parle Police Station',
    ],
    'vile parle west': [
      '112 — India Emergency (ERSS)',
      '100 — Police Control Room',
      '101 — Fire Brigade',
      '108 — Ambulance',
      '022-2610-7123 — Vile Parle Police Station',
    ],

    'santacruz east': [
      '112 — India Emergency (ERSS)',
      '100 — Police Control Room',
      '101 — Fire Brigade',
      '108 — Ambulance',
      '022-2649-0108 — Santacruz Police Station',
    ],
    'santacruz west': [
      '112 — India Emergency (ERSS)',
      '100 — Police Control Room',
      '101 — Fire Brigade',
      '108 — Ambulance',
      '022-2649-0108 — Santacruz Police Station',
    ],
    'virar': [
      '112 — India Emergency (ERSS)',
      '100 — Police Control Room',
      '101 — Fire Brigade',
      '108 — Ambulance',
      '0250-251-2111 — Virar Police Station',
    ],
    'vasai': [
      '112 — India Emergency (ERSS)',
      '100 — Police Control Room',
      '101 — Fire Brigade',
      '108 — Ambulance',
      '0250-232-3624 — Vasai Police Station',
    ],
    // Fallback key for generic Mumbai
    'mumbai': [
      '112 — India Emergency (ERSS)',
      '100 — Police Control Room',
      '101 — Fire Brigade',
      '108 — Ambulance',
    ],
  };

  static String? findNumbersForLocality(String query) {
    final String q = query.toLowerCase().trim();
    // Direct match
    if (localityToNumbers.containsKey(q)) {
      return localityToNumbers[q]!.join('\n');
    }
    // Contains/substring match across known keys
    for (final String key in localityToNumbers.keys) {
      if (q.contains(key) || key.contains(q)) {
        return localityToNumbers[key]!.join('\n');
      }
    }
    return null;
  }
}


