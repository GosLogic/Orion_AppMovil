import 'package:flutter_test/flutter_test.dart';
import 'package:orion_app/core/error/failures.dart';

void main() {
  test('Failure base message', () {
    const failure = ServerFailure('test');
    expect(failure.message, 'test');
  });
}
