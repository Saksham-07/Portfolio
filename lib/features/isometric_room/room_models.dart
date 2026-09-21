import 'package:flutter/material.dart';

/// Data for the walk-around rooms. Everything is boxes on a [roomSize] grid:
/// x runs down-right, y runs down-left, z is up (all in tile units).
const roomSize = 8.0;
const wallHeight = 3.1;

enum Wall { left, right } // left = plane x=0 (u runs along y), right = plane y=0 (u runs along x)
enum Face { x, y } // the two box faces the camera sees: plane x=x1, plane y=y1
enum Act { about, projects, contact, resume, retro, snake, mines, memory }
enum DecorKind { screen, books, drawers }
enum FloorStyle { wood, marble, concrete }
enum DecalKind { window, curtain, painting, mirror, neon, shelf, light }
enum Mat { matte, gloss, glass, metal, emissive }

class Decor {
  const Decor(this.kind, this.face,
      {this.c1 = const Color(0xFF1A202C), this.c2 = const Color(0xFF2D3748), this.f0 = 0.1, this.f1 = 0.9, this.count = 3, this.game});
  final DecorKind kind;
  final Act? game; // screens that mirror a game while it's being played
  final Face face;
  final Color c1, c2;
  final double f0, f1; // vertical extent as a fraction of the part's height
  final int count;
}

/// One box of furniture: a plain box, a chamfered "soft" box, or a leafy plant.
class Part {
  const Part(this.x, this.y, this.w, this.d, this.h, this.color,
      {this.z = 0, this.decor, this.glow, this.mat = Mat.matte, this.soft = false, this.plant = false});
  final double x, y, w, d, h, z;
  final Color color;
  final Decor? decor;
  final Color? glow;
  final Mat mat;
  final bool soft; // chamfered corners: cushions, poufs, armchairs
  final bool plant; // drawn as leaves instead of a box

  Rect get rect => Rect.fromLTWH(x, y, w, d);
  double get top => z + h;
  bool get solid => z < 1.2; // things hanging at head height don't block walking
}

/// Where the character sits while a module is open: [pos] is the seat, [stand] is the floor spot
/// he walks to first (and returns to), [face] is the direction he looks, [z] the cushion height.
class Seat {
  const Seat(this.pos, this.stand, this.face, this.z);
  final Offset pos, stand, face;
  final double z;
}

/// A furniture group; interactive when [act] is set.
class Prop {
  Prop(this.parts, {this.act, this.label, this.seat});
  final List<Part> parts;
  final Act? act;
  final String? label;
  final Seat? seat; // if set, the character sits here while the module is open

  late final Rect rect = parts.map((p) => p.rect).reduce((a, b) => a.expandToInclude(b));
  late final double topZ = parts.map((p) => p.top).reduce((a, b) => a > b ? a : b);
}

class Decal {
  const Decal(this.kind, this.wall, this.u, this.z, this.w, this.h,
      {this.c1 = Colors.white, this.c2 = Colors.grey});
  final DecalKind kind;
  final Wall wall;
  final double u, z, w, h;
  final Color c1, c2;

  /// Floor strip in front of a window: step into it and you go out through the glass.
  Rect get windowTrigger => wall == Wall.left ? Rect.fromLTWH(0, u, 0.62, w) : Rect.fromLTWH(u, 0, w, 0.62);
}

class Rug {
  const Rug(this.rect, this.a, this.b);
  final Rect rect;
  final Color a, b;
}

class Door {
  const Door(this.wall, this.u, this.to, this.spawn, this.label, {this.w = 1.2});
  final Wall wall;
  final double u, w;
  final int to; // index into [rooms]
  final Offset spawn; // where you appear in the destination room
  final String label;

  Rect get trigger => wall == Wall.left ? Rect.fromLTWH(0, u, 0.75, w) : Rect.fromLTWH(u, 0, w, 0.75);
}

class RoomDef {
  const RoomDef({
    required this.name,
    required this.topic,
    required this.wallL,
    required this.wallR,
    required this.floorA,
    required this.floorB,
    required this.style,
    required this.accent,
    required this.spawn,
    this.rugs = const [],
    this.props = const [],
    this.decals = const [],
    this.doors = const [],
  });
  final String name, topic;
  final Color wallL, wallR, floorA, floorB;
  final FloorStyle style;
  final Color accent; // LED strips, interaction rings, door glow
  final Offset spawn;
  final List<Rug> rugs;
  final List<Prop> props;
  final List<Decal> decals;
  final List<Door> doors;

