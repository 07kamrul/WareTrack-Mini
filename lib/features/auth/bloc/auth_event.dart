// import 'package:equatable/equatable.dart';

// abstract class AuthEvent
//     extends Equatable {
//   @override
//   List<Object?> get props => [];
// }

// class VerifyCodeEvent
//     extends AuthEvent {
//   final String code;

//   VerifyCodeEvent(this.code);

//   @override
//   List<Object?> get props => [code];
// }
abstract class AuthEvent {
  // No need to extend Equatable
}

class VerifyCodeEvent extends AuthEvent {
  final String code;

  VerifyCodeEvent(this.code);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VerifyCodeEvent && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}
