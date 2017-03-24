/*==============================================================================
        Interface Element

 https://dom.spec.whatwg.org/#interface-element
 https://www.w3.org/TR/2003/WD-DOM-Level-3-Core-20030226/DOM3-Core.html#core-ID-745549614
 
 https://w3c.github.io/DOM-Parsing/#extensions-to-the-element-interface
==============================================================================*/

#ifndef _webgear_js_dom_core_element_h
#define _webgear_js_dom_core_element_h

/*----- Методы -----------------------------------------------------------------
------------------------------------------------------------------------------*/

/* webgear_js_dom_core_element_hasAttributes
   webgear_js_dom_core_element_getAttributeNames */

static JSBool
webgear_js_dom_core_element_getAttribute(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSString *jsstring;
    HV       *xsself, *xsattribute;
    char     *data, *name, *value;
    int       namelength, valuelength;
    
    if (!argc) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }
    
    if (!JSVAL_IS_STRING(argv[0])) {
        webgear_js_exeption(cx, EXCEPTION_ILLEGAL_ARGUMENT_ERR);
        return JS_FALSE;
    }

    *rval = JSVAL_NULL;
    
    jsstring   = JS_ValueToString(cx, argv[0]); 
    data       = JS_GetStringBytes(jsstring);
    namelength = strlen(data);
    name       = webgear_attribute_normalize_name(data, namelength);

    if (name) {
        xsself      = JS_GetPrivate(cx, obj);
        
        xsattribute = webgear_element_search_attribute(xsself, name, namelength);
        
        if (xsattribute) {
            value       = webgear_xs_hv_get_pv(xsattribute, LITERAL("value"));
            valuelength = webgear_xs_hv_get_iv(xsattribute, LITERAL("valuelength"));
            jsstring    = JS_NewStringCopyN(cx, value, valuelength);
            
            *rval = STRING_TO_JSVAL(jsstring);
        } 
        
        webgear_xs_free(name);
    }

    return JS_TRUE;
}

/* webgear_js_dom_core_element_getAttributeNS */

static JSBool
webgear_js_dom_core_element_setAttribute(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSString *jsstring;
    HV       *xsself, *xsattribute;
    char     *data, *name, *value;
    int       namelength, valuelength;
    
    if (argc < 2) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }
    
    if (!JSVAL_IS_STRING(argv[0])) {
        webgear_js_exeption(cx, EXCEPTION_ILLEGAL_ARGUMENT_ERR);
        return JS_FALSE;
    }
        
    jsstring   = JS_ValueToString(cx, argv[0]); 
    data       = JS_GetStringBytes(jsstring);
    namelength = strlen(data);
    name       = webgear_attribute_normalize_name(data, namelength);
    
    if (!name) {
        webgear_js_exeption(cx, EXCEPTION_INVALID_CHARACTER_ERR);
        return JS_FALSE;
    }
    
    xsself      = JS_GetPrivate(cx, obj);
    
    xsattribute = webgear_element_search_attribute(xsself, name, namelength);
    
    jsstring    = JS_ValueToString(cx, argv[1]); 
    value       = JS_GetStringBytes(jsstring);
    valuelength = strlen(value);
    
    if (xsattribute) {
        webgear_xs_hv_set_pv(xsattribute, LITERAL("value"), value, valuelength);
        webgear_xs_hv_set_iv(xsattribute, LITERAL("valuelength"), valuelength);
    } else {
        xsattribute = webgear_node_create_attribute(NULL, 0, name, namelength, value, valuelength);
        webgear_element_add_attribute(xsself, xsattribute);
    }
    
    webgear_xs_free(name);
    return JS_TRUE;
}

/* webgear_js_dom_core_element_setAttributeNS */

