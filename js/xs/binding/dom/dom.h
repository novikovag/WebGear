/*==============================================================================
        Вспомогательные подпрограммы        
==============================================================================*/

#ifndef _webgear_js_dom_h
#define _webgear_js_dom_h

static void
webgear_js_reporter(JSContext *jscontext, const char *message, JSErrorReport *jserrorreport)
{    
    /* "js_reporter", $error, $message, $index */
    dSP;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv("js_reporter", 0)));
    XPUSHs(sv_2mortal(newSVpv(message, 0)));
    XPUSHs(sv_2mortal(newSVpv(jserrorreport->linebuf, 0)));
    XPUSHs(sv_2mortal(newSViv(jserrorreport->tokenptr - jserrorreport->linebuf + 1)));
    PUTBACK;

    call_pv("js_callback", G_DISCARD);
}

/*----- Исключения DOM ---------------------------------------------------------
 https://heycam.github.io/webidl/#dfn-DOMException
------------------------------------------------------------------------------*/

#define EXCEPTION_INDEX_SIZE_ERR               1
#define EXCEPTION_HIERARCHY_REQUEST_ERR        3
#define EXCEPTION_WRONG_DOCUMENT_ERR           4
#define EXCEPTION_INVALID_CHARACTER_ERR        5
#define EXCEPTION_NO_MODIFICATION_ALLOWED_ERR  7
#define EXCEPTION_NOT_FOUND_ERR                8
#define EXCEPTION_NOT_SUPPORTED_ERR            9
#define EXCEPTION_INUSE_ATTRIBUTE_ERR         10
#define EXCEPTION_INVALID_STATE_ERR           11
#define EXCEPTION_SYNTAX_ERR                  12
#define EXCEPTION_INVALID_MODIFICATION_ERR    13
#define EXCEPTION_NAMESPACE_ERR               14
#define EXCEPTION_INVALID_ACCESS_ERR          15
#define EXCEPTION_SECURITY_ERR                18
#define EXCEPTION_NETWORK_ERR                 19
#define EXCEPTION_ABORT_ERR                   20
#define EXCEPTION_URL_MISMATCH_ERR            21
#define EXCEPTION_QUOTA_EXCEEDED_ERR          22
#define EXCEPTION_TIMEOUT_ERR                 23
#define EXCEPTION_INVALID_NODE_TYPE_ERR       24
#define EXCEPTION_DATA_CLONE_ERR              25
/* Коды 30-32 не относятся к исключениям DOM. */
#define EXCEPTION_TOO_FEW_ARGUMENTS_ERR       30
#define EXCEPTION_ILLEGAL_ARGUMENT_ERR        31
#define EXCEPTION_NOT_IMPLEMENTED_ERR         32

inline __attribute__((always_inline)) void
webgear_js_exeption(JSContext *jscontext, int code)
{
    JSObject *jsexeption;

    jsexeption = JS_NewObject(jscontext, &webgear_js_dom_exeption, NULL, NULL);
    JS_SetPrivate(jscontext, jsexeption, INT_TO_JSVAL(code));

    JS_SetPendingException(jscontext, jsexeption);
}

/*----- Память Perl ------------------------------------------------------------
------------------------------------------------------------------------------*/

inline __attribute__((always_inline)) void *
webgear_xs_malloc(int size)
{
    void *block;

    Newx(block, size, char);
    return block;
}

inline __attribute__((always_inline)) void *
webgear_xs_zalloc(int size)
{
    void *block;

    Newxz(block, size, char);
    return block;
}

inline __attribute__((always_inline)) void
webgear_xs_free(void *block)
{
    Safefree(block);
}

inline __attribute__((always_inline)) void *
webgear_xs_realloc(void *block, int size)
{
    Renew(block, size, char);
    return block;
}

inline __attribute__((always_inline)) void *
webgear_xs_memcpy(void *destination, void *source, int count)
{
    Copy(source, destination, count, char);
    return destination;
}

/*----- Хэши и массивы Perl ----------------------------------------------------
 Префиксы:
  _av - массив
  _hv - хэш
 Постфиксы: 
  _iv - целое значение
  _pv - указатель на строку
  _rv - ссылка на скаляр (HV*, AV*)
------------------------------------------------------------------------------*/

inline __attribute__((always_inline)) SV *
webgear_xs_av_fetch_rv(AV *array, int index)
{
    SV **value;

    value = av_fetch(array, index, 0);
    return value ? SvRV(*value) : NULL;
}

inline __attribute__((always_inline)) void
webgear_xs_av_push_rv(AV *array, SV *value)
{
    av_push(array, value ? newRV(value) : &PL_sv_undef);
}

inline __attribute__((always_inline)) int
webgear_xs_hv_get_iv(HV *hash, char *key, int keylength)
{
    SV **value;

    value = hv_fetch(hash, key, keylength, 0);
    return value ? SvIV(*value) : 0;
}

inline __attribute__((always_inline)) char *
webgear_xs_hv_get_pv(HV *hash, char *key, int keylength)
{
    SV **value;

    value = hv_fetch(hash, key, keylength, 0);
    return value ? SvPV_nolen(*value) : NULL;
}

inline __attribute__((always_inline)) SV *
webgear_xs_hv_get_rv(HV *hash, char *key, int keylength)
{
    SV **value;

    value = hv_fetch(hash, key, keylength, 0);
    return value ? SvRV(*value) : NULL;
}

inline __attribute__((always_inline)) void
webgear_xs_hv_set_iv(HV *hash, char *key, int keylength, int value)
{
    hv_store(hash, key, keylength, newSViv(value), 0);
}

inline __attribute__((always_inline)) void
webgear_xs_hv_set_pv(HV *hash, char *key, int keylength, char *data, int datalength)
{
    hv_store(hash, key, keylength, newSVpvn(data, datalength),  0);
}

inline __attribute__((always_inline)) void
webgear_xs_hv_set_rv(HV *hash, char *key, int keylength, SV *value)
{
    hv_store(hash, key, keylength, value ? newRV(value) : &PL_sv_undef, 0);
}

/*----- Текст ------------------------------------------------------------------
------------------------------------------------------------------------------*/

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Возвращает пару литерал-длина.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
#define LITERAL(string) (string), (sizeof(string) - 1)

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Находит смешение первого байт utf8-символа по его позиции в строке.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
inline __attribute__((always_inline)) int
webgear_utf8_offset_to_index(char *data, int datalength, int offset)
{
    int index;

    if (!offset) {
        return 0;
    }

    if (offset > 0) {
        index = 0;

        while (index < datalength) {

            if (data[index] & 0x80) {

                switch (data[index] & 0xf0) {
                    
                    case 0xe0: /* 11100000 */
                        index += 3;
                        break;
                    case 0xf0: /* 11110000 */
                        index += 4;
                        break;
                    default:   /* 11000000 */
                        index += 2;
                        break;
                }

            } else {
                index++;
            }

            if (!--offset) {
                return index;
            }
        }
    }
    
    return -1;
}

