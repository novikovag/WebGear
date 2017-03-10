/*==============================================================================
        Interface DOMImplementation

 https://dom.spec.whatwg.org/#domimplementation
 https://www.w3.org/TR/2003/WD-DOM-Level-3-Core-20030226/DOM3-Core.html#core-ID-102161490
==============================================================================*/

#ifndef _webgear_js_dom_core_domimplementation_h
#define _webgear_js_dom_core_domimplementation_h

/*----- Методы -----------------------------------------------------------------
------------------------------------------------------------------------------*/

/* createDocumentType
   createDocument    
   createHTMLDocument */       

static JSBool
webgear_js_dom_core_domimplementation_hasFeature(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    *rval = JSVAL_TRUE;
    return JS_TRUE;
}

static JSFunctionSpec
webgear_js_dom_core_domimplementation_functions[] = {
 /* {"createDocumentType", webgear_js_dom_core_domimplementation_createDocumentType, 3},
    {"createDocument",     webgear_js_dom_core_domimplementation_createDocument,     3},    
    {"createHTMLDocument", webgear_js_dom_core_domimplementation_createHTMLDocument, 1}, */
    {"hasFeature",         webgear_js_dom_core_domimplementation_hasFeature,         0},
    {0}
};

/*----- Определение класса -----------------------------------------------------
------------------------------------------------------------------------------*/

static JSClass 
webgear_js_dom_core_domimplementation = {
    "DOMImplementation", 
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