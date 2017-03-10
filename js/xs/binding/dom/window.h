/*==============================================================================
        Window

 https://html.spec.whatwg.org/multipage/browsers.html#window
 https://www.w3.org/TR/html5/browsers.html#the-window-object
  
        WindowOrWorkerGlobalScope mixin
  
 https://html.spec.whatwg.org/multipage/webappapis.html#windoworworkerglobalscope
 https://www.w3.org/TR/html52/webappapis.html#windoworworkerglobalscope-mixin
  
==============================================================================*/

#ifndef _webgear_js_dom_window_h
#define _webgear_js_dom_window_h

/*----- Методы -----------------------------------------------------------------
------------------------------------------------------------------------------*/

/* webgear_js_dom_window_close
   webgear_js_dom_window_stop
   webgear_js_dom_window_focus
   webgear_js_dom_window_blur   
   webgear_js_dom_window_open
   webgear_js_dom_window_object               
   webgear_js_dom_window_alert                
   webgear_js_dom_window_confirm              
   webgear_js_dom_window_prompt               
   webgear_js_dom_window_print                
   webgear_js_dom_window_requestAnimationFrame
   webgear_js_dom_window_cancelAnimationFrame 
   webgear_js_dom_window_postMessage */
   
#if defined(XP_UNIX)
static JSBool   
webgear_js_dom_window_setTimeout(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSFunction *jscallback;
    JSString   *jsstring;
    jsval       jsreturn;
    IWindow    *iwindow;
    char       *function;
    int         delay, timeoutid;
    
    if (argc < 2) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }

    if (JSVAL_IS_STRING(argv[0])) {
        jsstring   = JS_ValueToString(cx, argv[0]); 
        function   = JS_GetStringBytes(jsstring);
        jscallback = JS_CompileFunction(cx, obj, NULL, 0, NULL, function, strlen(function), NULL, 0);
    } else {
        jscallback = JS_ValueToFunction(cx, argv[0]);   
    }
    /* Задержка не обязательно задаетеся целым числом, нужно приводить. */
    if (!jscallback || !JS_ValueToInt32(cx,  argv[1], &delay) || delay < 0) {
        webgear_js_exeption(cx, EXCEPTION_ILLEGAL_ARGUMENT_ERR);
        return JS_FALSE;
    }
    /* Нулевая задерджка исполняется сразу. */
    if (delay == 0) {
        JS_CallFunction(cx, obj, jscallback, argc - 2, argv + 2, &jsreturn);
        timeoutid = 0;
    } else {
        iwindow   = JS_GetPrivate(cx, obj);
        
        timeoutid = webgear_timer_add(iwindow->timers, false, delay, jscallback, argc - 2, argv + 2);
    } 
    
    *rval = INT_TO_JSVAL(timeoutid);
    return JS_TRUE;
}    

static JSBool 
webgear_js_dom_window_clearTimeout(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    IWindow *iwindow;
    Timers  *timers;
    int      timeoutid;
    
    if (!argc) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }
    
    if (!JSVAL_IS_INT(argv[0])) {
        webgear_js_exeption(cx, EXCEPTION_ILLEGAL_ARGUMENT_ERR);
        return JS_FALSE;
    }
    
    timeoutid = JSVAL_TO_INT(argv[0]);
    iwindow   = JS_GetPrivate(cx, obj);
    
    timers    = iwindow->timers;

    if (timeoutid > 0 && timeoutid <= timers->nextid) {
        webgear_timer_remove(timers, timeoutid);
    }

    return JS_TRUE;
}   

static JSBool 
webgear_js_dom_window_setInterval(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSFunction *jscallback;
    JSString   *jsstring;
    IWindow    *iwindow;
    char       *function;
    int         delay, timeoutid;
    
    if (argc < 2) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }

    if (JSVAL_IS_STRING(argv[0])) {
        jsstring   = JS_ValueToString(cx, argv[0]); 
        function   = JS_GetStringBytes(jsstring);
        jscallback = JS_CompileFunction(cx, obj, NULL, 0, NULL, function, strlen(function), NULL, 0);
    } else {
        jscallback = JS_ValueToFunction(cx, argv[0]);   
    }

    if (!jscallback || !JS_ValueToInt32(cx,  argv[1], &delay) || delay < 0) {
        webgear_js_exeption(cx, EXCEPTION_ILLEGAL_ARGUMENT_ERR);
        return JS_FALSE;
    }
    /* Минимальный шаг один тик. */
    if (!delay) {
        delay++;
    }
    
    iwindow   = JS_GetPrivate(cx, obj);
    
    timeoutid = webgear_timer_add(iwindow->timers, true, delay, jscallback, argc - 2, argv + 2);
    
    *rval = INT_TO_JSVAL(timeoutid);
    return JS_TRUE;
}    

