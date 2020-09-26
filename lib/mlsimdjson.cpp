#include <simdjson.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/bigarray.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/threads.h>

#define PRIM extern "C" CAMLprim

using namespace simdjson;

#define Parser_val(v) (*((dom::parser **) Data_custom_val(v)))
#define Element_val(v) (*((dom::element **) Data_custom_val(v)))
#define Array_val(v) (*((dom::array **) Data_custom_val(v)))
#define Obj_val(v) (*((dom::object **) Data_custom_val(v)))
#define Array_iterator_val(v) (*((dom::array::iterator **) Data_custom_val(v)))
#define Obj_iterator_val(v) (*((dom::object::iterator **) Data_custom_val(v)))
#define Doc_stream_val(v) (*((dom::document_stream **) Data_custom_val(v)))
#define Doc_stream_iter_val(v) (*((dom::document_stream::iterator **) Data_custom_val(v)))

void dom_parser_finalize (value x) {
    auto *p = Parser_val(x);
    delete p;
}

void dom_element_finalize (value x) {
    auto *e = Element_val(x);
    delete e;
}

void dom_object_finalize (value x) {
    auto *o = Obj_val(x);
    delete o;
}

void dom_array_finalize (value x) {
    auto *a = Array_val(x);
    delete a;
}

void dom_object_iterator_finalize (value x) {
    auto *i = Obj_iterator_val(x);
    delete i;
}

void dom_array_iterator_finalize (value x) {
    auto *i = Array_iterator_val(x);
    delete i;
}

void dom_document_stream_finalize (value x) {
    auto *s = Doc_stream_val(x);
    delete s;
}

