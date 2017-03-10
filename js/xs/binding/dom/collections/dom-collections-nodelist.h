/*==============================================================================
        Interface NodeList

 https://dom.spec.whatwg.org/#interface-nodelist
 https://www.w3.org/TR/2003/WD-DOM-Level-3-Core-20030226/DOM3-Core.html#core-ID-536297177

 Список реализован как массив Perl и может включать: элементы, текстовые узлы, 
 комментарии, узлы типов документа.
==============================================================================*/

#ifndef _webgear_js_dom_collections_nodelist_h
#define _webgear_js_dom_collections_nodelist_h

/*----- Методы -----------------------------------------------------------------
------------------------------------------------------------------------------*/

static JSBool
webgear_js_dom_collections_nodelist_item(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSObject  *jsnode;
    HV        *xsnode;
    INodeList *nodelist;
    int        index;

    if (!argc) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }

    if (!JSVAL_IS_INT(argv[0])) {
        webgear_js_exeption(cx, EXCEPTION_ILLEGAL_ARGUMENT_ERR);
        return JS_FALSE;
    }

    nodelist = JS_GetPrivate(cx, obj);

    webgear_nodelist_update(nodelist);

    index = JSVAL_TO_INT(argv[0]);

    if (index < 0 || index > av_len(nodelist->xsarray)) {
        *rval = JSVAL_NULL;
        return JS_TRUE;
    }

    xsnode = webgear_xs_av_fetch_rv(nodelist->xsarray, index);
    jsnode = webgear_xs_hv_get_iv(xsnode, LITERAL("object"));

    if (!jsnode) {

        switch (webgear_xs_hv_get_iv(xsnode, LITERAL("type"))) {
            case NODE_TYPE_ELEMENT:
                jsnode = JS_NewObject(cx, &webgear_js_dom_core_element, NULL, NULL);
                break;
            case NODE_TYPE_TEXT:
                jsnode = JS_NewObject(cx, &webgear_js_dom_core_text, NULL, NULL);
                break;
            case NODE_TYPE_COMMENT:
                jsnode = JS_NewObject(cx, &webgear_js_dom_core_comment, NULL, NULL);
                break;
            case NODE_TYPE_DOCUMENT_TYPE:
                jsnode = JS_NewObject(cx, &webgear_js_dom_core_documenttype, NULL, NULL);
                break;
        }

        webgear_xs_hv_set_iv(xsnode, LITERAL("object"), jsnode);
        JS_SetPrivate(cx, jsnode, xsnode);
    }

    *rval = OBJECT_TO_JSVAL(jsnode);
    return JS_TRUE;
};

static JSFunctionSpec
webgear_js_dom_collections_nodelist_functions[] = {
    {"item", webgear_js_dom_collections_nodelist_item, 1},
    {0}
};

/*----- Свойства ---------------------------------------------------------------
 Через свойство определяется как велечина массива так и осуществляется доступ
 к элементу по индексу.
------------------------------------------------------------------------------*/

static JSBool
webgear_js_dom_collections_nodelist_getter(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
    JSString  *jsstring;
    INodeList *nodelist;
    char      *data;
    int        length;
    /* Доступ по индексу. */
    if (JSVAL_IS_INT(id)) {
        webgear_js_dom_collections_nodelist_item(cx, obj, 1, &id, vp);
    /* Доступ по имени или доступ к атрибуту. */
    } else if (JSVAL_IS_STRING(id)) {
        jsstring = JS_ValueToString(cx, id); 
        data     = JS_GetStringBytes(jsstring);
        /* Доступ по имени атрибута. */
        if (!strcmp("length", data)) {
            nodelist = JS_GetPrivate(cx, obj);

            webgear_nodelist_update(nodelist);

            length = av_len(nodelist->xsarray) + 1;

            *vp = INT_TO_JSVAL(length);
        }
    }

    return JS_TRUE;
}

static JSPropertySpec
webgear_js_dom_collections_nodelist_properties[] = {
    {"length", 0, JSPROP_INDEX | JSPROP_READONLY},
    {0}
};

/*----- Деструктор -------------------------------------------------------------
------------------------------------------------------------------------------*/

void
webgear_js_dom_collections_nodelist_destructor(JSContext *cx, JSObject *obj)
{
    INodeList *nodelist;

    nodelist = JS_GetPrivate(cx, obj);

    if (nodelist) {
        webgear_xs_hv_set_iv(nodelist->xsroot, LITERAL("livenodelist"), NULL);

        av_undef(nodelist->xsarray);
        free(nodelist);
    }
}

/*----- Определение класса -----------------------------------------------------
------------------------------------------------------------------------------*/

static JSClass
webgear_js_dom_collections_nodelist = {
    "NodeList",
    JSCLASS_HAS_PRIVATE,
    JS_PropertyStub,
    JS_PropertyStub,
    webgear_js_dom_collections_nodelist_getter,
    JS_PropertyStub,
    JS_EnumerateStub,
    JS_ResolveStub,
    JS_ConvertStub,
    webgear_js_dom_collections_nodelist_destructor
};

#endif