static JSBool
webgear_js_dom_core_element_removeAttribute(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSString *jsstring;
    HV       *xsself, *xsattribute;
    char     *data, *name;
    int       namelength;

    if (!argc) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }

    if (!JSVAL_IS_STRING(argv[0])) {
        webgear_js_exeption(cx, EXCEPTION_ILLEGAL_ARGUMENT_ERR);
        return JS_FALSE;
    }
    
    jsstring   = JS_ValueToString(cx, argv[0]); 
    data       = JS_GetStringBytes(jsstring);
    namelength = strlen(data);
    name       = webgear_attribute_normalize_name(data, namelength);

    if (name) {
        xsself      = JS_GetPrivate(cx, obj);
        
        xsattribute = webgear_element_search_attribute(xsself, name, namelength);
        
        if (xsattribute) {
            webgear_element_remove_attribute(xsself, xsattribute);
        }

        webgear_xs_free(name);
    }
    
    return JS_TRUE;
}

/* webgear_js_dom_core_element_removeAttributeNS
   webgear_js_dom_core_element_hasAttribute
   webgear_js_dom_core_element_hasAttributeNS */

static JSBool
webgear_js_dom_core_element_getAttributeNode(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSObject *jsattribute;
    JSString *jsstring;
    HV       *xsself, *xsattribute;
    char     *data, *name;
    int       namelength;

    if (!argc) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }
    
    if (!JSVAL_IS_STRING(argv[0])) {
        webgear_js_exeption(cx, EXCEPTION_ILLEGAL_ARGUMENT_ERR);
        return JS_FALSE;
    }
    
    *rval = JSVAL_NULL;

    jsstring   = JS_ValueToString(cx, argv[0]); 
    data       = JS_GetStringBytes(jsstring);
    namelength = strlen(data);
    name       = webgear_attribute_normalize_name(data, namelength);
    
    if (name) {
        xsself      = JS_GetPrivate(cx, obj);
        
        xsattribute = webgear_element_search_attribute(xsself, name, namelength);
        
        if (xsattribute) {
            jsattribute = webgear_xs_hv_get_iv(xsattribute, LITERAL("object"));

            if (!jsattribute) {
                jsattribute = JS_NewObject(cx, &webgear_js_dom_core_attribute, NULL, NULL);
                webgear_xs_hv_set_iv(xsattribute, LITERAL("object"), jsattribute);  
                JS_SetPrivate(cx, jsattribute, xsattribute);
            }

            *rval = OBJECT_TO_JSVAL(jsattribute);
        }
        
        webgear_xs_free(name);
    }
    
    return JS_TRUE;
}

/* webgear_js_dom_core_element_getAttributeNodeNS */

static JSBool
webgear_js_dom_core_element_setAttributeNode(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)  
{
    JSObject *jsattribute;
    HV       *xsself, *xselement, *xsnewattribute, *xsattribute;
    char     *name;
    int       namelength;
    
    if (!argc) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }

    if (!JSVAL_IS_OBJECT(argv[0]) || !JS_InstanceOf(cx, argv[0], &webgear_js_dom_core_attribute, NULL)) {
        webgear_js_exeption(cx, EXCEPTION_INVALID_NODE_TYPE_ERR);
        return JS_FALSE;
    }

    xsself         = JS_GetPrivate(cx, obj);
    xsnewattribute = JS_GetPrivate(cx, JSVAL_TO_OBJECT(argv[0]));
    
    xselement      = webgear_xs_hv_get_iv(xsnewattribute, LITERAL("element"));

    if (xselement) {
        /* Атрибут принадлежит текущему элементу. */
        if (xselement == xsself) {
            *rval = argv[0];
            return JS_TRUE;
        }
        
        webgear_js_exeption(cx, EXCEPTION_INUSE_ATTRIBUTE_ERR);
        return JS_FALSE;
    }

    name        = webgear_xs_hv_get_pv(xsnewattribute, LITERAL("name"));
    namelength  = webgear_xs_hv_get_iv(xsnewattribute, LITERAL("namelength"));
    xsattribute = webgear_element_search_attribute(xsself, name, namelength);

    if (xsattribute) {
        webgear_element_remove_attribute(xsself, xsattribute);

        jsattribute = webgear_xs_hv_get_iv(xsattribute, LITERAL("object"));

        if (!jsattribute) {
            jsattribute = JS_NewObject(cx, &webgear_js_dom_core_attribute, NULL, NULL);
            webgear_xs_hv_set_iv(xsattribute, LITERAL("object"), jsattribute);  
            JS_SetPrivate(cx, jsattribute, xsattribute);
        }
        
        *rval = OBJECT_TO_JSVAL(jsattribute);
    } else {
        *rval = JSVAL_NULL;
    }
    
    webgear_element_add_attribute(xsself, xsnewattribute);
    return JS_TRUE;
}
   
