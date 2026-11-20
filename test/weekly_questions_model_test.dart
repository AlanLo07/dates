import 'package:flutter_test/flutter_test.dart';
import 'package:dates/models/weekly_question.dart';

void main() {
  group('WeeklyQuestion Model', () {
    test('fromJson creates WeeklyQuestion correctly', () {
      final json = {
        'id': 'test-id',
        'text': 'Test question?',
        'category': 'profundas',
        'catalogVersion': 1,
        'presented': true,
        'locked': false,
        'isCurrent': true,
        'status': 'partial',
        'canAnswer': false,
        'canEdit': true,
        'answers': {
          'user1': {
            'text': 'Test answer',
            'createdAt': '2026-11-19T18:00:00+00:00',
            'updatedAt': '2026-11-19T18:05:00+00:00',
          }
        },
        'firstPresentedAt': '2026-11-19T18:00:00+00:00',
        'lastPresentedWeek': '2026-11-16',
      };

      final question = WeeklyQuestion.fromJson(json);

      expect(question.id, 'test-id');
      expect(question.text, 'Test question?');
      expect(question.category, 'profundas');
      expect(question.catalogVersion, 1);
      expect(question.presented, true);
      expect(question.locked, false);
      expect(question.isCurrent, true);
      expect(question.status, 'partial');
      expect(question.canAnswer, false);
      expect(question.canEdit, true);
      expect(question.answers.length, 1);
      expect(question.answers['user1']?.text, 'Test answer');
      expect(question.firstPresentedAt, isNotNull);
      expect(question.lastPresentedWeek, '2026-11-16');
    });

    test('toJson serializes WeeklyQuestion correctly', () {
      final answer = Answer(
        text: 'Test answer',
        createdAt: DateTime.parse('2026-11-19T18:00:00+00:00'),
        updatedAt: DateTime.parse('2026-11-19T18:05:00+00:00'),
      );

      final question = WeeklyQuestion(
        id: 'test-id',
        text: 'Test question?',
        category: 'profundas',
        catalogVersion: 1,
        presented: true,
        locked: false,
        isCurrent: true,
        status: 'partial',
        canAnswer: false,
        canEdit: true,
        answers: {'user1': answer},
        firstPresentedAt: DateTime.parse('2026-11-19T18:00:00+00:00'),
        lastPresentedWeek: '2026-11-16',
      );

      final json = question.toJson();

      expect(json['id'], 'test-id');
      expect(json['text'], 'Test question?');
      expect(json['category'], 'profundas');
      expect(json['status'], 'partial');
      expect((json['answers'] as Map).containsKey('user1'), true);
    });

    test('copyWith creates modified copy', () {
      final question = WeeklyQuestion(
        id: 'test-id',
        text: 'Original text',
        category: 'profundas',
        catalogVersion: 1,
        presented: false,
        locked: true,
        isCurrent: false,
        status: 'unseen',
        canAnswer: false,
        canEdit: false,
        answers: {},
      );

      final modified = question.copyWith(
        text: 'Modified text',
        status: 'pending',
        presented: true,
      );

      expect(modified.text, 'Modified text');
      expect(modified.status, 'pending');
      expect(modified.presented, true);
      expect(modified.id, question.id); // unchanged
      expect(modified.category, question.category); // unchanged
    });
  });

  group('Answer Model', () {
    test('isEdited returns true when dates differ', () {
      final answer = Answer(
        text: 'Test',
        createdAt: DateTime.parse('2026-11-19T18:00:00+00:00'),
        updatedAt: DateTime.parse('2026-11-19T18:05:00+00:00'),
      );

      expect(answer.isEdited(), true);
    });

    test('isEdited returns false when dates are same', () {
      final now = DateTime.now();
      final answer = Answer(
        text: 'Test',
        createdAt: now,
        updatedAt: now,
      );

      expect(answer.isEdited(), false);
    });
  });

  group('CatalogQuestion Model', () {
    test('fromJson creates CatalogQuestion correctly', () {
      final json = {
        'id': 'test-id',
        'text': 'Test question?',
        'category': 'romanticas',
        'version': 2,
        'createdAt': '2026-11-15T10:00:00+00:00',
        'updatedAt': '2026-11-19T18:00:00+00:00',
        'createdBy': 'user-1',
        'updatedBy': 'user-1',
      };

      final question = CatalogQuestion.fromJson(json);

      expect(question.id, 'test-id');
      expect(question.text, 'Test question?');
      expect(question.category, 'romanticas');
      expect(question.version, 2);
      expect(question.createdBy, 'user-1');
      expect(question.updatedBy, 'user-1');
    });
  });

  group('WeeklyQuestionsResponse Model', () {
    test('fromJson creates response with question', () {
      final json = {
        'weekKey': '2026-11-16',
        'weekStart': '2026-11-16T00:00:00-06:00',
        'weekEnd': '2026-11-23T00:00:00-06:00',
        'timeZone': 'America/Mexico_City',
        'users': [
          {'sub': 'user-1', 'name': 'User 1'},
          {'sub': 'user-2', 'name': 'User 2'},
        ],
        'question': {
          'id': 'q-1',
          'text': 'Question?',
          'category': 'divertidas',
          'catalogVersion': 1,
          'presented': true,
          'locked': false,
          'isCurrent': true,
          'status': 'partial',
          'canAnswer': true,
          'canEdit': false,
          'answers': {},
          'firstPresentedAt': '2026-11-16T00:00:00-06:00',
          'lastPresentedWeek': '2026-11-16',
        },
        'message': null,
      };

      final response = WeeklyQuestionsResponse.fromJson(json);

      expect(response.weekKey, '2026-11-16');
      expect(response.users.length, 2);
      expect(response.question, isNotNull);
      expect(response.question!.text, 'Question?');
      expect(response.message, null);
    });

    test('fromJson creates response with null question', () {
      final json = {
        'weekKey': '2026-11-16',
        'weekStart': '2026-11-16T00:00:00-06:00',
        'weekEnd': '2026-11-23T00:00:00-06:00',
        'timeZone': 'America/Mexico_City',
        'users': [],
        'question': null,
        'message': 'No hay preguntas disponibles',
      };

      final response = WeeklyQuestionsResponse.fromJson(json);

      expect(response.question, null);
      expect(response.message, 'No hay preguntas disponibles');
    });
  });

  group('PaginatedResponse Model', () {
    test('fromJson parses pagination', () {
      final json = {
        'items': [
          {
            'id': 'q-1',
            'text': 'Q1?',
            'category': 'profundas',
            'catalogVersion': 1,
            'presented': false,
            'locked': true,
            'isCurrent': false,
            'status': 'unseen',
            'canAnswer': false,
            'canEdit': false,
            'answers': {},
          }
        ],
        'nextToken': 'token-123',
      };

      final response = PaginatedResponse.fromJson(
        json,
        (item) => WeeklyQuestion.fromJson(item),
      );

      expect(response.items.length, 1);
      expect(response.nextToken, 'token-123');
    });
  });
}
