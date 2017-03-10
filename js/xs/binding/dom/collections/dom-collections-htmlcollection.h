/*==============================================================================
        Interface HTMLCollection

 https://dom.spec.whatwg.org/#htmlcollection

 Колекция реализована как массив Perl и может содержать только элементы.
==============================================================================*/

#ifndef _webgear_js_dom_collections_htmlcollection_h
#define _webgear_js_dom_collections_htmlcollection_h

/*----- Методы -----------------------------------------------------------------
------------------------------------------------------------------------------*/

static JSBool
webgear_js_dom_collections_htmlcollection_item(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSObject        *jselement;
    HV              *xselement;
    IHTMLCollection *htmlcollection;
    int              index;

    if (!argc) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }

    if (!JSVAL_IS_INT(argv[0])) {
        webgear_js_exeption(cx, EXCEPTION_ILLEGAL_ARGUMENT_ERR);
        return JS_FALSE;
    }

    htmlcollection = JS_GetPrivate(cx, obj);
    
    webgear_htmlcollection_update(htmlcollection);

    index = JSVAL_TO_INT(argv[0]);

    if (index < 0 || index > av_len(htmlcollection->xsarray)) {
        *rval = JSVAL_NULL;
        return JS_TRUE;
    }

    xselement = webgear_xs_av_fetch_rv(htmlcollection->xsarray, index);
    jselement = webgear_xs_hv_get_iv(xselement, LITERAL("object"));

    if (!jselement) {
        jselement = JS_NewObject(cx, &webgear_js_dom_core_element, NULL, NULL);
        webgear_xs_hv_set_iv(xselement, LITERAL("object"), jselement);
        JS_SetPrivate(cx, jselement, xselement);
    }

    *rval = OBJECT_TO_JSVAL(jselement);
    return JS_TRUE;
}

static JSBool
webgear_js_dom_collections_htmlcollection_namedItem(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSObject        *jselement;
    JSString        *jsstring;
    HV              *xselement, *xsattribute;
    IHTMLCollection *htmlcollection;
    char            *data, *value;
    int              datalength, valuelength, index;

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
    
    htmlcollection = JS_GetPrivate(cx, obj);
    
    webgear_htmlcollection_update(htmlcollection);
    /* Поиск элемента по значению атрибутов. */
    for (index = 0; index <= av_len(htmlcollection->xsarray); index++) {
        xselement   = webgear_xs_av_fetch_rv(htmlcollection->xsarray, index);

        xsattribute = webgear_element_search_attribute(xselement, LITERAL("id"));

        if (xsattribute) {    
            value       = webgear_xs_hv_get_pv(xsattribute, LITERAL("value"));
            valuelength = webgear_xs_hv_get_iv(xsattribute, LITERAL("valuelength"));
            
            if (datalength == valuelength && !memcmp(data, value, datalength)) {
                goto L;
            }
        }

        xsattribute = webgear_element_search_attribute(xselement, LITERAL("name"));

        if (xsattribute) {    
            value       = webgear_xs_hv_get_pv(xsattribute, LITERAL("value"));
            valuelength = webgear_xs_hv_get_iv(xsattribute, LITERAL("valuelength"));
            
            if (datalength == valuelength && !memcmp(data, value, datalength)) {
                goto L;
            }
        }
    }
    /* Ничего не найдено. */
    *rval = JSVAL_NULL;
    return JS_TRUE;
L:
    jselement = webgear_xs_hv_get_iv(xselement, LITERAL("object"));

    if (!jselement) {
        jselement = JS_NewObject(cx, &webgear_js_dom_core_element, NULL, NULL);
        webgear_xs_hv_set_iv(xselement, LITERAL("object"), jselement);
        JS_SetPrivate(cx, jselement, xselement);
    }

    *rval = OBJECT_TO_JSVAL(jselement);
    return JS_TRUE;
}

static JSFunctionSpec
webgear_js_dom_collections_htmlcollection_functions[] = {
    {"item",      webgear_js_dom_collections_htmlcollection_item,      1},
    {"namedItem", webgear_js_dom_collections_htmlcollection_namedItem, 1},
    {0}
};

/*----- Свойства ---------------------------------------------------------------
 Через свойство определяется как велечина массива так и осуществляется доступ
 к элементу по значению атрибутов: id, name.

 Поскольку движок определяя имена методов класса проходит через разрешения атрибутов,
 то необходимо сравнивать и игнорировать имена методов: item, namedItem.

 Значения атрибутов не могут иметь вышеперечисленные зарезервированные имена.
------------------------------------------------------------------------------*/

static JSBool
webgear_js_dom_collections_htmlcollection_getter(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
    JSString        *jsstring;
    IHTMLCollection *htmlcollection;
    char            *data;
    /* Доступ по индексу. */
    if (JSVAL_IS_INT(id)) {
        webgear_js_dom_collections_htmlcollection_item(cx, obj, 1, &id, vp);
    /* Доступ по имени или доступ к атрибуту. */
    } else if (JSVAL_IS_STRING(id)) {
        jsstring = JS_ValueToString(cx, id); 
        data     = JS_GetStringBytes(jsstring);
        /* Доступ по имени атрибута. */
        if (!strcmp("length", data)) {
            htmlcollection = JS_GetPrivate(cx, obj);
            
            webgear_htmlcollection_update(htmlcollection);
            
            *vp = INT_TO_JSVAL(av_len(htmlcollection->xsarray) + 1);
        /* Доступ к элементу вида htmlcollection.ИМЯ или htmlcollection["ИМЯ"] и
        если это не вызов метода item или namedItem. */
        } else if (strcmp("item", data) && strcmp("namedItem", data)) {
            webgear_js_dom_collections_htmlcollection_namedItem(cx, obj, 1, &id, vp);
        }
    }

    return JS_TRUE;
}

static JSPropertySpec
webgear_js_dom_collections_htmlcollection_properties[] = {
    {"length", 0, JSPROP_INDEX | JSPROP_READONLY},
    {0}
};

/*----- Деструктор ------------------------------------------------------------
------------------------------------------------------------------------------*/

void
webgear_js_dom_collections_htmlcollection_destructor(JSContext *cx, JSObject *obj)
{
    IHTMLCollection *htmlcollection;

    htmlcollection = JS_GetPrivate(cx, obj);

    if (htmlcollection) {

        if (htmlcollection->previous) {
            htmlcollection->previous->next = htmlcollection->next;
        } else { /* Первый узел. */
            webgear_xs_hv_set_iv(htmlcollection->xsroot, LITERAL("livehtmlcollections"), htmlcollection->next);
        }

        if (htmlcollection->next) {
            htmlcollection->next->previous = htmlcollection->previous;
        }

        av_undef(htmlcollection->xsarray);
        free(htmlcollection->name);
        free(htmlcollection);
    }
}

/*----- Определение класса -----------------------------------------------------
------------------------------------------------------------------------------*/

static JSClass
webgear_js_dom_collections_htmlcollection = {
    "HTMLCollection",
    JSCLASS_HAS_PRIVATE,
    JS_PropertyStub,
    JS_PropertyStub,
    webgear_js_dom_collections_htmlcollection_getter,
    JS_PropertyStub,
    JS_EnumerateStub,
    JS_ResolveStub,
    JS_ConvertStub,
    webgear_js_dom_collections_htmlcollection_destructor
};

#endif
