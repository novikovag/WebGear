/*==============================================================================
        Interface EventTarget
 
 https://dom.spec.whatwg.org/#interface-eventtarget
 https://www.w3.org/TR/DOM-Level-2-Events/events.html#Events-EventTarget
 
  Списки фаз:                Порядок обхода:
 
 Capture Phase (1)          а) Capture Phase  - с хвоста.
                            б) Target Phase   - с головы.
      Bubbling Phase (3)    в) Bubbling Phase - с головы.
 
 * tail          tail *
 |                    |
 |                    |
 |                    |
 v head          head v
 
 head <----------* tail
 
    Target Phase (2)
 
 При текущем построении списков снизу вверх, обработчики родительских элементов
 фазы захвата добавляются в конец списка с сохранением последовательности в
 элементе:
 
 e1    -> head <- |c7, c8, c9| <- tail
 +-e2  -> head <- |c4, c5, c6| <- tail
   +e3 -> head <- |c1, c2, c3| <- tail
 
 список фазы захвата:
 
 tail -> |c7, c8, c9| -> |c4, c5, c6| -> |c1, c2, c3| -> head
 
 stopImmediatePropagation - немедленный выход из цикла.
 stopPropagation          - выполнение всех обработчиков событий текущего
                            элемента и выход из цикла.
 preventDefault           - отмена выполнения обработчика по умолчанию.
 
 В текущей реализации dispatch flag и initialized flag не используются, поэтому 
 dispatchEvent не генерирует исключение InvalidStateError.
==============================================================================*/

#ifndef _webgear_js_dom_events_eventtarget_h
#define _webgear_js_dom_events_eventtarget_h

/*----- Методы -----------------------------------------------------------------
------------------------------------------------------------------------------*/

static JSBool
webgear_js_dom_events_eventtarget_addEventListener(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSFunction *jscallback;
    JSString   *jsstring;
    HV         *xsself, *xsevent;
    char       *type, *function;
    int         usecapture, typelength, functionlength;

    if (argc < 2) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }

    if (!JS_InstanceOf(cx, obj, &webgear_js_dom_core_element, NULL)) {
        webgear_js_exeption(cx, EXCEPTION_INVALID_NODE_TYPE_ERR);
        return JS_FALSE;
    }

    if (!JSVAL_IS_STRING(argv[0])) {
        webgear_js_exeption(cx, EXCEPTION_ILLEGAL_ARGUMENT_ERR);
        return JS_FALSE;
    }
    
    jscallback = JS_ValueToFunction(cx, argv[1]);

    if (!jscallback) {
        webgear_js_exeption(cx, EXCEPTION_ILLEGAL_ARGUMENT_ERR);
        return JS_FALSE;
    }
    
    if (argc > 2) {
        JS_ValueToBoolean(cx, argv[2], &usecapture);
    } else {
        usecapture = 0;
    }

    xsself     = JS_GetPrivate(cx, obj);
    
    jsstring   = JS_ValueToString(cx, argv[0]); 
    type       = JS_GetStringBytes(jsstring);
    typelength = strlen(type);
    
    xsevent    = webgear_element_search_event(xsself, jscallback, usecapture, type, typelength);
    
    if (!xsevent) {
        jsstring       = JS_ValueToString(cx, argv[1]); 
        function       = JS_GetStringBytes(jsstring);
        functionlength = strlen(function);
        
        xsevent = webgear_node_create_event(jscallback, usecapture, 0, type, typelength, function, functionlength); 
        webgear_element_add_event(xsself, xsevent);
    }
    
    return JS_TRUE;
}

static JSBool
webgear_js_dom_events_eventtarget_removeEventListener(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSFunction *jscallback;
    JSString   *jsstring;
    HV         *xsself, *xsevent;
    char       *type;
    int         usecapture, typelength;      

    if (argc < 2) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }

    if (!JS_InstanceOf(cx, obj, &webgear_js_dom_core_element, NULL)) {
        webgear_js_exeption(cx, EXCEPTION_INVALID_NODE_TYPE_ERR);
        return JS_FALSE;
    }

    if (!JSVAL_IS_STRING(argv[0])) {
        webgear_js_exeption(cx, EXCEPTION_ILLEGAL_ARGUMENT_ERR);
        return JS_FALSE;
    }

    jscallback = JS_ValueToFunction(cx, argv[1]);

    if (!jscallback) {
        webgear_js_exeption(cx, EXCEPTION_ILLEGAL_ARGUMENT_ERR);
        return JS_FALSE;
    }

    if (argc > 2) {
        JS_ValueToBoolean(cx, argv[2], &usecapture);
    } else {
        usecapture = 0;
    }

    xsself     = JS_GetPrivate(cx, obj);
    
    jsstring   = JS_ValueToString(cx, argv[0]); 
    type       = JS_GetStringBytes(jsstring);
    typelength = strlen(type);
    
    xsevent    = webgear_element_search_event(xsself, jscallback, usecapture, type, typelength);
    
    if (xsevent) {
        webgear_element_remove_event(xsself, xsevent);
    }
    
    return JS_TRUE;
}