/* webgear_js_dom_core_element_setAttributeNodeNS */

static JSBool                                                                                                                 
webgear_js_dom_core_element_removeAttributeNode(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)       
{                    
    HV *xsself, *xselement, *xsattribute;

    if (!argc) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }

    if (!JSVAL_IS_OBJECT(argv[0]) || !JS_InstanceOf(cx, argv[0], &webgear_js_dom_core_attribute, NULL)) {
        webgear_js_exeption(cx, EXCEPTION_INVALID_NODE_TYPE_ERR);
        return JS_FALSE;
    } 
     
    xsself      = JS_GetPrivate(cx, obj);
    xsattribute = JS_GetPrivate(cx, JSVAL_TO_OBJECT(argv[0])); 

    if (webgear_xs_hv_get_iv(xsattribute, LITERAL("element")) != xsself) {
        webgear_js_exeption(cx, EXCEPTION_NOT_FOUND_ERR);
        return JS_FALSE;
    }

    webgear_element_remove_attribute(xsself, xsattribute);
    
    *rval = argv[0];
    return JS_TRUE;  
}
   
/* webgear_js_dom_core_element_attachShadow
   webgear_js_dom_core_element_closest
   webgear_js_dom_core_element_matches */

static JSBool
webgear_js_dom_core_element_getElementsByTagName(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSObject        *jshtmlcollection;
    JSString        *jsstring;
    IHTMLCollection *htmlcollectionhead, *htmlcollection;
    HV              *xsself;
    char            *data, *name;
    int              namelength, searchtype;
    
    if (!argc) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }
    
    if (!JSVAL_IS_STRING(argv[0])) {
        webgear_js_exeption(cx, EXCEPTION_ILLEGAL_ARGUMENT_ERR);
        return JS_FALSE;
    }

    jsstring   = JS_ValueToString(cx, argv[0]); 
    data       = JS_GetStringBytes(jsstring);
    namelength = strlen(data);
    name       = webgear_element_normalize_name(data, namelength);

    if (!name) {
        webgear_js_exeption(cx, EXCEPTION_INVALID_CHARACTER_ERR);
        return JS_FALSE;
    }

    xsself             = JS_GetPrivate(cx, obj);
    
    htmlcollectionhead = webgear_xs_hv_get_iv(xsself, LITERAL("livehtmlcollections"));
    htmlcollection     = htmlcollectionhead; 
    
    while (htmlcollection) {
        
        if (htmlcollection->searchtype != COLLECTION_SEARCH_BY_CLASSNAME &&
            webgear_data_are_equal(htmlcollection->name, htmlcollection->namelength, name, namelength)) {
            *rval = OBJECT_TO_JSVAL(htmlcollection->jsobject);
            return JS_TRUE;
        }

        htmlcollection = htmlcollection->next;
    }

    jshtmlcollection = JS_NewObject(cx, &webgear_js_dom_collections_htmlcollection, NULL, NULL);
    
    if (namelength == 1 && name[0] == '*') {
        searchtype = COLLECTION_SEARCH_ALL;
    } else {
        searchtype = COLLECTION_SEARCH_BY_TAGNAME;
    }
    
    htmlcollection = webgear_htmlcollection_create(jshtmlcollection, NULL, htmlcollectionhead, xsself, searchtype, name, namelength);
    
    if (htmlcollectionhead) {  
        htmlcollectionhead->previous = htmlcollection;
    } 
    
    webgear_xs_hv_set_iv(xsself, LITERAL("livehtmlcollections"), htmlcollection);
    JS_SetPrivate(cx, jshtmlcollection, htmlcollection);

    *rval = OBJECT_TO_JSVAL(jshtmlcollection);
    return JS_TRUE;
}

