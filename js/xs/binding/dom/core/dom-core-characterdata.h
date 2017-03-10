/*==============================================================================
        Interface CharacterData

 https://dom.spec.whatwg.org/#characterdata
 https://www.w3.org/TR/2003/WD-DOM-Level-3-Core-20030226/DOM3-Core.html#core-ID-FF21A306
==============================================================================*/

#ifndef _webgear_js_dom_core_characterdata_h
#define _webgear_js_dom_core_characterdata_h

/*----- Методы -----------------------------------------------------------------
------------------------------------------------------------------------------*/

static JSBool
webgear_js_dom_core_characterdata_substringData(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSString *jsstring;
    HV       *xsself;
    char     *data;
    int       offset, count, startindex, endindex, datalength;

    if (argc < 2) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }

    if (!JSVAL_IS_INT(argv[0]) || !JSVAL_IS_INT(argv[1])) {
        webgear_js_exeption(cx, EXCEPTION_ILLEGAL_ARGUMENT_ERR);
        return JS_FALSE;
    }

    offset = JSVAL_TO_INT(argv[0]);
    count  = JSVAL_TO_INT(argv[1]);

    if (offset < 0 || count < 0) {
        webgear_js_exeption(cx, EXCEPTION_INDEX_SIZE_ERR);
        return JS_FALSE;
    }

    if (!count) {
        *rval = JSVAL_NULL;
        return JS_TRUE;
    }

    xsself     = JS_GetPrivate(cx, obj);

    data       = webgear_xs_hv_get_pv(xsself, LITERAL("data"));
    datalength = webgear_xs_hv_get_iv(xsself, LITERAL("datalength"));
    startindex = webgear_utf8_offset_to_index(data, datalength, offset);

    if (startindex < 0) {
        webgear_js_exeption(cx, EXCEPTION_INDEX_SIZE_ERR);
        return JS_FALSE;
    }

    endindex = webgear_utf8_offset_to_index(data + startindex, datalength - startindex, count);

    if (endindex < 0) {
        endindex = datalength;
    } else {
        /* Учитывая data + startindex. */
        endindex += startindex;
    }

    jsstring = JS_NewStringCopyN(cx, data + startindex, endindex - startindex);
    *rval    = STRING_TO_JSVAL(jsstring);
    return JS_TRUE;
}

static JSBool
webgear_js_dom_core_characterdata_appendData(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSString *jsstring;
    HV       *xsself;
    char     *extradata, *data, *newdata;
    int       extradatalength, datalength, newdatalength;

    if (!argc) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }

    jsstring        = JS_ValueToString(cx, argv[0]); 
    extradata       = JS_GetStringBytes(jsstring);
    extradatalength = strlen(extradata);

    if (!extradatalength) {
        return JS_TRUE;
    }

    xsself        = JS_GetPrivate(cx, obj);
    
    data          = webgear_xs_hv_get_pv(xsself, LITERAL("data"));
    datalength    = webgear_xs_hv_get_iv(xsself, LITERAL("datalength"));
    
    newdatalength = datalength + extradatalength;
    newdata       = webgear_xs_malloc(newdatalength);
    webgear_xs_memcpy(newdata, data, datalength);
    webgear_xs_memcpy(newdata + datalength, extradata, extradatalength);

    webgear_xs_hv_set_pv(xsself, LITERAL("data"), newdata, newdatalength);
    webgear_xs_hv_set_iv(xsself, LITERAL("datalength"), newdatalength);

    webgear_xs_free(newdata);
    return JS_TRUE;
}

