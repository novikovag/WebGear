/*==============================================================================
        Глобальный класс        
==============================================================================*/

#ifndef _webgear_js_global_h
#define _webgear_js_global_h

/*----- Определение класса -----------------------------------------------------
------------------------------------------------------------------------------*/

static JSClass 
webgear_js_global = {
    "Global", 
    0,                      
    JS_PropertyStub,
    JS_PropertyStub, 
    JS_PropertyStub, 
    JS_PropertyStub, 
    JS_EnumerateStub,
    JS_ResolveStub,   
    JS_ConvertStub,  
    JS_FinalizeStub,  
    {0}              
};

#endif