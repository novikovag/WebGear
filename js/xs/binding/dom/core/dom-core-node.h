/*==============================================================================
        Interface Node

 https://dom.spec.whatwg.org/#node
 https://www.w3.org/TR/2003/WD-DOM-Level-3-Core-20030226/DOM3-Core.html#core-ID-1950641247
==============================================================================*/

#ifndef _webgear_js_dom_core_node_h
#define _webgear_js_dom_core_node_h

/*----- Методы -----------------------------------------------------------------
------------------------------------------------------------------------------*/

/* webgear_js_dom_core_node_getRootNode */

static JSBool
webgear_js_dom_core_node_hasChildNodes(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    HV *xsself, *xsfirstchild;

    xsself = JS_GetPrivate(cx, obj);

    if (webgear_xs_hv_get_iv(xsself, LITERAL("type")) == NODE_TYPE_ELEMENT) {
        xsfirstchild = webgear_xs_hv_get_rv(xsself, LITERAL("firstchild"));
        *rval        = BOOLEAN_TO_JSVAL(xsfirstchild);
    } else { 
        *rval = JSVAL_FALSE;
    }
    
    return JS_TRUE;
}

static JSBool
webgear_js_dom_core_node_normalize(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    HV   *xsself, *xsnode, *xsnextsibling, *xsfirstchild, *xstext; 
    char *wholedata;
    int   nodetype, wholedatalength, offset;

    xsself = JS_GetPrivate(cx, obj);
    
    if (webgear_xs_hv_get_iv(xsself, LITERAL("type")) != NODE_TYPE_ELEMENT) {
        return JS_TRUE;
    }
    
    xsnode = webgear_xs_hv_get_rv(xsself, LITERAL("firstchild"));

    while (xsnode) {    
        nodetype = webgear_xs_hv_get_iv(xsnode, LITERAL("type"));
    
        if (nodetype == NODE_TYPE_TEXT) {
            xstext        = xsnode;
            xsnextsibling = webgear_xs_hv_get_rv(xsnode, LITERAL("nextsibling"));
            
            if (webgear_xs_hv_get_iv(xsnextsibling, LITERAL("type")) == NODE_TYPE_TEXT) {     
                wholedatalength = webgear_xs_hv_get_iv(xstext, LITERAL("datalength"));
                wholedata       = webgear_xs_malloc(wholedatalength);
                webgear_xs_memcpy(wholedata, webgear_xs_hv_get_pv(xstext, LITERAL("data")), wholedatalength);

                do {
                    offset        = wholedatalength;
                    xsnode        = xsnextsibling;
                    xsnextsibling = webgear_xs_hv_get_rv(xsnode, LITERAL("nextsibling"));

                    wholedatalength += webgear_xs_hv_get_iv(xsnode, LITERAL("datalength"));
                    wholedata        = webgear_xs_realloc(wholedata, wholedatalength);
                    webgear_xs_memcpy(wholedata + offset, webgear_xs_hv_get_pv(xsnode, LITERAL("data")), wholedatalength - offset);

                    webgear_node_remove(xsself, xsnode);      
                } while (webgear_xs_hv_get_iv(xsnextsibling, LITERAL("type")) == NODE_TYPE_TEXT);
                
                webgear_xs_hv_set_iv(xstext, LITERAL("datalength"), wholedatalength);
                webgear_xs_hv_set_pv(xstext, LITERAL("data"), wholedata, wholedatalength); 
                webgear_xs_free(wholedata);
                /* Продолжаем с текущего текстового узла переходом на условие проверки
                уже установленного xsnextsibling. */
                xsnode = xstext;
            }
  
        } else {
            
            if (nodetype == NODE_TYPE_ELEMENT) {
                xsfirstchild = webgear_xs_hv_get_rv(xsnode, LITERAL("firstchild"));
        
                if (xsfirstchild) {
                    xsnode = xsfirstchild;
                    continue;
                } 
            }
        L: 
            /* Для всех узлов кроме текстовых. */
            xsnextsibling = webgear_xs_hv_get_rv(xsnode, LITERAL("nextsibling"));
        }

        if (xsnextsibling) {
            xsnode = xsnextsibling;
            continue;
        }
         
        xsnode = webgear_xs_hv_get_rv(xsnode, LITERAL("parent"));

        if (xsnode == xsself) {
            break;
        }
        
        goto L;
    }  

    return JS_TRUE;
}

