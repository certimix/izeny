class Validations {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nome é obrigatório.';
    return null;
  }

  static String? validateEmail(String? value, [bool isRequired = true]) {
    final v = (value ?? '').trim();
    if (v.isEmpty && isRequired) return 'E-mail é obrigatório.';
    final RegExp emailExp = RegExp(
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$");
    if (!emailExp.hasMatch(v) && isRequired) {
      return 'Insira um e-mail válido.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    final v = (value ?? '');
    if (v.isEmpty || v.length < 6) {
      return 'A senha deve ter no mínimo 6 caracteres.';
    }
    return null;
  }
}