static JSBool 
webgear_js_dom_window_clearInterval(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    return webgear_js_dom_window_clearTimeout(cx, obj, argc, argv, rval);
}  
#endif

static JSFunctionSpec 
webgear_js_dom_window_functions[] = {
 /* {"close",                 webgear_js_dom_window_close,                 0},
    {"stop",                  webgear_js_dom_window_stop,                  0},
    {"focus",                 webgear_js_dom_window_focus,                 0}, 
    {"blur",                  webgear_js_dom_window_blur,                  0}, 
    {"open",                  webgear_js_dom_window_open,                  3}, 
    {"object",                webgear_js_dom_window_object,                1},
    {"alert",                 webgear_js_dom_window_alert,                 1},
    {"confirm",               webgear_js_dom_window_confirm,               1},
    {"prompt",                webgear_js_dom_window_prompt,                2},
    {"print",                 webgear_js_dom_window_print,                 0},
    {"requestAnimationFrame", webgear_js_dom_window_requestAnimationFrame, 1},
    {"cancelAnimationFrame",  webgear_js_dom_window_cancelAnimationFrame,  1},
    {"postMessage",           webgear_js_dom_window_postMessage,           3}, */
    /* WindowOrWorkerGlobalScope mixin */
#if defined(XP_UNIX)   
    {"setTimeout",            webgear_js_dom_window_setTimeout,            3},
    {"clearTimeout",          webgear_js_dom_window_clearTimeout,          1},
    {"setInterval",           webgear_js_dom_window_setInterval,           3},
    {"clearInterva",          webgear_js_dom_window_clearInterval,         1},    
#endif
    {0}
};

/*----- Свойства ---------------------------------------------------------------
------------------------------------------------------------------------------*/

static JSBool
webgear_js_dom_window_getter(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
    IWindow *iwindow;
    int      tinyid;

    tinyid = JSVAL_TO_INT(id);
    
    if (tinyid > 3) {
        return JS_TRUE;
    }
    
    iwindow = JS_GetPrivate(cx, obj);
    
    if (tinyid <= 1) {
       *vp = OBJECT_TO_JSVAL(iwindow->jswindow);
    } else if (tinyid == 2) {
       *vp = OBJECT_TO_JSVAL(iwindow->jsdocument);
    }

    return JS_TRUE;
}

static JSPropertySpec
webgear_js_dom_window_properties[] = {
    {"window",            0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"self",              1, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"document",          2, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"name",              3, JSPROP_ENUMERATE},
    {"location",          4, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"history",           5, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"customElements",    6, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"locationbar",       7, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"menubar",           8, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"personalbar",       9, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"scrollbars",       10, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"statusbar",        11, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"toolbar",          12, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"status",           13, JSPROP_ENUMERATE},
    {"close",            14, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"frames",           15, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"length",           16, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"top",              17, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"opener",           18, JSPROP_ENUMERATE},
    {"parent",           19, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"frameElement",     20, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"navigator",        21, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"applicationCache", 22, JSPROP_ENUMERATE | JSPROP_READONLY},
    {0}
};

/*----- Деструктор -------------------------------------------------------------
------------------------------------------------------------------------------*/

static JSBool
webgear_js_dom_window_destructor(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    IWindow *iwindow;

    iwindow = JS_GetPrivate(cx, obj);
#if defined(XP_UNIX)
    timer_delete(iwindow->timers->timer);
#elif defined(XP_WIN) 
    DeleteTimerQueueTimer(NULL, iwindow->timers->timer, NULL);
#endif
    webgear_xs_free(iwindow->timers);
    webgear_xs_free(iwindow); 
}

/*----- Определение класса -----------------------------------------------------
------------------------------------------------------------------------------*/

static JSClass
webgear_js_dom_window = {
    "Window",
    JSCLASS_HAS_PRIVATE | JSCLASS_GLOBAL_FLAGS,
    JS_PropertyStub,
    JS_PropertyStub,
    webgear_js_dom_window_getter,
    JS_PropertyStub,
    JS_EnumerateStub,
    JS_ResolveStub,
    JS_ConvertStub,
    webgear_js_dom_window_destructor
};

#endif