import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waretrack_mini/data/models/user_model.dart';
import 'package:waretrack_mini/features/auth/verify_code_use_case.dart';
import 'package:waretrack_mini/core/services/storage_service.dart';
import 'package:waretrack_mini/core/constants/verification_storage_keys.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final VerifyCodeUseCase verifyCodeUseCase;
  final LocalStorage storage;

  AuthBloc(this.verifyCodeUseCase, this.storage) : super(AuthInitial()) {
    on<VerifyCodeEvent>(_codeVerify);
  }

  Future<void> _codeVerify(
    VerifyCodeEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await verifyCodeUseCase(event.code);

      await storage.writeString(
        kAuthUserData,
        jsonEncode((user as UserModel).toJson()),
      );

      emit(AuthSuccess(user));
    } catch (e) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      emit(AuthFailure(cleanMessage));
    }
  }
}
