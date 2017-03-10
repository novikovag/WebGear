/*==============================================================================
        Interface Text

 https://dom.spec.whatwg.org/#interface-text
 https://www.w3.org/TR/2003/WD-DOM-Level-3-Core-20030226/DOM3-Core.html#core-ID-1312295772
==============================================================================*/

#ifndef _webgear_js_dom_core_text_h
#define _webgear_js_dom_core_text_h

/*----- Методы -----------------------------------------------------------------
------------------------------------------------------------------------------*/

static JSBool
webgear_js_dom_core_text_splitText(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSObject  *jstext;
    HV        *xsself, *xstext, *xsparent;   
    INodeList *nodelist;
    char      *data;
    int        datalength, offset, index;

    if (!argc) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }

    if (!JSVAL_IS_INT(argv[0])) {
        webgear_js_exeption(cx, EXCEPTION_ILLEGAL_ARGUMENT_ERR);
        return JS_FALSE;
    }
    
    offset = JSVAL_TO_INT(argv[0]);
    
    if (offset < 0) {
        webgear_js_exeption(cx, EXCEPTION_INDEX_SIZE_ERR);
        return JS_FALSE;
    }
    
    xsself     = JS_GetPrivate(cx, obj);
    
    data       = webgear_xs_hv_get_pv(xsself, LITERAL("data"));
    datalength = webgear_xs_hv_get_iv(xsself, LITERAL("datalength"));
    index      = webgear_utf8_offset_to_index(data, datalength, offset);
    
    if (index == -1) {
        webgear_js_exeption(cx, EXCEPTION_INDEX_SIZE_ERR);
        return JS_FALSE;
    }
    
    jstext = JS_NewObject(cx, &webgear_js_dom_core_text, NULL, NULL);
    xstext = webgear_node_create_textnode(jstext, 0, data + index, datalength - index); 
    JS_SetPrivate(cx, jstext, xstext); 
    /* Обновляем параметры текущего текстового узла. */
    webgear_xs_hv_set_pv(xsself, LITERAL("data"), data, index);
    webgear_xs_hv_set_iv(xsself, LITERAL("datalength"), index);
    
    xsparent = webgear_xs_hv_get_rv(xsself, LITERAL("parent"));
    
    if (xsparent) {
        webgear_node_insert_after(xsparent, xsself, xstext);
        /* Обновляем только INodeList коллекцию и только у родительского элемента. */
        nodelist = webgear_xs_hv_get_iv(xsparent, LITERAL("livenodelist"));

        if (nodelist) {
            nodelist->modified = true;
        }
    } 

    *rval = OBJECT_TO_JSVAL(jstext);
    return JS_TRUE;
}

static JSFunctionSpec 
webgear_js_dom_core_text_functions[] = {
    {"splitText", webgear_js_dom_core_text_splitText, 1},
    {0}
};

/*----- Свойства ---------------------------------------------------------------
------------------------------------------------------------------------------*/

static JSBool
webgear_js_dom_core_text_getter(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
    JSString *jsstring;
    HV       *xstext, *xsprevioussibling, *xslastsibling;
    char     *wholedata, *data;
    int       wholedatalength, datalength, offset;
    
    if (!JSVAL_TO_INT(id)) {
        xsprevioussibling = JS_GetPrivate(cx, obj); /* xsself */
        
        xslastsibling     = webgear_xs_hv_get_rv(xsprevioussibling, LITERAL("nextsibling"));
        wholedatalength   = 0;
        /* Находим начальный текстовый узел начиная с текущего и подсчитываем общую длину текста. */
        do {
            xstext             = xsprevioussibling;
            wholedatalength   += webgear_xs_hv_get_iv(xstext, LITERAL("datalength"));
            xsprevioussibling  = webgear_xs_hv_get_rv(xstext, LITERAL("previoussibling"));  
        } while (webgear_xs_hv_get_iv(xsprevioussibling, LITERAL("type")) == NODE_TYPE_TEXT);
        /* Находим конечный сестринский не текстовый узел и подсчитываем общую длину текста. */
        while (webgear_xs_hv_get_iv(xslastsibling, LITERAL("type")) == NODE_TYPE_TEXT) {
            wholedatalength += webgear_xs_hv_get_iv(xslastsibling, LITERAL("datalength"));
            xslastsibling    = webgear_xs_hv_get_rv(xslastsibling, LITERAL("nextsibling"));  
        }
        
        wholedata = webgear_xs_malloc(wholedatalength);
        offset    = 0;

        do {
            data       = webgear_xs_hv_get_pv(xstext, LITERAL("data"));
            datalength = webgear_xs_hv_get_iv(xstext, LITERAL("datalength"));
            webgear_xs_memcpy(wholedata + offset, data, datalength);
            
            offset += datalength;
            xstext  = webgear_xs_hv_get_rv(xstext, LITERAL("nextsibling"));
        } while (xstext != xslastsibling);

        jsstring = JS_NewStringCopyN(cx, wholedata, wholedatalength);
        *vp      = STRING_TO_JSVAL(jsstring);
        
        webgear_xs_free(wholedata);
    }
    
    return JS_TRUE;
}

static JSPropertySpec
webgear_js_dom_core_text_properties[] = {
    {"wholeText", 0, JSPROP_READONLY},
    {0}
};

/*----- Конструктор ------------------------------------------------------------
------------------------------------------------------------------------------*/

static JSBool
webgear_js_dom_core_text_constructor(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSObject *jstext;
    JSString *jsstring;
    HV       *xstext;
    char     *data;
    int       datalength;
   
    if (!argc) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }

    jsstring   = JS_ValueToString(cx, argv[0]); 
    data       = JS_GetStringBytes(jsstring);
    datalength = strlen(data);
    
    jstext = JS_NewObject(cx, &webgear_js_dom_core_text, NULL, NULL);
    xstext = webgear_node_create_textnode(jstext, 0, data, datalength);
    JS_SetPrivate(cx, jstext, xstext);
    
    *rval = OBJECT_TO_JSVAL(jstext);
    return JS_TRUE;
}

/*----- Определение класса -----------------------------------------------------
------------------------------------------------------------------------------*/

static JSClass
webgear_js_dom_core_text = {
    "Text",
    JSCLASS_HAS_PRIVATE,
    JS_PropertyStub,
    JS_PropertyStub,
    webgear_js_dom_core_text_getter,
    JS_PropertyStub,
    JS_EnumerateStub,
    JS_ResolveStub,
    JS_ConvertStub,
    JS_FinalizeStub
};

#endif