static JSBool
webgear_js_dom_events_eventtarget_dispatchEvent(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSContext  *jscontext;
    JSFunction *jscallback;
    HV         *xsself, *xselement, *xsevents, *xsevent, *xstempcapturehead, *xstempcapturetail,
               *xscapturetail, *xstargethead, *xstargettail, *xsbubblehead, *xsbubbletail;
    IEvent     *event;
    char       *function;
    int         functionlength;
    
    if (!argc) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }

    if (!JS_InstanceOf(cx, obj, &webgear_js_dom_core_element, NULL)) {
        webgear_js_exeption(cx, EXCEPTION_INVALID_NODE_TYPE_ERR);
        return JS_FALSE;
    }

    if (!JSVAL_IS_OBJECT(argv[0]) || !JS_InstanceOf(cx, argv[0], &webgear_js_dom_events_event, NULL)) {
        webgear_js_exeption(cx, EXCEPTION_ILLEGAL_ARGUMENT_ERR);
        return JS_FALSE;
    }

    xsself = JS_GetPrivate(cx, obj);
    event  = JS_GetPrivate(cx, argv[0]);
    
    event->target = webgear_xs_hv_get_iv(xsself, LITERAL("object"));  
    /* Обход с хвоста. */
    xscapturetail     = NULL;
    xstempcapturehead = NULL;
    /* Обход с головы. */
    xsbubblehead      = NULL;
    xstargethead      = NULL;

    xselement         = xsself;
    
    do {
        xsevents = webgear_xs_hv_get_rv(xselement, LITERAL("events"));
        xsevent  = webgear_xs_hv_get_rv(xsevents, event->type, event->typelength);

        while (xsevent) {
            jscallback = webgear_xs_hv_get_iv(xsevent, LITERAL("callback"));

            if (!jscallback) {
                function       = webgear_xs_hv_get_pv(xsevent, LITERAL("function"));
                functionlength = webgear_xs_hv_get_pv(xsevent, LITERAL("functionlength"));
                jscallback     = JS_CompileFunction(cx, obj, NULL, 0, NULL, function, functionlength, NULL, 0);
                webgear_xs_hv_set_iv(xsevent, LITERAL("callback"), jscallback);
            }
            /* Target Phase (2). */
            if (xselement == xsself) {
                xstargettail = webgear_event_add(&xstargethead, &xstargettail, xsevent);
            /* Capture Phase (1). */
            } else if (webgear_xs_hv_get_iv(xsevent, LITERAL("flags"))) {
                xstempcapturetail = webgear_event_add(&xstempcapturehead, &xstempcapturetail, xsevent); 
            /* Bubbling Phase (3). */
            } else if (event->isbubbles) {                        
                xsbubbletail = webgear_event_add(&xsbubblehead, &xsbubbletail, xsevent);
            }

            xsevent = webgear_xs_hv_get_rv(xsevent, LITERAL("nextnode"));
        }

        if (xstempcapturehead) {
            /* Добавление списка фазы захвата в конец временного списка сохраняет
            последовательность событий. */
            webgear_xs_hv_set_rv(xstempcapturetail, LITERAL("nextphasenode"), xscapturetail);
            /* Разворот списка. */
            xscapturetail     = xstempcapturehead;
            /* Сброс временного списка на каждом элементе. */
            xstempcapturehead = NULL;
        }

        xselement = webgear_xs_hv_get_rv(xselement, LITERAL("parent"));
    } while (xselement);

    if (webgear_event_dispatch(cx, argv[0], event, EVENT_PAHASE_CAPTURING, xscapturetail) &&
        webgear_event_dispatch(cx, argv[0], event, EVENT_PAHASE_AT_TARGET, xstargethead)  &&
        event->isbubbles) {
        webgear_event_dispatch(cx, argv[0], event, EVENT_PAHASE_BUBBLING,  xsbubblehead);
    }

    if (event->flagcanceled) {
        *rval = JSVAL_TRUE;
    /* Вызов обработчика по умолчанию. */
    } else {
        jscontext = JS_GetContextPrivate(cx);
        /* "js_event", $target, $type */
        dSP;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv("js_event", 0)));
        XPUSHs(newRV_noinc(xsself));                                
        XPUSHs(sv_2mortal(newSVpv(event->type, event->typelength)));
        PUTBACK;
        call_pv("js_callback", G_DISCARD);
        
        event->eventphase    = EVENT_PAHASE_NONE;
        event->currenttarget = NULL;
        event->flags         = 0;
        
        *rval = JSVAL_FALSE;
    }
    
    return JS_TRUE;
}

static JSFunctionSpec
webgear_js_dom_events_eventtarget_functions[] = {
    {"addEventListener",    webgear_js_dom_events_eventtarget_addEventListener,    3},
    {"removeEventListener", webgear_js_dom_events_eventtarget_removeEventListener, 3},
    {"dispatchEvent",       webgear_js_dom_events_eventtarget_dispatchEvent,       1},
    {0}
};

/*----- Определение класса -----------------------------------------------------
------------------------------------------------------------------------------*/

static JSClass
webgear_js_dom_events_eventtarget = {
    "EventTarget",
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