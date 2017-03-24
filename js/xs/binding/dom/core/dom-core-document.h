/*==============================================================================
        Interface Document

 https://dom.spec.whatwg.org/#interface-document
 https://www.w3.org/TR/2003/WD-DOM-Level-3-Core-20030226/DOM3-Core.html#core-i-Document
==============================================================================*/

#ifndef _webgear_js_dom_core_document_h
#define _webgear_js_dom_core_document_h

/*----- Методы -----------------------------------------------------------------
------------------------------------------------------------------------------*/

static JSBool
webgear_js_dom_core_document_getElementsByTagName(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSObject *jsself;
    HV       *xsself;

    xsself = JS_GetPrivate(cx, obj);
    jsself = webgear_xs_hv_get_iv(xsself, LITERAL("object"));

    return webgear_js_dom_core_element_getElementsByTagName(cx, jsself, argc, argv, rval);
}

/* webgear_js_dom_core_document_getElementsByTagNameNS
   webgear_js_dom_core_document_getElementsByClassName */

static JSBool
webgear_js_dom_core_document_createElement(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSObject *jselement;
    JSString *jsstring;
    HV       *xselement;
    char     *data, *name;
    int       namelength, id;

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

    id = webgear_element_name_to_id(name, namelength);

    jselement = JS_NewObject(cx, &webgear_js_dom_core_element, NULL, NULL);
    xselement = webgear_node_create_element(jselement, 0, id, name, namelength);
    JS_SetPrivate(cx, jselement, xselement);

    webgear_xs_free(name);

    *rval = OBJECT_TO_JSVAL(jselement);
    return JS_TRUE;
}

/* webgear_js_dom_core_document_createElementNS
   webgear_js_dom_core_document_createDocumentFragment */

static JSBool
webgear_js_dom_core_document_createTextNode(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    return webgear_js_dom_core_text_constructor(cx, obj, argc, argv, rval);
}

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 CDATASection не поддерживается в HTML, создание объекта должно вызывать исключение.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
static JSBool
webgear_js_dom_core_document_createCDATASection(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    webgear_js_exeption(cx, EXCEPTION_NOT_SUPPORTED_ERR);
    return JS_FALSE;
}

static JSBool
webgear_js_dom_core_document_createComment(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    return webgear_js_dom_core_comment_constructor(cx, obj, argc, argv, rval);
}

/* webgear_js_dom_core_document_createProcessingInstruction
   webgear_js_dom_core_document_importNode
   webgear_js_dom_core_document_adoptNode */

static JSBool
webgear_js_dom_core_document_createAttribute(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSObject *jsattribute;
    JSString *jsstring;
    HV       *xsattribute;
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

    if (!name) {
        webgear_js_exeption(cx, EXCEPTION_INVALID_CHARACTER_ERR);
        return JS_FALSE;
    }

    jsattribute = JS_NewObject(cx, &webgear_js_dom_core_attribute, NULL, NULL);
    xsattribute = webgear_node_create_attribute(jsattribute, 0, name, namelength, NULL, 0);
    JS_SetPrivate(cx, jsattribute, xsattribute);

    webgear_xs_free(name);

    *rval = OBJECT_TO_JSVAL(jsattribute);
    return JS_TRUE;
}

/* webgear_js_dom_core_document_createAttributeNS
   webgear_js_dom_core_document_createEvent
   webgear_js_dom_core_document_createRange
   webgear_js_dom_core_document_createNodeIterator
   webgear_js_dom_core_document_createTreeWalker */

static JSBool
webgear_js_dom_core_document_getElementById(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSObject *jselement;
    JSString *jsstring;
    HV       *xsself, *xsnode, *xsnextnode, *xsattribute;
    char     *data, *value;
    int       datalength, valuelength;

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
    datalength = strlen(data);

    xsself     = JS_GetPrivate(cx, obj);
    xsnode     = webgear_xs_hv_get_rv(xsself, LITERAL("firstchild"));

    while (xsnode) {

        if (webgear_xs_hv_get_iv(xsnode, LITERAL("type")) == NODE_TYPE_ELEMENT) {
            xsattribute = webgear_element_search_attribute(xsnode, LITERAL("id"));

            if (xsattribute) { 
                value       = webgear_xs_hv_get_pv(xsattribute, LITERAL("value"));
                valuelength = webgear_xs_hv_get_iv(xsattribute, LITERAL("valuelength"));
            
                if (webgear_data_are_equal(data, datalength, value, valuelength)) {                        
                    jselement = webgear_xs_hv_get_iv(xsnode, LITERAL("object"));

                    if (!jselement) {
                        jselement = JS_NewObject(cx, &webgear_js_dom_core_element, NULL, NULL);
                        webgear_xs_hv_set_iv(xsnode, LITERAL("object"), jselement);
                        JS_SetPrivate(cx, jselement, xsnode);
                    }

                    *rval = OBJECT_TO_JSVAL(jselement);
                    return JS_TRUE;
                }
            }

            xsnextnode = webgear_xs_hv_get_rv(xsnode, LITERAL("firstchild"));

            if (xsnextnode) {
                xsnode = xsnextnode;
                continue;
            }
        }
    L:
        xsnextnode = webgear_xs_hv_get_rv(xsnode, LITERAL("nextsibling"));

        if (xsnextnode) {
            xsnode = xsnextnode;
            continue;
        }

        if (xsnode == xsself) {
            break;
        }

        if (xsnode = webgear_xs_hv_get_rv(xsnode, LITERAL("parent"))) {
            goto L;
        }
    }

    *rval = JSVAL_NULL;
    return JS_TRUE;
}

