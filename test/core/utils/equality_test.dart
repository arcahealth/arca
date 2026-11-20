import 'package:flutter_test/flutter_test.dart';
import 'package:arca/core/utils/equality.dart';

void main() {
  group('ArcaEquality Tests', () {
    test('stringList checks list equality and hashes correctly', () {
      const listA = ['Amoxicillin', 'Lisinopril'];
      const listB = ['Amoxicillin', 'Lisinopril'];
      const listC = ['Amoxicillin'];

      expect(ArcaEquality.stringList.equals(listA, listB), isTrue);
      expect(ArcaEquality.stringList.hash(listA), equals(ArcaEquality.stringList.hash(listB)));

      expect(ArcaEquality.stringList.equals(listA, listC), isFalse);
      expect(ArcaEquality.stringList.equals(listA, null), isFalse);
      expect(ArcaEquality.stringList.equals(null, null), isTrue);
    });

    test('list checks generic object equality and hashes correctly', () {
      const listA = [1, 'two', 3.0];
      const listB = [1, 'two', 3.0];
      const listC = [1, 'two', 4.0];

      expect(ArcaEquality.list.equals(listA, listB), isTrue);
      expect(ArcaEquality.list.hash(listA), equals(ArcaEquality.list.hash(listB)));

      expect(ArcaEquality.list.equals(listA, listC), isFalse);
      expect(ArcaEquality.list.equals(listA, null), isFalse);
    });

    test('set checks set equality and hashes correctly', () {
      const setA = {'a', 'b', 'c'};
      const setB = {'c', 'b', 'a'};
      const setC = {'a', 'b'};

      expect(ArcaEquality.set.equals(setA, setB), isTrue);
      expect(ArcaEquality.set.hash(setA), equals(ArcaEquality.set.hash(setB)));

      expect(ArcaEquality.set.equals(setA, setC), isFalse);
      expect(ArcaEquality.set.equals(setA, null), isFalse);
    });

    test('map checks map equality and hashes correctly', () {
      const mapA = {'key1': 'val1', 'key2': 'val2'};
      const mapB = {'key2': 'val2', 'key1': 'val1'};
      const mapC = {'key1': 'val1'};

      expect(ArcaEquality.map.equals(mapA, mapB), isTrue);
      expect(ArcaEquality.map.hash(mapA), equals(ArcaEquality.map.hash(mapB)));

      expect(ArcaEquality.map.equals(mapA, mapC), isFalse);
      expect(ArcaEquality.map.equals(mapA, null), isFalse);
    });
  });
}
