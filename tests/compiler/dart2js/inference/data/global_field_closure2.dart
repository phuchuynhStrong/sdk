// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: method:[exact=JSUInt31]*/
// Called only via [foo] with a small integer.
method(/*[exact=JSUInt31]*/ a) {
  return a;
}

/*strong.element: foo:[null|subclass=Closure]*/
/*omit.element: foo:[null|subclass=Closure]*/
/*strongConst.element: foo:[subclass=Closure]*/
/*omitConst.element: foo:[subclass=Closure]*/
var foo = method;

/*element: returnInt:[null|subclass=Object]*/
returnInt() {
  return foo(54);
}

/*element: main:[null]*/
main() {
  returnInt();
}