/*----- Узлы DOM ---------------------------------------------------------------
 https://dom.spec.whatwg.org/#node
------------------------------------------------------------------------------*/

#define NODE_TYPE_ELEMENT        1
#define NODE_TYPE_ATTRIBUTE      2
#define NODE_TYPE_TEXT           3
#define NODE_TYPE_COMMENT        8
#define NODE_TYPE_DOCUMENT       9
#define NODE_TYPE_DOCUMENT_TYPE 10
#define NODE_TYPE_EVENT         15

inline __attribute__((always_inline)) HV *
webgear_node_create_document(JSObject *jsobject)
{
    HV *document;

    document = newHV();

    webgear_xs_hv_set_iv(document, LITERAL("type"),            NODE_TYPE_DOCUMENT);
    webgear_xs_hv_set_iv(document, LITERAL("flags"),           0);
                                                       
    webgear_xs_hv_set_rv(document, LITERAL("parent"),          NULL);
    webgear_xs_hv_set_rv(document, LITERAL("previoussibling"), NULL);
    webgear_xs_hv_set_rv(document, LITERAL("nextsibling"),     NULL);
    webgear_xs_hv_set_rv(document, LITERAL("firstchild"),      NULL);
    webgear_xs_hv_set_rv(document, LITERAL("lastchild"),       NULL);
                                                       
    webgear_xs_hv_set_rv(document, LITERAL("soeprevious"),     NULL);
    webgear_xs_hv_set_rv(document, LITERAL("soenext"),         NULL);
                                                       
    webgear_xs_hv_set_iv(document, LITERAL("object"),          jsobject);
    
    webgear_xs_hv_set_rv(document, LITERAL("documenttype"),    NULL);
    webgear_xs_hv_set_rv(document, LITERAL("htmlelement"),     NULL); 
    webgear_xs_hv_set_rv(document, LITERAL("headelement"),     NULL); 
    webgear_xs_hv_set_rv(document, LITERAL("bodyelement"),     NULL); 
    return document;
}

inline __attribute__((always_inline)) HV *
webgear_node_create_element(JSObject *jsobject, int flags, int id, char *name, int namelength)
{
    HV *xselement;

    xselement = newHV();

    webgear_xs_hv_set_iv(xselement, LITERAL("type"),                NODE_TYPE_ELEMENT);
    webgear_xs_hv_set_iv(xselement, LITERAL("flags"),               flags);

    webgear_xs_hv_set_rv(xselement, LITERAL("parent"),              NULL);
    webgear_xs_hv_set_rv(xselement, LITERAL("previoussibling"),     NULL);
    webgear_xs_hv_set_rv(xselement, LITERAL("nextsibling"),         NULL);
    webgear_xs_hv_set_rv(xselement, LITERAL("firstchild"),          NULL);
    webgear_xs_hv_set_rv(xselement, LITERAL("lastchild"),           NULL);

    webgear_xs_hv_set_iv(xselement, LITERAL("id"),                  id);
    webgear_xs_hv_set_pv(xselement, LITERAL("name"),                name, namelength);
    webgear_xs_hv_set_iv(xselement, LITERAL("namelength"),          namelength);

    webgear_xs_hv_set_rv(xselement, LITERAL("attributes"),          newHV());

    webgear_xs_hv_set_rv(xselement, LITERAL("soeprevious"),         NULL);
    webgear_xs_hv_set_rv(xselement, LITERAL("soenext"),             NULL);
    webgear_xs_hv_set_rv(xselement, LITERAL("afeprevious"),         NULL);
    webgear_xs_hv_set_rv(xselement, LITERAL("afenext"),             NULL);
    webgear_xs_hv_set_rv(xselement, LITERAL("afemarkers"),          0);

    webgear_xs_hv_set_iv(xselement, LITERAL("object"),              jsobject);

    webgear_xs_hv_set_iv(xselement, LITERAL("livenodelist"),        NULL);
    webgear_xs_hv_set_iv(xselement, LITERAL("livehtmlcollections"), NULL);

    webgear_xs_hv_set_rv(xselement, LITERAL("events"),              newHV());
    return xselement;
}

inline __attribute__((always_inline)) HV *
webgear_node_create_attribute(JSObject *jsobject, int id, char *name, int namelength, char *value, int valuelength)
{
    HV *xsattribute;

    xsattribute = newHV();

    webgear_xs_hv_set_iv(xsattribute, LITERAL("type"),            NODE_TYPE_ATTRIBUTE);

    webgear_xs_hv_set_rv(xsattribute, LITERAL("element"),         NULL);

    webgear_xs_hv_set_iv(xsattribute, LITERAL("id"),              id);
    webgear_xs_hv_set_pv(xsattribute, LITERAL("name"),            name, namelength);
    webgear_xs_hv_set_iv(xsattribute, LITERAL("namelength"),      namelength);

    webgear_xs_hv_set_pv(xsattribute, LITERAL("value"),           value, valuelength);
    webgear_xs_hv_set_iv(xsattribute, LITERAL("valuelength"),     valuelength);

    webgear_xs_hv_set_iv(xsattribute, LITERAL("object"),          jsobject);
    return xsattribute;
}

inline __attribute__((always_inline)) HV *
webgear_node_create_event(JSObject *jscallback, int flags, int id, char *type, int typelength, char *function, int functionlength)
{
    HV *xsevent;

    xsevent = newHV();

    webgear_xs_hv_set_iv(xsevent, LITERAL("type"),            NODE_TYPE_EVENT);
    webgear_xs_hv_set_iv(xsevent, LITERAL("flags"),           flags);

    webgear_xs_hv_set_rv(xsevent, LITERAL("element"),         NULL);

    webgear_xs_hv_set_pv(xsevent, LITERAL("type"),            type, typelength);
    webgear_xs_hv_set_iv(xsevent, LITERAL("typelength"),      typelength);

    webgear_xs_hv_set_pv(xsevent, LITERAL("function"),        function, functionlength);
    webgear_xs_hv_set_iv(xsevent, LITERAL("functionlength"),  functionlength);

    webgear_xs_hv_set_iv(xsevent, LITERAL("callback"),        jscallback);

    webgear_xs_hv_set_rv(xsevent, LITERAL("previousnode"),    NULL);
    webgear_xs_hv_set_rv(xsevent, LITERAL("nextnode"),        NULL);
    webgear_xs_hv_set_rv(xsevent, LITERAL("lastnode"),        NULL);

    webgear_xs_hv_set_iv(xsevent, LITERAL("nextphasenode"),   0);
    return xsevent;
}

