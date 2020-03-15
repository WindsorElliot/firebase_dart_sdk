// File created by
// Lung Razvan <long1eu>
// on 17/09/2018

import 'package:cloud_firestore_vm/src/firebase/firestore/blob.dart';
import 'package:cloud_firestore_vm/src/firebase/firestore/model/value/field_value.dart';

/// A wrapper for blob values in Firestore.
class BlobValue extends FieldValue {
  const BlobValue(this._value);

  factory BlobValue.valueOf(Blob blob) => BlobValue(blob);

  final Blob _value;

  @override
  int get typeOrder => FieldValue.typeOrderBlob;

  @override
  Blob get value => _value;

  @override
  int compareTo(FieldValue other) {
    if (other is BlobValue) {
      return _value.compareTo(other._value);
    } else {
      return defaultCompareTo(other);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlobValue &&
          runtimeType == other.runtimeType &&
          _value == other._value;

  @override
  int get hashCode => _value.hashCode;
}