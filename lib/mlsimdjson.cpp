#include <simdjson.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/bigarray.h>
#include <caml/custom.h>
#include <caml/fail.h>

#define PRIM extern "C" CAMLprim

using namespace std;
using namespace simdjson;

#define Parser_val(v) (*((dom::parser **) Data_custom_val(v)))
#define Element_val(v) (*((dom::element **) Data_custom_val(v)))
#define Array_val(v) (*((dom::array **) Data_custom_val(v)))
#define Obj_val(v) (*((dom::object **) Data_custom_val(v)))
#define Array_iterator_val(v) (*((dom::array::iterator **) Data_custom_val(v)))
#define Obj_iterator_val(v) (*((dom::object::iterator **) Data_custom_val(v)))

void dom_parser_finalize (value x) {
    dom::parser *p = Parser_val(x);
    delete p;
}

void dom_element_finalize (value x) {
    dom::element *e = Element_val(x);
    delete e;
}

void dom_object_finalize (value x) {
    dom::object *o = Obj_val(x);
    delete o;
}

void dom_array_finalize (value x) {
    dom::array *a = Array_val(x);
    delete a;
}

void dom_object_iterator_finalize (value x) {
    dom::object::iterator *i = Obj_iterator_val(x);
    delete i;
}

void dom_array_iterator_finalize (value x) {
    dom::array::iterator *i = Array_iterator_val(x);
    delete i;
}

static struct custom_operations dom_parser_ops = {
  "simdjson.dom.parser",
  dom_parser_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default,
  custom_compare_ext_default,
  custom_fixed_length_default
};

static struct custom_operations dom_element_ops = {
  "simdjson.dom.element",
  dom_element_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default,
  custom_compare_ext_default,
  custom_fixed_length_default
};

static struct custom_operations dom_object_ops = {
  "simdjson.dom.object",
  dom_object_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default,
  custom_compare_ext_default,
  custom_fixed_length_default
};

static struct custom_operations dom_object_iterator_ops = {
  "simdjson.dom.object.iterator",
  dom_object_iterator_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default,
  custom_compare_ext_default,
  custom_fixed_length_default
};

static struct custom_operations dom_array_ops = {
  "simdjson.dom.array",
  dom_array_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default,
  custom_compare_ext_default,
  custom_fixed_length_default
};

static struct custom_operations dom_array_iterator_ops = {
  "simdjson.dom.array.iterator",
  dom_array_iterator_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default,
  custom_compare_ext_default,
  custom_fixed_length_default
};

PRIM value createParser_stubs (value unit) {
    CAMLparam1 (unit);
    CAMLlocal1(x);
    dom::parser *p = new dom::parser;
    x = caml_alloc_custom(&dom_parser_ops, sizeof (dom::parser *), 0, 1);
    Parser_val(x) = p;
    CAMLreturn(x);
}

PRIM value loadBuf_stubs (value parser, value buf) {
    CAMLparam2 (parser, buf);
    CAMLlocal1(x);
    dom::element *e = new dom::element;
    dom::parser *p = Parser_val(parser);
    auto error = p->parse((const uint8_t*) Caml_ba_data_val(buf),
                          Caml_ba_array_val(buf)->dim[0]-SIMDJSON_PADDING,
                          false).get(*e);
    if (error) {
        caml_invalid_argument(error_message(error));
    }
    x = caml_alloc_custom(&dom_element_ops, sizeof (dom::element *), 0, 1);
    Element_val(x) = e;
    CAMLreturn (x);
}

extern "C" value arraySize_stubs (value arr) {
    dom::array *a = Array_val(arr);
    return Val_int(a->size());
}

extern "C" value objSize_stubs (value obj) {
    dom::object *o = Obj_val(obj);
    return Val_int(o->size());
}

PRIM value createArrayIterator_stubs(value unit) {
    CAMLparam1(unit);
    CAMLlocal1(x);
    dom::array::iterator *i = new dom::array::iterator();
    x = caml_alloc_custom(&dom_array_iterator_ops, sizeof (dom::array::iterator *), 0, 1);
    Array_iterator_val(x) = i;
    CAMLreturn (x);
}

PRIM value createObjectIterator_stubs(value unit) {
    CAMLparam1(unit);
    CAMLlocal1(x);
    dom::object::iterator *i = new dom::object::iterator();
    x = caml_alloc_custom(&dom_array_iterator_ops, sizeof (dom::object::iterator *), 0, 1);
    Obj_iterator_val(x) = i;
    CAMLreturn (x);
}

