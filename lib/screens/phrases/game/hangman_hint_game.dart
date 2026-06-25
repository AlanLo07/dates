import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../../../utils/colors.dart';

/// Mini escena Forge2D para dar vida al juego sin alterar su logica.
class HangmanHintGame extends Forge2DGame {
  HangmanHintGame() : super(gravity: Vector2(0, 7.5), zoom: 20);

  final math.Random _random = math.Random();
  bool _boundsReady = false;
  bool _spawnedOnce = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(_SoftBackground());
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_boundsReady && size.x > 0 && size.y > 0) {
      _createBounds();
      _boundsReady = true;
    }

    if (_boundsReady && !_spawnedOnce) {
      for (var i = 0; i < 8; i++) {
        _spawnOrb(
          color: _palette[i % _palette.length],
          forceUp: _random.nextDouble() * 12,
        );
      }
      _spawnedOnce = true;
    }
  }

  void registerCorrectGuess() {
    _spawnOrb(color: const Color(0xFF81C784), forceUp: 18);
  }

  void registerWrongGuess() {
    _spawnOrb(color: const Color(0xFFE57373), forceUp: 22);
  }

  void _spawnOrb({required Color color, double forceUp = 12}) {
    if (!_boundsReady) {
      return;
    }

    final worldW = size.x / camera.viewfinder.zoom;
    final worldH = size.y / camera.viewfinder.zoom;

    final position = Vector2(
      0.8 + _random.nextDouble() * (worldW - 1.6),
      worldH * 0.1,
    );

    add(_OrbBody(position: position, color: color));

    // Impulso aleatorio para crear movimiento organico.
    final xImpulse = (_random.nextDouble() - 0.5) * 3.2;
    world.children.whereType<_OrbBody>().last.body.applyLinearImpulse(
      Vector2(xImpulse, -forceUp),
    );
  }

  void _createBounds() {
    final worldW = size.x / camera.viewfinder.zoom;
    final worldH = size.y / camera.viewfinder.zoom;
    addAll([
      _WallBody(Vector2(worldW / 2, worldH + 0.2), Vector2(worldW, 0.4)),
      _WallBody(Vector2(-0.2, worldH / 2), Vector2(0.4, worldH)),
      _WallBody(Vector2(worldW + 0.2, worldH / 2), Vector2(0.4, worldH)),
      _WallBody(Vector2(worldW / 2, -0.2), Vector2(worldW, 0.4)),
    ]);
  }
}

const List<Color> _palette = [
  Color(0xFFB0B6E8),
  Color(0xFFA9D1DF),
  Color(0xFFD8C9E7),
  Color(0xFFF8BBD0),
];

class _SoftBackground extends PositionComponent
    with HasGameReference<Forge2DGame> {
  _SoftBackground();

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, game.size.x, game.size.y);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x11FFFFFF), Color(0x22FFFFFF)],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      paint,
    );
  }
}

class _WallBody extends BodyComponent {
  _WallBody(this._position, this._size);

  final Vector2 _position;
  final Vector2 _size;

  @override
  Body createBody() {
    final shape = PolygonShape()..setAsBoxXY(_size.x / 2, _size.y / 2);
    final fixtureDef = FixtureDef(shape);
    final bodyDef = BodyDef(position: _position, type: BodyType.static);
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}

class _OrbBody extends BodyComponent {
  _OrbBody({required Vector2 position, required this.color})
    : _position = position;

  final Vector2 _position;
  final Color color;

  @override
  Body createBody() {
    final radius = 0.30;
    final shape = CircleShape()..radius = radius;
    final fixture = FixtureDef(
      shape,
      density: 1,
      friction: 0.15,
      restitution: 0.88,
    );

    final bodyDef = BodyDef(
      position: _position,
      type: BodyType.dynamic,
      angularDamping: 0.25,
      linearDamping: 0.05,
    );

    return world.createBody(bodyDef)..createFixture(fixture);
  }

  @override
  void render(Canvas canvas) {
    final radiusPx = 0.30;

    final paint = Paint()..color = color.withOpacity(0.85);
    final glow = Paint()..color = AppColors.letterBg.withOpacity(0.26);

    canvas.drawCircle(Offset.zero, radiusPx, paint);
    canvas.drawCircle(const Offset(-0.08, -0.08), radiusPx * 0.33, glow);
  }
}
