// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';
import 'resolution.dart';
import 'task_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassDriverResolutionTest);
    defineReflectiveTests(ClassTaskResolutionTest);
  });
}

@reflectiveTest
class ClassDriverResolutionTest extends DriverResolutionTest
    with ClassResolutionMixin {}

abstract class ClassResolutionMixin implements ResolutionTest {
  test_abstractSuperMemberReference_getter() async {
    addTestFile(r'''
abstract class A {
  get foo;
}
abstract class B extends A {
  bar() {
    super.foo; // ref
  }
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE]);
    assertElement(findNode.simple('foo; // ref'), findElement.getter('foo'));
  }

  test_abstractSuperMemberReference_getter2() async {
    addTestFile(r'''
abstract class Foo {
  String get foo;
}

abstract class Bar implements Foo {
}

class Baz extends Bar {
  String get foo => super.foo; // ref
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE]);
    assertElement(
      findNode.simple('foo; // ref'),
      findElement.getter('foo', className: 'Foo'),
    );
  }

  test_abstractSuperMemberReference_method_invocation() async {
    addTestFile(r'''
abstract class A {
  foo();
}
abstract class B extends A {
  bar() {
    super.foo(); // ref
  }

  foo() {} // does not matter
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE]);
    assertElement(
      findNode.simple('foo(); // ref'),
      findElement.method('foo', of: 'A'),
    );
  }

  test_abstractSuperMemberReference_method_reference() async {
    addTestFile(r'''
abstract class A {
  foo();
}
abstract class B extends A {
  bar() {
    super.foo; // ref
  }
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE]);
    assertElement(findNode.simple('foo; // ref'), findElement.method('foo'));
  }