static JSBool
webgear_js_dom_core_characterdata_insertData(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSString *jsstring;
    HV       *xsself;
    char     *data, *extradata, *newdata;
    int       offset, index, datalength, extradatalength, newdatalength;

    if (argc < 2) {
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

    if (index < 0) {
        webgear_js_exeption(cx, EXCEPTION_INDEX_SIZE_ERR);
        return JS_FALSE;
    }

    jsstring        = JS_ValueToString(cx, argv[1]); 
    extradata       = JS_GetStringBytes(jsstring);
    extradatalength = strlen(extradata);

    if (!extradatalength) {
        return JS_TRUE;
    }

    newdatalength = datalength + extradatalength;
    newdata       = webgear_xs_malloc(datalength + extradatalength);
    webgear_xs_memcpy(newdata, data, index);
    webgear_xs_memcpy(newdata + index, extradata, extradatalength);
    webgear_xs_memcpy(newdata + index + extradatalength, data + index, datalength - index);

    webgear_xs_hv_set_pv(xsself, LITERAL("data"), newdata, newdatalength);
    webgear_xs_hv_set_iv(xsself, LITERAL("datalength"), newdatalength);

    webgear_xs_free(newdata);
    return JS_TRUE;
}

static JSBool
webgear_js_dom_core_characterdata_deleteData(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    HV   *xsself;
    char *data, *newdata;
    int   offset, count, startindex, endindex, datalength, newdatalength;

    if (argc < 2) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }

    if (!JSVAL_IS_INT(argv[0]) || !JSVAL_IS_INT(argv[1])) {
        webgear_js_exeption(cx, EXCEPTION_ILLEGAL_ARGUMENT_ERR);
        return JS_FALSE;
    }

    offset = JSVAL_TO_INT(argv[0]);
    count  = JSVAL_TO_INT(argv[1]);

    if (offset < 0 || count < 0) {
        webgear_js_exeption(cx, EXCEPTION_INDEX_SIZE_ERR);
        return JS_FALSE;
    }

    if (!count) {
        return JS_TRUE;
    }

    xsself     = JS_GetPrivate(cx, obj);

    datalength = webgear_xs_hv_get_iv(xsself, LITERAL("datalength"));
    data       = webgear_xs_hv_get_pv(xsself, LITERAL("data"));
    startindex = webgear_utf8_offset_to_index(data, datalength, offset);

    if (startindex < 0) {
        webgear_js_exeption(cx, EXCEPTION_INDEX_SIZE_ERR);
        return JS_FALSE;
    }

    endindex = webgear_utf8_offset_to_index(data + startindex, datalength - startindex, count);

    if (endindex < 0) {
        endindex = datalength;
    } else {
        endindex += startindex; 
    }

    newdatalength = datalength - (endindex - startindex);
    newdata       = webgear_xs_malloc(newdatalength);
    webgear_xs_memcpy(newdata, data, startindex);
    webgear_xs_memcpy(newdata + startindex, data + endindex, datalength - endindex);

    webgear_xs_hv_set_pv(xsself, LITERAL("data"), newdata, newdatalength);
    webgear_xs_hv_set_iv(xsself, LITERAL("datalength"), newdatalength);

    webgear_xs_free(newdata);
    return JS_TRUE;
}

static JSBool
webgear_js_dom_core_characterdata_replaceData(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSString *jsstring;
    HV       *xsself;
    char     *data, *extradata, *newdata;
    int       offset, count, startindex, endindex, datalength, extradatalength, newdatalength;

    if (argc < 3) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }

    if (!JSVAL_IS_INT(argv[0]) || !JSVAL_IS_INT(argv[1])) {
        webgear_js_exeption(cx, EXCEPTION_ILLEGAL_ARGUMENT_ERR);
        return JS_FALSE;
    }

    offset = JSVAL_TO_INT(argv[0]);
    count  = JSVAL_TO_INT(argv[1]);

    if (offset < 0 || count < 0) {
        webgear_js_exeption(cx, EXCEPTION_INDEX_SIZE_ERR);
        return JS_FALSE;
    }

    xsself     = JS_GetPrivate(cx, obj);

    data       = webgear_xs_hv_get_pv(xsself, LITERAL("data"));
    datalength = webgear_xs_hv_get_iv(xsself, LITERAL("datalength"));
    startindex = webgear_utf8_offset_to_index(data, datalength, offset);

    if (startindex < 0) {
        webgear_js_exeption(cx, EXCEPTION_INDEX_SIZE_ERR);
        return JS_FALSE;
    }

    jsstring        = JS_ValueToString(cx, argv[2]); 
    extradata       = JS_GetStringBytes(jsstring);
    extradatalength = strlen(extradata);

    if (!extradatalength) {
        return JS_TRUE;
    }

    endindex = webgear_utf8_offset_to_index(data + startindex, datalength - startindex, count);

    if (endindex < 0) {
        endindex = datalength;
    } else {
        endindex += startindex;
    }

    newdatalength = datalength - (endindex - startindex) + extradatalength;
    newdata       = webgear_xs_malloc(newdatalength);
    webgear_xs_memcpy(newdata, data, startindex);
    webgear_xs_memcpy(newdata + startindex, extradata, extradatalength);
    webgear_xs_memcpy(newdata + startindex + extradatalength, data + endindex, datalength - endindex);

    webgear_xs_hv_set_pv(xsself, LITERAL("data"), newdata, newdatalength);
    webgear_xs_hv_set_iv(xsself, LITERAL("datalength"), newdatalength);

    webgear_xs_free(newdata);
    return JS_TRUE;
}

