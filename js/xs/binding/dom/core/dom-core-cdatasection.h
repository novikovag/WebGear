/*==============================================================================
        Interface CDATASection

 https://dom.spec.whatwg.org/#cdatasection
 https://www.w3.org/TR/2003/WD-DOM-Level-3-Core-20030226/DOM3-Core.html#core-ID-667469212
==============================================================================*/

#ifndef _webgear_js_dom_core_cdatasection_h
#define _webgear_js_dom_core_cdatasection_h

/*----- Определение класса -----------------------------------------------------
------------------------------------------------------------------------------*/

static JSClass 
webgear_js_dom_cdatasection = {
    "CDATASection", 
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