  test_abstractSuperMemberReference_noSuchMethod() async {
    setAnalysisOptions(enableSuperMixins: true);
    addTestFile('''
class A {
  void foo();
  noSuchMethod(im) {}
}

abstract class B {
  void foo();
  noSuchMethod(im) {}
}

class C extends A with B {
  void bar() {
    super.foo(); // ref
  }
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE]);
    assertElement(
      findNode.simple('foo(); // ref'),
      findElement.method('foo', of: 'B'),
    );
  }

  test_abstractSuperMemberReference_OK_mixinHasConcrete2_method() async {
    addTestFile('''
class A {
}

class M {
  void foo() {}
}

class B = A with M;

class C extends B {
  void bar() {
    super.foo(); // ref
  }
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    assertElement(
      findNode.simple('foo(); // ref'),
      findElement.method('foo', of: 'M'),
    );
  }

  test_abstractSuperMemberReference_OK_superHasConcrete_mixinHasAbstract_method() async {
    addTestFile('''
class A {
  void foo() {}
}

abstract class B {
  void foo();
}

class C extends A with B {
  void bar() {
    super.foo(); // ref
  }
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    assertElement(
      findNode.simple('foo(); // ref'),
      findElement.method('foo', of: 'A'),
    );
  }

  test_abstractSuperMemberReference_OK_superSuperHasConcrete_getter() async {
    addTestFile('''
abstract class A {
  int get foo => 0;
}

abstract class B extends A {
  int get foo;
}

class C extends B {
  int get bar => super.foo; // ref
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    assertElement(
      findNode.simple('foo; // ref'),
      findElement.getter('foo', className: 'A'),
    );
  }

  test_abstractSuperMemberReference_OK_superSuperHasConcrete_method() async {
    addTestFile('''
abstract class A {
  void foo() {}
}

abstract class B extends A {
  void foo();
}

class C extends B {
  void bar() {
    super.foo(); // ref
  }
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    assertElement(
      findNode.simple('foo(); // ref'),
      findElement.method('foo', of: 'A'),
    );
  }

  test_abstractSuperMemberReference_OK_superSuperHasConcrete_setter() async {
    addTestFile('''
abstract class A {
  void set foo(_) {}
}

abstract class B extends A {
  void set foo(_);
}

class C extends B {
  void bar() {
    super.foo = 0;
  }
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    assertElement(
      findNode.simple('foo = 0;'),
      findElement.setter('foo', className: 'A'),
    );
  }

  test_abstractSuperMemberReference_setter() async {
    addTestFile(r'''
abstract class A {
  set foo(_);
}
abstract class B extends A {
  bar() {
    super.foo = 0;
  }
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE]);
    assertElement(findNode.simple('foo = 0;'), findElement.setter('foo'));
  }

  test_conflictingGenericInterfaces_simple() async {
    addTestFile('''
class I<T> {}
class A implements I<int> {}
class B implements I<String> {}
class C extends A implements B {}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES]);
  }

  test_conflictingGenericInterfaces_viaMixin() async {
    addTestFile('''
class I<T> {}
class A implements I<int> {}
class B implements I<String> {}
class C extends A with B {}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES]);
  }

  test_element_allSupertypes() async {
    addTestFile(r'''
class A {}
class B {}
class C {}
class D {}
class E {}

class X1 extends A {}
class X2 implements B {}
class X3 extends A implements B {}
class X4 extends A with B implements C {}
class X5 extends A with B, C implements D, E {}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var a = findElement.class_('A');
    var b = findElement.class_('B');
    var c = findElement.class_('C');
    var d = findElement.class_('D');
    var e = findElement.class_('E');
    assertElementTypes(
      findElement.class_('X1').allSupertypes,
      [a.type, objectType],
    );
    assertElementTypes(
      findElement.class_('X2').allSupertypes,
      [objectType, b.type],
    );
    assertElementTypes(
      findElement.class_('X3').allSupertypes,
      [a.type, objectType, b.type],
    );
    assertElementTypes(
      findElement.class_('X4').allSupertypes,
      [a.type, b.type, objectType, c.type],
    );
    assertElementTypes(
      findElement.class_('X5').allSupertypes,
      [a.type, b.type, c.type, objectType, d.type, e.type],
    );
  }

  test_element_allSupertypes_generic() async {
    addTestFile(r'''
class A<T> {}
class B<T, U> {}
class C<T> extends B<int, T> {}

class X1 extends A<String> {}
class X2 extends B<String, List<int>> {}
class X3 extends C<double> {}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var a = findElement.class_('A');
    var b = findElement.class_('B');
    var c = findElement.class_('C');
    assertElementTypes(
      findElement.class_('X1').allSupertypes,
      [
        a.type.instantiate([stringType]),
        objectType
      ],
    );
    assertElementTypes(
      findElement.class_('X2').allSupertypes,
      [
        b.type.instantiate([
          stringType,
          typeProvider.listType.instantiate([intType])
        ]),
        objectType
      ],
    );
    assertElementTypes(
      findElement.class_('X3').allSupertypes,
      [
        c.type.instantiate([doubleType]),
        b.type.instantiate([intType, doubleType]),
        objectType
      ],
    );
  }

  test_element_allSupertypes_recursive() async {
    addTestFile(r'''
class A extends B {}
class B extends C {}
class C extends A {}

class X extends A {}
''');
    await resolveTestFile();
    assertHasTestErrors();

    var a = findElement.class_('A');
    var b = findElement.class_('B');
    var c = findElement.class_('C');
    assertElementTypes(
      findElement.class_('X').allSupertypes,
      [a.type, b.type, c.type],
    );
  }

  test_error_conflictingConstructorAndStaticField_field() async {
    addTestFile(r'''
class C {
  C.foo();
  static int foo;
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD,
    ]);
  }

  test_error_conflictingConstructorAndStaticField_getter() async {
    addTestFile(r'''
class C {
  C.foo();
  static int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD,
    ]);
  }

  test_error_conflictingConstructorAndStaticField_OK_notSameClass() async {
    addTestFile(r'''
class A {
  static int foo;
}
class B extends A {
  B.foo();
}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_conflictingConstructorAndStaticField_OK_notStatic() async {
    addTestFile(r'''
class C {
  C.foo();
  int foo;
}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_conflictingConstructorAndStaticField_setter() async {
    addTestFile(r'''
class C {
  C.foo();
  static void set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD,
    ]);
  }

  test_error_conflictingConstructorAndStaticMethod() async {
    addTestFile(r'''
class C {
  C.foo();
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_METHOD,
    ]);
  }

  test_error_conflictingConstructorAndStaticMethod_OK_notSameClass() async {
    addTestFile(r'''
class A {
  static void foo() {}
}
class B extends A {
  B.foo();
}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_conflictingConstructorAndStaticMethod_OK_notStatic() async {
    addTestFile(r'''
class C {
  C.foo();
  void foo() {}
}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_conflictingFieldAndMethod_inSuper_field() async {
    addTestFile(r'''
class A {
  foo() {}
}
class B extends A {
  int foo;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD]);
  }

  test_error_conflictingFieldAndMethod_inSuper_getter() async {
    addTestFile(r'''
class A {
  foo() {}
}
class B extends A {
  get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD]);
  }

  test_error_conflictingFieldAndMethod_inSuper_setter() async {
    addTestFile(r'''
class A {
  foo() {}
}
class B extends A {
  set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD]);
  }

  test_error_conflictingMethodAndField_inSuper_field() async {
    addTestFile(r'''
class A {
  int foo;
}
class B extends A {
  foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD]);
  }

  test_error_conflictingMethodAndField_inSuper_getter() async {
    addTestFile(r'''
class A {
  get foo => 0;
}
class B extends A {
  foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD]);
  }

  test_error_conflictingMethodAndField_inSuper_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
class B extends A {
  foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD]);
  }

  test_error_conflictingStaticAndInstance_inClass_getter_getter() async {
    addTestFile(r'''
class C {
  static int get foo => 0;
  int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inClass_getter_method() async {
    addTestFile(r'''
class C {
  static int get foo => 0;
  void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inClass_getter_setter() async {
    addTestFile(r'''
class C {
  static int get foo => 0;
  set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inClass_method_getter() async {
    addTestFile(r'''
class C {
  static void foo() {}
  int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inClass_method_method() async {
    addTestFile(r'''
class C {
  static void foo() {}
  void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inClass_method_setter() async {
    addTestFile(r'''
class C {
  static void foo() {}
  set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inClass_setter_getter() async {
    addTestFile(r'''
class C {
  static set foo(_) {}
  int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inClass_setter_method() async {
    addTestFile(r'''
class C {
  static set foo(_) {}
  void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inClass_setter_setter() async {
    addTestFile(r'''
class C {
  static set foo(_) {}
  set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inInterface_getter_getter() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}
abstract class B implements A {
  static int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inInterface_getter_method() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}
abstract class B implements A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inInterface_getter_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
abstract class B implements A {
  static int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inInterface_method_getter() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}
abstract class B implements A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inInterface_method_method() async {
    addTestFile(r'''
class A {
  void foo() {}
}
abstract class B implements A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inInterface_method_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
abstract class B implements A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inInterface_setter_method() async {
    addTestFile(r'''
class A {
  void foo() {}
}
abstract class B implements A {
  static set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inInterface_setter_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
abstract class B implements A {
  static set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inMixin_getter_getter() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}
class B extends Object with A {
  static int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inMixin_getter_method() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}
class B extends Object with A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inMixin_getter_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
class B extends Object with A {
  static int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inMixin_method_getter() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}
class B extends Object with A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inMixin_method_method() async {
    addTestFile(r'''
class A {
  void foo() {}
}
class B extends Object with A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inMixin_method_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
class B extends Object with A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inMixin_setter_method() async {
    addTestFile(r'''
class A {
  void foo() {}
}
class B extends Object with A {
  static set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inMixin_setter_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
class B extends Object with A {
  static set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inSuper_getter_getter() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}
class B extends A {
  static int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inSuper_getter_method() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}
class B extends A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inSuper_getter_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
class B extends A {
  static int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inSuper_method_getter() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}
class B extends A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inSuper_method_method() async {
    addTestFile(r'''
class A {
  void foo() {}
}
class B extends A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inSuper_method_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
class B extends A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inSuper_setter_method() async {
    addTestFile(r'''
class A {
  void foo() {}
}
class B extends A {
  static set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inSuper_setter_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
class B extends A {
  static set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_duplicateConstructorDefault() async {
    addTestFile(r'''
class C {
  C();
  C();
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT,
    ]);
  }

  test_error_duplicateConstructorName() async {
    addTestFile(r'''
class C {
  C.foo();
  C.foo();
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME,
    ]);
  }

  test_error_duplicateDefinition_field_field() async {
    addTestFile(r'''
class C {
  int foo;
  int foo;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_field_field_static() async {
    addTestFile(r'''
class C {
  static int foo;
  static int foo;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_field_getter() async {
    addTestFile(r'''
class C {
  int foo;
  int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_field_method() async {
    addTestFile(r'''
class C {
  int foo;
  void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_getter_getter() async {
    addTestFile(r'''
class C {
  int get foo => 0;
  int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_getter_method() async {
    addTestFile(r'''
class C {
  int get foo => 0;
  void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_method_getter() async {
    addTestFile(r'''
class C {
  void foo() {}
  int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_method_method() async {
    addTestFile(r'''
class C {
  void foo() {}
  void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_method_setter() async {
    addTestFile(r'''
class C {
  void foo() {}
  set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_OK_fieldFinal_setter() async {
    addTestFile(r'''
class C {
  final int foo = 0;
  set foo(int x) {}
}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_duplicateDefinition_OK_getter_setter() async {
    addTestFile(r'''
class C {
  int get foo => 0;
  set foo(_) {}
}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_duplicateDefinition_OK_setter_getter() async {
    addTestFile(r'''
class C {
  set foo(_) {}
  int get foo => 0;
}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_duplicateDefinition_setter_method() async {
    addTestFile(r'''
class C {
  set foo(_) {}
  void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_setter_setter() async {
    addTestFile(r'''
class C {
  void set foo(_) {}
  void set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_extendsNonClass_dynamic() async {
    addTestFile(r'''
class A extends dynamic {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.EXTENDS_NON_CLASS,
    ]);

    var a = findElement.class_('A');
    assertElementType(a.supertype, objectType);
  }

  test_error_extendsNonClass_enum() async {
    addTestFile(r'''
enum E { ONE }
class A extends E {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.EXTENDS_NON_CLASS,
    ]);

    var a = findElement.class_('A');
    assertElementType(a.supertype, objectType);

    var eRef = findNode.typeName('E {}');
    assertTypeName(eRef, findElement.enum_('E'), 'E');
  }

  test_error_extendsNonClass_mixin() async {
    addTestFile(r'''
mixin M {}
class A extends M {} // ref
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.EXTENDS_NON_CLASS,
    ]);

    var a = findElement.class_('A');
    assertElementType(a.supertype, objectType);

    var mRef = findNode.typeName('M {} // ref');
    assertTypeName(mRef, findElement.mixin('M'), 'M');
  }

  test_error_extendsNonClass_variable() async {
    addTestFile(r'''
int v;
class A extends v {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.EXTENDS_NON_CLASS,
    ]);

    var a = findElement.class_('A');
    assertElementType(a.supertype, objectType);
  }

  test_error_implementsRepeated() async {
    addTestFile(r'''
class A {}
class B implements A, A {} // ref
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.IMPLEMENTS_REPEATED]);

    var a = findElement.class_('A');
    assertTypeName(findNode.typeName('A, A {} // ref'), a, 'A');
    assertTypeName(findNode.typeName('A {} // ref'), a, 'A');
  }

  test_error_implementsRepeated_3times() async {
    addTestFile(r'''
class A {} class C{}
class B implements A, A, A, A {}''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.IMPLEMENTS_REPEATED,
      CompileTimeErrorCode.IMPLEMENTS_REPEATED,
      CompileTimeErrorCode.IMPLEMENTS_REPEATED
    ]);
  }

  test_error_memberWithClassName_getter() async {
    addTestFile(r'''
class C {
  int get C => null;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);
  }

  test_error_memberWithClassName_getter_static() async {
    addTestFile(r'''
class C {
  static int get C => null;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);

    var method = findNode.methodDeclaration('C =>');
    expect(method.isGetter, isTrue);
    expect(method.isStatic, isTrue);
    assertElement(method, findElement.getter('C'));
  }

  test_error_memberWithClassName_setter() async {
    addTestFile(r'''
class C {
  set C(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);
  }

  test_error_memberWithClassName_setter_static() async {
    addTestFile(r'''
class C {
  static set C(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);

    var method = findNode.methodDeclaration('C(_)');
    expect(method.isSetter, isTrue);
    expect(method.isStatic, isTrue);
  }

  test_inconsistentMethodInheritance_parameterType() async {
    addTestFile(r'''
abstract class A {
  x(int i);
}
abstract class B {
  x(String s);
}
abstract class C implements A, B {}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE,
    ]);
  }

  test_inconsistentMethodInheritance_requiredParameters() async {
    addTestFile(r'''
abstract class A {
  x();
}
abstract class B {
  x(int y);
}
abstract class C implements A, B {}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE,
    ]);
  }

  test_inconsistentMethodInheritance_returnType() async {
    addTestFile(r'''
abstract class A {
  int x();
}
abstract class B {
  String x();
}
abstract class C implements A, B {}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE,
    ]);
  }

  test_inconsistentMethodInheritanceGetterAndMethod_getter_method() async {
    addTestFile(r'''
abstract class A {
  int get x;
}
abstract class B {
  int x();
}
abstract class C implements A, B {}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticWarningCode.INCONSISTENT_METHOD_INHERITANCE_GETTER_AND_METHOD,
    ]);
  }

  test_inconsistentMethodInheritanceGetterAndMethod_method_getter() async {
    addTestFile(r'''
abstract class A {
  int x();
}
abstract class B {
  int get x;
}
abstract class C implements A, B {}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticWarningCode.INCONSISTENT_METHOD_INHERITANCE_GETTER_AND_METHOD,
    ]);
  }

  test_mixinInference_conflictingSubstitution() async {
    setAnalysisOptions(enableSuperMixins: true);
    addTestFile('''
abstract class A<T> {}
class M<T> extends A<Map<T, T>> {}
class C extends A<Map<int, String>> with M {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.MIXIN_INFERENCE_NO_POSSIBLE_SUBSTITUTION,
      CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES
    ]);
  }

  test_mixinInference_doNotIgnorePreviousExplicitMixins() async {
    setAnalysisOptions(enableSuperMixins: true);
    addTestFile('''
class A extends Object with B<String>, C {}
class B<T> {}
class C<T> extends B<T> {}
''');
    await resolveTestFile();
    assertNoTestErrors();
    var mixins = result.unit.declaredElement.getType('A').mixins;
    expect(mixins[1].toString(), 'C<String>');
  }

  test_mixinInference_impossibleSubstitution() async {
    setAnalysisOptions(enableSuperMixins: true);
    addTestFile('''
abstract class A<T> {}
class M<T> extends A<Map<T, T>> {}
class C extends A<List<int>> with M {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.MIXIN_INFERENCE_NO_POSSIBLE_SUBSTITUTION,
      CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES
    ]);
  }

  test_mixinInference_noMatchingClass_constraintSatisfiedByImplementsClause() async {
    setAnalysisOptions(enableSuperMixins: true);
    addTestFile('''
abstract class A<T> {}
class B {}
class M<T> extends A<T> {}
class C extends Object with M implements A<B> {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.MIXIN_INFERENCE_NO_MATCHING_CLASS,
      CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES,
    ]);
  }

  test_recursiveInterfaceInheritance_extends() async {
    addTestFile(r'''
class A extends B {}
class B extends A {}''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
  }

  test_recursiveInterfaceInheritance_extends_implements() async {
    addTestFile(r'''
class A extends B {}
class B implements A {}''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
  }

  test_recursiveInterfaceInheritance_implements() async {
    addTestFile(r'''
class A implements B {}
class B implements A {}''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
  }

  test_recursiveInterfaceInheritance_mixin() async {
    addTestFile(r'''
class M1 = Object with M2;
class M2 = Object with M1;''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
  }

  test_recursiveInterfaceInheritance_mixin_superclass() async {
    // Make sure we don't get CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS in
    // addition--that would just be confusing.
    addTestFile('''
class C = D with M;
class D = C with M;
class M {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
  }

  test_recursiveInterfaceInheritance_tail() async {
    addTestFile(r'''
abstract class A implements A {}
class B implements A {}''');
    await resolveTestFile();
    assertTestErrors(
        [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS]);
  }

  test_recursiveInterfaceInheritance_tail2() async {
    addTestFile(r'''
abstract class A implements B {}
abstract class B implements A {}
class C implements A {}''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
  }

  test_recursiveInterfaceInheritance_tail3() async {
    addTestFile(r'''
abstract class A implements B {}
abstract class B implements C {}
abstract class C implements A {}
class D implements A {}''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
  }

  test_recursiveInterfaceInheritanceExtends() async {
    addTestFile("class A extends A {}");
    await resolveTestFile();
    assertTestErrors(
        [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_EXTENDS]);
  }

  test_recursiveInterfaceInheritanceExtends_abstract() async {
    addTestFile(r'''
class C extends C {
  var bar = 0;
  m();
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_EXTENDS,
      StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER,
      StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE
    ]);
  }

  test_recursiveInterfaceInheritanceImplements() async {
    addTestFile("class A implements A {}");
    await resolveTestFile();
    assertTestErrors(
        [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS]);
  }

  test_recursiveInterfaceInheritanceImplements_typeAlias() async {
    addTestFile(r'''
class A {}
class M {}
class B = A with M implements B;''');
    await resolveTestFile();
    assertTestErrors(
        [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS]);
  }

  test_recursiveInterfaceInheritanceWith() async {
    addTestFile("class M = Object with M;");
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_WITH,
    ]);
  }

  test_undefinedSuperGetter() async {
    addTestFile(r'''
class A {}
class B extends A {
  get g {
    return super.g;
  }
}''');
    await resolveTestFile();
    assertTestErrors([StaticTypeWarningCode.UNDEFINED_SUPER_GETTER]);
  }

  test_undefinedSuperMethod() async {
    addTestFile(r'''
class A {}
class B extends A {
  m() {
    return super.m();
  }
}''');
    await resolveTestFile();
    assertTestErrors([StaticTypeWarningCode.UNDEFINED_SUPER_METHOD]);
  }

  test_undefinedSuperOperator_binaryExpression() async {
    addTestFile(r'''
class A {}
class B extends A {
  operator +(value) {
    return super + value;
  }
}''');
    await resolveTestFile();
    assertTestErrors([StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR]);
  }

  test_undefinedSuperOperator_indexBoth() async {
    addTestFile(r'''
class A {}
class B extends A {
  operator [](index) {
    return super[index]++;
  }
}''');
    await resolveTestFile();
    assertTestErrors([StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR]);
  }

  test_undefinedSuperOperator_indexGetter() async {
    addTestFile(r'''
class A {}
class B extends A {
  operator [](index) {
    return super[index + 1];
  }
}''');
    await resolveTestFile();
    assertTestErrors([StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR]);
  }

  test_undefinedSuperOperator_indexSetter() async {
    addTestFile(r'''
class A {}
class B extends A {
  operator []=(index, value) {
    super[index] = 0;
  }
}''');
    await resolveTestFile();
    assertTestErrors([StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR]);
  }

  test_undefinedSuperSetter() async {
    addTestFile(r'''
class A {}
class B extends A {
  f() {
    super.m = 0;
  }
}''');
    await resolveTestFile();
    assertTestErrors([StaticTypeWarningCode.UNDEFINED_SUPER_SETTER]);
  }
}

@reflectiveTest
class ClassTaskResolutionTest extends TaskResolutionTest
    with ClassResolutionMixin {
  @failingTest
  test_conflictingGenericInterfaces_simple() {
    return super.test_conflictingGenericInterfaces_simple();
  }

  @failingTest
  test_conflictingGenericInterfaces_viaMixin() {
    return super.test_conflictingGenericInterfaces_viaMixin();
  }

  @failingTest
  test_mixinInference_conflictingSubstitution() {
    return super.test_mixinInference_conflictingSubstitution();
  }

  @failingTest
  test_mixinInference_doNotIgnorePreviousExplicitMixins() {
    return super.test_mixinInference_doNotIgnorePreviousExplicitMixins();
  }

  @failingTest
  test_mixinInference_impossibleSubstitution() {
    return super.test_mixinInference_impossibleSubstitution();
  }

  @failingTest
  test_mixinInference_noMatchingClass_constraintSatisfiedByImplementsClause() {
    return super
        .test_mixinInference_noMatchingClass_constraintSatisfiedByImplementsClause();
  }
}
