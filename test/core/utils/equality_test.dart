import 'package:flutter_test/flutter_test.dart';
import 'package:arca/core/utils/equality.dart';

void main() {
  group('CollectionEquality Tests', () {
    test('stringList checks list equality and hashes correctly', () {
      const listA = ['Amoxicillin', 'Lisinopril'];
      const listB = ['Amoxicillin', 'Lisinopril'];
      const listC = ['Amoxicillin'];

      expect(CollectionEquality.stringList.equals(listA, listB), isTrue);
      expect(CollectionEquality.stringList.hash(listA), equals(CollectionEquality.stringList.hash(listB)));

      expect(CollectionEquality.stringList.equals(listA, listC), isFalse);
      expect(CollectionEquality.stringList.equals(listA, null), isFalse);
      expect(CollectionEquality.stringList.equals(null, null), isTrue);
    });

    test('list checks generic object equality and hashes correctly', () {
      const listA = [1, 'two', 3.0];
      const listB = [1, 'two', 3.0];
      const listC = [1, 'two', 4.0];

      expect(CollectionEquality.list.equals(listA, listB), isTrue);
      expect(CollectionEquality.list.hash(listA), equals(CollectionEquality.list.hash(listB)));

      expect(CollectionEquality.list.equals(listA, listC), isFalse);
      expect(CollectionEquality.list.equals(listA, null), isFalse);
    });

    test('set checks set equality and hashes correctly', () {
      const setA = {'a', 'b', 'c'};
      const setB = {'c', 'b', 'a'};
      const setC = {'a', 'b'};

      expect(CollectionEquality.set.equals(setA, setB), isTrue);
      expect(CollectionEquality.set.hash(setA), equals(CollectionEquality.set.hash(setB)));

      expect(CollectionEquality.set.equals(setA, setC), isFalse);
      expect(CollectionEquality.set.equals(setA, null), isFalse);
    });

    test('map checks map equality and hashes correctly', () {
      const mapA = {'key1': 'val1', 'key2': 'val2'};
      const mapB = {'key2': 'val2', 'key1': 'val1'};
      const mapC = {'key1': 'val1'};

      expect(CollectionEquality.map.equals(mapA, mapB), isTrue);
      expect(CollectionEquality.map.hash(mapA), equals(CollectionEquality.map.hash(mapB)));

      expect(CollectionEquality.map.equals(mapA, mapC), isFalse);
      expect(CollectionEquality.map.equals(mapA, null), isFalse);
    });

    test('ArcaEquality alias is identical to CollectionEquality', () {
      expect(identical(ArcaEquality.stringList, CollectionEquality.stringList), isTrue);
      expect(identical(ArcaEquality.list, CollectionEquality.list), isTrue);
    });
  });
}