/* webgear_js_dom_core_document_getElementsByName
   webgear_js_dom_core_document_open
   webgear_js_dom_core_document_close */

static JSBool
webgear_js_dom_core_document_write(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSString  *jsstring;
    IGlobal   *global;
    AV        *xsbufferdata;
    char      *data;
    int        index, datalength, byte, bufferindex, sourceindex, destinationindex;

    if (!argc) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }
    
    jsstring   = JS_ValueToString(cx, argv[0]); 
    data       = JS_GetStringBytes(jsstring);
    datalength = strlen(data);

    global = JS_GetContextPrivate(cx);
    /* Индексы будут скорректированы на единицу при входе в цикл. */
    sourceindex      = webgear_xs_hv_get_iv(global->xsinbuffer, LITERAL("datalength"));
    destinationindex = sourceindex + datalength;

    webgear_xs_hv_set_iv(global->xsinbuffer, LITERAL("datalength"), destinationindex);
    
    bufferindex  = webgear_xs_hv_get_iv(global->xsinbuffer, LITERAL("index"));
    xsbufferdata = webgear_xs_hv_get_rv(global->xsinbuffer, LITERAL("data"));
    
    while (sourceindex >= bufferindex) {
        sourceindex--;
        destinationindex--;

        byte = webgear_xs_av_get_iv(xsbufferdata, sourceindex);
        /* Массив будет расширен автоматически. */
        webgear_xs_av_set_iv(xsbufferdata, destinationindex, byte);
    }
    
    for (index = 0; index < datalength; index++) {
        webgear_xs_av_set_iv(xsbufferdata, bufferindex++, data[index]);
    }  
    
    return JS_TRUE;
}

static JSBool
webgear_js_dom_core_document_writeln(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSString *jswholestring, *jsstring;
    
    if (!argc) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }
    
    jswholestring = JS_ValueToString(cx, argv[0]);
    jsstring      = JS_NewStringCopyN(cx, LITERAL("\n"));
    jswholestring = JS_ConcatStrings(cx, jswholestring, jsstring);
    
    argv[0] = STRING_TO_JSVAL(jswholestring);
 
    return webgear_js_dom_core_document_write(cx, obj, argc, argv, rval);
}

/* webgear_js_dom_core_document_hasFocus
   webgear_js_dom_core_document_execCommand
   webgear_js_dom_core_document_queryCommandEnabled
   webgear_js_dom_core_document_queryCommandIndeterm
   webgear_js_dom_core_document_queryCommandState
   webgear_js_dom_core_document_queryCommandSupported
   webgear_js_dom_core_document_queryCommandValue */

static JSFunctionSpec
webgear_js_dom_core_document_functions[] = {
    {"getElementsByTagName",        webgear_js_dom_core_document_getElementsByTagName,        1},
 /* {"getElementsByTagNameNS",      webgear_js_dom_core_document_getElementsByTagNameNS,      2},
    {"getElementsByClassName",      webgear_js_dom_core_document_getElementsByClassName,      1}, */
    {"createElement",               webgear_js_dom_core_document_createElement,               2},
 /* {"createElementNS",             webgear_js_dom_core_document_createElementNS,             3},
    {"createDocumentFragment",      webgear_js_dom_core_document_createDocumentFragment,      0}, */
    {"createTextNode",              webgear_js_dom_core_document_createTextNode,              1},
    {"createCDATASection",          webgear_js_dom_core_document_createCDATASection,          1},
    {"createComment",               webgear_js_dom_core_document_createComment,               1},
 /* {"createProcessingInstruction", webgear_js_dom_core_document_createProcessingInstruction, 2},
    {"importNode",                  webgear_js_dom_core_document_importNode,                  2},
    {"adoptNode",                   webgear_js_dom_core_document_adoptNode,                   1}, */
    {"createAttribute",             webgear_js_dom_core_document_createAttribute,             1},
 /* {"createAttributeNS",           webgear_js_dom_core_document_createAttributeNS,           2},
    {"createEvent",                 webgear_js_dom_core_document_createEvent,                 1},
    {"createRange",                 webgear_js_dom_core_document_createRange,                 0},
    {"createNodeIterator",          webgear_js_dom_core_document_createNodeIterator,          3},
    {"createTreeWalker",            webgear_js_dom_core_document_createTreeWalker,            3}, */
    {"getElementById",              webgear_js_dom_core_document_getElementById,              1},
 /* {"getElementsByName",           webgear_js_dom_core_document_getElementsByName,           1},
    {"open",                        webgear_js_dom_core_document_open,                        3},
    {"close",                       webgear_js_dom_core_document_close,                       0}, */
    {"write",                       webgear_js_dom_core_document_write,                       1},
    {"writeln",                     webgear_js_dom_core_document_writeln,                     1},
 /* {"hasFocus",                    webgear_js_dom_core_document_hasFocus,                    0},
    {"execCommand",                 webgear_js_dom_core_document_execCommand,                 3},
    {"queryCommandEnabled",         webgear_js_dom_core_document_queryCommandEnabled,         1},
    {"queryCommandIndeterm",        webgear_js_dom_core_document_queryCommandIndeterm,        1},
    {"queryCommandState",           webgear_js_dom_core_document_queryCommandState,           1},
    {"queryCommandSupported",       webgear_js_dom_core_document_queryCommandSupported,       1},
    {"queryCommandValue",           webgear_js_dom_core_document_queryCommandValue,           1}, */
    {0}
};

