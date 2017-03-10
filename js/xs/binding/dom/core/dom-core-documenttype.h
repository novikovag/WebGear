/*==============================================================================
        Interface DocumentType

 https://dom.spec.whatwg.org/#documenttype
 https://www.w3.org/TR/2003/WD-DOM-Level-3-Core-20030226/DOM3-Core.html#core-ID-412266927
==============================================================================*/

#ifndef _webgear_js_dom_core_documenttype_h
#define _webgear_js_dom_core_documenttype_h

/*----- Свойства ---------------------------------------------------------------
------------------------------------------------------------------------------*/

static JSBool
webgear_js_dom_core_documenttype_getter(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
    JSString *jsstring;
    HV       *xsself;
    char     *name, *public, *system;
    int       tinyid, namelength, publiclength, systemlength;

    tinyid = JSVAL_TO_INT(id);
    
    if (tinyid > 2) {
        return JS_TRUE;
    }
    
    xsself = JS_GetPrivate(cx, obj);

    if (!tinyid) {
        name         = webgear_xs_hv_get_pv(xsself, LITERAL("name"));
        namelength   = webgear_xs_hv_get_iv(xsself, LITERAL("namelength"));
        jsstring     = JS_NewStringCopyN(cx, name, namelength);
    } else if (tinyid == 1) {
        public       = webgear_xs_hv_get_pv(xsself, LITERAL("public"));
        publiclength = webgear_xs_hv_get_iv(xsself, LITERAL("publiclength"));
        jsstring     = JS_NewStringCopyN(cx, name, namelength);
    } else {
        system       = webgear_xs_hv_get_pv(xsself, LITERAL("system"));
        systemlength = webgear_xs_hv_get_iv(xsself, LITERAL("systemlength"));
        jsstring     = JS_NewStringCopyN(cx, system, systemlength);
    }
    
    *vp = STRING_TO_JSVAL(jsstring);
    return JS_TRUE;
}

static JSPropertySpec
webgear_js_dom_core_documenttype_properties[] = {
    {"name",     0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"publicId", 1, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"systemId", 2, JSPROP_ENUMERATE | JSPROP_READONLY},
    {0}
};

/*----- Определение класса -----------------------------------------------------
------------------------------------------------------------------------------*/

static JSClass 
webgear_js_dom_core_documenttype = {
    "DocumentType",
    JSCLASS_HAS_PRIVATE,
    JS_PropertyStub,
    JS_PropertyStub,
    webgear_js_dom_core_documenttype_getter,
    JS_PropertyStub,
    JS_EnumerateStub,
    JS_ResolveStub,
    JS_ConvertStub,
    JS_FinalizeStub
};

#endif