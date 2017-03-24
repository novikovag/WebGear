#===============================================================================
#       Главный файл XS
# 
# https://dom.spec.whatwg.org/
# 
# Иерархия интерфейсов DOM:
# 
#    Global
#    +->DOMException
#    +->DOMImplementation
#    +->Event
#    +->EventTarget
#    |  +->Node                  /абстрактный класс
#    |  |  +->Attr
#    |  |  +->CharacterData      /абстрактный класс
#    |  |  |  +->Text
#    |  |  |  |  +->CDATASection /только XML
#    |  |  |  +->Comment
#    |  |  +->Document
#    |  |  +->DocumentType
#    |  |  +->Element
#    |  +->Window
#    +->HTMLCollection
#    +->NodeList
#===============================================================================

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SV*
js_initialize_runtime()
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CODE:
{
    JSRuntime *jsruntime;
    
    jsruntime = JS_NewRuntime(8L * 1024L * 1024L);
    
    RETVAL    = newSViv(jsruntime);
}
OUTPUT:
    RETVAL

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SV*
js_initialize_context(SV *xsjsruntime, HV* xsinbuffer, HV *xsdocument)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CODE:
{
    JSRuntime *jsruntime;
    JSContext *jscontext;
    JSObject  *jsglobal, *jsconsole, *jseventtarget, *jsnode, *jsdocument, *jswindow, *jscharacterdata, *jstext;
    IWindow   *global;
    IWindow   *window;
    
    jsruntime = SvIV(xsjsruntime);
    jscontext = JS_NewContext(jsruntime, 8192);
    
    jsglobal = JS_NewObject(jscontext, &webgear_js_global, 0, 0);
    JS_InitStandardClasses(jscontext, jsglobal);
           
    JS_SetErrorReporter(jscontext, webgear_js_reporter);
           
    jsconsole = JS_InitClass(jscontext, jsglobal, NULL, &js_console, NULL, 0, NULL, js_console_functions, NULL, NULL);
    JS_DefineObject(jscontext, jsglobal, "console", &js_console, jsconsole, 0);     
            
    JS_InitClass(jscontext, jsglobal, NULL, &webgear_js_dom_exeption, NULL, 0, webgear_js_dom_exeption_properties, NULL, NULL, NULL);
    JS_InitClass(jscontext, jsglobal, NULL, &webgear_js_dom_collections_nodelist, NULL, 0, webgear_js_dom_collections_nodelist_properties, webgear_js_dom_collections_nodelist_functions, NULL, NULL);
    JS_InitClass(jscontext, jsglobal, NULL, &webgear_js_dom_collections_htmlcollection, NULL, 0, webgear_js_dom_collections_htmlcollection_properties, webgear_js_dom_collections_htmlcollection_functions, NULL, NULL);    
    JS_InitClass(jscontext, jsglobal, NULL, &webgear_js_dom_events_event, &webgear_js_dom_events_event_constructor, 0, webgear_js_dom_events_event_properties, webgear_js_dom_events_event_functions, NULL, NULL);      

    jseventtarget = JS_InitClass(jscontext, jsglobal, NULL, &webgear_js_dom_events_eventtarget, NULL, 0, NULL, webgear_js_dom_events_eventtarget_functions, NULL, NULL);    
    jsnode        = JS_InitClass(jscontext, jsglobal, jseventtarget, &webgear_js_dom_core_node, NULL, 0, webgear_js_dom_core_node_properties, webgear_js_dom_core_node_functions, NULL, NULL);
    jsdocument    = JS_InitClass(jscontext, jsglobal, jsnode, &webgear_js_dom_core_document, NULL, 0, webgear_js_dom_core_document_properties, webgear_js_dom_core_document_functions, NULL, NULL);
    jswindow      = JS_InitClass(jscontext, jsglobal, jseventtarget, &webgear_js_dom_window, NULL, 0, webgear_js_dom_window_properties, webgear_js_dom_window_functions, NULL, NULL);     

    JS_InitClass(jscontext, jsglobal, jsnode, &webgear_js_dom_core_attribute, NULL, 0, webgear_js_dom_core_attribute_properties, NULL, NULL, NULL);
    JS_InitClass(jscontext, jsglobal, jsnode, &webgear_js_dom_core_documenttype, NULL, 0, webgear_js_dom_core_documenttype_properties, NULL, NULL, NULL);
    JS_InitClass(jscontext, jsglobal, jsnode, &webgear_js_dom_core_domimplementation, NULL, 0, NULL, webgear_js_dom_core_domimplementation_functions, NULL, NULL);
    JS_InitClass(jscontext, jsglobal, jsnode, &webgear_js_dom_core_element,  NULL, 0, webgear_js_dom_core_element_properties, webgear_js_dom_core_element_functions, NULL, NULL);
    
    jscharacterdata = JS_InitClass(jscontext, jsglobal, jsnode, &webgear_js_dom_core_characterdata, NULL, 0, webgear_js_dom_core_characterdata_properties, webgear_js_dom_core_characterdata_functions, NULL, NULL);
    JS_InitClass(jscontext, jsglobal, jscharacterdata, &webgear_js_dom_core_comment, &webgear_js_dom_core_comment_constructor, 0, NULL, NULL, NULL, NULL);
    
    jstext = JS_InitClass(jscontext, jsglobal, jscharacterdata, &webgear_js_dom_core_text, &webgear_js_dom_core_text_constructor, 0, webgear_js_dom_core_text_properties, webgear_js_dom_core_text_functions, NULL, NULL);
    JS_InitClass(jscontext, jsglobal, jstext, &webgear_js_dom_cdatasection, NULL, 0, NULL, NULL, NULL, NULL);
    /* Связываем узел документа с объектом. */
    webgear_xs_hv_set_iv(xsdocument, LITERAL("object"), jsdocument);
    JS_SetPrivate(jscontext, jsdocument, xsdocument);
    
    window = webgear_window_create(jscontext, jsglobal, jswindow, jsdocument);
    JS_SetPrivate(jscontext, jswindow, window);
    /* Делаем объект класса Window == this. */
    JS_SetGlobalObject(jscontext, jswindow);  
    
    global = webgear_global_create(jsglobal, xsinbuffer, jswindow, jsdocument);
    JS_SetPrivate(jscontext, jsglobal, global);
    JS_SetContextPrivate(jscontext, global);
    
    RETVAL = newSViv(jscontext);
}
OUTPUT:
    RETVAL

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void
js_destroy_context(SV *xsjscontext)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CODE:
{
    JS_DestroyContext(SvIV(xsjscontext));
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void
js_destroy_runtime(SV *xsjsruntime)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CODE:
{
    JSRuntime *jsruntime;
    
    jsruntime = SvIV(xsjsruntime);
    
    JS_DestroyRuntime(jsruntime);
    JS_ShutDown();
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
bool
js_evaluate(SV *xsjscontext, SV *xsdata, SV *xsdatalength)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CODE:
{
    JSContext *jscontext;  
    JSObject  *jsglobal;
    jsval      jsvalue;  
    char      *data;
    int        datalength;

    jscontext  = SvIV(xsjscontext);
    jsglobal   = JS_GetGlobalObject(jscontext);
    
    datalength = SvIV(xsdatalength);
    data       = SvPVbyte(xsdata, datalength);
    
    RETVAL     = JS_EvaluateScript(jscontext, jsglobal, data, datalength, "| SpiderMonkey |", 0, &jsvalue);
}
OUTPUT:
    RETVAL
