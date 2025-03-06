import 'package:equatable/equatable.dart';
import '../../core/models/user_register.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String identifier;
  final String password;

  LoginRequested(this.identifier, this.password);

  @override
  List<Object> get props => [identifier, password];
}

class RegisterRequested extends AuthEvent {
  final UserRegister user;

  RegisterRequested(this.user);

  @override
  List<Object> get props => [user];
}

class LogoutRequested extends AuthEvent {}