static JSBool
webgear_js_dom_core_node_cloneNode(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    JSObject *jsnode;
    HV       *xsnode, *xsnextsibling, *xsfirstchild, *xscloneparent, *xsclonenode, *xsattributes, *xscloneattributes, *xsattribute, *xscloneattribute;
    SV       *xsentry; 
    char     *name, *value, *data, *public, *system;
    int       deep, nodetype, flags, id, publicid, systemid, namelength, valuelength, datalength, publiclength, systemlength;
    
    if (argc) {
        JS_ValueToBoolean(cx, argv[0], &deep);
    } else {
        deep = 0;
    }

    xsnode        = JS_GetPrivate(cx, obj);
    xscloneparent = NULL;
    xsfirstchild  = NULL;

    while (1) {
        nodetype = webgear_xs_hv_get_iv(xsnode, LITERAL("type"));
        
        switch (nodetype) {
            case NODE_TYPE_ELEMENT:
                flags        = webgear_xs_hv_get_iv(xsnode, LITERAL("flags"));
                id           = webgear_xs_hv_get_iv(xsnode, LITERAL("id"));
                name         = webgear_xs_hv_get_pv(xsnode, LITERAL("name"));
                namelength   = webgear_xs_hv_get_iv(xsnode, LITERAL("namelength"));
            
                xsclonenode  = webgear_node_create_element(NULL, flags, id, name, namelength);
  
                xsattributes = webgear_xs_hv_get_rv(xsnode, LITERAL("attributes"));
                /* Копирование атрибутов реализовано отдельной подпрограммой в парсере. */
                while (1) {
                    xsentry = hv_iternextsv(xsattributes, &name, &namelength);
                    
                    if (!xsentry) {
                        break;
                    }
                    
                    xsattribute = SvRV(xsentry); 
                    
                    id          = webgear_xs_hv_get_iv(xsattribute, LITERAL("id"));
                    value       = webgear_xs_hv_get_pv(xsattribute, LITERAL("value"));
                    valuelength = webgear_xs_hv_get_iv(xsattribute, LITERAL("valuelength"));
                    
                    xscloneattribute = webgear_node_create_attribute(NULL, id, name, namelength, value, valuelength);
                                                           
                    webgear_element_add_attribute(xsclonenode, xscloneattribute);
                }
  
                xsfirstchild = webgear_xs_hv_get_rv(xsnode, LITERAL("firstchild"));
                break;
            case NODE_TYPE_TEXT:
                flags        = webgear_xs_hv_get_iv(xsnode, LITERAL("flags"));
                data         = webgear_xs_hv_get_pv(xsnode, LITERAL("data"));
                datalength   = webgear_xs_hv_get_iv(xsnode, LITERAL("datalength"));
                
                xsclonenode  = webgear_node_create_textnode(NULL, flags, data, datalength);
                break;
            case NODE_TYPE_COMMENT:  
                flags        = webgear_xs_hv_get_iv(xsnode, LITERAL("flags"));
                data         = webgear_xs_hv_get_pv(xsnode, LITERAL("data"));
                datalength   = webgear_xs_hv_get_iv(xsnode, LITERAL("datalength"));
            
                xsclonenode  = webgear_node_create_comment(NULL, flags, data, datalength);        
                break;
            case NODE_TYPE_ATTRIBUTE:  
                id           = webgear_xs_hv_get_iv(xsnode, LITERAL("id"));
                name         = webgear_xs_hv_get_pv(xsnode, LITERAL("name"));
                namelength   = webgear_xs_hv_get_iv(xsnode, LITERAL("namelength"));
                value        = webgear_xs_hv_get_pv(xsnode, LITERAL("value"));
                valuelength  = webgear_xs_hv_get_iv(xsnode, LITERAL("valuelength"));
            
                xsclonenode  = webgear_node_create_attribute(NULL, id, name, namelength, value, valuelength); 
                break;
            case NODE_TYPE_DOCUMENT_TYPE: 
                flags        = webgear_xs_hv_get_iv(xsnode, LITERAL("flags"));
                id           = webgear_xs_hv_get_iv(xsnode, LITERAL("id"));
                name         = webgear_xs_hv_get_pv(xsnode, LITERAL("name"));
                namelength   = webgear_xs_hv_get_iv(xsnode, LITERAL("namelength"));
                publicid     = webgear_xs_hv_get_iv(xsnode, LITERAL("publicid"));
                public       = webgear_xs_hv_get_pv(xsnode, LITERAL("public"));
                publiclength = webgear_xs_hv_get_iv(xsnode, LITERAL("publiclength"));
                systemid     = webgear_xs_hv_get_iv(xsnode, LITERAL("systemid"));
                system       = webgear_xs_hv_get_pv(xsnode, LITERAL("system"));
                systemlength = webgear_xs_hv_get_iv(xsnode, LITERAL("systemlength"));
                
                xsclonenode  = webgear_node_create_documenttype(NULL, flags, id, name, namelength, publicid, public, publiclength, systemid, system, systemlength);
                break;
        }

        if (xscloneparent) {
            webgear_node_append(xscloneparent, xsclonenode);  
        /* Объект класса создается только для возвращаемого первого клонированного
        узла, у него нет родителя. */
        } else {
            
            switch (nodetype) {
                case NODE_TYPE_ELEMENT:
                    jsnode = JS_NewObject(cx, &webgear_js_dom_core_element, NULL, NULL);
                    break;
                case NODE_TYPE_TEXT:
                    jsnode = JS_NewObject(cx, &webgear_js_dom_core_text, NULL, NULL);
                    break;
                case NODE_TYPE_COMMENT:
                    jsnode = JS_NewObject(cx, &webgear_js_dom_core_comment, NULL, NULL);
                    break;
                case NODE_TYPE_ATTRIBUTE:
                    jsnode = JS_NewObject(cx, &webgear_js_dom_core_attribute, NULL, NULL);
                    break;
                case NODE_TYPE_DOCUMENT_TYPE:
                    jsnode = JS_NewObject(cx, &webgear_js_dom_core_documenttype, NULL, NULL);
                    break;
            }           
            
            webgear_xs_hv_set_iv(xsclonenode, LITERAL("object"), jsnode);
            JS_SetPrivate(cx, jsnode, xsclonenode);
            
            *rval = OBJECT_TO_JSVAL(jsnode);
        }

        if (deep && xsfirstchild) {
            xsnode        = xsfirstchild;
            xscloneparent = xsclonenode;
            xsfirstchild  = NULL;
            continue;
        } 
    L:    
        /* Выход на начальном узле. */
        if (!xscloneparent) {
            break;
        }
        /* Узлы без сестринских связей не пропустятся предыдущими проверками. */
        xsnextsibling = webgear_xs_hv_get_rv(xsnode, LITERAL("nextsibling"));
    
        if (xsnextsibling) {
            xsnode = xsnextsibling;
            continue;
        }

        xsnode        = webgear_xs_hv_get_rv(xsnode, LITERAL("parent")); 
        /* Всегда над текущим xsnode. */
        xscloneparent = webgear_xs_hv_get_rv(xscloneparent, LITERAL("parent"));        
        goto L;
    }

    return JS_TRUE;
}