/* webgear_js_dom_core_element_getElementsByTagNameNS
   webgear_js_dom_core_element_getElementsByClassName */
 
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
 Позиции:
 
 <!-- "beforebegin" -->
   <p>
     <!-- "afterbegin" -->
     foo
     <!-- "beforeend" -->
   </p>
 <!-- "afterend" --> 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
static JSBool   
webgear_js_dom_core_element_insertAdjacentHTML(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{ 
    JSString *jsstring;
    HV       *xsself, *xsparent, *xsinbuffer, *xsdocument, *xsplcontext, *xshtml, *xsfirstchild, *xslastchild;  
    char     *position, *data, *name;
    int       positionlength, datalength, namelength, positionid, id;
    
    if (argc < 2) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }

    jsstring       = JS_ValueToString(cx, argv[0]); 
    position       = JS_GetStringBytes(jsstring);
    positionlength = strlen(position);
    
    if (!strcmp("beforebegin", position)) {
        positionid = 1;
    } else if (!strcmp("afterend", position)) {
        positionid = 2;
    } else if (!strcmp("afterbegin", position)) {
        positionid = 3;
    } else if (!strcmp("beforeend", position)) {
        positionid = 4;
    } else {
        webgear_js_exeption(cx, EXCEPTION_SYNTAX_ERR);
        return JS_FALSE; 
    }
    
    xsself = JS_GetPrivate(cx, obj);
    /* xsparent является контекстным элементом. */
    if (positionid <= 2) {
        xsparent = webgear_xs_hv_get_rv(xsself, LITERAL("parent"));
        
        if (!xsparent || webgear_xs_hv_get_iv(xsparent, LITERAL("type")) == NODE_TYPE_DOCUMENT) {
            webgear_js_exeption(cx, EXCEPTION_NO_MODIFICATION_ALLOWED_ERR);
            return JS_FALSE;
        }
        
    } else {
        xsparent = xsself;
        
        if (positionid == 3) {
            xsself = webgear_xs_hv_get_rv(xsself, LITERAL("firstchild"));
        } else {
            xsself = webgear_xs_hv_get_rv(xsself, LITERAL("lastchild"));
        }
    } 
        
    name       = webgear_xs_hv_get_pv(xsparent, LITERAL("name")); 
    namelength = webgear_xs_hv_get_iv(xsparent, LITERAL("namelength"));

    if (webgear_data_are_equal(LITERAL("HTML"), name, namelength)) {    
        id       = webgear_element_name_to_id(LITERAL("BODY"));    
        xsparent = webgear_node_create_element(NULL, 0, id, NULL, 0);
    } 
    
    jsstring   = JS_ValueToString(cx, argv[1]);
    data       = JS_GetStringBytes(jsstring);
    datalength = strlen(data);
    /* Нулевая строка не обрабатывается и не генерирует исключение. */
    if (!datalength) {
        return JS_TRUE;
    }
    
    xsinbuffer = webgear_inbuffer_create(data, datalength);
    xsdocument = webgear_node_create_document(NULL);    

    dSP;
    PUSHMARK(SP);
    XPUSHs(newRV_noinc(xsinbuffer));
    XPUSHs(newRV_noinc(xsdocument));
    XPUSHs(sv_2mortal(newSViv(0)));
    PUTBACK;
    call_pv("parser_initialize_context", G_SCALAR);
    SPAGAIN;

    xsplcontext = SvRV(POPs);

    PUSHMARK(SP);
    XPUSHs(newRV_noinc(xsplcontext));
    XPUSHs(newRV_noinc(xsparent));
    PUTBACK;
    call_pv("parser_fragment", G_DISCARD);

    xshtml       = webgear_xs_hv_get_rv(xsdocument, LITERAL("html"));    
    xsfirstchild = webgear_xs_hv_get_rv(xshtml, LITERAL("firstchild"));
    xslastchild  = webgear_xs_hv_get_rv(xshtml, LITERAL("lastchild"));

    if (xsfirstchild) {
    
        if (positionid == 1 || positionid == 3) { /* "beforebegin", "afterbegin" */
            webgear_nodes_insert_before(xsparent, xsself, xsfirstchild, xslastchild);
        } else {                                  /* "afterend", "beforeend" */
            webgear_nodes_insert_after(xsparent, xsself, xsfirstchild, xslastchild);
        } 
    }
    
    return JS_TRUE;
}

