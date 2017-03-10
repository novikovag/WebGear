/*==============================================================================
        DOMException

 https://heycam.github.io/webidl/#idl-exceptions
 https://heycam.github.io/webidl/#es-exceptions

 Сообщения об ошибках взяты из mozilla/dom/base/domerr.msg
==============================================================================*/

#ifndef _webgear_js_dom_exeption_h
#define _webgear_js_dom_exeption_h

/*----- Свойства ---------------------------------------------------------------
------------------------------------------------------------------------------*/

static JSBool
webgear_js_dom_exeption_getter(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
    JSString *jsstring;
    int       tinyid, code;

    tinyid = JSVAL_TO_INT(id); 
    
    if (tinyid > 3) {
        return JS_TRUE;
    }
    
    code = JSVAL_TO_INT(JS_GetPrivate(cx, obj));
    
    if (tinyid == 1) {
        *vp = INT_TO_JSVAL(code);
    } else if (tinyid == 2) {

        switch (code) {
            case EXCEPTION_INDEX_SIZE_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("IndexSizeError"));
                break;
            case EXCEPTION_HIERARCHY_REQUEST_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("HierarchyRequestError"));
                break;
            case EXCEPTION_WRONG_DOCUMENT_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("WrongDocumentError"));
                break;
            case EXCEPTION_INVALID_CHARACTER_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("InvalidCharacterError"));
                break;
            case EXCEPTION_NO_MODIFICATION_ALLOWED_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("NoModificationAllowedError"));
                break;
            case EXCEPTION_NOT_FOUND_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("NotFoundError"));
                break;
            case EXCEPTION_NOT_SUPPORTED_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("NotSupportedError"));
                break;
            case EXCEPTION_INUSE_ATTRIBUTE_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("InUseAttributeError"));
                break;
            case EXCEPTION_INVALID_STATE_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("InvalidStateError"));
                break;
            case EXCEPTION_SYNTAX_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("SyntaxError"));
                break;
            case EXCEPTION_INVALID_MODIFICATION_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("InvalidModificationError"));
                break;
            case EXCEPTION_NAMESPACE_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("NamespaceError"));
                break;
            case EXCEPTION_INVALID_ACCESS_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("InvalidAccessError"));
                break;
            case EXCEPTION_SECURITY_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("SecurityError"));
                break;
            case EXCEPTION_NETWORK_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("NetworkError"));
                break;
            case EXCEPTION_ABORT_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("AbortError"));
                break;
            case EXCEPTION_URL_MISMATCH_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("URLMismatchError"));
                break;
            case EXCEPTION_QUOTA_EXCEEDED_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("QuotaExceededError"));
                break;
            case EXCEPTION_TIMEOUT_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("TimeoutError"));
                break;
            case EXCEPTION_INVALID_NODE_TYPE_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("InvalidNodeTypeError"));
                break;
            case EXCEPTION_DATA_CLONE_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("DataCloneError"));
                break;
            /* Ошибки JS. */    
            case EXCEPTION_TOO_FEW_ARGUMENTS_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("TooFewArguments"));
                break;
            case EXCEPTION_ILLEGAL_ARGUMENT_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("IllegalArgument"));
                break;
            case EXCEPTION_NOT_IMPLEMENTED_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("MethodNotImplemented"));
                break;
            default:
                jsstring = JS_NewStringCopyN(cx, LITERAL("EXCEPTION UNKNOWN"));
                break;
        }
        
        *vp = STRING_TO_JSVAL(jsstring);
    } else if (tinyid == 3) {

        switch (code) {
            case EXCEPTION_INDEX_SIZE_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("Index or size is negative or greater than the allowed amount"));
                break;
            case EXCEPTION_HIERARCHY_REQUEST_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("Node cannot be inserted at the specified point in the hierarchy"));
                break;
            case EXCEPTION_WRONG_DOCUMENT_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("Node cannot be used in a document other than the one in which it was created"));
                break;
            case EXCEPTION_INVALID_CHARACTER_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("String contains an invalid character"));
                break;
            case EXCEPTION_NO_MODIFICATION_ALLOWED_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("Modifications are not allowed for this document"));
                break;
            case EXCEPTION_NOT_FOUND_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("Node was not found"));
                break;
            case EXCEPTION_NOT_SUPPORTED_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("Operation is not supported"));
                break;
            case EXCEPTION_INUSE_ATTRIBUTE_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("Attribute already in use"));
                break;
            case EXCEPTION_INVALID_STATE_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("An attempt was made to use an object that is not, or is no longer, usable"));
                break;
            case EXCEPTION_SYNTAX_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("An invalid or illegal string was specified"));
                break;
            case EXCEPTION_INVALID_MODIFICATION_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("An attempt was made to modify the type of the underlying objec"));
                break;
            case EXCEPTION_NAMESPACE_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("An attempt was made to create or change an object in a way which is incorrect with regard to namespaces"));
                break;
            case EXCEPTION_INVALID_ACCESS_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("A parameter or an operation is not supported by the underlying object"));
                break;
            case EXCEPTION_SECURITY_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("The operation is insecure"));
                break;
            case EXCEPTION_NETWORK_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("A network error occurred"));
                break;
            case EXCEPTION_ABORT_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("The operation was aborted"));
                break;
            case EXCEPTION_URL_MISMATCH_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("The given URL does not match another URL"));
                break;
            case EXCEPTION_QUOTA_EXCEEDED_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("The quota has been exceeded"));
                break;
            case EXCEPTION_TIMEOUT_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("The operation timed out"));
                break;
            case EXCEPTION_INVALID_NODE_TYPE_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("The supplied node is incorrect or has an incorrect ancestor for this operation"));
                break;
            case EXCEPTION_DATA_CLONE_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("The object could not be cloned"));
                break;
            /* Ошибки JS. */    
            case EXCEPTION_TOO_FEW_ARGUMENTS_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("Too few arguments"));
                break;
            case EXCEPTION_ILLEGAL_ARGUMENT_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("Illegal argument"));
                break;
            case EXCEPTION_NOT_IMPLEMENTED_ERR:
                jsstring = JS_NewStringCopyN(cx, LITERAL("Method not implemented"));
                break;
            default:
                jsstring = JS_NewStringCopyN(cx, LITERAL("EXCEPTION UNKNOWN"));
                break;
        }
        
        *vp = STRING_TO_JSVAL(jsstring);
    }

    return JS_TRUE;
}