  Iterable<Decal> get windows => decals.where((d) => d.kind == DecalKind.window);
}

// ---- palette ----------------------------------------------------------------------

const _black = Color(0xFF14171C);
const _steel = Color(0xFFB4BCC8);
const _walnut = Color(0xFF6A4A34);
const _oak = Color(0xFFD9C3A0);
const _oatmeal = Color(0xFFD8D1C4);
const _warm = Color(0xFFFFE3B0);

/// Room index of the bedroom: where he wakes up, and where he lands when he leaves.
const bedroomIndex = 4;

/// Sitting up on the bed / getting out of it. `pos` is where his hips are when lying, `stand` the floor by the foot of the bed.
const bedSeat = Seat(Offset(1.5, 3.4), Offset(2.95, 3.4), Offset(1, 0), 0.62);

/// Direction (grid) his head points while lying in bed (the head of the bed is against the left wall).
const bedHead = Offset(-1, 0);

/// Extra avatar animation state: lying down, falling, tumbling, fading, snoring...
class Pose {
  const Pose({this.lie = 0, this.lift = 0, this.spin = 0, this.scale = 1, this.alpha = 1, this.zzz = false, this.shout});
  final double lie; // 0 upright ... 1 lying along [bedHead]
  final double lift; // extra height (tiles), e.g. dropping from the ceiling
  final double spin; // extra rotation (radians)
  final double scale, alpha;
  final bool zzz; // floating Z's while asleep
  final String? shout; // speech bubble ("AAAH!")

  bool get neutral => lie == 0 && lift == 0 && spin == 0 && scale == 1 && alpha == 1 && !zzz && shout == null;
}

const _pouf1 = Seat(Offset(2.85, 3.95), Offset(2.85, 5.0), Offset(0, -1), 0.55);
const _pouf2 = Seat(Offset(4.65, 3.95), Offset(4.65, 5.0), Offset(0, -1), 0.55);

/// A leafy plant standing at (cx, cy) in a dark planter.
Prop _plant(double cx, double cy, {Color pot = const Color(0xFF2A2F37), double h = 1.5}) => Prop([
      Part(cx - 0.3, cy - 0.3, 0.6, 0.6, 0.5, pot, soft: true, mat: Mat.gloss),
      Part(cx - 0.4, cy - 0.4, 0.8, 0.8, h, const Color(0xFF2F9E6A), z: 0.5, plant: true),
    ]);

// ---- the rooms ------------------------------------------------------------------