/* webgear_js_dom_core_node_isEqualNode
   webgear_js_dom_core_node_isSameNode
   webgear_js_dom_core_node_compareDocumentPosition
   webgear_js_dom_core_node_contains
   webgear_js_dom_core_node_lookupPrefix
   webgear_js_dom_core_node_lookupNamespaceURI
   webgear_js_dom_core_node_isDefaultNamespace */
   
static JSBool
webgear_js_dom_core_node_insertBefore(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    HV *xsself, *xsreferencenode, *xsparent, *xsnode;    

    if (!argc) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }
    
    if (!JSVAL_IS_OBJECT(argv[0])) {
        webgear_js_exeption(cx, EXCEPTION_ILLEGAL_ARGUMENT_ERR);
        return JS_FALSE; 
    }

    if (!(JS_InstanceOf(cx, obj,     &webgear_js_dom_core_element, NULL) &&
         (JS_InstanceOf(cx, argv[0], &webgear_js_dom_core_element, NULL) ||
          JS_InstanceOf(cx, argv[0], &webgear_js_dom_core_text,    NULL) ||
          JS_InstanceOf(cx, argv[0], &webgear_js_dom_core_comment, NULL)))) {
        webgear_js_exeption(cx, EXCEPTION_INVALID_NODE_TYPE_ERR);
        return JS_FALSE;                 
    }
    
    xsself = JS_GetPrivate(cx, obj);

    if (argc >= 2) {
        
        if (!JSVAL_IS_OBJECT(argv[1])) {
            webgear_js_exeption(cx, EXCEPTION_ILLEGAL_ARGUMENT_ERR);
            return JS_FALSE; 
        }
        
        if (!(JS_InstanceOf(cx, argv[1], &webgear_js_dom_core_element, NULL) ||
              JS_InstanceOf(cx, argv[1], &webgear_js_dom_core_text,    NULL) ||
              JS_InstanceOf(cx, argv[1], &webgear_js_dom_core_comment, NULL))) {
            webgear_js_exeption(cx, EXCEPTION_INVALID_NODE_TYPE_ERR);
            return JS_FALSE;                 
        }
        
        xsreferencenode = JS_GetPrivate(cx, argv[1]);

        if (webgear_xs_hv_get_rv(xsreferencenode, LITERAL("parent")) != xsself) {
            webgear_js_exeption(cx, EXCEPTION_NOT_FOUND_ERR);
            return JS_FALSE; 
        }
            
    } else {
        xsreferencenode = NULL;
    }

    xsnode = JS_GetPrivate(cx, argv[0]);
    /* Проверяем, не является ли новый элемент родителем текущего или текущим и 
    обновляем "живые" коллекции. */
    if (!webgear_collections_reset(xsself, xsnode)) {
        webgear_js_exeption(cx, EXCEPTION_HIERARCHY_REQUEST_ERR);
        return JS_FALSE;
    }

    xsparent = webgear_xs_hv_get_rv(xsnode, LITERAL("parent"));
    /* Удаляем новый узел при необходимости. */
    if (xsparent) {
        webgear_node_remove(xsparent, xsnode);
        /* Обновляем "живые" коллекции вверх до текущего узла, учитывая предыдущее 
        обновление. */
        webgear_collections_reset(xsparent, xsnode);
    }
    
    if (xsreferencenode) {
        webgear_node_insert_before(xsself, xsreferencenode, xsnode);
    } else {
        webgear_node_append(xsself, xsnode);
    }
    
    *rval = argv[0];
    return JS_TRUE;
}