PRIM value arrayIterator_stubs (value iter, value arr) {
    dom::array *a = Array_val(arr);
    dom::array::iterator *i = Array_iterator_val(iter);
    *i = a->begin();
    return Val_unit;
}
PRIM value objIterator_stubs (value iter, value obj) {
    dom::object *o = Obj_val(obj);
    dom::object::iterator *i = Obj_iterator_val(iter);
    *i = o->begin();
    return Val_unit;
}

PRIM value arrayIteratorGet_stubs (value iter) {
    CAMLparam1(iter);
    CAMLlocal1(x);
    dom::array::iterator *i = Array_iterator_val(iter);
    dom::element *e = new dom::element(*(*i));
    x = caml_alloc_custom(&dom_element_ops, sizeof (dom::element *), 0, 1);
    Element_val(x) = e;
    CAMLreturn(x);
}

PRIM value objIteratorGet_stubs (value iter) {
    CAMLparam1(iter);
    CAMLlocal3(block, k, v);
    dom::object::iterator *i = Obj_iterator_val(iter);
    k = caml_copy_string(i->key_c_str());
    dom::element *e = new dom::element(i->value());
    v = caml_alloc_custom(&dom_element_ops, sizeof (dom::element *), 0, 1);
    Element_val(v) = e;
    block = caml_alloc_tuple(2);
    Store_field(block,0,k);
    Store_field(block,1,v);
    CAMLreturn(block);
}

extern "C" value arrayIteratorNext_stubs(value iter) {
    dom::array::iterator *i = Array_iterator_val(iter);
    (*i)++;
    return Val_unit;
}

extern "C" value objIteratorNext_stubs(value iter) {
    dom::object::iterator *i = Obj_iterator_val(iter);
    (*i)++;
    return Val_unit;
}

extern "C" value getInt_stubs(value elt) {
    dom::element *e = Element_val(elt);
    return Val_long(int64_t(*e));
}

extern "C" value getBool_stubs(value elt) {
    dom::element *e = Element_val(elt);
    return Val_bool(bool(*e));
}

PRIM value getInt64_stubs(value elt) {
    CAMLparam1(elt);
    CAMLlocal1(x);
    dom::element *e = Element_val(elt);
    x = caml_copy_int64(int64_t(*e));
    CAMLreturn(x);
}

PRIM value getDouble_stubs(value elt) {
    CAMLparam1(elt);
    CAMLlocal1(x);
    dom::element *e = Element_val(elt);
    x = caml_copy_double(double(*e));
    CAMLreturn(x);
}

PRIM value getString_stubs(value elt) {
    CAMLparam1(elt);
    CAMLlocal1(x);
    dom::element *e = Element_val(elt);
    x = caml_copy_string(e->get_c_str());
    CAMLreturn(x);
}

PRIM value createArray_stubs (value unit) {
    CAMLparam1(unit);
    CAMLlocal1(x);
    dom::array *a = new dom::array;
    x = caml_alloc_custom(&dom_array_ops, sizeof (dom::array *), 0, 1);
    Array_val(x) = a;
    CAMLreturn(x);
}

PRIM value createObject_stubs (value unit) {
    CAMLparam1(unit);
    CAMLlocal1(x);
    dom::object *o = new dom::object;
    x = caml_alloc_custom(&dom_object_ops, sizeof (dom::object *), 0, 1);
    Obj_val(x) = o;
    CAMLreturn(x);
}

PRIM value getArray_stubs (value arr, value elt) {
    CAMLparam2(arr, elt);
    dom::element *e = Element_val(elt);
    dom::array *a = Array_val(arr);
    auto error = e->get(*a);
    if (error) {
        caml_invalid_argument(error_message(error));
    }
    return Val_unit;
}

PRIM value getObject_stubs (value obj, value elt) {
    CAMLparam2(obj, elt);
    dom::element *e = Element_val(elt);
    dom::object *o = Obj_val (obj);
    auto error = e->get(*o);
    if (error) {
        caml_invalid_argument(error_message(error));
    }
    return Val_unit;
}

extern "C" value elementType_stubs (value elt) {
    dom::element *e = Element_val(elt);
    return Val_int(e->type());
}
