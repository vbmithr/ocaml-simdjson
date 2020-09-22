#include <simdjson.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/bigarray.h>
#include <caml/custom.h>

using namespace simdjson;

void dom_parser_finalize (value x) {
    dom::parser *p = (dom::parser *) Data_custom_val(x);
    delete p;
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
  custom_finalize_default,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default,
  custom_compare_ext_default,
  custom_fixed_length_default
};

static struct custom_operations dom_object_ops = {
  "simdjson.dom.object",
  custom_finalize_default,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default,
  custom_compare_ext_default,
  custom_fixed_length_default
};

CAMLprim value createParser_stubs (value unit) {
    CAMLparam1 (unit);
    dom::parser *p = new dom::parser;
    value x = caml_alloc_custom(&dom_parser_ops, sizeof (dom::parser *), 0, 1);
    *((dom::parser **) Data_custom_val(x)) = p;
    CAMLreturn(x);
}

CAMLprim value loadBuf_stubs (value parser, value buf) {
    CAMLparam2 (parser, buf);
    dom::parser *p = (dom::parser *) Data_custom_val(parser);
    dom::element e = p->parse((const uint8_t*) Caml_ba_data_val(buf),
                              Caml_ba_array_val(buf)->dim[0],
                              false);
    value x = caml_alloc_custom(&dom_element_ops, sizeof (dom::element *), 0, 1);
    *((dom::element **) Data_custom_val(x)) = &e;
    CAMLreturn (x);
}

CAMLprim value getObject_stubs (value parser, value elt) {
    CAMLparam2(parser, elt);
    dom::parser *p = (dom::parser *) Data_custom_val(parser);
    dom::element *e = (dom::element *) Data_custom_val(elt);
    dom::object obj;
    auto error = e->get(obj);
    value x = caml_alloc_custom(&dom_object_ops, sizeof (dom::object *), 0, 1);
    *((dom::object **) Data_custom_val(x)) = &obj;
    CAMLreturn (x);
}