static JSBool
webgear_js_dom_core_node_appendChild(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{    
    /* Исключаем вставку узла при двух и более аргументах. */
    if (argc > 1) {
        argc = 1;
    }
    
    return webgear_js_dom_core_node_insertBefore(cx, obj, argc, argv, rval);
}

static JSBool
webgear_js_dom_core_node_replaceChild(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    HV *xsself, *xsoldnode, *xsparent, *xsnode;

    if (argc < 2) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }
    
    if (!JSVAL_IS_OBJECT(argv[0]) || !JSVAL_IS_OBJECT(argv[1])) {
        webgear_js_exeption(cx, EXCEPTION_ILLEGAL_ARGUMENT_ERR);
        return JS_FALSE; 
    }
    
    if (!(JS_InstanceOf(cx, obj,     &webgear_js_dom_core_element, NULL) &&
         (JS_InstanceOf(cx, argv[0], &webgear_js_dom_core_element, NULL) ||
          JS_InstanceOf(cx, argv[0], &webgear_js_dom_core_text,    NULL) ||
          JS_InstanceOf(cx, argv[0], &webgear_js_dom_core_comment, NULL) || 
          JS_InstanceOf(cx, argv[1], &webgear_js_dom_core_element, NULL) ||
          JS_InstanceOf(cx, argv[1], &webgear_js_dom_core_text,    NULL) ||
          JS_InstanceOf(cx, argv[1], &webgear_js_dom_core_comment, NULL)))) {
        webgear_js_exeption(cx, EXCEPTION_INVALID_NODE_TYPE_ERR);
        return JS_FALSE;                 
    }

    xsself    = JS_GetPrivate(cx, obj);
    xsoldnode = JS_GetPrivate(cx, argv[1]);
    
    if (webgear_xs_hv_get_rv(xsoldnode, LITERAL("parent")) != xsself) {
        webgear_js_exeption(cx, EXCEPTION_NOT_FOUND_ERR);
        return JS_FALSE; 
    }

    xsnode = JS_GetPrivate(cx, argv[0]);

    if (!webgear_collections_reset(xsself, xsnode)) {
        webgear_js_exeption(cx, EXCEPTION_HIERARCHY_REQUEST_ERR);
        return JS_FALSE;
    }
    
    xsparent = webgear_xs_hv_get_rv(xsnode, LITERAL("parent"));
    
    if (xsparent) {
        webgear_node_remove(xsparent, xsnode);
        webgear_collections_reset(xsparent, xsnode);
    }
    
    webgear_node_replace(xsself, xsoldnode, xsnode);
    
    *rval = argv[1];
    return JS_TRUE;   
}