inline __attribute__((always_inline)) HV *
webgear_node_create_textnode(JSObject *jsobject, int flags, char *data, int datalength)
{
    HV *xstext;

    xstext = newHV();

    webgear_xs_hv_set_iv(xstext, LITERAL("type"),            NODE_TYPE_TEXT);
    webgear_xs_hv_set_iv(xstext, LITERAL("flags"),           flags);

    webgear_xs_hv_set_rv(xstext, LITERAL("parent"),          NULL);
    webgear_xs_hv_set_rv(xstext, LITERAL("previoussibling"), NULL);
    webgear_xs_hv_set_rv(xstext, LITERAL("nextsibling"),     NULL);

    webgear_xs_hv_set_pv(xstext, LITERAL("data"),            data, datalength);
    webgear_xs_hv_set_iv(xstext, LITERAL("datalength"),      datalength);

    webgear_xs_hv_set_iv(xstext, LITERAL("object"),          jsobject);
    return xstext;
}

inline __attribute__((always_inline)) HV *
webgear_node_create_comment(JSObject *jsobject, int flags, char *data, int datalength)
{
    HV *xscomment;

    xscomment = newHV();

    webgear_xs_hv_set_iv(xscomment, LITERAL("type"),            NODE_TYPE_COMMENT);
    webgear_xs_hv_set_iv(xscomment, LITERAL("flags"),           flags);

    webgear_xs_hv_set_rv(xscomment, LITERAL("parent"),          NULL);
    webgear_xs_hv_set_rv(xscomment, LITERAL("previoussibling"), NULL);
    webgear_xs_hv_set_rv(xscomment, LITERAL("nextsibling"),     NULL);

    webgear_xs_hv_set_pv(xscomment, LITERAL("data"),            data, datalength);
    webgear_xs_hv_set_iv(xscomment, LITERAL("datalength"),      datalength);

    webgear_xs_hv_set_iv(xscomment, LITERAL("object"),          jsobject);
    return xscomment;
}

inline __attribute__((always_inline)) HV *
webgear_node_create_documenttype(JSObject *jsobject, int flags, int id, char *name, int namelength, int publicid, char *public, int publiclength, int systemid, char *system, int systemlength)
{
    HV *xsdocumenttype;

    xsdocumenttype = newHV();

    webgear_xs_hv_set_iv(xsdocumenttype, LITERAL("type"),            NODE_TYPE_DOCUMENT_TYPE);
    webgear_xs_hv_set_iv(xsdocumenttype, LITERAL("flags"),           flags);

    webgear_xs_hv_set_rv(xsdocumenttype, LITERAL("parent"),          NULL);
    webgear_xs_hv_set_rv(xsdocumenttype, LITERAL("previoussibling"), NULL);
    webgear_xs_hv_set_rv(xsdocumenttype, LITERAL("nextsibling"),     NULL);

    webgear_xs_hv_set_iv(xsdocumenttype, LITERAL("id"),              id);
    webgear_xs_hv_set_pv(xsdocumenttype, LITERAL("name"),            name, namelength);
    webgear_xs_hv_set_iv(xsdocumenttype, LITERAL("namelength"),      namelength);

    webgear_xs_hv_set_iv(xsdocumenttype, LITERAL("publicid"),        publicid);
    webgear_xs_hv_set_pv(xsdocumenttype, LITERAL("public"),          public, publiclength);
    webgear_xs_hv_set_iv(xsdocumenttype, LITERAL("publiclength"),    publiclength);

    webgear_xs_hv_set_iv(xsdocumenttype, LITERAL("systemid"),        systemid);
    webgear_xs_hv_set_pv(xsdocumenttype, LITERAL("system"),          system, systemlength);
    webgear_xs_hv_set_iv(xsdocumenttype, LITERAL("systemlength"),    systemlength);

    webgear_xs_hv_set_iv(xsdocumenttype, LITERAL("object"),          jsobject);
    return xsdocumenttype;
}

inline __attribute__((always_inline)) void
webgear_node_append(HV *xsparent, HV *xsnode)
{
    HV *xslastchild;

    xslastchild = webgear_xs_hv_get_rv(xsparent, LITERAL("lastchild"));

    if (xslastchild) {
        webgear_xs_hv_set_rv(xslastchild, LITERAL("nextsibling"), xsnode);
    } else { /* первый узел */
        webgear_xs_hv_set_rv(xsparent, LITERAL("firstchild"), xsnode);
    }

    webgear_xs_hv_set_rv(xsparent, LITERAL("lastchild"), xsnode);
    
    webgear_xs_hv_set_rv(xsnode, LITERAL("parent"),          xsparent);
    webgear_xs_hv_set_rv(xsnode, LITERAL("previoussibling"), xslastchild);
    webgear_xs_hv_set_rv(xsnode, LITERAL("nextsibling"),     NULL);
}

inline __attribute__((always_inline)) void
webgear_node_remove(HV *xsparent, HV *xsnode)
{
    HV *xsprevioussibling, *xsnextsibling;

    xsprevioussibling = webgear_xs_hv_get_rv(xsnode, LITERAL("previoussibling"));
    xsnextsibling     = webgear_xs_hv_get_rv(xsnode, LITERAL("nextsibling"));

    if (xsprevioussibling) {
        webgear_xs_hv_set_rv(xsprevioussibling, LITERAL("nextsibling"), xsnextsibling);
    } else { /* первый узел */
        webgear_xs_hv_set_rv(xsparent, LITERAL("firstchild"), xsnextsibling);
    }

    if (xsnextsibling) {
        webgear_xs_hv_set_rv(xsnextsibling, LITERAL("previoussibling"), xsprevioussibling);
    } else { /* последний узел */
        webgear_xs_hv_set_rv(xsparent, LITERAL("lastchild"), xsprevioussibling);
    }

    webgear_xs_hv_set_rv(xsnode, LITERAL("parent"),          NULL);
    webgear_xs_hv_set_rv(xsnode, LITERAL("previoussibling"), NULL);
    webgear_xs_hv_set_rv(xsnode, LITERAL("nextsibling"),     NULL);
}

