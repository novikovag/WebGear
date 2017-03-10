/*==============================================================================
        Главный заголовочный файл
==============================================================================*/

#ifndef _js_spidermonkey_h
#define _js_spidermonkey_h

#include <stdio.h>

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <jsapi.h>

static JSClass webgear_js_dom_collections_htmlcollection;
static JSClass webgear_js_dom_collections_nodelist;
static JSClass webgear_js_dom_core_attribute;
static JSClass webgear_js_dom_core_cdatasection;
static JSClass webgear_js_dom_core_characterdata;
static JSClass webgear_js_dom_core_comment;
static JSClass webgear_js_dom_core_document;
static JSClass webgear_js_dom_core_documenttype;
static JSClass webgear_js_dom_core_domimplementation;
static JSClass webgear_js_dom_core_element;
static JSClass webgear_js_dom_core_node;
static JSClass webgear_js_dom_core_text; 
static JSClass webgear_js_dom_events_event;
static JSClass webgear_js_dom_events_eventtarget;
static JSClass webgear_js_dom_exeption;

static JSBool  webgear_js_dom_core_comment_constructor();
static JSBool  webgear_js_dom_core_element_getElementsByTagName();

static JSBool  webgear_js_dom_core_text_constructor();

#include "console.h"
#include "global.h"

#include "dom/dom.h"
#include "dom/exeption.h"
#include "dom/window.h"
#include "dom/core/dom-core-attribute.h"
#include "dom/core/dom-core-cdatasection.h"
#include "dom/core/dom-core-characterdata.h"
#include "dom/core/dom-core-comment.h"
#include "dom/core/dom-core-document.h"
#include "dom/core/dom-core-documenttype.h"
#include "dom/core/dom-core-domimplementation.h"
#include "dom/core/dom-core-element.h"
#include "dom/core/dom-core-node.h"
#include "dom/core/dom-core-text.h"
#include "dom/collections/dom-collections-htmlcollection.h"
#include "dom/collections/dom-collections-nodelist.h"
#include "dom/events/dom-events-event.h"
#include "dom/events/dom-events-eventtarget.h"

#endif