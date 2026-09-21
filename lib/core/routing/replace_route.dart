import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Switches to [location] *replacing* the current page, including the browser history entry.
///
/// A bare `pushReplacement` still tells the browser to add a history entry, so bouncing between
/// the retro OS and the 3D room piled up Back clicks. `Router.neglect` makes it a real replace.
void replaceRoute(BuildContext context, String location) =>
    Router.neglect(context, () => context.pushReplacement(location));