inline __attribute__((always_inline)) void
webgear_node_replace(HV *xsparent, HV *xsoldnode, HV *xsnode)
{
    HV *xsprevioussibling, *xsnextsibling;

    xsprevioussibling = webgear_xs_hv_get_rv(xsoldnode, LITERAL("previoussibling"));
    xsnextsibling     = webgear_xs_hv_get_rv(xsoldnode, LITERAL("nextsibling"));

    if (xsprevioussibling) {
        webgear_xs_hv_set_rv(xsprevioussibling, LITERAL("nextsibling"), xsnode);
        webgear_xs_hv_set_rv(xsnode, LITERAL("previoussibling"), xsprevioussibling);
    } else { /* первый узел */
        webgear_xs_hv_set_rv(xsparent, LITERAL("firstchild"), xsnode);
    }

    if (xsnextsibling) {
        webgear_xs_hv_set_rv(xsnextsibling, LITERAL("previoussibling"), xsnode);
        webgear_xs_hv_set_rv(xsnode, LITERAL("nextsibling"), xsnextsibling);
    } else { /* последний узел */
        webgear_xs_hv_set_rv(xsparent, LITERAL("lastchild"), xsnode);
    }

    webgear_xs_hv_set_rv(xsnode, LITERAL("parent"), xsparent);

    webgear_xs_hv_set_rv(xsoldnode, LITERAL("parent"),          NULL);
    webgear_xs_hv_set_rv(xsoldnode, LITERAL("previoussibling"), NULL);
    webgear_xs_hv_set_rv(xsoldnode, LITERAL("nextsibling"),     NULL);
}

inline __attribute__((always_inline)) void
webgear_node_insert_before(HV *xsparent, HV *xsreferencenode, HV *xsnode)
{
    HV *xsprevioussibling;

    xsprevioussibling = webgear_xs_hv_get_rv(xsreferencenode, LITERAL("previoussibling"));

    if (xsprevioussibling) {
        webgear_xs_hv_set_rv(xsprevioussibling, LITERAL("nextsibling"), xsnode);
    } else { /* первый узел */
        webgear_xs_hv_set_rv(xsparent, LITERAL("firstchild"), xsnode);
    }

    webgear_xs_hv_set_rv(xsreferencenode, LITERAL("previoussibling"), xsnode);
    
    webgear_xs_hv_set_rv(xsnode, LITERAL("parent"),          xsparent);
    webgear_xs_hv_set_rv(xsnode, LITERAL("previoussibling"), xsprevioussibling);
    webgear_xs_hv_set_rv(xsnode, LITERAL("nextsibling"),     xsreferencenode);
}

inline __attribute__((always_inline)) void
webgear_node_insert_after(HV *xsparent, HV *xsreferencenode, HV *xsnode)
{
    HV *xsnextsibling;

    xsnextsibling = webgear_xs_hv_get_rv(xsreferencenode, LITERAL("nextsibling"));

    if (xsnextsibling) {
        webgear_xs_hv_set_rv(xsnextsibling, LITERAL("previoussibling"), xsnode);
    } else { /* последний узел */
        webgear_xs_hv_set_rv(xsparent, LITERAL("lastchild"), xsnode);
    }

    webgear_xs_hv_set_rv(xsreferencenode, LITERAL("nextsibling"), xsnode);
    
    webgear_xs_hv_set_rv(xsnode, LITERAL("parent"),          xsparent);
    webgear_xs_hv_set_rv(xsnode, LITERAL("previoussibling"), xsreferencenode);
    webgear_xs_hv_set_rv(xsnode, LITERAL("nextsibling"),     xsnextsibling);
}

/*----- Элементы ---------------------------------------------------------------
------------------------------------------------------------------------------*/

inline __attribute__((always_inline)) void
webgear_element_add_attribute(HV *xselement, HV *xsattribute)
{
    HV   *xsattributes;
    char *name;
    int   namelength;
    
    xsattributes = webgear_xs_hv_get_rv(xselement, LITERAL("attributes"));  
    
    name         = webgear_xs_hv_get_pv(xsattribute, LITERAL("name"));
    namelength   = webgear_xs_hv_get_iv(xsattribute, LITERAL("namelength"));

    webgear_xs_hv_set_rv(xsattributes, name, namelength, xsattribute);

    webgear_xs_hv_set_rv(xsattribute, LITERAL("element"), xselement);
}

inline __attribute__((always_inline)) void
webgear_element_remove_attribute(HV *xselement, HV *xsattribute)
{
    HV   *xsattributes;
    char *name;
    int   namelength;
    
    xsattributes = webgear_xs_hv_get_rv(xselement, LITERAL("attributes")); 
    
    name         = webgear_xs_hv_get_pv(xsattribute, LITERAL("name"));
    namelength   = webgear_xs_hv_get_iv(xsattribute, LITERAL("namelength"));
    
    hv_delete(xsattributes, name, namelength, 0);

    webgear_xs_hv_set_rv(xsattribute, LITERAL("element"), NULL);
}

inline __attribute__((always_inline)) HV *
webgear_element_search_attribute(HV *xselement, char *name, int namelength)
{
    HV *xsattributes;
    
    xsattributes = webgear_xs_hv_get_rv(xselement, LITERAL("attributes"));    
    return webgear_xs_hv_get_rv(xsattributes, name, namelength);
}

inline __attribute__((always_inline)) void
webgear_element_add_event(HV *xselement, HV *xsevent)
{
    HV   *xsevents, *xsheadevent, *xtailevent;
    char *type;
    int   typelength;
    
    xsevents    = webgear_xs_hv_get_rv(xselement, LITERAL("events"));       
    
    type        = webgear_xs_hv_get_pv(xsevent, LITERAL("type"));
    typelength  = webgear_xs_hv_get_iv(xsevent, LITERAL("typelength"));
    
    xsheadevent = webgear_xs_hv_get_rv(xsevents, type, typelength);
    
    if (xsheadevent) {
        xtailevent = webgear_xs_hv_get_rv(xsheadevent, LITERAL("lastnode"));

        webgear_xs_hv_set_rv(xtailevent,  LITERAL("nextnode"),     xsevent);
        webgear_xs_hv_set_rv(xsevent,     LITERAL("previousnode"), xtailevent);
        webgear_xs_hv_set_rv(xsheadevent, LITERAL("lastnode"),     xsevent);
    } else {
        /* Единственный узел события также является хвостовым. */
        webgear_xs_hv_set_rv(xsevent, LITERAL("lastnode"), xsevent);
        webgear_xs_hv_set_rv(xsevents, type, typelength, xsevent);
    }

    webgear_xs_hv_set_rv(xsevent, LITERAL("element"), xselement);
}

