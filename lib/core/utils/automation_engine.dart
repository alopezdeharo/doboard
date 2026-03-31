class AutomationEngine {
  const AutomationEngine._();
  static const AutomationEngine instance = AutomationEngine._();

  static final List<_KeywordRule> _rules = [
    _KeywordRule(RegExp(r'\bcomprar?\b', caseSensitive: false),
        '🛒', label: 'Compra', triggers: 'comprar, compra'),
    _KeywordRule(RegExp(r'\bllamar?\b|\btelefon\w*\b', caseSensitive: false),
        '📞', label: 'Llamada', triggers: 'llamar, llamada, teléfono'),
    _KeywordRule(RegExp(r'\breuni[oó]n\b|\bmeet\w*\b', caseSensitive: false),
        '👥', label: 'Reunión', triggers: 'reunión, meet, meeting'),
    _KeywordRule(RegExp(r'\bleer?\b|\blibro\b|\blectura\b', caseSensitive: false),
        '📖', label: 'Lectura', triggers: 'leer, libro, lectura'),
    _KeywordRule(RegExp(r'\bbanco\b|\btransferencia\b|\bpago\b|\bfactura\b|\bpagar?\b', caseSensitive: false),
        '💰', label: 'Pago', triggers: 'banco, pago, factura, pagar, transferencia'),
    _KeywordRule(RegExp(r'\bemail\b|\bcorreo\b|\bresponder?\b', caseSensitive: false),
        '📧', label: 'Email', triggers: 'email, correo, responder'),
    _KeywordRule(RegExp(r'\bm[eé]dico\b|\bcita\b|\bdoctor\b|\bfarmacia\b', caseSensitive: false),
        '🏥', label: 'Salud', triggers: 'médico, cita, doctor, farmacia'),
    _KeywordRule(RegExp(r'\bviaje\b|\bvolar?\b|\bvuelo\b|\bhotel\b|\breservar?\b', caseSensitive: false),
        '✈️', label: 'Viaje', triggers: 'viaje, vuelo, hotel, reservar'),
    _KeywordRule(RegExp(r'\bdeporte\b|\bgym\b|\bcorrer?\b|\bentrenar?\b', caseSensitive: false),
        '🏃', label: 'Deporte', triggers: 'deporte, gym, correr, entrenar'),
    _KeywordRule(RegExp(r'\bregalo\b|\bcumple\w*\b|\bsorpresa\b', caseSensitive: false),
        '🎁', label: 'Regalo', triggers: 'regalo, cumpleaños, sorpresa'),
  ];

  String? detect(String title, {bool enabled = true}) {
    if (!enabled || title.trim().isEmpty) return null;
    for (final rule in _rules) {
      if (rule.pattern.hasMatch(title)) return rule.emoji;
    }
    return null;
  }

  List<KeywordRuleInfo> get allRules => _rules
      .map((r) => KeywordRuleInfo(
    triggers: r.triggers,
    emoji: r.emoji,
    label: r.label,
  ))
      .toList();
}

class _KeywordRule {
  const _KeywordRule(this.pattern, this.emoji,
      {required this.label, required this.triggers});
  final RegExp pattern;
  final String emoji;
  final String label;
  final String triggers;
}

class KeywordRuleInfo {
  const KeywordRuleInfo(
      {required this.triggers, required this.emoji, required this.label});
  final String triggers; // palabras legibles, no regex
  final String emoji;
  final String label;
}