final rooms = <RoomDef>[
  // 0 - LIVING ROOM: About me (the TV)
  RoomDef(
    name: 'LIVING ROOM',
    topic: 'ABOUT',
    wallL: const Color(0xFF2F3745),
    wallR: const Color(0xFF3D4757),
    floorA: const Color(0xFFB98F66),
    floorB: const Color(0xFFA98058),
    style: FloorStyle.wood,
    accent: const Color(0xFF5EEAD4),
    spawn: const Offset(4.6, 5.6),
    rugs: const [Rug(Rect.fromLTWH(1.7, 2.3, 3.8, 3.5), Color(0xFF3B4453), Color(0xFF566073))],
    doors: const [
      Door(Wall.left, 1.5, 1, Offset(1.6, 2.1), 'STUDY'),
      Door(Wall.right, 6.3, 2, Offset(1.6, 2.1), 'HALL'),
      Door(Wall.left, 6.6, bedroomIndex, Offset(6.9, 1.6), 'BEDROOM'),
    ],
    decals: const [
      Decal(DecalKind.window, Wall.left, 3.3, 0.2, 2.5, 2.7),
      Decal(DecalKind.curtain, Wall.left, 2.75, 0.1, 0.55, 2.95, c1: Color(0xFFE7E1D6)),
      Decal(DecalKind.curtain, Wall.left, 5.8, 0.1, 0.55, 2.95, c1: Color(0xFFE7E1D6)),
      Decal(DecalKind.light, Wall.right, 1.2, 1.3, 0.1, 0.9, c1: _warm),
    ],
    props: [
      // sofa against the left wall, facing +x
      Prop([
        Part(0.05, 3.9, 1.35, 2.6, 0.4, const Color(0xFF2B3038), z: 0.08, mat: Mat.metal),
        Part(0.05, 3.9, 1.3, 2.6, 0.32, _oatmeal, z: 0.16, soft: true),
        Part(0.05, 3.9, 0.42, 2.6, 0.55, const Color(0xFFCBC3B4), z: 0.45, soft: true),
        Part(0.05, 3.9, 1.3, 0.34, 0.3, const Color(0xFFC2BAAB), z: 0.48, soft: true),
        Part(0.05, 6.16, 1.3, 0.34, 0.3, const Color(0xFFC2BAAB), z: 0.48, soft: true),
        Part(0.47, 4.26, 0.88, 1.0, 0.16, const Color(0xFFE2DCD0), z: 0.48, soft: true),
        Part(0.47, 5.3, 0.88, 0.86, 0.16, const Color(0xFFE2DCD0), z: 0.48, soft: true),
        Part(0.5, 4.35, 0.24, 0.55, 0.4, const Color(0xFFC2714F), z: 0.64, soft: true),
        Part(0.5, 5.65, 0.24, 0.5, 0.36, const Color(0xFF4F8A8B), z: 0.64, soft: true),
        Part(0.0, 3.9, 1.4, 2.6, 0.03, Color(0xFF5EEAD4), z: 0.0, mat: Mat.emissive, glow: Color(0xFF5EEAD4)),
      ]),
      // glass coffee table
      Prop([
        for (final (x, y) in [(2.7, 3.35), (3.75, 3.35), (2.7, 4.4), (3.75, 4.4)])
          Part(x, y, 0.1, 0.1, 0.3, _black, mat: Mat.metal),
        Part(2.6, 3.25, 1.4, 1.4, 0.06, const Color(0xFF9CC7D6), z: 0.3, mat: Mat.glass),
        Part(2.85, 3.5, 0.5, 0.35, 0.1, const Color(0xFFE9E5DC), z: 0.36),
        Part(3.5, 4.0, 0.2, 0.2, 0.22, const Color(0xFFC2714F), z: 0.36, soft: true, mat: Mat.gloss),
      ]),
      // wall-mounted TV over a floating console (right wall) - opens ABOUT ME
      Prop([
        Part(2.2, 0, 3.0, 0.75, 0.38, _walnut, z: 0.32),
        Part(2.3, 0.05, 2.8, 0.6, 0.03, Color(0xFF5EEAD4), z: 0.29, mat: Mat.emissive, glow: Color(0xFF5EEAD4)),
        Part(2.75, 0.06, 2.1, 0.07, 1.15, const Color(0xFF0A0D12),
            z: 0.95,
            glow: const Color(0xFF7DD3FC),
            decor: const Decor(DecorKind.screen, Face.y,
                c1: Color(0xFF0B1B4D), c2: Color(0xFF14B8A6), f0: 0.04, f1: 0.96)),
      ], act: Act.about, label: 'ABOUT ME', seat: const Seat(Offset(6.15, 4.2), Offset(5.0, 4.2), Offset(0, -1), 0.52)),
      // cognac leather armchair facing the TV
      Prop([
        Part(5.65, 3.7, 0.12, 0.12, 0.25, _black, mat: Mat.metal),
        Part(6.5, 3.7, 0.12, 0.12, 0.25, _black, mat: Mat.metal),
        Part(5.65, 4.55, 0.12, 0.12, 0.25, _black, mat: Mat.metal),
        Part(6.5, 4.55, 0.12, 0.12, 0.25, _black, mat: Mat.metal),
        Part(5.6, 3.65, 1.1, 1.1, 0.3, const Color(0xFF9A5B3C), z: 0.22, soft: true, mat: Mat.gloss),
        Part(5.6, 4.5, 1.1, 0.28, 0.6, const Color(0xFF8A4F33), z: 0.5, soft: true, mat: Mat.gloss),
        Part(5.6, 3.65, 0.22, 0.9, 0.28, const Color(0xFF8A4F33), z: 0.52, soft: true, mat: Mat.gloss),
        Part(6.48, 3.65, 0.22, 0.9, 0.28, const Color(0xFF8A4F33), z: 0.52, soft: true, mat: Mat.gloss),
      ]),
      // arc floor lamp
      Prop([
        Part(5.72, 0.42, 0.12, 0.12, 0.05, _black, mat: Mat.metal),
        Part(5.76, 0.46, 0.04, 0.04, 1.45, _black, mat: Mat.metal),
        Part(5.55, 0.25, 0.5, 0.5, 0.38, _warm, z: 1.4, soft: true, mat: Mat.emissive, glow: Color(0xFFFFC46B)),
      ]),
      _plant(0.65, 0.65, h: 1.9),
      _plant(7.2, 6.8, h: 1.3),
    ],
  ),

  // 1 - STUDY: Projects (the desk)
  RoomDef(
    name: 'STUDY',
    topic: 'PROJECTS',
    wallL: const Color(0xFF243336),
    wallR: const Color(0xFF2F4548),
    floorA: const Color(0xFF5B4030),
    floorB: const Color(0xFF4E3628),
    style: FloorStyle.wood,
    accent: const Color(0xFF818CF8),
    spawn: const Offset(2.4, 3.4),
    rugs: const [Rug(Rect.fromLTWH(3.0, 1.4, 3.7, 2.9), Color(0xFF2B333D), Color(0xFF454F5C))],
    doors: const [Door(Wall.left, 1.5, 0, Offset(1.6, 2.1), 'LIVING ROOM')],
    decals: const [
      Decal(DecalKind.window, Wall.right, 0.9, 0.2, 2.5, 2.7),
      Decal(DecalKind.curtain, Wall.right, 0.35, 0.1, 0.55, 2.95, c1: Color(0xFFDDD8CE)),
      Decal(DecalKind.curtain, Wall.right, 3.4, 0.1, 0.55, 2.95, c1: Color(0xFFDDD8CE)),
      Decal(DecalKind.painting, Wall.left, 5.7, 1.5, 1.4, 1.0, c1: Color(0xFF223A4A), c2: Color(0xFFE9A15B)),
      Decal(DecalKind.painting, Wall.right, 4.4, 2.05, 1.7, 0.75, c1: Color(0xFF2E2A45), c2: Color(0xFF7DD3FC)),
      Decal(DecalKind.light, Wall.left, 7.4, 1.4, 0.1, 0.9, c1: _warm),
    ],
    props: [
      // full-height walnut bookshelf (left wall)
      Prop([
        Part(0, 3.6, 0.75, 2.4, 2.7, _walnut,
            decor: const Decor(DecorKind.books, Face.x, f0: 0.04, f1: 0.96, count: 5)),
      ]),
      // desk with ultrawide monitor + laptop - opens PROJECTS
      Prop([
        Part(3.4, 0, 3.2, 1.3, 0.07, _oak, z: 0.76, mat: Mat.gloss),
        Part(3.45, 0.05, 0.08, 1.2, 0.76, _black, mat: Mat.metal),
        Part(6.47, 0.05, 0.08, 1.2, 0.76, _black, mat: Mat.metal),
        Part(5.35, 0.08, 1.05, 1.1, 0.68, const Color(0xFF2B3038),
            decor: const Decor(DecorKind.drawers, Face.y, c1: Color(0xFF3A414C), count: 3)),
        Part(3.75, 0.28, 1.9, 0.08, 0.72, const Color(0xFF0A0D12),
            z: 0.98,
            glow: const Color(0xFF818CF8),
            decor: const Decor(DecorKind.screen, Face.y, c1: Color(0xFF1E1B4B), c2: Color(0xFF6366F1), f0: 0.05, f1: 0.95)),
        Part(4.6, 0.32, 0.22, 0.14, 0.2, _black, z: 0.83, mat: Mat.metal),
        Part(4.1, 0.8, 0.85, 0.3, 0.03, const Color(0xFFC9CED6), z: 0.83, mat: Mat.metal),
        Part(6.05, 0.3, 0.14, 0.14, 0.16, const Color(0xFFF2EFE8), z: 0.83, soft: true, mat: Mat.gloss),
        Part(3.55, 0.25, 0.1, 0.1, 0.45, _black, z: 0.83, mat: Mat.metal),
        Part(3.5, 0.2, 0.32, 0.22, 0.1, _warm, z: 1.28, soft: true, mat: Mat.emissive, glow: Color(0xFFFFC46B)),
      ], act: Act.projects, label: 'PROJECTS', seat: const Seat(Offset(4.6, 2.3), Offset(3.7, 2.4), Offset(0, -1), 0.64)),
      // ergonomic chair (back toward the camera, facing the desk)
      Prop([
        Part(4.5, 2.35, 0.12, 0.12, 0.5, _steel, mat: Mat.metal),
        Part(4.15, 1.95, 0.9, 0.9, 0.14, const Color(0xFF3A4556), z: 0.5, soft: true),
        Part(4.2, 2.75, 0.8, 0.14, 0.85, const Color(0xFF3A4556), z: 0.62, soft: true),
      ]),
      _plant(7.15, 0.7, h: 1.6),
      // reading lamp near the shelf
      Prop([
        Part(0.4, 6.75, 0.12, 0.12, 0.05, _black, mat: Mat.metal),
        Part(0.44, 6.79, 0.04, 0.04, 1.4, _black, mat: Mat.metal),
        Part(0.22, 6.57, 0.5, 0.5, 0.36, _warm, z: 1.35, soft: true, mat: Mat.emissive, glow: Color(0xFFFFC46B)),
      ]),
    ],
  ),

  // 2 - HALL: Contact + Resume
  RoomDef(
    name: 'HALL',
    topic: 'CONTACT',
    wallL: const Color(0xFF4A4541),
    wallR: const Color(0xFF5A544F),
    floorA: const Color(0xFFEAE7E2),
    floorB: const Color(0xFFD9D5CF),
    style: FloorStyle.marble,
    accent: const Color(0xFFFBBF24),
    spawn: const Offset(3.8, 3.4),
    rugs: const [Rug(Rect.fromLTWH(1.4, 1.5, 5.4, 1.8), Color(0xFF5A463D), Color(0xFF8A6F5E))],
    doors: const [
      Door(Wall.left, 1.5, 0, Offset(6.9, 1.6), 'LIVING ROOM'),
      Door(Wall.right, 6.3, 3, Offset(1.6, 2.1), 'GAME LOUNGE'),
    ],
    decals: const [
      Decal(DecalKind.mirror, Wall.right, 2.3, 1.45, 1.8, 1.4),
      Decal(DecalKind.painting, Wall.right, 4.9, 1.9, 1.1, 1.0, c1: Color(0xFF2C3E3A), c2: Color(0xFFD9A441)),
      Decal(DecalKind.painting, Wall.left, 4.0, 1.5, 1.5, 1.1, c1: Color(0xFF3A2D3F), c2: Color(0xFFE08D79)),
      Decal(DecalKind.light, Wall.left, 3.2, 1.3, 0.1, 0.9, c1: _warm),
      Decal(DecalKind.light, Wall.left, 6.4, 1.3, 0.1, 0.9, c1: _warm),
    ],
    props: [
      // marble-top console with a smart-speaker phone dock - opens CONTACT
      Prop([
        Part(2.0, 0, 2.4, 0.8, 0.07, const Color(0xFFF1EFEA), z: 0.8, mat: Mat.gloss),
        Part(2.05, 0.05, 0.07, 0.7, 0.8, Color(0xFFB08D57), mat: Mat.metal),
        Part(4.25, 0.05, 0.07, 0.7, 0.8, Color(0xFFB08D57), mat: Mat.metal),
        Part(2.5, 0.25, 0.42, 0.42, 0.2, _black, z: 0.87, soft: true, mat: Mat.gloss),
        Part(2.55, 0.3, 0.32, 0.32, 0.03, Color(0xFFFBBF24), z: 1.07, soft: true, mat: Mat.emissive, glow: Color(0xFFFBBF24)),
        Part(3.5, 0.3, 0.12, 0.12, 0.5, _black, z: 0.87, mat: Mat.metal),
        Part(3.3, 0.15, 0.5, 0.5, 0.3, _warm, z: 1.33, soft: true, mat: Mat.emissive, glow: Color(0xFFFFC46B)),
      ], act: Act.contact, label: 'CONTACT', seat: const Seat(Offset(0.45, 4.7), Offset(1.6, 4.7), Offset(1, 0), 0.5)),
      // brushed-steel filing cabinet - opens RESUME
      Prop([
        Part(4.9, 0, 1.2, 0.9, 1.5, Color(0xFF8A94A1), mat: Mat.metal,
            decor: const Decor(DecorKind.drawers, Face.y, c1: Color(0xFF9EA8B5), count: 3)),
      ], act: Act.resume, label: 'RESUME'),
      // bench under the left wall
      Prop([
        Part(0.05, 3.6, 0.8, 2.2, 0.36, _walnut),
        Part(0.12, 3.68, 0.66, 2.04, 0.14, const Color(0xFF2F3A3A), z: 0.36, soft: true),
      ]),
      // sculpture on a pedestal
      Prop([
        Part(0.3, 6.3, 0.7, 0.7, 0.9, const Color(0xFFEDEAE4), soft: true, mat: Mat.gloss),
        Part(0.45, 6.45, 0.4, 0.4, 0.5, Color(0xFFB08D57), z: 0.9, soft: true, mat: Mat.metal),
      ]),
      _plant(0.65, 0.65, h: 1.8),
    ],
  ),

  // 3 - GAME LOUNGE: game kiosks + retro PC
  RoomDef(
    name: 'GAME LOUNGE',
    topic: 'GAMES',
    wallL: const Color(0xFF1D1C33),
    wallR: const Color(0xFF29274A),
    floorA: const Color(0xFF3A3D4A),
    floorB: const Color(0xFF343747),
    style: FloorStyle.concrete,
    accent: const Color(0xFFE879F9),
    spawn: const Offset(4.0, 5.6),
    rugs: const [Rug(Rect.fromLTWH(2.2, 2.6, 3.8, 3.2), Color(0xFF232637), Color(0xFF3A3F5A))],
    doors: const [Door(Wall.left, 1.5, 2, Offset(6.9, 1.6), 'HALL')],
    decals: const [
      Decal(DecalKind.neon, Wall.right, 5.0, 1.7, 2.5, 0.9, c1: Color(0xFFE879F9)),
      Decal(DecalKind.painting, Wall.left, 3.9, 1.7, 1.2, 1.0, c1: Color(0xFF14172A), c2: Color(0xFF34D399)),
      Decal(DecalKind.painting, Wall.left, 5.4, 1.7, 1.2, 1.0, c1: Color(0xFF14172A), c2: Color(0xFFF59E0B)),
    ],
    props: [
      // three glass game kiosks
      for (final (i, c) in [
        (0, (Act.snake, 'SNAKE', Color(0xFFF43F5E))),
        (1, (Act.mines, 'MINESWEEPER', Color(0xFF38BDF8))),
        (2, (Act.memory, 'MEMORY', Color(0xFF34D399))),
      ])
        Prop([
          Part(0.75 + i * 1.35, 0.05, 0.9, 0.7, 0.28, const Color(0xFF1B1F2A), soft: true, mat: Mat.metal),
          Part(0.85 + i * 1.35, 0.3, 0.7, 0.1, 1.95, const Color(0xFF0B0E16),
              z: 0.28,
              glow: c.$3,
              decor: Decor(DecorKind.screen, Face.y, c1: const Color(0xFF0B0E16), c2: c.$3, f0: 0.06, f1: 0.94, game: c.$1)),
          Part(0.85 + i * 1.35, 0.3, 0.7, 0.1, 0.05, c.$3, z: 2.23, mat: Mat.emissive, glow: c.$3),
        ], act: c.$1, label: c.$2, seat: i == 2 ? _pouf2 : _pouf1),
      // retro PC on a dark desk - goes back to the retro OS
      Prop([
        Part(0, 3.4, 1.2, 2.2, 0.06, const Color(0xFF232A35), z: 0.72, mat: Mat.gloss),
        for (final (x, y) in [(0.06, 3.46), (1.06, 3.46), (0.06, 5.46), (1.06, 5.46)])
          Part(x, y, 0.08, 0.08, 0.72, _black, mat: Mat.metal),
        Part(0.15, 3.95, 0.9, 0.9, 0.85, const Color(0xFFCFC6B0),
            z: 0.78,
            glow: const Color(0xFF68D391),
            decor: const Decor(DecorKind.screen, Face.x, c1: Color(0xFF052E1C), c2: Color(0xFF22C55E), f0: 0.2, f1: 0.85)),
        Part(0.75, 4.1, 0.35, 0.6, 0.04, const Color(0xFF3A414C), z: 0.78, soft: true),
      ], act: Act.retro, label: 'RETRO PC'),
      // lounge poufs (facing the kiosks)
      Prop([Part(2.3, 3.4, 1.1, 1.1, 0.55, const Color(0xFF5B5F97), soft: true)]),
      Prop([Part(4.1, 3.4, 1.1, 1.1, 0.55, const Color(0xFF3E7C86), soft: true)]),
      _plant(7.2, 6.7, h: 1.5),
    ],
  ),

  // 4 - BEDROOM: where he wakes up (and where he lands when he leaves)
  RoomDef(
    name: 'BEDROOM',
    topic: 'BEDROOM',
    wallL: const Color(0xFF2B2F4A),
    wallR: const Color(0xFF383D5E),
    floorA: const Color(0xFF8A6A50),
    floorB: const Color(0xFF7C5E46),
    style: FloorStyle.wood,
    accent: const Color(0xFFA78BFA),
    spawn: const Offset(2.95, 3.4),
    rugs: const [Rug(Rect.fromLTWH(1.0, 1.9, 3.6, 3.0), Color(0xFF3B3F63), Color(0xFF5A5F8F))],
    doors: const [Door(Wall.right, 6.3, 0, Offset(1.6, 7.2), 'LIVING ROOM')],
    decals: const [
      Decal(DecalKind.window, Wall.right, 1.5, 0.2, 2.6, 2.7),
      Decal(DecalKind.curtain, Wall.right, 0.95, 0.1, 0.55, 2.95, c1: Color(0xFFCBBFEA)),
      Decal(DecalKind.curtain, Wall.right, 4.1, 0.1, 0.55, 2.95, c1: Color(0xFFCBBFEA)),
      Decal(DecalKind.painting, Wall.left, 2.8, 1.7, 1.3, 0.95, c1: Color(0xFF1E2140), c2: Color(0xFFF59E0B)),
      Decal(DecalKind.light, Wall.left, 1.75, 1.2, 0.1, 0.8, c1: _warm),
      Decal(DecalKind.light, Wall.left, 5.1, 1.2, 0.1, 0.8, c1: _warm),
      Decal(DecalKind.mirror, Wall.right, 4.7, 1.5, 1.1, 1.3),
    ],
    props: [
      // the bed: head against the left wall
      Prop([
        Part(0.02, 2.4, 2.45, 2.0, 0.3, _walnut),
        Part(0, 2.35, 0.14, 2.1, 1.25, const Color(0xFF4A3628)),
        Part(0.15, 2.5, 2.3, 1.8, 0.25, const Color(0xFFECE7F5), z: 0.3, soft: true),
        Part(0.9, 2.5, 1.57, 1.8, 0.14, const Color(0xFF7C6FC1), z: 0.55, soft: true),
        Part(0.2, 2.65, 0.55, 0.7, 0.16, Colors.white, z: 0.55, soft: true),
        Part(0.2, 3.45, 0.55, 0.7, 0.16, Colors.white, z: 0.55, soft: true),
      ]),
      // nightstands with lamps
      Prop([
        Part(0.05, 1.5, 0.6, 0.75, 0.6, _walnut),
        Part(0.15, 1.72, 0.35, 0.35, 0.3, _warm, z: 0.6, soft: true, mat: Mat.emissive, glow: Color(0xFFFFC46B)),
      ]),
      Prop([
        Part(0.05, 4.55, 0.6, 0.75, 0.6, _walnut),
        Part(0.15, 4.75, 0.35, 0.35, 0.3, _warm, z: 0.6, soft: true, mat: Mat.emissive, glow: Color(0xFFFFC46B)),
      ]),
      // wardrobe
      Prop([
        Part(0, 5.6, 0.75, 1.9, 2.6, const Color(0xFF5B5F80), decor: const Decor(DecorKind.drawers, Face.x, c1: Color(0xFF6E7398), count: 2)),
      ]),
      // dresser under the mirror
      Prop([
        Part(4.5, 0, 1.4, 0.7, 0.95, _walnut, decor: const Decor(DecorKind.drawers, Face.y, c1: Color(0xFF7A5A44), count: 3)),
        Part(5.0, 0.2, 0.3, 0.3, 0.22, const Color(0xFFCFE3EA), z: 0.95, soft: true, mat: Mat.glass),
      ]),
      _plant(7.2, 6.8, h: 1.5),
    ],
  ),
];
