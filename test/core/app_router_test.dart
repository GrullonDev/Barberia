import 'package:barberia/core/platform/platform_capabilities.dart';
import 'package:barberia/core/router/app_router.dart';
import 'package:barberia/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState();

  void set(AuthState next) => state = next;
}

const admin = AuthState(isAuthenticated: true, role: UserRole.admin);
const barber = AuthState(isAuthenticated: true, role: UserRole.barber);
const newBarber = AuthState(
  isAuthenticated: true,
  role: UserRole.barber,
  mustChangePassword: true,
);

void main() {
  test('signing in keeps the same router (web must not reset to /)', () {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(FakeAuth.new),
        platformCapabilitiesProvider.overrideWithValue(
          PlatformCapabilities.forPlatform(
            isWeb: true,
            platform: TargetPlatform.android,
            webStaffPortals: true,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);
    (container.read(authProvider.notifier) as FakeAuth).set(admin);
    expect(identical(container.read(appRouterProvider), router), isTrue);
  });

  group('staffRedirect', () {
    test('signed-in staff on /login go to their portal', () {
      expect(staffRedirect(admin, '/login'), '/admin/portal');
      expect(staffRedirect(barber, '/login'), '/barber/portal');
      expect(staffRedirect(newBarber, '/login'), '/barber/change-password');
    });

    test('anonymous users cannot open portals', () {
      expect(staffRedirect(const AuthState(), '/admin/portal'), '/login');
      expect(staffRedirect(const AuthState(), '/barber/portal'), '/login');
      expect(staffRedirect(const AuthState(), '/booking'), isNull);
    });

    test('roles cannot open each other\'s portal', () {
      expect(staffRedirect(admin, '/barber/portal'), '/admin/portal');
      expect(staffRedirect(barber, '/admin/portal'), '/barber/portal');
      expect(staffRedirect(admin, '/admin/portal'), isNull);
    });

    test('barbers must change a temporary password first', () {
      expect(
        staffRedirect(newBarber, '/barber/portal'),
        '/barber/change-password',
      );
      expect(
        staffRedirect(barber, '/barber/change-password'),
        '/barber/portal',
      );
    });
  });
}