static JSBool
webgear_js_dom_core_node_removeChild(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    HV *xsself, *xsnode;
    
    if (!argc) {
        webgear_js_exeption(cx, EXCEPTION_TOO_FEW_ARGUMENTS_ERR);
        return JS_FALSE;
    }
    
    if (!JSVAL_IS_OBJECT(argv[0])) {
        webgear_js_exeption(cx, EXCEPTION_ILLEGAL_ARGUMENT_ERR);
        return JS_FALSE; 
    }
    
    if (!(JS_InstanceOf(cx, obj,     &webgear_js_dom_core_element, NULL) &&
         (JS_InstanceOf(cx, argv[0], &webgear_js_dom_core_element, NULL) ||
          JS_InstanceOf(cx, argv[0], &webgear_js_dom_core_text,    NULL) ||
          JS_InstanceOf(cx, argv[0], &webgear_js_dom_core_comment, NULL)))) {
        webgear_js_exeption(cx, EXCEPTION_INVALID_NODE_TYPE_ERR);
        return JS_FALSE;                 
    }

    xsself = JS_GetPrivate(cx, obj);
    xsnode = JS_GetPrivate(cx, argv[0]);
    
    if (webgear_xs_hv_get_rv(xsnode, LITERAL("parent")) != xsself) {
        webgear_js_exeption(cx, EXCEPTION_NOT_FOUND_ERR);
        return JS_FALSE; 
    }

    if (!webgear_collections_reset(xsself, xsnode)) {
        webgear_js_exeption(cx, EXCEPTION_HIERARCHY_REQUEST_ERR);
        return JS_FALSE;
    }

    webgear_node_remove(xsself, xsnode);
    
    *rval = argv[0];
    return JS_TRUE; 
}

static JSFunctionSpec 
webgear_js_dom_core_node_functions[] = {
 /* {"getRootNode",             webgear_js_dom_core_node_getRootNode,             1}, */
    {"hasChildNodes",           webgear_js_dom_core_node_hasChildNodes,           0},
    {"normalize",               webgear_js_dom_core_node_normalize,               0},
    {"cloneNode",               webgear_js_dom_core_node_cloneNode,               1},
 /* {"isEqualNode",             webgear_js_dom_core_node_isEqualNode,             1},
    {"isSameNode",              webgear_js_dom_core_node_isSameNode,              1},
    {"compareDocumentPosition", webgear_js_dom_core_node_compareDocumentPosition, 1},
    {"contains",                webgear_js_dom_core_node_contains,                1},
    {"lookupPrefix",            webgear_js_dom_core_node_lookupPrefix,            1},
    {"lookupNamespaceURI",      webgear_js_dom_core_node_lookupNamespaceURI,      1},
    {"isDefaultNamespace",      webgear_js_dom_core_node_isDefaultNamespace,      1}, */
    {"insertBefore",            webgear_js_dom_core_node_insertBefore,            2},
    {"appendChild",             webgear_js_dom_core_node_appendChild,             1},
    {"replaceChild",            webgear_js_dom_core_node_replaceChild,            2},
    {"removeChild",             webgear_js_dom_core_node_removeChild,             1},
    {0}
};

/*----- Свойства ---------------------------------------------------------------
------------------------------------------------------------------------------*/