static JSFunctionSpec
webgear_js_dom_core_characterdata_functions[] = {
    {"substringData", webgear_js_dom_core_characterdata_substringData, 2},
    {"appendData",    webgear_js_dom_core_characterdata_appendData,    1},
    {"insertData",    webgear_js_dom_core_characterdata_insertData,    2},
    {"deleteData",    webgear_js_dom_core_characterdata_deleteData,    2},
    {"replaceData",   webgear_js_dom_core_characterdata_replaceData,   2},
    {0}
};

/*-----Свойства --------------------------------------------------------------*/

static JSBool
webgear_js_dom_core_characterdata_getter(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
    JSString *jsstring;
    HV       *xsself;
    char     *data;
    int       tinyid, datalength, stringlength;

    tinyid = JSVAL_TO_INT(id);
    
    if (tinyid > 1) {
        return JS_TRUE;
    }
    
    xsself = JS_GetPrivate(cx, obj);

    if (!tinyid) {
        data         = webgear_xs_hv_get_pv(xsself, LITERAL("data"));
        datalength   = webgear_xs_hv_get_iv(xsself, LITERAL("datalength"));
        jsstring     = JS_NewStringCopyN(cx, data, datalength);
        
        *vp = STRING_TO_JSVAL(jsstring);
    } else if (tinyid == 1) {
        data         = webgear_xs_hv_get_pv(xsself, LITERAL("data"));
        datalength   = webgear_xs_hv_get_iv(xsself, LITERAL("datalength"));
        jsstring     = JS_NewStringCopyN(cx, data, datalength);
        /* Вычисление длины строки в символах. */
        stringlength = JS_GetStringLength(jsstring);
        
        *vp = INT_TO_JSVAL(stringlength);
    }

    return JS_TRUE;
}

static JSBool
webgear_js_dom_core_characterdata_setter(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
    JSString *jsstring;
    HV       *xsself;
    char     *data;
    int       datalength;

    if (!JSVAL_TO_INT(id)) {
        xsself     = JS_GetPrivate(cx, obj);

        jsstring   = JS_ValueToString(cx, *vp); 
        data       = JS_GetStringBytes(jsstring);
        datalength = strlen(data);

        webgear_xs_hv_set_pv(xsself, LITERAL("data"), data, datalength);
        webgear_xs_hv_set_iv(xsself, LITERAL("datalength"), datalength);
    }

    return JS_TRUE;
}

static JSPropertySpec
webgear_js_dom_core_characterdata_properties[] = {
    {"data",   0, JSPROP_ENUMERATE},
    {"length", 1, JSPROP_ENUMERATE | JSPROP_READONLY},
    {0}
};

/*----- Определение класса -----------------------------------------------------
------------------------------------------------------------------------------*/

static JSClass
webgear_js_dom_core_characterdata = {
    "CharacterData",
    JSCLASS_HAS_PRIVATE,
    JS_PropertyStub,
    JS_PropertyStub,
    webgear_js_dom_core_characterdata_getter,
    webgear_js_dom_core_characterdata_setter,
    JS_EnumerateStub,
    JS_ResolveStub,
    JS_ConvertStub,
    JS_FinalizeStub
};

#endif