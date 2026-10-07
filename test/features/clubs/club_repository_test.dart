import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_clubes/features/clubs/data/repositories/club_repository.dart';

void main() {
  group('ClubRepository slug normalization', () {
    test('normalizes accents, spaces, punctuation, and case', () {
      expect(
        ClubRepository.normalizeSlug('  Fútbol Árbol Ñandú 2013! '),
        'futbol-arbol-nandu-2013',
      );
    });

    test('validates that normalization leaves a usable slug', () {
      expect(ClubRepository.validateSlug('!!!'), isNotNull);
      expect(ClubRepository.validateSlug('F.C. Burguillos 2013'), isNull);
    });
  });

  group('ClubRepository creation error mapping', () {
    test('maps a duplicate clubs slug constraint to a friendly message', () {
      expect(
        ClubRepository.creationErrorMessage(
          code: '23505',
          message:
              'duplicate key value violates unique constraint "clubs_slug_key"',
        ),
        'Ese identificador ya está en uso, elige otro.',
      );
    });

    test('does not expose unrelated Postgres errors', () {
      expect(
        ClubRepository.creationErrorMessage(
          code: '23505',
          message:
              'duplicate key value violates unique constraint "other_key"',
        ),
        'No se ha podido crear el club. Inténtalo de nuevo.',
      );
    });
  });
}
