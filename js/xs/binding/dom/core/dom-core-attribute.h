/*==============================================================================
        Interface Attr

 https://dom.spec.whatwg.org/#interface-attr
 https://www.w3.org/TR/2003/WD-DOM-Level-3-Core-20030226/DOM3-Core.html#core-ID-637646024
==============================================================================*/

#ifndef _webgear_js_dom_core_attribute_h
#define _webgear_js_dom_core_attribute_h

/*----- Свойства ---------------------------------------------------------------
------------------------------------------------------------------------------*/

static JSBool
webgear_js_dom_core_attribute_getter(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
    JSObject *jselement;
    JSString *jsstring;
    HV       *xsself, *xselement; 
    char     *name, *value;
    int       tinyid, namelength, valuelength;

    tinyid = JSVAL_TO_INT(id);
    
    if (tinyid > 6) {
        return JS_TRUE;
    }
    
    xsself = JS_GetPrivate(cx, obj);

    switch (tinyid) {
        case 3:
            name        = webgear_xs_hv_get_pv(xsself, LITERAL("name"));
            namelength  = webgear_xs_hv_get_iv(xsself, LITERAL("namelength"));
            jsstring    = JS_NewStringCopyN(cx, name, namelength);
            
            *vp         = STRING_TO_JSVAL(jsstring);
            break;
        case 4:
            value       = webgear_xs_hv_get_pv(xsself, LITERAL("value"));
            valuelength = webgear_xs_hv_get_iv(xsself, LITERAL("valuelength"));
            jsstring    = JS_NewStringCopyN(cx, value, valuelength);
            
            *vp         = STRING_TO_JSVAL(jsstring);
            break;
        case 5:
            xselement = webgear_xs_hv_get_rv(xsself, LITERAL("element"));
            
            if (xselement) {
                jselement = webgear_xs_hv_get_iv(xselement, LITERAL("object"));
                
                if (!jselement) {
                    jselement = JS_NewObject(cx, &webgear_js_dom_core_element, NULL, NULL);
                    webgear_xs_hv_set_iv(xselement, LITERAL("object"), jselement);
                    JS_SetPrivate(cx, jselement, xselement);
                }
                
                *vp = OBJECT_TO_JSVAL(jselement);
            } else {
                *vp = JSVAL_NULL;
            }
            
            break;
    }
    
    return JS_TRUE;
}

static JSBool
webgear_js_dom_core_attribute_setter(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
    JSString *jsstring;
    HV       *xsself;
    char     *value;
    int       valuelength;
    
    if (JSVAL_TO_INT(id) == 4) {
        jsstring    = JS_ValueToString(cx, *vp); 
        value       = JS_GetStringBytes(jsstring);
        valuelength = strlen(value);
        
        xsself = JS_GetPrivate(cx, obj);
        
        webgear_xs_hv_set_pv(xsself, LITERAL("value"), value, valuelength);
        webgear_xs_hv_set_iv(xsself, LITERAL("valuelength"), valuelength);
    }
    
    return JS_TRUE;
}

static JSPropertySpec
webgear_js_dom_core_attribute_properties[] = {
 /* {"namespaceURI",  0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"prefix",        1, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"localName",     2, JSPROP_ENUMERATE | JSPROP_READONLY}, */
    {"name",          3, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"value",         4, JSPROP_ENUMERATE},
    {"ownerElement",  5, JSPROP_ENUMERATE | JSPROP_READONLY},
 /* {"specified",     6, JSPROP_ENUMERATE | JSPROP_READONLY}, */
    {0}
};

/*----- Определение класса -----------------------------------------------------
------------------------------------------------------------------------------*/

static JSClass
webgear_js_dom_core_attribute = {
    "Attr",
    JSCLASS_HAS_PRIVATE,
    JS_PropertyStub,
    JS_PropertyStub,
    webgear_js_dom_core_attribute_getter,
    webgear_js_dom_core_attribute_setter,
    JS_EnumerateStub,
    JS_ResolveStub,
    JS_ConvertStub,
    JS_FinalizeStub
};

#endif