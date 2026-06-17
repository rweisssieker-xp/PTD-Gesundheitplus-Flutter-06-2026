class AiConsentService {
  AiConsentService({required bool initialAllowed}) : _allowed = initialAllowed;

  bool _allowed;

  bool get allowed => _allowed;

  void grant() => _allowed = true;

  void revoke() => _allowed = false;
}
