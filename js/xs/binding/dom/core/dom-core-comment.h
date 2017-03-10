/*==============================================================================
        Interface Comment
 
 https://dom.spec.whatwg.org/#comment
 https://www.w3.org/TR/2003/WD-DOM-Level-3-Core-20030226/DOM3-Core.html#core-ID-1728279322
==============================================================================*/

#ifndef _webgear_js_dom_core_comment_h
#define _webgear_js_dom_core_comment_h

/*----- Конструктор ------------------------------------------------------------
------------------------------------------------------------------------------*/

static JSBool
webgear_js_dom_core_comment_constructor(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSObject *jscomment;
    JSString *jsstring;
    HV       *xscomment;
    char     *data;
    int       datalength;

    if (!argc) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }
    
    jsstring   = JS_ValueToString(cx, argv[0]); 
    data       = JS_GetStringBytes(jsstring);
    datalength = strlen(data);
    
    jscomment  = JS_NewObject(cx, &webgear_js_dom_core_comment, NULL, NULL);
    xscomment  = webgear_node_create_comment(jscomment, 0, data, datalength);
    JS_SetPrivate(cx, jscomment, xscomment);
 
    *rval = OBJECT_TO_JSVAL(jscomment);
    return JS_TRUE;
}

/*----- Определение класса -----------------------------------------------------
------------------------------------------------------------------------------*/

static JSClass 
webgear_js_dom_core_comment = {
    "Comment",
    JSCLASS_HAS_PRIVATE,
    JS_PropertyStub,
    JS_PropertyStub,
    JS_PropertyStub,
    JS_PropertyStub,
    JS_EnumerateStub,
    JS_ResolveStub,
    JS_ConvertStub,
    JS_FinalizeStub
};

#endif