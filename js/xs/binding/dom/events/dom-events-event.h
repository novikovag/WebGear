/*==============================================================================
        Interface Event
        
 https://dom.spec.whatwg.org/#interface-event
 https://www.w3.org/TR/DOM-Level-2-Events/events.html#Events-interface)
==============================================================================*/

#ifndef _webgear_js_dom_events_event_h
#define _webgear_js_dom_events_event_h

/*----- Методы -----------------------------------------------------------------
------------------------------------------------------------------------------*/

/* webgear_js_dom_events_event_composedPath */

static JSBool
webgear_js_dom_events_event_stopPropagation(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    IEvent *event;

    event = JS_GetPrivate(cx, obj);

    event->flagstoppropagation = true;
    return JS_TRUE;
}

static JSBool
webgear_js_dom_events_event_stopImmediatePropagation(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    IEvent *event;

    event = JS_GetPrivate(cx, obj);

    event->flagstoppropagation          = true;
    event->flagstopimmediatepropagation = true;
    return JS_TRUE;
}

static JSBool
webgear_js_dom_events_event_preventDefault(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    IEvent *event;

    event = JS_GetPrivate(cx, obj);
    /* Без проверки на in passive listener flag. */
    if (event->iscancelable) { 
        event->flagcanceled = true;
    }
    
    return JS_TRUE;
}

static JSFunctionSpec
webgear_js_dom_events_event_functions[] = {
 /* {"composedPath",             webgear_js_dom_events_event_composedPath,             0}, */
    {"stopPropagation",          webgear_js_dom_events_event_stopPropagation,          0},
    {"stopImmediatePropagation", webgear_js_dom_events_event_stopImmediatePropagation, 0},
    {"preventDefault",           webgear_js_dom_events_event_preventDefault,           0},
    {0}
};

/*----- Свойства ---------------------------------------------------------------
------------------------------------------------------------------------------*/

static JSBool
webgear_js_dom_events_event_getter(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
    JSString *jsstring;
    IEvent   *event;
    double   *timestamp;
    int       tinyid;
 
    tinyid = JSVAL_TO_INT(id);
    
    if (tinyid > 13) {
        return JS_TRUE;
    }

    if (tinyid <= 3) {
        *vp = INT_TO_JSVAL(tinyid);
    } else {
        event  = JS_GetPrivate(cx, obj);
    
        switch (tinyid) {
            case 4:
                jsstring = JS_NewStringCopyN(cx, event->type, event->typelength);
                *vp = STRING_TO_JSVAL(jsstring);
                break;
            case 5:
                *vp = OBJECT_TO_JSVAL(event->target);
                break;
            case 6:
                *vp = OBJECT_TO_JSVAL(event->currenttarget);
                break;
            case 7:
                *vp = INT_TO_JSVAL(event->eventphase);
                break;
            case 8:
                *vp = BOOLEAN_TO_JSVAL(event->isbubbles);
                break;
            case 9:
                *vp = BOOLEAN_TO_JSVAL(event->iscancelable);
                break;
            case 10:
                *vp = BOOLEAN_TO_JSVAL(event->flagcanceled);
                break;
            case 13:
                timestamp = JS_NewDouble(cx, event->timestamp);
                *vp       = DOUBLE_TO_JSVAL(timestamp);
                break;
        }
    }

    return JS_TRUE;
}

static JSPropertySpec
webgear_js_dom_events_event_properties[] = {
    {"NONE",              0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"CAPTURING_PHASE",   1, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"AT_TARGET",         2, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"BUBBLING_PHASE",    3, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"type",              4, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"target",            5, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"currentTarget",     6, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"eventPhase",        7, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"bubbles",           8, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"cancelable",        9, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"defaultPrevented", 10, JSPROP_ENUMERATE | JSPROP_READONLY},
 /* {"composed",         11, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"isTrusted",        12, JSPROP_ENUMERATE | JSPROP_READONLY}, */
    {"timeStamp",        13, JSPROP_ENUMERATE | JSPROP_READONLY},
    {0}
};

/*----- Конструктор ------------------------------------------------------------
------------------------------------------------------------------------------*/

static JSBool
webgear_js_dom_events_event_constructor(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSObject *jsevent;
    JSString *jsstring;
    jsval     jsvalue;
    IEvent   *event;
    char     *type;
    int       isbubbles, iscancelable, typelength;
    
    if (!argc) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }

    if (!JSVAL_IS_STRING(argv[0])) {
        webgear_js_exeption(cx, EXCEPTION_ILLEGAL_ARGUMENT_ERR);
        return JS_FALSE;
    }
    
    if (argc > 1 && JSVAL_IS_OBJECT(argv[1])) {
        JS_GetProperty(cx, argv[1], "bubbles", &jsvalue);
        JS_ValueToBoolean(cx, jsvalue, &isbubbles);
        
        JS_GetProperty(cx, argv[1], "cancelable", &jsvalue);
        JS_ValueToBoolean(cx, jsvalue, &iscancelable);
    } else {
        isbubbles    = 0;
        iscancelable = 0;
    }
    
    jsstring   = JS_ValueToString(cx, argv[0]); 
    type       = JS_GetStringBytes(jsstring);
    typelength = strlen(type);
    event      = webgear_event_create(type, typelength, isbubbles, iscancelable);

    jsevent = JS_NewObject(cx, &webgear_js_dom_events_event, NULL, NULL);
    JS_SetPrivate(cx, jsevent, event);

    *rval = OBJECT_TO_JSVAL(jsevent);
    return JS_TRUE;
}

/*----- Деструктор -------------------------------------------------------------
------------------------------------------------------------------------------*/

static JSBool
webgear_js_dom_events_event_destructor(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    IEvent *event;

    event = JS_GetPrivate(cx, obj);

    if (event) {
        webgear_xs_free(event->type);
        webgear_xs_free(event);
    }
}

/*----- Определение класса -----------------------------------------------------
------------------------------------------------------------------------------*/

static JSClass
webgear_js_dom_events_event = {
    "Event",
    JSCLASS_HAS_PRIVATE,
    JS_PropertyStub,
    JS_PropertyStub,
    webgear_js_dom_events_event_getter,
    JS_PropertyStub,
    JS_EnumerateStub,
    JS_ResolveStub,
    JS_ConvertStub,
    webgear_js_dom_events_event_destructor
};

#endif