static JSBool
webgear_js_dom_core_node_getter(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
    JSObject  *jsnode, *jsnodelist;
    JSString  *jsstring;
    INodeList *nodelist;
    HV        *xsself, *xsnode;
    char      *name, *value, *data;
    int        tinyid, nodetype, namelength, valuelength, datalength;

    tinyid   = JSVAL_TO_INT(id);
    
    if (tinyid > 31) {
        return JS_TRUE;
    }
    
    xsself   = JS_GetPrivate(cx, obj);
    nodetype = webgear_xs_hv_get_iv(xsself, LITERAL("type"));

    *vp      = JSVAL_NULL;
    
    if (tinyid <= 11) {
        *vp = INT_TO_JSVAL(tinyid + 1);
    } else if (tinyid <= 17) {
        *vp = INT_TO_JSVAL(1 << (tinyid - 12));
    } else if (tinyid == 18) {
        *vp = INT_TO_JSVAL(nodetype);
    } else if (tinyid == 19) {
        
        if (nodetype == NODE_TYPE_ELEMENT || nodetype == NODE_TYPE_ATTRIBUTE) {
            name       = webgear_xs_hv_get_pv(xsself, LITERAL("name"));
            namelength = webgear_xs_hv_get_iv(xsself, LITERAL("namelength"));
            jsstring   = JS_NewStringCopyN(cx, name, namelength);
            
            *vp = STRING_TO_JSVAL(jsstring);
        } else if (nodetype == NODE_TYPE_TEXT) {
            jsstring = JS_NewStringCopyN(cx, LITERAL("#text"));
            
            *vp = STRING_TO_JSVAL(jsstring);
        } else if (nodetype == NODE_TYPE_COMMENT) {
            jsstring = JS_NewStringCopyN(cx, LITERAL("#comment"));
            
            *vp = STRING_TO_JSVAL(jsstring);
        }
        /* NODE_TYPE_CDATA_SECTION
           NODE_TYPE_PROCESSING_INSTRUCTION
           NODE_TYPE_DOCUMENT_TYPE
           NODE_TYPE_DOCUMENT_FRAGMENT */
    } else if (tinyid <= 24) {

        if (tinyid == 20) {
            xsnode = webgear_xs_hv_get_rv(xsself, LITERAL("parent"));
        } else if (tinyid == 21 && nodetype == NODE_TYPE_ELEMENT) {
            xsnode = webgear_xs_hv_get_rv(xsself, LITERAL("firstchild"));
        } else if (tinyid == 22 && nodetype == NODE_TYPE_ELEMENT) {
            xsnode = webgear_xs_hv_get_rv(xsself, LITERAL("lastchild"));
        } else if (tinyid == 23 && nodetype != NODE_TYPE_ATTRIBUTE) {
            xsnode = webgear_xs_hv_get_rv(xsself, LITERAL("previoussibling"));
        } else if (tinyid == 24 && nodetype != NODE_TYPE_ATTRIBUTE) {
            xsnode = webgear_xs_hv_get_rv(xsself, LITERAL("nextsibling"));
        } else {
            xsnode = NULL;
        }
        
        if (xsnode) {
            jsnode = webgear_xs_hv_get_iv(xsnode, LITERAL("object"));
            
            if (!jsnode) {

                switch (webgear_xs_hv_get_iv(xsnode, LITERAL("type"))) {
                    case NODE_TYPE_ELEMENT:
                        jsnode = JS_NewObject(cx, &webgear_js_dom_core_element, NULL, NULL);
                        // NODE_TYPE_DOCUMENT jsnode = JS_NewObject(cx, &webgear_js_dom_core_document, NULL, NULL);
                        break;
                    case NODE_TYPE_TEXT:
                        jsnode = JS_NewObject(cx, &webgear_js_dom_core_text, NULL, NULL);
                        break;
                    case NODE_TYPE_ATTRIBUTE:
                        jsnode = JS_NewObject(cx, &webgear_js_dom_core_attribute, NULL, NULL);
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
            
            *vp = OBJECT_TO_JSVAL(jsnode);
        } 
        
    } else if (tinyid == 29) {
        
        if (nodetype == NODE_TYPE_ELEMENT) {
            nodelist = webgear_xs_hv_get_iv(xsself, LITERAL("livenodelist"));
            
            if (!nodelist) {
                jsnodelist = JS_NewObject(cx, &webgear_js_dom_collections_nodelist, NULL, NULL);
                nodelist   = webgear_nodelist_create(jsnodelist, xsself);
            
                webgear_xs_hv_set_iv(xsself, LITERAL("livenodelist"), nodelist);
                JS_SetPrivate(cx, jsnodelist, nodelist);
            }
            
            *vp = OBJECT_TO_JSVAL(nodelist->jsobject);    
        } 
        
    } else if (tinyid == 30) {
    
        if (nodetype == NODE_TYPE_ATTRIBUTE) {
            value       = webgear_xs_hv_get_pv(xsself, LITERAL("value"));
            valuelength = webgear_xs_hv_get_iv(xsself, LITERAL("valuelength"));
            jsstring    = JS_NewStringCopyN(cx, value, valuelength);
        
            *vp = STRING_TO_JSVAL(jsstring);
        } else if (nodetype == NODE_TYPE_TEXT || nodetype == NODE_TYPE_COMMENT) {
            data        = webgear_xs_hv_get_pv(xsself, LITERAL("data"));
            datalength  = webgear_xs_hv_get_iv(xsself, LITERAL("datalength"));
            jsstring    = JS_NewStringCopyN(cx, data, datalength);
            
            *vp = STRING_TO_JSVAL(jsstring);
        } 
    }

    return JS_TRUE; 
}

static JSBool
webgear_js_dom_core_node_setter(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
    JSString *jsstring;
    HV       *xsself;
    char     *data;
    int       tinyid, datalength;

    tinyid = JSVAL_TO_INT(id);
    
    if (tinyid == 30) {
        jsstring   = JS_ValueToString(cx, *vp); 
        data       = JS_GetStringBytes(jsstring);
        datalength = strlen(data);

        if (datalength) {
            xsself = JS_GetPrivate(cx, obj);
            
            switch (webgear_xs_hv_get_iv(xsself, LITERAL("type"))) {
                case NODE_TYPE_ATTRIBUTE:
                    webgear_xs_hv_set_pv(xsself, LITERAL("value"), data, datalength);
                    webgear_xs_hv_set_iv(xsself, LITERAL("valuelength"), datalength);
                    break;
                case NODE_TYPE_TEXT:
                case NODE_TYPE_COMMENT:
                    webgear_xs_hv_set_pv(xsself, LITERAL("data"), data, datalength);
                    webgear_xs_hv_set_iv(xsself, LITERAL("datalength"), datalength);
                    break;
            }
        }
    }
    
    return JS_TRUE; 
}

static JSPropertySpec 
webgear_js_dom_core_node_properties[] = {
    {"NODE_TYPE_ELEMENT",                          0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"NODE_TYPE_ATTRIBUTE",                        1, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"NODE_TYPE_TEXT",                             2, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"NODE_TYPE_CDATA_SECTION",                    3, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"NODE_TYPE_ENTITY_REFERENCE",                 4, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"NODE_TYPE_ENTITY",                           5, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"NODE_TYPE_PROCESSING_INSTRUCTION",           6, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"NODE_TYPE_COMMENT",                          7, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"NODE_TYPE_DOCUMENT",                         8, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"NODE_TYPE_DOCUMENT_TYPE",                    9, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"NODE_TYPE_DOCUMENT_FRAGMENT",               10, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"NODE_TYPE_NOTATION_NODE",                   11, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"DOCUMENT_POSITION_DISCONNECTED",            12, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"DOCUMENT_POSITION_PRECEDING",               13, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"DOCUMENT_POSITION_FOLLOWING",               14, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"DOCUMENT_POSITION_CONTAINS",                15, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"DOCUMENT_POSITION_CONTAINED_BY",            16, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC", 17, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"nodeType",                                  18, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"nodeName",                                  19, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"parentNode",                                20, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"firstChild",                                21, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"lastChild",                                 22, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"previousSibling",                           23, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"nextSibling",                               24, JSPROP_ENUMERATE | JSPROP_READONLY},
 /* {"baseURI",                                   25, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"isConnected",                               26, JSPROP_ENUMERATE | JSPROP_READONLY}, */
    {"ownerDocument",                             27, JSPROP_ENUMERATE | JSPROP_READONLY},
 /* {"parentElement",                             28, JSPROP_ENUMERATE | JSPROP_READONLY}, */
    {"childNodes",                                29, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"nodeValue",                                 30, JSPROP_ENUMERATE},
 /* {"textContent",                               31, JSPROP_ENUMERATE}  */
    {0}
};

/*----- Определение класса -----------------------------------------------------
------------------------------------------------------------------------------*/

static JSClass 
webgear_js_dom_core_node = {
    "Node",
    JSCLASS_HAS_PRIVATE,
    JS_PropertyStub,
    JS_PropertyStub, 
    webgear_js_dom_core_node_getter,
    webgear_js_dom_core_node_setter, 
    JS_EnumerateStub, 
    JS_ResolveStub,   
    JS_ConvertStub,   
    JS_FinalizeStub              
};

#endif