inline __attribute__((always_inline)) void
webgear_element_remove_event(HV *xselement, HV *xsevent)
{
    HV   *xsevents, *xsheadevent, *xtailevent, *xspreviousevent, *xsnextevent;
    char *eventtype;
    int   eventtypelength;
    
    xsevents        = webgear_xs_hv_get_rv(xselement, LITERAL("events"));  
    
    eventtype       = webgear_xs_hv_get_pv(xsevent, LITERAL("type"));
    eventtypelength = webgear_xs_hv_get_iv(xsevent, LITERAL("typelength"));

    xspreviousevent = webgear_xs_hv_get_rv(xsevent, LITERAL("previousnode"));
    xsnextevent     = webgear_xs_hv_get_rv(xsevent, LITERAL("nextnode"));
    
    if (xspreviousevent) {
        webgear_xs_hv_set_rv(xspreviousevent, LITERAL("nextnode"), xsnextevent);
    } else if (xsnextevent) {
        xtailevent = webgear_xs_hv_get_rv(xsevent, LITERAL("lastnode"));
        
        webgear_xs_hv_set_rv(xsnextevent, LITERAL("lastnode"), xtailevent);
        webgear_xs_hv_set_rv(xsevents, eventtype, eventtypelength, xsnextevent);
    } else {
        hv_delete(xsevents, eventtype, eventtypelength, 0);
    }

    if (xsnextevent) {
        webgear_xs_hv_set_rv(xsnextevent, LITERAL("previousnode"), xspreviousevent);
    } else if (xspreviousevent) {
        xsheadevent = webgear_xs_hv_get_rv(xsevents, eventtype, eventtypelength);
        webgear_xs_hv_set_rv(xsheadevent, LITERAL("lastnode"), xspreviousevent);
    } 
    
    webgear_xs_hv_set_rv(xsevent, LITERAL("element"),      NULL);
    webgear_xs_hv_set_rv(xsevent, LITERAL("nextnode"),     NULL);
    webgear_xs_hv_set_rv(xsevent, LITERAL("previousnode"), NULL);
    webgear_xs_hv_set_rv(xsevent, LITERAL("lastnode"),     NULL);
}

inline __attribute__((always_inline)) HV *
webgear_element_search_event(HV *xselement, JSObject *jscallback, int flags, char *type, int typelength)
{
    HV *xsevents, *xsevent;
    
    xsevents = webgear_xs_hv_get_rv(xselement, LITERAL("events"));       
    xsevent  = webgear_xs_hv_get_rv(xsevents, type, typelength);
    
    while (xsevent) {

        if (webgear_xs_hv_get_iv(xsevent, LITERAL("callback")) == jscallback && webgear_xs_hv_get_iv(xsevent, LITERAL("flags")) == flags) {
            return xsevent;
        }

        xsevent = webgear_xs_hv_get_rv(xsevent, LITERAL("nextnode"));
    }
    
    return NULL;
}

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
 Допустимые символы в имени тега:
 https://html.spec.whatwg.org/multipage/syntax.html#tag-name-state
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
inline __attribute__((always_inline)) char *
webgear_element_normalize_name(char *data, int datalength)
{
    char *name;
    int   index;

    if (!datalength) {
        return NULL;
    }

    name = webgear_xs_malloc(datalength + 1);
    name[datalength] = 0;

    for (index = 0; index < datalength; index++) {

        if (data[index] == 0x09 || /* TAB   */
            data[index] == 0x0a || /* LF    */
            data[index] == 0x0c || /* FF    */
            data[index] == 0x20 || /* SPACE */
            data[index] == 0x2f || /* '/'   */
            data[index] == 0x3e) { /* '>'   */
            webgear_xs_free(name);
            return NULL;
        }

        if (data[index] >= 0x61 && /* 'a' */
            data[index] <= 0x7a) { /* 'Z' */
            /* Преобразовываем в верхний регистр. */
            name[index] = data[index] & 0xdf;
        } else {
            name[index] = data[index];
        }
    }

    return name;
}

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
 Согласно спецификации имя тега в узле должно храниться в нижнем регистре, но 
 возвращаться, например через Element.tagName в верхнем. В текущей реализации
 имена хранятся в верхнем регистре.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
static char *elementnames[] = {
    "UNCKNOWN", "A"         , "ABBR"    , "ADDRESS" , "APPLET"   ,
    "AREA"    , "ARTICLE"   , "ASIDE"   , "AUDIO"   , "B"        ,
    "BASE"    , "BASEFONT"  , "BDI"     , "BDO"     , "BGSOUND"  ,
    "BIG"     , "BLOCKQUOTE", "BODY"    , "BR"      , "BUTTON"   ,
    "CANVAS"  , "CAPTION"   , "CENTER"  , "CITE"    , "CODE"     ,
    "COL"     , "COLGROUP"  , "DATA"    , "DATALIST", "DD"       ,
    "DEL"     , "DETAILS"   , "DFN"     , "DIALOG"  , "DIR"      ,
    "DIV"     , "DL"        , "DT"      , "EM"      , "EMBED"    ,
    "FIELDSET", "FIGCAPTION", "FIGURE"  , "FONT"    , "FOOTER"   ,
    "FORM"    , "FRAME"     , "FRAMESET", "H1"      , "H2"       ,
    "H3"      , "H4"        , "H5"      , "H6"      , "HEAD"     ,
    "HEADER"  , "HGROUP"    , "HR"      , "HTML"    , "I"        ,
    "IFRAME"  , "IMAGE"     , "IMG"     , "INPUT"   , "INS"      ,
    "KBD"     , "KEYGEN"    , "LABEL"   , "LEGEND"  , "LI"       ,
    "LINK"    , "LISTING"   , "MAIN"    , "MAP"     , "MARK"     ,
    "MARQUEE" , "MATH"      , "MENU"    , "MENUITEM", "META"     ,
    "METER"   , "NAV"       , "NOBR"    , "NOEMBED" , "NOFRAMES" ,
    "NOSCRIPT", "OBJECT"    , "OL"      , "OPTGROUP", "OPTION"   ,
    "OUTPUT"  , "P"         , "PARAM"   , "PICTURE" , "PLAINTEXT",
    "PRE"     , "PROGRESS"  , "Q"       , "RB"      , "RP"       ,
    "RT"      , "RTC"       , "RUBY"    , "S"       , "SAMP"     ,
    "SCRIPT"  , "SECTION"   , "SELECT"  , "SLOT"    , "SMALL"    ,
    "SOURCE"  , "SPAN"      , "STRIKE"  , "STRONG"  , "STYLE"    ,
    "SUB"     , "SUMMARY"   , "SUP"     , "SVG"     , "TABLE"    ,
    "TBODY"   , "TD"        , "TEMPLATE", "TEXTAREA", "TFOOT"    ,
    "TH"      , "THEAD"     , "TIME"    , "TITLE"   , "TR"       ,
    "TRACK"   , "TT"        , "U"       , "UL"      , "VAR"      ,
    "VIDEO"   , "WBR"       , "XMP"};

inline __attribute__((always_inline)) int
webgear_element_name_to_id(char *name, int namelength)
{
    int base, limit, index, result;
    /* Минимальная и максимальная длина имени в массиве. */
    if (namelength < 1 || namelength > 10) {
        return 0;
    }

    base  = 0;
    /* Количество имен. */
    limit = 138;

    while (limit) {
		index  = base + (limit >> 1);
        result = strcmp(name, elementnames[index]);

		if (result == 0) {
			return index;
        }

		if (result > 0) {
			base = index + 1;
			limit--;
		}

        limit >>= 1;
	}

	return 0;
}

