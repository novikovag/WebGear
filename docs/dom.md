# Иерархия DOM

    Object
    +->DOMException
    +->DOMImplementation
    +->Event
    +->EventTarget
    |  +->Node                  /абстрактный класс
    |  |  +->Attr
    |  |  +->CharacterData      /абстрактный класс
    |  |  |  +->Text
    |  |  |  |  +->CDATASection /только XML
    |  |  |  +->Comment
    |  |  +->Document
    |  |  +->DocumentType
    |  |  +->Element
    |  +->Window
    +->HTMLCollection
    +->NodeList

## Interface DOMException
[live](https://heycam.github.io/webidl/#dfn-DOMException)

            Методы

    code                        |  *  |
    name                        |  *  |
    message                     |  *  |

## Interface DOMImplementation
[live](https://dom.spec.whatwg.org/#domimplementation)
[w3c](https://www.w3.org/TR/2003/WD-DOM-Level-3-Core-20030226/DOM3-Core.html#core-ID-102161490)

            Методы

    createDocumentType          |     |
    createDocument              |     |
    createHTMLDocument          |     |
    hasFeature                  |  *  | Всегда TRUE

## Interface Event
[live](https://dom.spec.whatwg.org/#interface-event)
[w3c](https://www.w3.org/TR/DOM-Level-2-Events/events.html#Events-interface)

            Методы

    constructor                 |  *  |
    composedPath                |     |
    stopPropagation             |  *  |
    stopImmediatePropagation    |  *  |
    preventDefault              |     |

            Свойства

    type                        |  *  |
    target                      |  *  |
    currentTarget               |  *  |
    eventPhase                  |  *  |
    bubbles                     |  *  |
    cancelable                  |     |
    defaultPrevented            |     |
    composed                    |     |
    isTrusted                   |     |
    timeStamp                   |  *  |

## Interface EventTarget
[live](https://dom.spec.whatwg.org/#interface-eventtarget)
[w3c](https://www.w3.org/TR/DOM-Level-2-Events/events.html#Events-EventTarget)

            Методы

    addEventListener            |  p  | Атрибуты: composed, isTrusted и
                                |     | флаги: in passive listener flag,
                                |     | composed flag, initialized flag,
                                |     | dispatch flag не используются
    removeEventListener         |  *  |
    dispatchEvent               |  *  |


## Interface Node
[live](https://dom.spec.whatwg.org/#node)
[w3c](https://www.w3.org/TR/2003/WD-DOM-Level-3-Core-20030226/DOM3-Core.html#core-ID-1950641247)

            Методы

    getRootNode                 |     |
    hasChildNodes               |  *  |
    normalize                   |  *  |
    cloneNode                   |  *  |
    isEqualNode                 |     |
    isSameNode                  |     |
    compareDocumentPosition     |     |
    contains                    |     |
    lookupPrefix                |     |
    lookupNamespaceURI          |     |
    isDefaultNamespace          |     |
    insertBefore                |  *  |
    appendChild                 |  *  |
    replaceChild                |  *  |
    removeChild                 |  *  |

            Свойства

    nodeType                    |  *  |
    nodeName                    |  *  |
    baseURI                     |     |
    isConnected                 |     |
    ownerDocument               |     |
    parentNode                  |  *  |
    parentElement               |     |
    childNodes                  |  *  |
    firstChild                  |  *  |
    lastChild                   |  *  |
    previousSibling             |  *  |
    nextSibling                 |  *  |
    nodeValue                   |  *  |
    textContent                 |     |

## Interface Attr
[live](https://dom.spec.whatwg.org/#attr)
[w3c](https://www.w3.org/TR/2003/WD-DOM-Level-3-Core-20030226/DOM3-Core.html#core-ID-637646024)

            Свойства

    namespaceURI                |     |
    prefix                      |     |
    localName                   |     |
    name                        |  *  |
    value                       |  *  |
    ownerElement                |  *  |
    specified                   |     |

## Interface CharacterData
[live](https://dom.spec.whatwg.org/#characterdata)
[w3c](https://www.w3.org/TR/2003/WD-DOM-Level-3-Core-20030226/DOM3-Core.html#core-ID-FF21A306)

            Методы

    substringData               |  *  |
    appendData                  |  *  |
    insertData                  |  *  |
    deleteDatа                  |  *  |
    replaceData                 |  *  |

            Свойства

    data                        |  *  |
    length                      |  *  |

## Interface Text
[live](https://dom.spec.whatwg.org/#interface-text)
[w3c](https://www.w3.org/TR/2003/WD-DOM-Level-3-Core-20030226/DOM3-Core.html#core-ID-1312295772)

            Методы

    constructor                 |  *  |
    splitText                   |  *  |


            Свойства

    wholeText                   |  *  |

## Interface CDATASection
[live](https://dom.spec.whatwg.org/#cdatasection)
[w3c](https://www.w3.org/TR/2003/WD-DOM-Level-3-Core-20030226/DOM3-Core.html#core-ID-667469212)

## Interface Comment
[live](https://dom.spec.whatwg.org/#comment)
[w3c](https://www.w3.org/TR/2003/WD-DOM-Level-3-Core-20030226/DOM3-Core.html#core-ID-1728279322)

            Методы

    constructor                 |  *  |

## Interface Document
[live](https://dom.spec.whatwg.org/#interface-document)
[w3c](https://www.w3.org/TR/2003/WD-DOM-Level-3-Core-20030226/DOM3-Core.html#core-i-Document)

DocumentOrShadowRoot mixin: [live](https://dom.spec.whatwg.org/#documentorshadowroot)
[w3c](https://www.w3.org/TR/shadow-dom/#extensions-to-the-documentorshadowroot-mixin)

HTML5: [live](https://html.spec.whatwg.org/multipage/dom.html#the-document-object)
[w3c](https://www.w3.org/TR/html51/dom.html#the-document-object)

            Методы

    getElementsByTagName        |  *  |
    getElementsByTagNameNS      |     |
    getElementsByClassName      |     |
    createElement               |  *  |
    createElementNS             |     |
    createDocumentFragment      |     |
    createTextNode              |  *  |
    createCDATASection          |  *  | Исключение EXCEPTION_NOT_SUPPORTED_ERR
    createComment               |  *  |
    createProcessingInstruction |     |
    importNode                  |     |
    adoptNode                   |     |
    createAttribute             |  *  |
    createAttributeNS           |     |
    createEvent                 |     |
    createRange                 |     |
    createNodeIterator          |     |
    createTreeWalker            |     |
    - DocumentOrShadowRoot mixin
    getElementById              |  *  |
    - HTML5
    getElementsByName           |     |
    open                        |     |
    close                       |     |
    write                       |     |
    writeln                     |     |
    hasFocus                    |     |
    execCommand                 |     |
    queryCommandEnabled         |     |
    queryCommandIndeterm        |     |
    queryCommandState           |     |
    queryCommandSupported       |     |
    queryCommandValue           |     |

            Свойства

    implementation              |  *  |
    URL                         |     |
    documentURI                 |     |
    origin                      |     |
    compatMode                  |     |
    characterSet                |     |
    charset                     |     |
    inputEncoding               |     |
    contentType                 |     |
    doctype                     |  *  |
    documentElement             |  *  |
    - HTML5
    location                    |     |
    domain                      |     |
    referrer                    |     |
    cookie                      |     |
    lastModified                |     |
    readyState                  |     |
    name                        |     |
    title                       |     |
    dir                         |     |
    body                        |     |
    head                        |     |
    images                      |     |
    embeds                      |     |
    plugins                     |     |
    links                       |     |
    forms                       |     |
    scripts                     |     |
    currentScript               |     |
    defaultView                 |     |
    ctiveElement                |     |
    designMode                  |     |
    onreadystatechange          |     |

## Interface DocumentType
[live](https://dom.spec.whatwg.org/#documenttype)
[w3c](https://www.w3.org/TR/2003/WD-DOM-Level-3-Core-20030226/DOM3-Core.html#core-ID-412266927)

            Свойства

    name                        |  *  |
    publicId                    |  *  |
    systemId                    |  *  |

## Interface Element
[live](https://dom.spec.whatwg.org/#interface-element)
[w3c](https://www.w3.org/TR/2003/WD-DOM-Level-3-Core-20030226/DOM3-Core.html#core-ID-745549614)

            Методы

    hasAttributes               |     |
    getAttributeNames           |     |
    getAttribute                |  *  |
    getAttributeNS              |     |
    setAttribute                |  *  |
    setAttributeNS              |     |
    removeAttribute             |  *  |
    removeAttributeNS           |     |
    hasAttribute                |     |
    hasAttributeNS              |     |
    getAttributeNode            |  *  |
    getAttributeNodeNS          |     |
    setAttributeNode            |  *  |
    setAttributeNodeNS          |     |
    removeAttributeNode         |  *  |
    attachShadow                |     |
    closest                     |     |
    matches                     |     |
    getElementsByTagName        |  *  |
    getElementsByTagNameNS      |     |
    getElementsByClassName      |     |

            Свойства

    namespaceURI                |     |
    prefix                      |     |
    localName                   |     |
    tagName                     |  *  |
    id                          |     |
    className                   |     |
    classList                   |     |
    slot                        |     |
    attributes                  |     |
    shadowRoot                  |     |

## Interface Window
[live](https://html.spec.whatwg.org/multipage/browsers.html#window)
[w3c](https://www.w3.org/TR/html5/browsers.html#the-window-object)

WindowOrWorkerGlobalScope mixin: [live](https://html.spec.whatwg.org/multipage/webappapis.html#windoworworkerglobalscope)
[w3c](https://www.w3.org/TR/html52/webappapis.html#windoworworkerglobalscope-mixin)

            Методы

    close                       |     |
    stop                        |     |
    focus                       |     |
    blur                        |     |
    open                        |     |
    object                      |     |
    alert                       |     |
    confirm                     |     |
    prompt                      |     |
    print                       |     |
    requestAnimationFrame       |     |
    cancelAnimationFrame        |     |
    postMessage                 |     |
    - WindowOrWorkerGlobalScope mixin
    setTimeout                  |  *  | Только POSIX
    clearTimeout                |  *  | Только POSIX
    setInterval                 |  *  | Только POSIX
    clearInterval               |  *  | Только POSIX

            Свойства

    window                      |     |
    self                        |  *  |
    document                    |  *  |
    name                        |     |
    location                    |     |
    history                     |     |
    customElements              |     |
    locationbar                 |     |
    menubar                     |     |
    personalbar                 |     |
    scrollbars                  |     |
    statusbar                   |     |
    toolbar                     |     |
    status                      |     |
    close                       |     |
    frames                      |     |
    length                      |     |
    top                         |     |
    opener                      |     |
    parent                      |     |
    frameElement                |     |
    navigator                   |     |
    applicationCache            |     |

## Interface HTMLCollection
[live](https://dom.spec.whatwg.org/#htmlcollection)

            Методы

    item                        |  *  |
    namedItem                   |  *  |

            Свойства

    length;                     |  *  |

## Interface NodeList
[live](https://dom.spec.whatwg.org/#interface-nodelist)
[w3c](https://www.w3.org/TR/2003/WD-DOM-Level-3-Core-20030226/DOM3-Core.html#core-ID-536297177)

            Методы

    item                        |  *  |


            Свойства

    length                      |  *  |