void dom_document_stream_iter_finalize (value x) {
    auto *i = Doc_stream_iter_val(x);
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

static struct custom_operations dom_document_stream_ops = {
  "simdjson.dom.document_stream",
  dom_document_stream_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default,
  custom_compare_ext_default,
  custom_fixed_length_default
};

static struct custom_operations dom_document_stream_iter_ops = {
  "simdjson.dom.document_stream.iterator",
  dom_document_stream_iter_finalize,
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
    auto *p = new dom::parser;
    x = caml_alloc_custom_mem(&dom_parser_ops,
                              sizeof (dom::parser *),
                              sizeof (dom::parser));
    Parser_val(x) = p;
    CAMLreturn(x);
}

PRIM value parse_stubs (value parser, value buf) {
    CAMLparam2 (parser, buf);
    CAMLlocal1(x);
    auto *e = new dom::element;
    auto *p = Parser_val(parser);
    auto error = p->parse((const uint8_t*) Caml_ba_data_val(buf),
                          Caml_ba_array_val(buf)->dim[0]-SIMDJSON_PADDING,
                          false).get(*e);
    if (error) {
        caml_invalid_argument(error_message(error));
    }
    x = caml_alloc_custom_mem(&dom_element_ops,
                              sizeof (dom::element *),
                              p->capacity());
    Element_val(x) = e;
    CAMLreturn (x);
}

PRIM value loadMany_stubs (value parser, value fn, value batchSize) {
    CAMLparam3(parser, fn, batchSize);
    CAMLlocal1(x);
    auto *p = Parser_val(parser);
    auto *d = new dom::document_stream;
    caml_release_runtime_system();
    auto error = p->load_many(String_val(fn), Long_val(batchSize)).get(*d);
    caml_acquire_runtime_system();
    if (error) {
        caml_invalid_argument(error_message(error));
    }
    x = caml_alloc_custom_mem(&dom_document_stream_ops,
                              sizeof (dom::document_stream *),
                              Long_val(batchSize));
    Doc_stream_val(x) = d;
    CAMLreturn (x);
}

PRIM value parseMany_stubs (value parser, value buf, value batchSize) {
    CAMLparam3(parser, buf, batchSize);
    CAMLlocal1(x);
    auto *p = Parser_val(parser);
    auto *d = new dom::document_stream;
    caml_release_runtime_system();
    auto error = p->parse_many((const uint8_t*) Caml_ba_data_val(buf),
                               Caml_ba_array_val(buf)->dim[0]-SIMDJSON_PADDING,
                               Long_val(batchSize)
                               ).get(*d);
    caml_acquire_runtime_system();
    if (error) {
        caml_invalid_argument(error_message(error));
    }
    x = caml_alloc_custom_mem(&dom_document_stream_ops,
                              sizeof (dom::document_stream *),
                              Long_val(batchSize));
    Doc_stream_val(x) = d;
    CAMLreturn (x);
}

extern "C" value arraySize_stubs (value arr) {
    auto *a = Array_val(arr);
    return Val_int(a->size());
}

extern "C" value objSize_stubs (value obj) {
    auto *o = Obj_val(obj);
    return Val_int(o->size());
}

PRIM value arrayIterator_stubs (value arr) {
    CAMLparam1(arr);
    CAMLlocal1(x);
    auto *a = Array_val(arr);
    auto *i = new dom::array::iterator(a->begin());
    x = caml_alloc_custom_mem(&dom_array_iterator_ops,
                              sizeof (dom::array::iterator *),
                              sizeof(dom::array::iterator));
    Array_iterator_val(x) = i;
    CAMLreturn (x);
}

PRIM value objIterator_stubs (value obj) {
    CAMLparam1(obj);
    CAMLlocal1(x);
    auto *o = Obj_val(obj);
    auto *i = new dom::object::iterator(o->begin());
    x = caml_alloc_custom_mem(&dom_object_iterator_ops,
                              sizeof (dom::object::iterator *),
                              sizeof (dom::object::iterator));
    Obj_iterator_val(x) = i;
    CAMLreturn (x);
}

PRIM value docStreamIteratorBegin_stubs (value ds) {
    CAMLparam1(ds);
    CAMLlocal1(x);
    auto *d = Doc_stream_val(ds);
    auto *i = new dom::document_stream::iterator(d->begin());
    x = caml_alloc_custom_mem(&dom_document_stream_iter_ops,
                              sizeof (dom::document_stream::iterator *),
                              sizeof (dom::document_stream::iterator));
    Doc_stream_iter_val(x) = i;
    CAMLreturn (x);
}

PRIM value docStreamIteratorEnd_stubs (value ds) {
    CAMLparam1(ds);
    CAMLlocal1(x);
    auto *d = Doc_stream_val(ds);
    auto *i = new dom::document_stream::iterator(d->end());
    x = caml_alloc_custom_mem(&dom_document_stream_iter_ops,
                              sizeof (dom::document_stream::iterator *),
                              sizeof (dom::document_stream::iterator));
    Doc_stream_iter_val(x) = i;
    CAMLreturn (x);
}

extern "C" value docStreamIteratorCompare_stubs (value x, value y) {
    auto *a = Doc_stream_iter_val(x), *b = Doc_stream_iter_val(y);
    return Val_bool(*a != *b);
}

PRIM value docStreamIteratorGet_stubs (value iter) {
    CAMLparam1(iter);
    CAMLlocal1(x);
    auto *i = Doc_stream_iter_val(iter);
    auto *e = new dom::element(*(*i));
    x = caml_alloc_custom_mem(&dom_element_ops,
                              sizeof (dom::element *),
                              sizeof (dom::element));
    Element_val(x) = e;
    CAMLreturn(x);
}

PRIM value arrayIteratorGet_stubs (value iter) {
    CAMLparam1(iter);
    CAMLlocal1(x);
    auto *i = Array_iterator_val(iter);
    auto *e = new dom::element(*(*i));
    x = caml_alloc_custom_mem(&dom_element_ops,
                              sizeof (dom::element *),
                              sizeof (dom::element));
    Element_val(x) = e;
    CAMLreturn(x);
}

PRIM value objIteratorGet_stubs (value iter) {
    CAMLparam1(iter);
    CAMLlocal3(block, k, v);
    auto *i = Obj_iterator_val(iter);
    k = caml_copy_string(i->key_c_str());
    auto *e = new dom::element(i->value());
    v = caml_alloc_custom_mem(&dom_element_ops,
                              sizeof (dom::element *),
                              sizeof (dom::element));
    Element_val(v) = e;
    block = caml_alloc_tuple(2);
    Store_field(block,0,k);
    Store_field(block,1,v);
    CAMLreturn(block);
}

extern "C" value arrayIteratorNext_stubs(value iter) {
    auto *i = Array_iterator_val(iter);
    ++(*i);
    return Val_unit;
}

extern "C" value objIteratorNext_stubs(value iter) {
    auto *i = Obj_iterator_val(iter);
    ++(*i);
    return Val_unit;
}

extern "C" value docStreamIteratorNext_stubs(value iter) {
    auto *i = Doc_stream_iter_val(iter);
    caml_release_runtime_system();
    ++(*i);
    caml_acquire_runtime_system();
    return Val_unit;
}

extern "C" value getInt_stubs(value elt) {
    auto *e = Element_val(elt);
    return Val_long(int64_t(*e));
}

extern "C" value getBool_stubs(value elt) {
    auto *e = Element_val(elt);
    return Val_bool(bool(*e));
}

PRIM value getInt64_stubs(value elt) {
    CAMLparam1(elt);
    CAMLlocal1(x);
    auto *e = Element_val(elt);
    x = caml_copy_int64(int64_t(*e));
    CAMLreturn(x);
}

PRIM value getDouble_stubs(value elt) {
    CAMLparam1(elt);
    CAMLlocal1(x);
    auto *e = Element_val(elt);
    x = caml_copy_double(double(*e));
    CAMLreturn(x);
}

PRIM value getString_stubs(value elt) {
    CAMLparam1(elt);
    CAMLlocal1(x);
    auto *e = Element_val(elt);
    x = caml_copy_string(e->get_c_str());
    CAMLreturn(x);
}

PRIM value getArray_stubs (value elt) {
    CAMLparam1(elt);
    CAMLlocal1(x);
    auto *e = Element_val(elt);
    auto *a = new dom::array;
    auto error = e->get(*a);
    if (error) {
        caml_invalid_argument(error_message(error));
    }
    x = caml_alloc_custom_mem(&dom_array_ops,
                              sizeof (dom::array *),
                              sizeof (dom::object));
    Array_val(x) = a;
    CAMLreturn (x);
}

PRIM value getObject_stubs (value elt) {
    CAMLparam1(elt);
    CAMLlocal1(x);
    auto *e = Element_val(elt);
    auto *obj = new dom::object;
    auto error = e->get(*obj);
    if (error) {
        caml_invalid_argument(error_message(error));
    }
    x = caml_alloc_custom_mem(&dom_object_ops,
                              sizeof (dom::object *),
                              sizeof (dom::object));
    Obj_val(x) = obj;
    CAMLreturn (x);
}

extern "C" value elementType_stubs (value elt) {
    auto *e = Element_val(elt);
    return Val_int(e->type());
}