/*----- Атрибуты ---------------------------------------------------------------
 Допустимые символы в имени атрибута:
 https://html.spec.whatwg.org/multipage/syntax.html#attribute-name-state
------------------------------------------------------------------------------*/

inline __attribute__((always_inline)) char *
webgear_attribute_normalize_name(char *data, int datalength)
{
    char *name;
    int   index;

    if (!datalength) {
        return NULL;
    }

    name = webgear_xs_malloc(datalength + 1);
    name[datalength] = 0;

    for (index = 0; index < datalength; index++) {

        if (data[index] == 0x09 || /* TAB   */
            data[index] == 0x0a || /* LF    */
            data[index] == 0x0c || /* FF    */
            data[index] == 0x20 || /* SPACE */
            data[index] == 0x2f || /* '/'   */
            data[index] == 0x3d || /* '='   */
            data[index] == 0x3e) { /* '>'   */
            webgear_xs_free(name);
            return NULL;
        }

        if (data[index] >= 0x41 && /* 'A' */
            data[index] <= 0x5a) { /* 'Z' */
            /* Преобразовываем в нижний регистр. */
            name[index] = data[index] | 0x20;
        } else {
            name[index] = data[index];
        }
    }

    return name;
}

/*------ "Живые" коллекции и списки --------------------------------------------
------------------------------------------------------------------------------*/

#define COLLECTION_SEARCH_ALL          0
#define COLLECTION_SEARCH_BY_TAGNAME   1
#define COLLECTION_SEARCH_BY_CLASSNAME 2

typedef struct INodeList {
    JSObject *jsobject;
    HV       *xsroot;
    AV       *xsarray;
    bool      modified;
} INodeList;

inline __attribute__((always_inline)) INodeList *
webgear_nodelist_create(JSObject *jsobject, HV *xsroot)
{
    INodeList *nodelist;

    nodelist = webgear_xs_malloc(sizeof(INodeList));

    nodelist->jsobject = jsobject;
    nodelist->modified = true;
    nodelist->xsroot   = xsroot;
    nodelist->xsarray  = newAV();
    return nodelist;
}

inline __attribute__((always_inline)) void
webgear_nodelist_update(INodeList *nodelist)
{
    HV  *xsnode;
    int  type;

    if (nodelist->modified) {
        av_clear(nodelist->xsarray);

        xsnode = webgear_xs_hv_get_rv(nodelist->xsroot, LITERAL("firstchild"));

        while (xsnode) {
            webgear_xs_av_push_rv(nodelist->xsarray, xsnode);
            xsnode = webgear_xs_hv_get_rv(xsnode, LITERAL("nextsibling"));
        }

        nodelist->modified = false;
    }
}

typedef struct IHTMLCollection {
    JSObject *jsobject;
    
    HV       *xsroot;
    AV       *xsarray;
    bool      modified;
    
    int       searchtype;
    char     *name;
    int       namelength;
    
    struct IHTMLCollection *previous;
    struct IHTMLCollection *next;
} IHTMLCollection;

inline __attribute__((always_inline)) IHTMLCollection *
webgear_htmlcollection_create(JSObject *jsobject, IHTMLCollection *previous, IHTMLCollection *next, HV *xsroot, char searchtype, char *name, int namelength)
{
    IHTMLCollection *htmlcollection;

    htmlcollection = webgear_xs_malloc(sizeof(IHTMLCollection));

    htmlcollection->jsobject        = jsobject;
    htmlcollection->previous        = previous;
    htmlcollection->next            = next;
    htmlcollection->xsroot          = xsroot;
    htmlcollection->xsarray         = newAV();
    htmlcollection->modified        = true;
    htmlcollection->searchtype      = searchtype;
    htmlcollection->name            = webgear_xs_malloc(namelength);
    webgear_xs_memcpy(htmlcollection->name, name, namelength);
    htmlcollection->namelength      = namelength;
    return htmlcollection;
}

inline __attribute__((always_inline)) void
webgear_htmlcollection_update(IHTMLCollection *htmlcollection)
{
    HV  *xsnode, *xsnextnode, *xsattribute;

    if (htmlcollection->modified) {
        av_clear(htmlcollection->xsarray);

        xsnode = webgear_xs_hv_get_rv(htmlcollection->xsroot, LITERAL("firstchild"));

        while (xsnode) {
            /*
            if (webgear_xs_hv_get_iv(xsnode, LITERAL("type")) == NODE_TYPE_ELEMENT                                            &&
               (htmlcollection->searchtype            == COLLECTION_SEARCH_ALL                                        ||
               (htmlcollection->searchtype            == COLLECTION_SEARCH_BY_TAGNAME                                 &&
                htmlcollection->namelength            == webgear_xs_hv_get_iv(xsnode, LITERAL("datalength"))                   &&
               !memcmp(htmlcollection->name, webgear_xs_hv_get_pv(xsnode, LITERAL("data")), htmlcollection->namelength)) ||
               (htmlcollection->searchtype            == COLLECTION_SEARCH_BY_ID                                      && 1))) {
                webgear_xs_av_push_rv(htmlcollection->xsarray, xsnode);
            }
            */

            if (webgear_xs_hv_get_iv(xsnode, LITERAL("type")) == NODE_TYPE_ELEMENT) {
                /*
                if (htmlcollection->searchtype            == COLLECTION_SEARCH_ALL                                        ||
                   (htmlcollection->searchtype            == COLLECTION_SEARCH_BY_TAGNAME                                 &&
                    htmlcollection->namelength            == webgear_xs_hv_get_iv(xsnode, LITERAL("datalength"))                   &&
                    !memcmp(htmlcollection->name, webgear_xs_hv_get_pv(xsnode, LITERAL("data")), htmlcollection->namelength))) {
                    webgear_xs_av_push_rv(htmlcollection->xsarray, xsnode);
                }
                */

                if (htmlcollection->searchtype == COLLECTION_SEARCH_BY_TAGNAME               &&
                   (htmlcollection->namelength != webgear_xs_hv_get_iv(xsnode, LITERAL("namelength")) ||
                    memcmp(htmlcollection->name, webgear_xs_hv_get_pv(xsnode, LITERAL("name")), htmlcollection->namelength))) {
                    goto L1;
                }
                /* Проваливаемся на COLLECTION_SEARCH_ALL.*/
                webgear_xs_av_push_rv(htmlcollection->xsarray, xsnode);
        L1:
                xsnextnode = webgear_xs_hv_get_rv(xsnode, LITERAL("firstchild"));

                if (xsnextnode) {
                    xsnode = xsnextnode;
                    continue;
                }
            }
        L2:
            xsnextnode = webgear_xs_hv_get_rv(xsnode, LITERAL("nextsibling"));

            if (xsnextnode) {
                xsnode = xsnextnode;
                continue;
            }

            if (xsnode == htmlcollection->xsroot) {
                break;
            }

            if (xsnode = webgear_xs_hv_get_rv(xsnode, LITERAL("parent"))) {
                goto L2;
            }
        }

        htmlcollection->modified = false;
    }
}