static JSFunctionSpec
webgear_js_dom_core_element_functions[] = {
 /* {"hasAttributes",          webgear_js_dom_core_element_hasAttributes,          0},
    {"getAttributeNames",      webgear_js_dom_core_element_getAttributeNames,      0}, */
    {"getAttribute",           webgear_js_dom_core_element_getAttribute,           1},
 /* {"getAttributeNS",         webgear_js_dom_core_element_getAttributeNS,         2}, */
    {"setAttribute",           webgear_js_dom_core_element_setAttribute,           2},
 /* {"setAttributeNS",         webgear_js_dom_core_element_setAttributeNS,         3}, */
    {"removeAttribute",        webgear_js_dom_core_element_removeAttribute,        1},
 /* {"removeAttributeNS",      webgear_js_dom_core_element_removeAttributeNS,      2},
    {"hasAttribute",           webgear_js_dom_core_element_hasAttribute,           1},
    {"hasAttributeNS",         webgear_js_dom_core_element_hasAttributeNS,         2}, */
    {"getAttributeNode",       webgear_js_dom_core_element_getAttributeNode,       1},
 /* {"getAttributeNodeNS",     webgear_js_dom_core_element_getAttributeNodeNS,     2}, */
    {"setAttributeNode",       webgear_js_dom_core_element_setAttributeNode,       1},
 /* {"setAttributeNodeNS",     webgear_js_dom_core_element_setAttributeNodeNS,     1}, */
    {"removeAttributeNode",    webgear_js_dom_core_element_removeAttributeNode,    1},
 /* {"attachShadow",           webgear_js_dom_core_element_attachShadow,           1},
    {"closest",                webgear_js_dom_core_element_closest,                1},
    {"matches",                webgear_js_dom_core_element_matches,                1}, */
    {"getElementsByTagName",   webgear_js_dom_core_element_getElementsByTagName,   1},
 /* {"getElementsByTagNameNS", webgear_js_dom_core_element_getElementsByTagNameNS, 2},
    {"getElementsByClassName", webgear_js_dom_core_element_getElementsByClassName, 1}, */
    {"insertAdjacentHTML",     webgear_js_dom_core_element_insertAdjacentHTML,     2},
    {0}
};

/*----- Свойства ---------------------------------------------------------------
------------------------------------------------------------------------------*/

static JSBool
webgear_js_dom_core_element_getter(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
    JSString *jsstring;
    HV       *xsself;
    char     *name, *data;
    int       tinyid, namelength;
    
    tinyid = JSVAL_TO_INT(id);
    
    if (tinyid <= 11) {
        xsself = JS_GetPrivate(cx, obj);
            
        if (tinyid == 3) {
            name       = webgear_xs_hv_get_pv(xsself, LITERAL("name"));
            namelength = webgear_xs_hv_get_iv(xsself, LITERAL("namelength"));
            jsstring   = JS_NewStringCopyN(cx, name, namelength);
        } else  {
            /* $element, $outermode */
            dSP;
            PUSHMARK(SP);
            XPUSHs(newRV_noinc(xsself));
            XPUSHs(sv_2mortal(newSViv(tinyid == 10 ? 0 : 1)));
            PUTBACK;
            call_pv("element_serialize", G_SCALAR);
            SPAGAIN;
            
            data     = POPp;
            jsstring = JS_NewStringCopyZ(cx, data);
        }
        
        *vp = STRING_TO_JSVAL(jsstring);
    }
    
    return JS_TRUE;
}

