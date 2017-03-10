/*==============================================================================
        Класс вывода
==============================================================================*/

#ifndef _js_console_h
#define _js_console_h

/*----- Методы -----------------------------------------------------------------
------------------------------------------------------------------------------*/

static JSBool
js_console_log(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSString *jswholestring, *jsstring;
    char     *data;
    int       index;

    jswholestring = JS_ValueToString(cx, argv[0]);

    for (index = 1; index < argc; index++) {
        jsstring      = JS_ValueToString(cx, argv[index]);
        jswholestring = JS_ConcatStrings(cx, jswholestring, jsstring);
    }

    data = JS_GetStringBytes(jswholestring);
    /* "js_console_log", $message */
    dSP;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv("js_console_log", 0)));
    XPUSHs(sv_2mortal(newSVpv(data, 0)));
    PUTBACK;

    call_pv("js_callback", G_DISCARD);
    return JS_TRUE;
}

static JSBool
js_console_tree(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    HV *xsnode;

    if (argc && JSVAL_IS_OBJECT(argv[0])                                    &&
       (JS_InstanceOf(cx, argv[0], &webgear_js_dom_core_document,     NULL) ||
        JS_InstanceOf(cx, argv[0], &webgear_js_dom_core_documenttype, NULL) ||
        JS_InstanceOf(cx, argv[0], &webgear_js_dom_core_element,      NULL) ||
        JS_InstanceOf(cx, argv[0], &webgear_js_dom_core_text,         NULL) ||
        JS_InstanceOf(cx, argv[0], &webgear_js_dom_core_comment,      NULL))) {
        xsnode = JS_GetPrivate(cx, argv[0]);
        /* "js_console_tree", $node */
        dSP;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv("js_console_tree", 0)));
        XPUSHs(newRV_noinc(xsnode));
        PUTBACK;

        call_pv("js_callback", G_DISCARD);
    }

    return JS_TRUE;
}

static JSFunctionSpec
js_console_functions[] = {
    {"log",  js_console_log,  1},
    {"tree", js_console_tree, 1},
    {0}
};

/*----- Определение класса -----------------------------------------------------
------------------------------------------------------------------------------*/

static JSClass
js_console = {
    "Console",
    JSCLASS_HAS_PRIVATE,
    JS_PropertyStub,
    JS_PropertyStub,
    JS_PropertyStub,
    JS_PropertyStub,
    JS_EnumerateStub,
    JS_ResolveStub,
    JS_ConvertStub,
    JS_FinalizeStub,
    {0}
};

#endif