inline __attribute__((always_inline)) bool
webgear_collections_reset(HV *xsparent, HV *xsnode)
{
    INodeList       *nodelist;
    IHTMLCollection *htmlcollection;

    nodelist = webgear_xs_hv_get_iv(xsparent, LITERAL("livenodelist"));

    if (nodelist) {
        nodelist->modified = true;
    }

    while (xsparent) {

        if (xsparent == xsnode) {
            return false;
        }

        htmlcollection = webgear_xs_hv_get_iv(xsparent, LITERAL("livehtmlcollections"));

        while (htmlcollection) {
            htmlcollection->modified = true;
            htmlcollection = htmlcollection->next;
        }

        xsparent = webgear_xs_hv_get_rv(xsparent, LITERAL("parent"));
    }

    return true;
}

/*----- События ----------------------------------------------------------------
 В текущей реализации атрибуты: composed, isTrusted и флаги: in passive listener
 flag, composed flag, initialized flag, dispatch flag не используются.
------------------------------------------------------------------------------*/

#define EVENT_PAHASE_NONE      0
#define EVENT_PAHASE_CAPTURING 1
#define EVENT_PAHASE_AT_TARGET 2
#define EVENT_PAHASE_BUBBLING  3

typedef struct IEvent {
    char *type;
    int   typelength;

    int  *target;
    int  *currenttarget;
    char  eventphase;

    char  isbubbles:    1;
    char  iscancelable: 1;
    
    int64 timestamp; /* double? */

    union {
        char flags;

        struct {
            char flagstoppropagation:          1;
            char flagstopimmediatepropagation: 1;
            char flagcanceled:                 1;
        };
    };
} IEvent;

inline __attribute__((always_inline)) IEvent *
webgear_event_create(char *type, int typelength, bool isbubbles, bool iscancelable)
{
    IEvent *event;

    event = webgear_xs_malloc(sizeof(IEvent));

    event->type          = webgear_xs_malloc(typelength);
    webgear_xs_memcpy(event->type, type, typelength);
    event->typelength    = typelength;
    event->target        = NULL;
    event->currenttarget = NULL;
    event->eventphase    = EVENT_PAHASE_NONE;
    event->isbubbles     = isbubbles;
    event->iscancelable  = iscancelable;
    event->timestamp     = JS_Now();
    event->flags         = 0;
    return event;
}

inline __attribute__((always_inline)) bool
webgear_event_dispatch(JSContext *jscontext, JSObject *jsevent, IEvent *event, char eventphase, HV *xsevent)
{
    JSObject *jselement;
    jsval     jsargumens[1], jsreturn;
    /* Текущий объект события как единственный аргумент колбэка. */
    jsargumens[0]     = jsevent;

    event->eventphase = eventphase;

    while (xsevent) {
        jselement = webgear_xs_hv_get_iv(webgear_xs_hv_get_rv(xsevent, LITERAL("element")), LITERAL("object"));
        /* Флаг изначально сброшен, указатель на предыдущий элемент может быть NULL. */
        if (event->flagstoppropagation && jselement != event->currenttarget) {
            return false;
        }

        event->currenttarget = jselement;
        /* jselement будет доступен через this. */
        JS_CallFunction(jscontext, jselement, webgear_xs_hv_get_iv(xsevent, LITERAL("callback")), 1, &jsargumens, &jsreturn);

        if (event->flagstopimmediatepropagation) {
            return false;
        }

        xsevent = webgear_xs_hv_get_rv(xsevent, LITERAL("nextphasenode"));
    }

    return true;
}

inline __attribute__((always_inline)) HV *
webgear_event_add(HV **xshead, HV **xstail, HV *xsevent)
{
    if (*xshead) {
        webgear_xs_hv_set_rv(*xstail, LITERAL("nextphasenode"), xsevent);
    } else {
        *xshead = xsevent;
    }
    
    *xstail = xsevent;
    return xsevent;
}

/*----- Таймеры ----------------------------------------------------------------
 В Windows после вызова JS_CallFunction из основной подпрограммы таймера не 
 происходит возврат, возможно различия в версиях потоков MinGW или ошибка в
 параметрах CreateTimerQueueTimer или нужно использовать флаг JS_THREADSAFE.
------------------------------------------------------------------------------*/

typedef struct Timer {
    int          id;

    bool         periodic;
   
    int          delay;
    /* Время срабатывани таймера (тики). */
    int          timeout;
    
    JSFunction  *jscallback;
    int          argumentcount;
    jsval      **argumentvector;

    struct Timer *previous;
    struct Timer *next;
} Timer;

inline __attribute__((always_inline)) Timer *
webgear_timer_create(int id, bool periodic, int delay, int timeout, JSFunction *jscallback, int argumentcount, jsval **argumentvector)
{
    Timer *timer;
    int    index;

    timer = malloc(sizeof(Timer));

    timer->id             = id;

    timer->periodic       = periodic;
    timer->delay          = delay;
    timer->timeout        = timeout;
    timer->jscallback     = jscallback;

    timer->argumentcount  = argumentcount;
    timer->argumentvector = malloc(argumentcount + sizeof(jsval));
    /* Возможно ли удаление переданных аргументов GC? */
    for (index = 0; index < argumentcount; index++) {
        timer->argumentvector[index] = argumentvector[index];
    }

    timer->previous       = NULL;
    timer->next           = NULL;
    return timer;
}

/* Размер массива должна быть степенью двойки для битового вычисления модуля. */
#define TIMERS_BUCKETS_SIZE 512

typedef struct Timers {
    /* Количество работающих таймеров. */
    int        total;
    /* Следующий ID для таймера. */
    int        nextid;
    int        ticks;
    /* Главный таймер. */
#if defined(XP_UNIX)
    timer_t    timer;
#elif defined(XP_WIN)
    HANDLE     timer;
#endif
    JSContext *jscontext;
    JSContext *jsobject;

    Timer     *buckets[TIMERS_BUCKETS_SIZE];
} Timers;


inline __attribute__((always_inline))
webgear_timer_add_to_bucket(Timers **bucket, Timer *timer)
{
    Timer *nexttimer; /* *referencetimer ??? */

    if (*bucket) {
        nexttimer = *bucket;

        while (1) {
            /* Вставка перед текущим таймером. */
            if (nexttimer->timeout > timer->timeout) {

                if (nexttimer->previous) {
                    nexttimer->previous->next = timer;
                    timer->previous = nexttimer->previous;
                } else {
                    *bucket = timer;
                }

                timer->next         = nexttimer;
                nexttimer->previous = timer;
                break;
            }
            /* Вставка в конец списка. */
            if (!nexttimer->next) {
                timer->previous = nexttimer;
                nexttimer->next = timer;
                break;
            }

            nexttimer = nexttimer->next;
        }

    } else {
        *bucket = timer;
    }
}