static JSBool
webgear_js_dom_core_element_setter(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
    JSString *jsstring;
    HV       *xsinbuffer, *xsdocument, *xsplcontext, *xsself, *xsparent,
             *xsprevioussibling, *xshtml, *xsfirstchild, *xslastchild;
    char     *data;
    int       tinyid, datalength;

    tinyid = JSVAL_TO_INT(id);

    if (tinyid <= 11) {
        xsself = JS_GetPrivate(cx, obj);

        if (tinyid == 11) {
            xsparent = webgear_xs_hv_get_rv(xsself, LITERAL("parent"));
        
            if (!xsparent || webgear_xs_hv_get_iv(xsparent, LITERAL("type")) == NODE_TYPE_DOCUMENT) {
                webgear_js_exeption(cx, EXCEPTION_NO_MODIFICATION_ALLOWED_ERR);
                return JS_FALSE;
            }
            
            xsprevioussibling = webgear_xs_hv_get_rv(xsself, LITERAL("previoussibling"));
            /* Узел удаляется в любом случае. */
            webgear_node_remove(xsparent, xsself);
        } 
        
        jsstring   = JS_ValueToString(cx, *vp);
        data       = JS_GetStringBytes(jsstring);
        datalength = strlen(data);
        
        if (!datalength) {
            
            if (tinyid == 10) {
                webgear_xs_hv_set_rv(xsself, LITERAL("firstchild"), NULL);
                webgear_xs_hv_set_rv(xsself, LITERAL("lastchild"), NULL);
            }

            return JS_TRUE;
        }
        
        xsinbuffer = webgear_inbuffer_create(data, datalength);
        xsdocument = webgear_node_create_document(NULL);    

        dSP;
        PUSHMARK(SP);
        XPUSHs(newRV_noinc(xsinbuffer));
        XPUSHs(newRV_noinc(xsdocument));
        XPUSHs(sv_2mortal(newSViv(0)));
        PUTBACK;
        call_pv("parser_initialize_context", G_SCALAR);
        SPAGAIN;

        xsplcontext = SvRV(POPs);

        PUSHMARK(SP);
        XPUSHs(newRV_noinc(xsplcontext));
        XPUSHs(newRV_noinc(xsself));
        PUTBACK;
        call_pv("parser_fragment", G_DISCARD);

        xshtml       = webgear_xs_hv_get_rv(xsdocument, LITERAL("html"));    
        xsfirstchild = webgear_xs_hv_get_rv(xshtml, LITERAL("firstchild"));
        xslastchild  = webgear_xs_hv_get_rv(xshtml, LITERAL("lastchild"));

        if (xsfirstchild) {

            if (tinyid == 11) {
                webgear_nodes_insert_after(xsparent, xsprevioussibling, xsfirstchild, xslastchild);
            } else {
                webgear_nodes_replace(xsself, xsfirstchild, xslastchild);
            }

        } else if (tinyid == 10) {
            webgear_nodes_replace(xsself, NULL, NULL);
        }
    }

    return JS_TRUE; 
}

static JSPropertySpec
webgear_js_dom_core_element_properties[] = {
 /* {"namespaceURI",  0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"prefix",        1, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"localName",     2, JSPROP_ENUMERATE | JSPROP_READONLY}, */
    {"tagName",       3, JSPROP_ENUMERATE | JSPROP_READONLY},
 /* {"id",            4, JSPROP_ENUMERATE},
    {"className",     5, JSPROP_ENUMERATE},
    {"classList",     6, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"slot",          7, JSPROP_ENUMERATE},
    {"attributes",    8, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"shadowRoot",    9, JSPROP_ENUMERATE | JSPROP_READONLY}, */
    {"innerHTML",    10, JSPROP_ENUMERATE},
    {"outerHTML",    11, JSPROP_ENUMERATE},
    {0}
};

/*----- Определение класса -----------------------------------------------------
------------------------------------------------------------------------------*/

static JSClass
webgear_js_dom_core_element = {
    "Element",
    JSCLASS_HAS_PRIVATE,
    JS_PropertyStub,
    JS_PropertyStub,
    webgear_js_dom_core_element_getter,
    webgear_js_dom_core_element_setter,
    JS_EnumerateStub,
    JS_ResolveStub,
    JS_ConvertStub,
    JS_FinalizeStub
};

#endif