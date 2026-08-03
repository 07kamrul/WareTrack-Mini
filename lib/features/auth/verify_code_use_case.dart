import 'package:waretrack_mini/data/models/user_entity.dart';
import 'package:waretrack_mini/core/api_services/auth_service.dart';

class VerifyCodeUseCase {
  final AuthService authService;

  VerifyCodeUseCase(this.authService);

  Future<UserEntity> call(String code) {
    return authService.codeVerify(code);
  }
}
