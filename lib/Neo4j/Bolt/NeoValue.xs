#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ingyINLINE.h"

#include <neo4j-client.h>
#define C_PTR_OF(perl_obj,c_type) ((c_type *)SvIV(SvRV(perl_obj)))
#define NVCLASS "Neo4j::Bolt::NeoValue"
extern neo4j_value_t SV_to_neo4j_value(SV*);
extern SV *neo4j_value_to_SV(neo4j_value_t);
struct neovalue {
  neo4j_value_t value;
};
typedef struct neovalue neovalue_t;

SV *_new_from_perl (const char* classname, SV *v) {
   SV *neosv, *neosv_ref;
   neovalue_t *obj;
   Newx(obj, 1, neovalue_t);
   obj->value = SV_to_neo4j_value(v);
   neosv = newSViv((IV) obj);
   neosv_ref = newRV_noinc(neosv);
   sv_bless(neosv_ref, gv_stashpv(classname, GV_ADD));
   SvREADONLY_on(neosv);
   return neosv_ref;
}

const char* _neotype (SV *obj) {
  neo4j_value_t v;
  v = C_PTR_OF(obj,neovalue_t)->value;
  return neo4j_typestr( neo4j_type( v ) );
}

SV* _as_perl (SV *obj) {
  SV *ret;
  ret = newSV(0);
  sv_setsv(ret,neo4j_value_to_SV( C_PTR_OF(obj, neovalue_t)->value ));
  return ret;
}

int _map_size (SV *obj) {
  return neo4j_map_size( C_PTR_OF(obj, neovalue_t)->value );
}
void DESTROY(SV *obj) {
  neo4j_value_t *val = C_PTR_OF(obj, neo4j_value_t);
  return;
}


MODULE = Neo4j::Bolt::NeoValue  PACKAGE = Neo4j::Bolt::NeoValue  

PROTOTYPES: DISABLE


SV *
_new_from_perl (classname, v)
	const char *	classname
	SV *	v

const char *
_neotype (obj)
	SV *	obj

SV *
_as_perl (obj)
	SV *	obj

int
_map_size (obj)
	SV *	obj

void
DESTROY (obj)
	SV *	obj
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        DESTROY(obj);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