/*----- Свойства ---------------------------------------------------------------
------------------------------------------------------------------------------*/

static JSBool
webgear_js_dom_core_document_getter(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
    JSObject *jsdomimplementation, *jsnode;
    HV       *xsself, *xscontext, *xsnode;
    int       tinyid;

    tinyid = JSVAL_TO_INT(id);

    if (!tinyid) {
        jsdomimplementation = JS_NewObject(cx, &webgear_js_dom_core_domimplementation, NULL, NULL);
        *vp = OBJECT_TO_JSVAL(jsdomimplementation);
    } else if (tinyid <= 10) {
        xsself = JS_GetPrivate(cx, obj);

        if (tinyid == 9) {
            xsnode = webgear_xs_hv_get_iv(xsself, LITERAL("documenttype"));
        } else {
            xsnode = webgear_xs_hv_get_iv(xsself, LITERAL("html"));
        }

        if (xsnode) {
            jsnode = webgear_xs_hv_get_iv(xsnode, LITERAL("object"));

            if (!jsnode) {

                if (tinyid == 9) {
                    jsnode = JS_NewObject(cx, &webgear_js_dom_core_documenttype, NULL, NULL);
                } else {
                    jsnode = JS_NewObject(cx, &webgear_js_dom_core_element, NULL, NULL);
                }

                webgear_xs_hv_set_iv(xsnode, LITERAL("object"), jsnode);
                JS_SetPrivate(cx, jsnode, xsnode);
            }

            *vp = OBJECT_TO_JSVAL(jsnode);
        } else {
            *vp = JSVAL_NULL;
        }
    }

    return JS_TRUE;
}

static JSPropertySpec
webgear_js_dom_core_document_properties[] = {
    {"implementation",      0, JSPROP_ENUMERATE | JSPROP_READONLY},
 /* {"URL",                 1, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"documentURI",         2, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"origin",              3, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"compatMode",          4, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"characterSet",        5, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"charset",             6, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"inputEncoding",       7, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"contentType",         8, JSPROP_ENUMERATE | JSPROP_READONLY}, */
    {"doctype",             9, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"documentElement",    10, JSPROP_ENUMERATE | JSPROP_READONLY},
 /* {"location",           11, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"domain",             12, JSPROP_ENUMERATE},
    {"referrer",           13, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"cookie",             14, JSPROP_ENUMERATE},
    {"lastModified",       15, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"readyState",         16, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"name",               17, JSPROP_ENUMERATE},
    {"title",              18, JSPROP_ENUMERATE}, 
    {"dir",                19, JSPROP_ENUMERATE},
    {"body",               20, JSPROP_ENUMERATE},
    {"head",               21, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"images",             22, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"embeds",             23, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"plugins",            24, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"links",              25, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"forms",              26, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"scripts",            27, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"currentScript",      28, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"defaultView",        29, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"ctiveElement",       30, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"designMode",         31, JSPROP_ENUMERATE},
    {"onreadystatechange", 32, JSPROP_ENUMERATE},                   */
    {0}
};

/*----- Определение класса -----------------------------------------------------
------------------------------------------------------------------------------*/

static JSClass
webgear_js_dom_core_document = {
    "Document",
    JSCLASS_HAS_PRIVATE,
    JS_PropertyStub,
    JS_PropertyStub,
    webgear_js_dom_core_document_getter,
    JS_PropertyStub,
    JS_EnumerateStub,
    JS_ResolveStub,
    JS_ConvertStub,
    JS_FinalizeStub
};

#endif