inline __attribute__((always_inline)) void
webgear_timer_remove_from_bucket(Timers **bucket, Timer *timer)
{
    if (timer->previous) {
        timer->previous->next = timer->next;
    } else { /* (первый таймер) */
        *bucket = timer->next;
    }

    if (timer->next) {
        timer->next->previous = timer->previous;
    } /* (последний таймер) */

    timer->previous = NULL;
    timer->next     = NULL;
}

#if defined(XP_UNIX)
#define SIGTIMER (SIGRTMAX)
struct itimerspec intervaloff = {};
/* 1мс = 1000000нс */
struct itimerspec interval1ms = {.it_value.tv_nsec = 1000000, .it_interval.tv_nsec = 1000000};
#endif

#if defined(XP_UNIX)
void
webgear_timers_process(int signal, siginfo_t *signalinfo, void *context)
#elif defined(XP_WIN)
void
webgear_timers_process(void *parameter)
#endif
{
    jsval   jsreturn;
    Timer  *timer, *nexttimer, *referencetimer;
    Timers *timers;
    int     index, newindex;
#if defined(XP_UNIX)
    timers = (Timers*)signalinfo->si_value.sival_ptr;
#elif defined(XP_WIN)
    timers = (Timers*)parameter;
#endif
    timers->ticks++;
 
    index = timers->ticks & (TIMERS_BUCKETS_SIZE - 1);
    timer = timers->buckets[index];

    while (timer) {
        /* Таймер может быть удален или перемещен. */
        nexttimer = timer->next;

        if (timer->timeout <= timers->ticks) { 
            JS_CallFunction(timers->jscontext, timers->jsobject, timer->jscallback, timer->argumentcount, timer->argumentvector, &jsreturn);

            webgear_timer_remove_from_bucket(&timers->buckets[index], timer);

            if (!timer->periodic) {
                webgear_xs_free(timer);

                if (!--timers->total) {
                #if defined(XP_UNIX)
                    timer_settime(&timers->timer, 0, &intervaloff, NULL);
                #elif defined(XP_WIN)    
                    DeleteTimerQueueTimer(NULL, timers->timer, NULL);
                #endif
                }

            } else {
                timer->timeout = timers->ticks + timer->delay;
                newindex       = timer->timeout & (TIMERS_BUCKETS_SIZE - 1);
              
                webgear_timer_add_to_bucket(&timers->buckets[newindex], timer);
            }
        }

        timer = nexttimer;
    }
}

inline __attribute__((always_inline)) int
webgear_timer_add(Timers *timers, bool periodic, int delay, JSFunction *callback, int argumentcount, jsval **argumentvector)
{
    Timer *timer, *referencetimer;
    int    index, timeout;

    timers->nextid++;
    timers->total++;
    /* Для корректной работы минимальная задержка должна быть больше нуля. */
    timeout = timers->ticks + delay;
    timer   = webgear_timer_create(timers->nextid, periodic, delay, timeout, callback, argumentcount, argumentvector);
    /* Битовый аналог delay % TMERS_BUCKETS_SIZE. */
    index   = timeout & (TIMERS_BUCKETS_SIZE - 1);
    /* Отключаем главный таймер перед критическим участком кода.*/
#if defined(XP_UNIX)
    timer_settime(&timers->timer, 0, &intervaloff, NULL);
#elif defined(XP_WIN)    
    DeleteTimerQueueTimer(NULL, timers->timer, NULL);
#endif
    /* Критический участок. */
    webgear_timer_add_to_bucket(&timers->buckets[index], timer);
    /* Включаем главный таймер.*/
#if defined(XP_UNIX)
    timer_settime(&timers->timer, 0, &interval1ms, NULL);
#elif defined(XP_WIN) 
    CreateTimerQueueTimer(&timers->timer, NULL, (WAITORTIMERCALLBACK)webgear_timers_process, timers, 0, 1, WT_EXECUTEINTIMERTHREAD); 
#endif
    return timer->id;
}

inline __attribute__((always_inline)) int
webgear_timer_remove(Timers *timers, int id)
{
    Timer *timer, *nexttimer;
    int    index;
#if defined(XP_UNIX)
    timer_settime(&timers->timer, 0, &intervaloff, NULL);
#elif defined(XP_WIN)    
    DeleteTimerQueueTimer(NULL, timers->timer, NULL);
#endif    
    for (index = 0; index < TIMERS_BUCKETS_SIZE; index++) {
        timer = timers->buckets[index];

        while (timer) {
            nexttimer = timer->next;

            if (timer->id == id) {
                webgear_timer_remove_from_bucket(&timers->buckets[index], timer);

                webgear_xs_free(timer);
                timers->total--;
                goto L;
            }

            timer = nexttimer;
        }
    }
  L:
    if (timers->total) {
    #if defined(XP_UNIX)
        timer_settime(&timers->timer, 0, &interval1ms, NULL);
    #elif defined(XP_WIN) 
        CreateTimerQueueTimer(&timers->timer, NULL, (WAITORTIMERCALLBACK)webgear_timers_process, timers, 0, 1, WT_EXECUTEINTIMERTHREAD); 
    #endif
    }
}

/*----- "Окно браузера" --------------------------------------------------------
------------------------------------------------------------------------------*/

typedef struct IWindow {
    JSObject *jswindow;
    JSObject *jsdocument;

    Timers   *timers;
} IWindow;

inline __attribute__((always_inline)) INodeList *
webgear_window_create(JSContext *jscontext, JSObject *jsglobal, JSObject *jswindow, JSObject *jsdocument)
{
    IWindow *window;
#if defined(XP_UNIX)
    struct sigaction signalaction;
    struct sigevent  signalevent;
#endif
    window = webgear_xs_malloc(sizeof(IWindow));
    window->jswindow   = jswindow;
    window->jsdocument = jsdocument;

    window->timers = webgear_xs_zalloc(sizeof(Timers));
    window->timers->jscontext = jscontext;
    window->timers->jsobject  = jswindow;
#if defined(XP_UNIX)
    signalaction.sa_flags     = SA_SIGINFO;
    signalaction.sa_sigaction = webgear_timers_process;
    sigaction(SIGTIMER, &signalaction, NULL);

    signalevent.sigev_notify          = SIGEV_SIGNAL;
    signalevent.sigev_signo           = SIGTIMER;
    signalevent.sigev_value.sival_ptr = window->timers;
    timer_create(CLOCK_REALTIME, &signalevent, &window->timers->timer);
#endif  
    return window;
}

#endif /* _webgear_js_dom_h */