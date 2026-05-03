import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../data/repositories/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository = AuthRepository();

  AuthBloc() : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<CheckSession>(_onCheckSession);
    on<LogoutRequested>(_onLogoutRequested);
  }

  void _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await _authRepository.clearSession();
    emit(AuthInitial());
  }

  void _onCheckSession(CheckSession event, Emitter<AuthState> emit) async {
    try {
      final user = await _authRepository.getSession();
      if (user != null) {
        emit(AuthSuccess(message: 'Sesi ditemukan', user: user));
      } else {
        emit(AuthInitial());
      }
    } catch (e) {
      emit(AuthInitial());
    }
  }

  void _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      if (event.email.isEmpty || event.password.isEmpty) {
        emit(const AuthFailure(error: 'Email dan Password harus diisi'));
        return;
      }

      final user = await _authRepository.login(event.email, event.password);
      emit(AuthSuccess(message: 'Login Berhasil', user: user));
    } catch (e) {
      emit(AuthFailure(error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      if (event.name.isEmpty ||
          event.email.isEmpty ||
          event.password.isEmpty ||
          event.role.isEmpty) {
        emit(const AuthFailure(error: 'Semua field harus diisi'));
        return;
      }

      final user = await _authRepository.register(
        event.name,
        event.email,
        event.password,
        event.role,
      );
      emit(
        AuthSuccess(
          message: 'Registrasi Berhasil. Selamat Datang.',
          user: user,
        ),
      );
    } catch (e) {
      emit(AuthFailure(error: e.toString().replaceAll('Exception: ', '')));
    }
  }
}