static JSPropertySpec
webgear_js_dom_exeption_properties[] = {
    {"EXCEPTION_INDEX_SIZE_ERR",              0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"EXCEPTION_HIERARCHY_REQUEST_ERR",       0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"EXCEPTION_WRONG_DOCUMENT_ERR",          0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"EXCEPTION_INVALID_CHARACTER_ERR",       0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"EXCEPTION_NO_MODIFICATION_ALLOWED_ERR", 0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"EXCEPTION_NOT_FOUND_ERR",               0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"EXCEPTION_NOT_SUPPORTED_ERR",           0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"EXCEPTION_INUSE_ATTRIBUTE_ERR",         0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"EXCEPTION_INVALID_STATE_ERR",           0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"EXCEPTION_SYNTAX_ERR",                  0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"EXCEPTION_INVALID_MODIFICATION_ERR",    0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"EXCEPTION_NAMESPACE_ERR",               0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"EXCEPTION_INVALID_ACCESS_ERR",          0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"EXCEPTION_SECURITY_ERR",                0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"EXCEPTION_NETWORK_ERR",                 0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"EXCEPTION_ABORT_ERR",                   0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"EXCEPTION_URL_MISMATCH_ERR",            0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"EXCEPTION_QUOTA_EXCEEDED_ERR",          0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"EXCEPTION_TIMEOUT_ERR",                 0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"EXCEPTION_INVALID_NODE_TYPE_ERR",       0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"EXCEPTION_DATA_CLONE_ERR",              0, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"code",                                  1, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"name",                                  2, JSPROP_ENUMERATE | JSPROP_READONLY},
    {"message",                               3, JSPROP_ENUMERATE | JSPROP_READONLY},
    {0}
};

/*----- Определение класса -----------------------------------------------------
------------------------------------------------------------------------------*/

static JSClass
webgear_js_dom_exeption = {
    "DOMException",
    JSCLASS_HAS_PRIVATE,
    JS_PropertyStub,
    JS_PropertyStub,
    webgear_js_dom_exeption_getter,
    JS_PropertyStub,
    JS_EnumerateStub,
    JS_ResolveStub,
    JS_ConvertStub,
    JS_FinalizeStub
};

#endif