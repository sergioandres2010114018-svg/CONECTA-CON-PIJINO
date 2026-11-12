import 'package:conecta_pijino/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Créditos del proyecto presentes', () {
    expect(AppConfig.creditos, contains('Grupo de Estudiantes Conecta con Pijiño'));
    expect(Categoria.todas.length, 7);
  });
}
