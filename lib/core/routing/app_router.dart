import 'package:go_router/go_router.dart';
import '../../features/experience_selector/boot_screen.dart';
import '../../features/retro_os/retro_os_view.dart';
import '../../features/isometric_room/isometric_room_view.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const BootScreen(),
    ),
    GoRoute(
      path: '/retro',
      builder: (context, state) => const RetroOSView(),
    ),
    GoRoute(
      path: '/isometric',
      builder: (context, state) => IsometricRoomView(debug: state.uri.queryParameters['debug'] == '1'),
    ),
  ],
);