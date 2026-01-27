import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

// ===================== Mock Classes =====================

/// Mock لـ FirebaseAuth
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

/// Mock لـ User
class MockUser extends Mock implements User {}

/// Mock لـ UserCredential
class MockUserCredential extends Mock implements UserCredential {}

/// Mock لـ DatabaseReference
class MockDatabaseReference extends Mock implements DatabaseReference {}

/// Mock لـ DataSnapshot
class MockDataSnapshot extends Mock implements DataSnapshot {}

/// Mock لـ DatabaseEvent
class MockDatabaseEvent extends Mock implements DatabaseEvent {}

/// Mock لـ Query
class MockQuery extends Mock implements Query {}

// ===================== Fake Classes =====================

/// Fake لـ AuthCredential (مطلوب لـ registerFallbackValue)
class FakeAuthCredential extends Fake implements AuthCredential {}

// ===================== Setup =====================

/// تهيئة الـ Mocks قبل الاختبارات
void setUpMocks() {
  registerFallbackValue(FakeAuthCredential());
}

// ===================== Helper Functions =====================

/// إنشاء MockFirebaseAuth مهيأ للنجاح
MockFirebaseAuth createSuccessfulAuthMock() {
  final mockAuth = MockFirebaseAuth();
  final mockUserCredential = MockUserCredential();
  final mockUser = MockUser();

  when(() => mockUser.uid).thenReturn('test-user-id');
  when(() => mockUser.email).thenReturn('test@example.com');
  when(() => mockUserCredential.user).thenReturn(mockUser);
  when(() => mockAuth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => mockUserCredential);
  when(() => mockAuth.signOut()).thenAnswer((_) async {});
  when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(null));

  return mockAuth;
}

/// إنشاء MockFirebaseAuth مهيأ للفشل
MockFirebaseAuth createFailedAuthMock(String errorCode) {
  final mockAuth = MockFirebaseAuth();

  when(() => mockAuth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenThrow(FirebaseAuthException(errorCode, 'Test error'));
  when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(null));

  return mockAuth;
}

/// إنشاء MockDatabaseReference مهيأ لإرجاع بيانات مستخدم
MockDatabaseReference createDatabaseMockWithUser({
  required String phone,
  required String email,
  String? encodedPassword,
}) {
  final mockDbRef = MockDatabaseReference();
  final mockSnapshot = MockDataSnapshot();
  final mockEvent = MockDatabaseEvent();
  final mockQuery = MockQuery();

  // بيانات المستخدم
  when(() => mockSnapshot.exists).thenReturn(true);
  when(() => mockSnapshot.value).thenReturn({
    'user-id': {
      'phone': phone,
      'email': email,
      'password': encodedPassword,
    },
  });

  when(() => mockEvent.snapshot).thenReturn(mockSnapshot);
  when(() => mockQuery.get()).thenAnswer((_) async => mockSnapshot);
  when(() => mockDbRef.orderByChild(any())).thenReturn(mockQuery);
  when(() => mockQuery.equalTo(any())).thenReturn(mockQuery);
  when(() => mockDbRef.child(any())).thenReturn(mockDbRef);
  when(() => mockDbRef.update(any())).thenAnswer((_) async {});
  when(() => mockDbRef.once()).thenAnswer((_) async => mockEvent);

  return mockDbRef;
}

/// إنشاء MockDatabaseReference مهيأ لإرجاع "مستخدم غير موجود"
MockDatabaseReference createDatabaseMockWithNoUser() {
  final mockDbRef = MockDatabaseReference();
  final mockSnapshot = MockDataSnapshot();
  final mockQuery = MockQuery();

  when(() => mockSnapshot.exists).thenReturn(false);
  when(() => mockSnapshot.value).thenReturn(null);
  when(() => mockQuery.get()).thenAnswer((_) async => mockSnapshot);
  when(() => mockDbRef.orderByChild(any())).thenReturn(mockQuery);
  when(() => mockQuery.equalTo(any())).thenReturn(mockQuery);

  return mockDbRef;
}

// ===================== Custom FirebaseAuthException =====================

/// Exception مخصص لمحاكاة أخطاء Firebase Auth
class FirebaseAuthException implements Exception {
  final String code;
  final String message;

  FirebaseAuthException(this.code, this.message);

  @override
  String toString() => 'FirebaseAuthException: [$code] $message';
}

// ===================== Main Tests =====================

void main() {
  setUpMocks();

  group('Firebase Auth Mocks - اختبار المحاكاة', () {
    test('يجب أن يُنشئ Mock ناجح لتسجيل الدخول', () async {
      final mockAuth = createSuccessfulAuthMock();

      final result = await mockAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result.user, isNotNull);
      expect(result.user?.uid, 'test-user-id');
    });

    test('يجب أن يُنشئ Mock فاشل يرمي استثناء', () async {
      final mockAuth = createFailedAuthMock('wrong-password');

      expect(
        () => mockAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'wrong',
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });

  group('Database Mocks - اختبار محاكاة قاعدة البيانات', () {
    test('يجب أن يُرجع بيانات مستخدم موجود', () async {
      final mockDb = createDatabaseMockWithUser(
        phone: '775378412',
        email: 'test@example.com',
      );

      final query = mockDb.orderByChild('phone').equalTo('775378412');
      final snapshot = await query.get();

      expect(snapshot.exists, true);
      expect(snapshot.value, isA<Map>());
    });

    test('يجب أن يُرجع false لمستخدم غير موجود', () async {
      final mockDb = createDatabaseMockWithNoUser();

      final query = mockDb.orderByChild('phone').equalTo('999999999');
      final snapshot = await query.get();

      expect(snapshot.exists, false);
    });
  });
}
