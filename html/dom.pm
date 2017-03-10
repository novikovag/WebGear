#===============================================================================
#       Отладочные подпрограммы вывода
#===============================================================================

package WebGear::HTML::DOM;
use strict;

use Exporter qw(import);
our @EXPORT = qw(
    node_create_document
    node_create_textnode
    node_create_element
    node_create_endtag
    node_create_attribute
    node_create_event
    node_create_comment
    node_create_documenttype
    node_create_eof
    node_append
    node_remove
    node_replace
    node_insert
    node_insert_before
    node_insert_after
    element_merge_attributes
    element_compare_attributes
    element_append_rawdata
    element_id_to_name
    attribute_id_to_name
    event_id_to_name
    documenttype_id_to_name
);

use WebGear::HTML::Constants;
use WebGear::HTML::Tries;
use WebGear::HTML::Utilities;      

#----- Узлы DOM ----------------------------------------------------------------
# https://dom.spec.whatwg.org/#node
#-------------------------------------------------------------------------------

sub node_create_document
{
    my ($document);
    
    $document = {
        'type'            => $NODE_TYPE_DOCUMENT,
        'flags'           => 0,

        'parent'          => $NULL,
        'previoussibling' => $NULL,
        'nextsibling'     => $NULL,
        'firstchild'      => $NULL,
        'lastchild'       => $NULL,
        
        'soeprevious'     => $NULL,
        'soenext'         => $NULL,
        
        'object'          => $NULL,
        
        'documenttype'    => $NULL,
        'html'            => $NULL,
        'head'            => $NULL,
        'title'           => $NULL,
        'body'            => $NULL
    };
    
    return $document;
}

sub node_create_element
{
    my ($flags, $id, $name, $namelength) = @_;
    my ($element);

    $element = {
        'type'                => $NODE_TYPE_START_TAG,
        'flags'               => $flags,
        
        'parent'              => $NULL,
        'previoussibling'     => $NULL,
        'nextsibling'         => $NULL,
        'firstchild'          => $NULL,
        'lastchild'           => $NULL,
        
        'id'                  => $id,
        'name'                => $name,
        'namelength'          => $namelength,
        
        'attributes'          => {},
        
        'soeprevious'         => $NULL,
        'soenext'             => $NULL, 
        'afeprevious'         => $NULL,
        'afenext'             => $NULL,
        'afemarkers'          => 0,

        'object'              => $NULL,
        
        'livenodelist'        => $NULL,
        'livehtmlcollections' => $NULL,
        
        'events'              => {}
    };
    
    return $element;
}

sub node_create_attribute
{
    my ($element, $id, $name, $namelength, $value, $valuelength) = @_;
    my ($attribute);
    
    $attribute = {
        'type'        => $NODE_TYPE_ATTRIBUTE,

        'element'     => $element, # (parent)
        
        'id'          => $id,
        'name'        => $name,
        'namelength'  => $namelength,
        
        'value'       => $value,
        'valuelength' => $valuelength,
        
        'object'      => $NULL
    };
    
    return $attribute;
}

sub node_create_event
{
    my ($element, $id, $type, $typelength, $function, $functionlength) = @_;
    my ($event);
    
    $event = {
        'type'           => $NODE_TYPE_EVENT,
        'flags'          => 0,
                         
        'element'        => $element, # (parent)
                         
        'id'             => $id,
        'type'           => $type,
        'typelength'     => $typelength,
                         
        'function'       => $function,
        'functionlength' => $functionlength,
                         
        'callback'       => $NULL,
                         
        'previousnode'   => $NULL,
        'nextnode'       => $NULL,
        'lastnode'       => $NULL,
                         
        'nextphasenode'  => $NULL
    };

    return $event;
}

sub node_create_textnode
{
    my ($flags, $data, $datalengh) = @_;
    my ($textnode);
    
    $textnode = {
        'type'            => $NODE_TYPE_TEXT,
        'flags'           => $flags,
        
        'parent'          => $NULL,
        'previoussibling' => $NULL,
        'nextsibling'     => $NULL,
        
        'data'            => $data,
        'datalengh'       => $datalengh,
        
        'object'          => $NULL
    };
    
    return $textnode;
}

sub node_create_comment
{
    my ($flags, $data, $datalengh) = @_;
    my ($comment);
    
    $comment = {
        'type'            => $NODE_TYPE_COMMENT,
        'flags'           => $flags,
        
        'parent'          => $NULL,
        'previoussibling' => $NULL,
        'nextsibling'     => $NULL,
        
        'data'            => $data,
        'datalengh'       => $datalengh,
        
        'object'          => $NULL
    };
    
    return $comment;
}

sub node_create_documenttype
{
    my ($flags, $id, $name, $namelength, $publicid, $public, $publiclength, $systemid, $system, $systemlength) = @_; 
    my ($documenttype);
    
    $documenttype = {
        'type'            => $NODE_TYPE_DOCUMENT_TYPE,
        'flags'           => $flags,

        'parent'          => $NULL,
        'previoussibling' => $NULL,
        'nextsibling'     => $NULL,
        
        'id'              => $id,
        'name'            => $name,
        'namelength'      => $namelength,
        
        'publicid'        => $publicid, 
        'public'          => $public,
        'publiclength'    => $publiclength, 
        
        'systemid'        => $systemid, 
        'system'          => $system,
        'systemlength'    => $systemlength,
        
        'object'          => $NULL,
    };
 
    return $documenttype;
}
 
sub node_create_endtag
{
    my ($flags, $id, $name, $namelength) = @_; 
    my ($endtag);
    
    $endtag = {
        'type'       => $NODE_TYPE_END_TAG,
        'flags'      => $flags,
        
        'id'         => $id,
        'name'       => $name,
        'namelength' => $namelength
    };
    
    return $endtag;
}

sub node_create_eof
{
    my ($eof);

    $eof = {
        'type' => $NODE_TYPE_EOF
    };
    
    return $eof;
}

sub node_remove
{
    my ($parent, $node) = @_;
    
    if ($node->{'previoussibling'}) {
        $node->{'previoussibling'}{'nextsibling'} = $node->{'nextsibling'};
    } else { # (первый узел)
        $parent->{'firstchild'} = $node->{'nextsibling'};
    }
    
    if ($node->{'nextsibling'}) {
        $node->{'nextsibling'}{'previoussibling'} = $node->{'previoussibling'};
    } else { # (последний узел)
        $parent->{'lastchild'} = $node->{'previoussibling'};
    }
    
    $node->{'parent'}          = $NULL;
    $node->{'previoussibling'} = $NULL;
    $node->{'nextsibling'}     = $NULL; 
}

sub node_replace
{
    my ($parent, $oldnode, $node) = @_;

    if ($oldnode->{'previoussibling'}) {
        $oldnode->{'previoussibling'}{'nextsibling'} = $node;
        $node->{'previoussibling'} = $oldnode->{'previoussibling'};
    } else { # (первый узел)
        $parent->{'firstchild'} = $node;
    }
    
    if ($oldnode->{'nextsibling'}) {
        $oldnode->{'nextsibling'}{'previoussibling'} = $node;
        $node->{'nextsibling'} = $oldnode->{'nextsibling'};
    } else { # (последний узел)
        $parent->{'lastchild'} = $node;
    }
    
    $oldnode->{'parent'}          = $NULL;
    $oldnode->{'previoussibling'} = $NULL;
    $oldnode->{'nextsibling'}     = $NULL; 
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Вставляет заданный узел в место определнное алгоритмом описаным в:
# https://html.spec.whatwg.org/multipage/syntax.html#appropriate-place-for-inserting-a-node
# https://www.w3.org/TR/html/syntax.html#creating-and-inserting-nodes
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub node_insert
{
    my ($context, $targetelement, $node) = @_;
    
    if ($context->{'flags'} & $PARSER_FLAG_FOSTER_PARENTING   &&  
       ($targetelement->{'id'} == $ELEMENT_TABLE ||
        $targetelement->{'id'} == $ELEMENT_TBODY ||
        $targetelement->{'id'} == $ELEMENT_TFOOT ||
        $targetelement->{'id'} == $ELEMENT_THEAD ||
        $targetelement->{'id'} == $ELEMENT_TR)) { 
        $targetelement = $context->{'soe'}; 
        # Необходимо найти наиболее ранний <TEMPLATE> или <TABLE>. 
        while ($targetelement) {
        
            if ($targetelement->{'id'} == $ELEMENT_TABLE) {
                
                if ($targetelement->{'parent'}) {
                    node_insert_before($targetelement->{'parent'}, $targetelement, $node);
                    return;
                } 
                
                $targetelement = $targetelement->{'soeprevious'};
                last;
            } 
            
            if ($targetelement->{'id'} == $ELEMENT_TEMPLATE ||
                $targetelement->{'id'} == $ELEMENT_HTML) {
                last;
            }
            
            $targetelement = $targetelement->{'soeprevious'};
        }
    }

    node_append($targetelement, $node);
}              

sub node_insert_before
{
    my ($parent, $referencenode, $node) = @_;

    if ($referencenode->{'previoussibling'}) {
        $referencenode->{'previoussibling'}{'nextsibling'} = $node;
    } else { # (первый узел)
        $parent->{'firstchild'} = $node;
    }
    
    $node->{'parent'}          = $parent;       
    $node->{'previoussibling'} = $referencenode->{'previoussibling'};
    $node->{'nextsibling'}     = $referencenode;
    
    $referencenode->{'previoussibling'} = $node;
}

sub node_insert_after
{
    my ($parent, $referencenode, $node) = @_;

    if ($referencenode->{'nextsibling'}) {
        $referencenode->{'nextsibling'}{'previoussibling'} = $node;
    } else { # (последний узел)
        $parent->{'lastchild'} = $node;
    }
    
    $node->{'parent'}          = $parent;       
    $node->{'previoussibling'} = $referencenode;
    $node->{'nextsibling'}     = $referencenode->{'nextsibling'};
    
    $referencenode->{'nextsibling'} = $node;
}

sub node_append
{
    my ($parent, $node) = @_;
    my ($lastchild);

    if ($parent->{'lastchild'}) {
        $parent->{'lastchild'}{'nextsibling'} = $node;
    } else {
        $parent->{'firstchild'} = $node
    }
    
    $node->{'parent'}          = $parent;       
    $node->{'previoussibling'} = $parent->{'lastchild'};
    $node->{'nextsibling'}     = $NULL;
    
    $parent->{'lastchild'} = $node;
}

#----- Элементы ----------------------------------------------------------------
#-------------------------------------------------------------------------------

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Копирует атрибуты одного элемента в другой с условиями:
# а) если имя атрибута существует в элементе назначения, значения атрибутов не
#    сравниваются, перезапись не происходит;
# б) события как разновидность атрибутов не копируются.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub element_merge_attributes
{
    my ($destinationelement, $element) = @_;
    my ($attributename, $attribute, $newattribute);

    foreach $attributename (keys %{$element->{'attributes'}}) {

        if (!exists $destinationelement->{'attributes'}{$attributename}) {  
            $attribute    = $element->{'attributes'}{$attributename};
            $newattribute = node_create_attribute($destinationelement, $attribute->{'id'}, $attribute->{'name'}, $attribute->{'namelength'}, $attribute->{'value'}, $attribute->{'valuelength'});
            $destinationelement->{'attributes'}->{$attributename} = $newattribute;
        }
    }
}

sub element_compare_attributes 
{
    my ($referenceelement, $element) = @_;
    my ($attributename);

    if (keys %{$referenceelement->{'attributes'}} != keys %{$element->{'attributes'}}) {
        return $FALSE;
    }
    
    foreach $attributename (keys %{$element->{'attributes'}}) {
        
        if (!exists $referenceelement->{'attributes'}{$attributename}  ||
            $referenceelement->{'attributes'}{$attributename}{'value'} ne
            $element->{'attributes'}{$attributename}{'value'}) {  
            return $FALSE;
        }
    }
    
    return $TRUE;
}

sub element_append_rawdata
{
    my ($context, $element) = @_;

    if ($element->{'id'} == $ELEMENT_IFRAME) {
        $context->{'rawswitch'} = $raw[0];
    } elsif ($element->{'id'} == $ELEMENT_MATH) { 
        $context->{'rawswitch'} = $raw[1];
    } elsif ($element->{'id'} == $ELEMENT_NOEMBED) {
        $context->{'rawswitch'} = $raw[2];
    } elsif ($element->{'id'} == $ELEMENT_NOFRAMES) { 
        $context->{'rawswitch'} = $raw[3];
    } elsif ($element->{'id'} == $ELEMENT_NOSCRIPT) { 
        $context->{'rawswitch'} = $raw[4];
    } elsif ($element->{'id'} == $ELEMENT_PLAINTEXT) {
        $context->{'rawswitch'} = $raw[5];
    } elsif ($element->{'id'} == $ELEMENT_SCRIPT) { 
        $context->{'rawswitch'} = $raw[6];
    } elsif ($element->{'id'} == $ELEMENT_STYLE) {
        $context->{'rawswitch'} = $raw[7];
    } elsif ($element->{'id'} == $ELEMENT_SVG) {
        $context->{'rawswitch'} = $raw[8];
    } elsif ($element->{'id'} == $ELEMENT_TEXTAREA) {
        $context->{'rawswitch'} = $raw[9];
    } elsif ($element->{'id'} == $ELEMENT_TITLE) {
        $context->{'rawswitch'} = $raw[10];
    } elsif ($element->{'id'} == $ELEMENT_XMP) {
        $context->{'rawswitch'} = $raw[11];
    }
    
    $context->{'scannerstate'} = $context->{'rawswitch'}{'state'};
    
    $context->{'scannerstate'}($context);
    $context->{'index'}++;
    # В условии игнорируется возможные EOF и не/обнуление указателя узла.
    if ($context->{'node'}{'type'} == $NODE_TYPE_TEXT) {
        node_append($element, $context->{'node'});
        $context->{'scannerstate'}($context);
        $context->{'index'}++;
    }
    # Пропускаем закрывающий тег.
    $context->{'nodeready'} = $FALSE;
}

sub element_id_to_name
{
    return "A"          if $_[0] == $ELEMENT_A;
    return "ABBR"       if $_[0] == $ELEMENT_ABBR;
    return "ADDRESS"    if $_[0] == $ELEMENT_ADDRESS;
    return "APPLET"     if $_[0] == $ELEMENT_APPLET;
    return "AREA"       if $_[0] == $ELEMENT_AREA;
    return "ARTICLE"    if $_[0] == $ELEMENT_ARTICLE;
    return "ASIDE"      if $_[0] == $ELEMENT_ASIDE;
    return "AUDIO"      if $_[0] == $ELEMENT_AUDIO;
    return "B"          if $_[0] == $ELEMENT_B;
    return "BASE"       if $_[0] == $ELEMENT_BASE;
    return "BASEFONT"   if $_[0] == $ELEMENT_BASEFONT;
    return "BDI"        if $_[0] == $ELEMENT_BDI;
    return "BDO"        if $_[0] == $ELEMENT_BDO;
    return "BGSOUND"    if $_[0] == $ELEMENT_BGSOUND;
    return "BIG"        if $_[0] == $ELEMENT_BIG;
    return "BLOCKQUOTE" if $_[0] == $ELEMENT_BLOCKQUOTE;
    return "BODY"       if $_[0] == $ELEMENT_BODY;
    return "BR"         if $_[0] == $ELEMENT_BR;
    return "BUTTON"     if $_[0] == $ELEMENT_BUTTON;
    return "CANVAS"     if $_[0] == $ELEMENT_CANVAS;
    return "CAPTION"    if $_[0] == $ELEMENT_CAPTION;
    return "CENTER"     if $_[0] == $ELEMENT_CENTER;
    return "CITE"       if $_[0] == $ELEMENT_CITE;
    return "CODE"       if $_[0] == $ELEMENT_CODE;
    return "COL"        if $_[0] == $ELEMENT_COL;
    return "COLGROUP"   if $_[0] == $ELEMENT_COLGROUP;
    return "DATA"       if $_[0] == $ELEMENT_DATA;
    return "DATALIST"   if $_[0] == $ELEMENT_DATALIST;
    return "DD"         if $_[0] == $ELEMENT_DD;
    return "DEL"        if $_[0] == $ELEMENT_DEL;
    return "DETAILS"    if $_[0] == $ELEMENT_DETAILS;
    return "DFN"        if $_[0] == $ELEMENT_DFN;
    return "DIALOG"     if $_[0] == $ELEMENT_DIALOG;
    return "DIR"        if $_[0] == $ELEMENT_DIR;
    return "DIV"        if $_[0] == $ELEMENT_DIV;
    return "DL"         if $_[0] == $ELEMENT_DL;
    return "DT"         if $_[0] == $ELEMENT_DT;
    return "EM"         if $_[0] == $ELEMENT_EM;
    return "EMBED"      if $_[0] == $ELEMENT_EMBED;
    return "FIELDSET"   if $_[0] == $ELEMENT_FIELDSET;
    return "FIGCAPTION" if $_[0] == $ELEMENT_FIGCAPTION;
    return "FIGURE"     if $_[0] == $ELEMENT_FIGURE;
    return "FONT"       if $_[0] == $ELEMENT_FONT;
    return "FOOTER"     if $_[0] == $ELEMENT_FOOTER;
    return "FORM"       if $_[0] == $ELEMENT_FORM;
    return "FRAME"      if $_[0] == $ELEMENT_FRAME;
    return "FRAMESET"   if $_[0] == $ELEMENT_FRAMESET;
    return "H1"         if $_[0] == $ELEMENT_H1;
    return "H2"         if $_[0] == $ELEMENT_H2;
    return "H3"         if $_[0] == $ELEMENT_H3;
    return "H4"         if $_[0] == $ELEMENT_H4;
    return "H5"         if $_[0] == $ELEMENT_H5;
    return "H6"         if $_[0] == $ELEMENT_H6;
    return "HEAD"       if $_[0] == $ELEMENT_HEAD;
    return "HEADER"     if $_[0] == $ELEMENT_HEADER;
    return "HGROUP"     if $_[0] == $ELEMENT_HGROUP;
    return "HR"         if $_[0] == $ELEMENT_HR;
    return "HTML"       if $_[0] == $ELEMENT_HTML;
    return "I"          if $_[0] == $ELEMENT_I;
    return "IFRAME"     if $_[0] == $ELEMENT_IFRAME;
    return "IMAGE"      if $_[0] == $ELEMENT_IMAGE;
    return "IMG"        if $_[0] == $ELEMENT_IMG;
    return "INPUT"      if $_[0] == $ELEMENT_INPUT;
    return "INS"        if $_[0] == $ELEMENT_INS;
    return "KBD"        if $_[0] == $ELEMENT_KBD;
    return "KEYGEN"     if $_[0] == $ELEMENT_KEYGEN;
    return "LABEL"      if $_[0] == $ELEMENT_LABEL;
    return "LEGEND"     if $_[0] == $ELEMENT_LEGEND;
    return "LI"         if $_[0] == $ELEMENT_LI;
    return "LINK"       if $_[0] == $ELEMENT_LINK;
    return "LISTING"    if $_[0] == $ELEMENT_LISTING;
    return "MAIN"       if $_[0] == $ELEMENT_MAIN;
    return "MAP"        if $_[0] == $ELEMENT_MAP;
    return "MARK"       if $_[0] == $ELEMENT_MARK;
    return "MARQUEE"    if $_[0] == $ELEMENT_MARQUEE;
    return "MATH"       if $_[0] == $ELEMENT_MATH;
    return "MENU"       if $_[0] == $ELEMENT_MENU;
    return "MENUITEM"   if $_[0] == $ELEMENT_MENUITEM;
    return "META"       if $_[0] == $ELEMENT_META;
    return "METER"      if $_[0] == $ELEMENT_METER;
    return "NAV"        if $_[0] == $ELEMENT_NAV;
    return "NOBR"       if $_[0] == $ELEMENT_NOBR;
    return "NOEMBED"    if $_[0] == $ELEMENT_NOEMBED;
    return "NOFRAMES"   if $_[0] == $ELEMENT_NOFRAMES;
    return "NOSCRIPT"   if $_[0] == $ELEMENT_NOSCRIPT;
    return "OBJECT"     if $_[0] == $ELEMENT_OBJECT;
    return "OL"         if $_[0] == $ELEMENT_OL;
    return "OPTGROUP"   if $_[0] == $ELEMENT_OPTGROUP;
    return "OPTION"     if $_[0] == $ELEMENT_OPTION;
    return "OUTPUT"     if $_[0] == $ELEMENT_OUTPUT;
    return "P"          if $_[0] == $ELEMENT_P;
    return "PARAM"      if $_[0] == $ELEMENT_PARAM;
    return "PICTURE"    if $_[0] == $ELEMENT_PICTURE;
    return "PLAINTEXT"  if $_[0] == $ELEMENT_PLAINTEXT;
    return "PRE"        if $_[0] == $ELEMENT_PRE;
    return "PROGRESS"   if $_[0] == $ELEMENT_PROGRESS;
    return "Q"          if $_[0] == $ELEMENT_Q;
    return "RB"         if $_[0] == $ELEMENT_RB;
    return "RP"         if $_[0] == $ELEMENT_RP;
    return "RT"         if $_[0] == $ELEMENT_RT;
    return "RTC"        if $_[0] == $ELEMENT_RTC;
    return "RUBY"       if $_[0] == $ELEMENT_RUBY;
    return "S"          if $_[0] == $ELEMENT_S;
    return "SAMP"       if $_[0] == $ELEMENT_SAMP;
    return "SCRIPT"     if $_[0] == $ELEMENT_SCRIPT;
    return "SECTION"    if $_[0] == $ELEMENT_SECTION;
    return "SELECT"     if $_[0] == $ELEMENT_SELECT;
    return "SLOT"       if $_[0] == $ELEMENT_SLOT;
    return "SMALL"      if $_[0] == $ELEMENT_SMALL;
    return "SOURCE"     if $_[0] == $ELEMENT_SOURCE;
    return "SPAN"       if $_[0] == $ELEMENT_SPAN;
    return "STRIKE"     if $_[0] == $ELEMENT_STRIKE;
    return "STRONG"     if $_[0] == $ELEMENT_STRONG;
    return "STYLE"      if $_[0] == $ELEMENT_STYLE;
    return "SUB"        if $_[0] == $ELEMENT_SUB;
    return "SUMMARY"    if $_[0] == $ELEMENT_SUMMARY;
    return "SUP"        if $_[0] == $ELEMENT_SUP;
    return "SVG"        if $_[0] == $ELEMENT_SVG;
    return "TABLE"      if $_[0] == $ELEMENT_TABLE;
    return "TBODY"      if $_[0] == $ELEMENT_TBODY;
    return "TD"         if $_[0] == $ELEMENT_TD;
    return "TEMPLATE"   if $_[0] == $ELEMENT_TEMPLATE;
    return "TEXTAREA"   if $_[0] == $ELEMENT_TEXTAREA;
    return "TFOOT"      if $_[0] == $ELEMENT_TFOOT;
    return "TH"         if $_[0] == $ELEMENT_TH;
    return "THEAD"      if $_[0] == $ELEMENT_THEAD;
    return "TIME"       if $_[0] == $ELEMENT_TIME;
    return "TITLE"      if $_[0] == $ELEMENT_TITLE;
    return "TR"         if $_[0] == $ELEMENT_TR;
    return "TRACK"      if $_[0] == $ELEMENT_TRACK;
    return "TT"         if $_[0] == $ELEMENT_TT;
    return "U"          if $_[0] == $ELEMENT_U;
    return "UL"         if $_[0] == $ELEMENT_UL;
    return "VAR"        if $_[0] == $ELEMENT_VAR;
    return "VIDEO"      if $_[0] == $ELEMENT_VIDEO;
    return "WBR"        if $_[0] == $ELEMENT_WBR;
    return "XMP"        if $_[0] == $ELEMENT_XMP;
    #return "ROOT"       if $_[0] == -1;
    return "?";
}

#----- Атрибуты ----------------------------------------------------------------
#-------------------------------------------------------------------------------

sub attribute_id_to_name
{
    return "abbr"                 if $_[0] == $ATTRIBUTE_ABBR;
    return "accept"               if $_[0] == $ATTRIBUTE_ACCEPT;
    return "accept_charset"       if $_[0] == $ATTRIBUTE_ACCEPT_CHARSET;
    return "accesskey"            if $_[0] == $ATTRIBUTE_ACCESSKEY;
    return "action"               if $_[0] == $ATTRIBUTE_ACTION;
    return "allowfullscreen"      if $_[0] == $ATTRIBUTE_ALLOWFULLSCREEN;
    return "alt"                  if $_[0] == $ATTRIBUTE_ALT;
    return "async"                if $_[0] == $ATTRIBUTE_ASYNC;
    return "autocomplete"         if $_[0] == $ATTRIBUTE_AUTOCOMPLETE;
    return "autofocus"            if $_[0] == $ATTRIBUTE_AUTOFOCUS;
    return "autoplay"             if $_[0] == $ATTRIBUTE_AUTOPLAY;
    return "challenge"            if $_[0] == $ATTRIBUTE_CHALLENGE;
    return "charset"              if $_[0] == $ATTRIBUTE_CHARSET;
    return "checked"              if $_[0] == $ATTRIBUTE_CHECKED;
    return "cite"                 if $_[0] == $ATTRIBUTE_CITE;
    return "class"                if $_[0] == $ATTRIBUTE_CLASS;
    return "cols"                 if $_[0] == $ATTRIBUTE_COLS;
    return "colspan"              if $_[0] == $ATTRIBUTE_COLSPAN;
    return "content"              if $_[0] == $ATTRIBUTE_CONTENT;
    return "contenteditable"      if $_[0] == $ATTRIBUTE_CONTENTEDITABLE;
    return "contextmenu"          if $_[0] == $ATTRIBUTE_CONTEXTMENU;
    return "controls"             if $_[0] == $ATTRIBUTE_CONTROLS;
    return "coords"               if $_[0] == $ATTRIBUTE_COORDS;
    return "crossorigin"          if $_[0] == $ATTRIBUTE_CROSSORIGIN;
    return "data"                 if $_[0] == $ATTRIBUTE_DATA;
    return "datetime"             if $_[0] == $ATTRIBUTE_DATETIME;
    return "default"              if $_[0] == $ATTRIBUTE_DEFAULT;
    return "defer"                if $_[0] == $ATTRIBUTE_DEFER;
    return "dir"                  if $_[0] == $ATTRIBUTE_DIR;
    return "dirname"              if $_[0] == $ATTRIBUTE_DIRNAME;
    return "disabled"             if $_[0] == $ATTRIBUTE_DISABLED;
    return "download"             if $_[0] == $ATTRIBUTE_DOWNLOAD;
    return "draggable"            if $_[0] == $ATTRIBUTE_DRAGGABLE;
    return "dropzone"             if $_[0] == $ATTRIBUTE_DROPZONE;
    return "enctype"              if $_[0] == $ATTRIBUTE_ENCTYPE;
    return "for"                  if $_[0] == $ATTRIBUTE_FOR;
    return "form"                 if $_[0] == $ATTRIBUTE_FORM;
    return "formaction"           if $_[0] == $ATTRIBUTE_FORMACTION;
    return "formenctype"          if $_[0] == $ATTRIBUTE_FORMENCTYPE;
    return "formmethod"           if $_[0] == $ATTRIBUTE_FORMMETHOD;
    return "formnovalidate"       if $_[0] == $ATTRIBUTE_FORMNOVALIDATE;
    return "formtarget"           if $_[0] == $ATTRIBUTE_FORMTARGET;
    return "headers"              if $_[0] == $ATTRIBUTE_HEADERS;
    return "height"               if $_[0] == $ATTRIBUTE_HEIGHT;
    return "hidden"               if $_[0] == $ATTRIBUTE_HIDDEN;
    return "high"                 if $_[0] == $ATTRIBUTE_HIGH;
    return "href"                 if $_[0] == $ATTRIBUTE_HREF;
    return "hreflang"             if $_[0] == $ATTRIBUTE_HREFLANG;
    return "http_equiv"           if $_[0] == $ATTRIBUTE_HTTP_EQUIV;
    return "icon"                 if $_[0] == $ATTRIBUTE_ICON;
    return "id"                   if $_[0] == $ATTRIBUTE_ID;
    return "inputmode"            if $_[0] == $ATTRIBUTE_INPUTMODE;
    return "is"                   if $_[0] == $ATTRIBUTE_IS;
    return "ismap"                if $_[0] == $ATTRIBUTE_ISMAP;
    return "itemid"               if $_[0] == $ATTRIBUTE_ITEMID;
    return "itemprop"             if $_[0] == $ATTRIBUTE_ITEMPROP;
    return "itemref"              if $_[0] == $ATTRIBUTE_ITEMREF;
    return "itemscope"            if $_[0] == $ATTRIBUTE_ITEMSCOPE;
    return "itemtype"             if $_[0] == $ATTRIBUTE_ITEMTYPE;
    return "keytype"              if $_[0] == $ATTRIBUTE_KEYTYPE;
    return "kind"                 if $_[0] == $ATTRIBUTE_KIND;
    return "label"                if $_[0] == $ATTRIBUTE_LABEL;
    return "lang"                 if $_[0] == $ATTRIBUTE_LANG;
    return "list"                 if $_[0] == $ATTRIBUTE_LIST;
    return "loop"                 if $_[0] == $ATTRIBUTE_LOOP;
    return "low"                  if $_[0] == $ATTRIBUTE_LOW;
    return "manifest"             if $_[0] == $ATTRIBUTE_MANIFEST;
    return "max"                  if $_[0] == $ATTRIBUTE_MAX;
    return "maxlength"            if $_[0] == $ATTRIBUTE_MAXLENGTH;
    return "media"                if $_[0] == $ATTRIBUTE_MEDIA;
    return "menu"                 if $_[0] == $ATTRIBUTE_MENU;
    return "method"               if $_[0] == $ATTRIBUTE_METHOD;
    return "min"                  if $_[0] == $ATTRIBUTE_MIN;
    return "minlength"            if $_[0] == $ATTRIBUTE_MINLENGTH;
    return "multiple"             if $_[0] == $ATTRIBUTE_MULTIPLE;
    return "muted"                if $_[0] == $ATTRIBUTE_MUTED;
    return "name"                 if $_[0] == $ATTRIBUTE_NAME;
    return "nonce"                if $_[0] == $ATTRIBUTE_NONCE;
    return "novalidate"           if $_[0] == $ATTRIBUTE_NOVALIDATE;
    return "open"                 if $_[0] == $ATTRIBUTE_OPEN;
    return "optimum"              if $_[0] == $ATTRIBUTE_OPTIMUM;
    return "pattern"              if $_[0] == $ATTRIBUTE_PATTERN;
    return "ping"                 if $_[0] == $ATTRIBUTE_PING;
    return "placeholder"          if $_[0] == $ATTRIBUTE_PLACEHOLDER;
    return "poster"               if $_[0] == $ATTRIBUTE_POSTER;
    return "preload"              if $_[0] == $ATTRIBUTE_PRELOAD;
    return "radiogroup"           if $_[0] == $ATTRIBUTE_RADIOGROUP;
    return "readonly"             if $_[0] == $ATTRIBUTE_READONLY;
    return "referrerpolicy"       if $_[0] == $ATTRIBUTE_REFERRERPOLICY;
    return "rel"                  if $_[0] == $ATTRIBUTE_REL;
    return "required"             if $_[0] == $ATTRIBUTE_REQUIRED;
    return "reversed"             if $_[0] == $ATTRIBUTE_REVERSED;
    return "rows"                 if $_[0] == $ATTRIBUTE_ROWS;
    return "rowspan"              if $_[0] == $ATTRIBUTE_ROWSPAN;
    return "sandbox"              if $_[0] == $ATTRIBUTE_SANDBOX;
    return "scope"                if $_[0] == $ATTRIBUTE_SCOPE;
    return "selected"             if $_[0] == $ATTRIBUTE_SELECTED;
    return "shape"                if $_[0] == $ATTRIBUTE_SHAPE;
    return "size"                 if $_[0] == $ATTRIBUTE_SIZE;
    return "sizes"                if $_[0] == $ATTRIBUTE_SIZES;
    return "slot"                 if $_[0] == $ATTRIBUTE_SLOT;
    return "span"                 if $_[0] == $ATTRIBUTE_SPAN;
    return "spellcheck"           if $_[0] == $ATTRIBUTE_SPELLCHECK;
    return "src"                  if $_[0] == $ATTRIBUTE_SRC;
    return "srcdoc"               if $_[0] == $ATTRIBUTE_SRCDOC;
    return "srclang"              if $_[0] == $ATTRIBUTE_SRCLANG;
    return "srcset"               if $_[0] == $ATTRIBUTE_SRCSET;
    return "start"                if $_[0] == $ATTRIBUTE_START;
    return "step"                 if $_[0] == $ATTRIBUTE_STEP;
    return "style"                if $_[0] == $ATTRIBUTE_STYLE;
    return "tabindex"             if $_[0] == $ATTRIBUTE_TABINDEX;
    return "target"               if $_[0] == $ATTRIBUTE_TARGET;
    return "title"                if $_[0] == $ATTRIBUTE_TITLE;
    return "translate"            if $_[0] == $ATTRIBUTE_TRANSLATE;
    return "type"                 if $_[0] == $ATTRIBUTE_TYPE;
    return "typemustmatch"        if $_[0] == $ATTRIBUTE_TYPEMUSTMATCH;
    return "usemap"               if $_[0] == $ATTRIBUTE_USEMAP;
    return "value"                if $_[0] == $ATTRIBUTE_VALUE;
    return "width"                if $_[0] == $ATTRIBUTE_WIDTH;
    return "?";
}

#----- События -----------------------------------------------------------------
#-------------------------------------------------------------------------------

sub event_id_to_name
{
    return "onabort"              if $_[0] == $EVENT_ONABORT;
    return "onafterprint"         if $_[0] == $EVENT_ONAFTERPRINT;
    return "onbeforeprint"        if $_[0] == $EVENT_ONBEFOREPRINT;
    return "onbeforeunload"       if $_[0] == $EVENT_ONBEFOREUNLOAD;
    return "onblur"               if $_[0] == $EVENT_ONBLUR;
    return "oncancel"             if $_[0] == $EVENT_ONCANCEL;
    return "oncanplay"            if $_[0] == $EVENT_ONCANPLAY;
    return "oncanplaythrough"     if $_[0] == $EVENT_ONCANPLAYTHROUGH;
    return "onchange"             if $_[0] == $EVENT_ONCHANGE;
    return "onclick"              if $_[0] == $EVENT_ONCLICK;
    return "onclose"              if $_[0] == $EVENT_ONCLOSE;
    return "oncontextmenu"        if $_[0] == $EVENT_ONCONTEXTMENU;
    return "oncopy"               if $_[0] == $EVENT_ONCOPY;
    return "oncuechange"          if $_[0] == $EVENT_ONCUECHANGE;
    return "oncut"                if $_[0] == $EVENT_ONCUT;
    return "ondblclick"           if $_[0] == $EVENT_ONDBLCLICK;
    return "ondrag"               if $_[0] == $EVENT_ONDRAG;
    return "ondragend"            if $_[0] == $EVENT_ONDRAGEND;
    return "ondragenter"          if $_[0] == $EVENT_ONDRAGENTER;
    return "ondragexit"           if $_[0] == $EVENT_ONDRAGEXIT;
    return "ondragleave"          if $_[0] == $EVENT_ONDRAGLEAVE;
    return "ondragover"           if $_[0] == $EVENT_ONDRAGOVER;
    return "ondragstart"          if $_[0] == $EVENT_ONDRAGSTART;
    return "ondrop"               if $_[0] == $EVENT_ONDROP;
    return "ondurationchange"     if $_[0] == $EVENT_ONDURATIONCHANGE;
    return "onemptied"            if $_[0] == $EVENT_ONEMPTIED;
    return "onended"              if $_[0] == $EVENT_ONENDED;
    return "onerror"              if $_[0] == $EVENT_ONERROR;
    return "onfocus"              if $_[0] == $EVENT_ONFOCUS;
    return "onhashchange"         if $_[0] == $EVENT_ONHASHCHANGE;
    return "oninput"              if $_[0] == $EVENT_ONINPUT;
    return "oninvalid"            if $_[0] == $EVENT_ONINVALID;
    return "onkeydown"            if $_[0] == $EVENT_ONKEYDOWN;
    return "onkeypress"           if $_[0] == $EVENT_ONKEYPRESS;
    return "onkeyup"              if $_[0] == $EVENT_ONKEYUP;
    return "onlanguagechange"     if $_[0] == $EVENT_ONLANGUAGECHANGE;
    return "onload"               if $_[0] == $EVENT_ONLOAD;
    return "onloadeddata"         if $_[0] == $EVENT_ONLOADEDDATA;
    return "onloadedmetadata"     if $_[0] == $EVENT_ONLOADEDMETADATA;
    return "onloadstart"          if $_[0] == $EVENT_ONLOADSTART;
    return "onmessage"            if $_[0] == $EVENT_ONMESSAGE;
    return "onmousedown"          if $_[0] == $EVENT_ONMOUSEDOWN;
    return "onmouseenter"         if $_[0] == $EVENT_ONMOUSEENTER;
    return "onmouseleave"         if $_[0] == $EVENT_ONMOUSELEAVE;
    return "onmousemove"          if $_[0] == $EVENT_ONMOUSEMOVE;
    return "onmouseout"           if $_[0] == $EVENT_ONMOUSEOUT;
    return "onmouseover"          if $_[0] == $EVENT_ONMOUSEOVER;
    return "onmouseup"            if $_[0] == $EVENT_ONMOUSEUP;
    return "onoffline"            if $_[0] == $EVENT_ONOFFLINE;
    return "ononline"             if $_[0] == $EVENT_ONONLINE;
    return "onpagehide"           if $_[0] == $EVENT_ONPAGEHIDE;
    return "onpageshow"           if $_[0] == $EVENT_ONPAGESHOW;
    return "onpaste"              if $_[0] == $EVENT_ONPASTE;
    return "onpause"              if $_[0] == $EVENT_ONPAUSE;
    return "onplay"               if $_[0] == $EVENT_ONPLAY;
    return "onplaying"            if $_[0] == $EVENT_ONPLAYING;
    return "onpopstate"           if $_[0] == $EVENT_ONPOPSTATE;
    return "onprogress"           if $_[0] == $EVENT_ONPROGRESS;
    return "onratechange"         if $_[0] == $EVENT_ONRATECHANGE;
    return "onrejectionhandled"   if $_[0] == $EVENT_ONREJECTIONHANDLED;
    return "onreset"              if $_[0] == $EVENT_ONRESET;
    return "onresize"             if $_[0] == $EVENT_ONRESIZE;
    return "onscroll"             if $_[0] == $EVENT_ONSCROLL;
    return "onseeked"             if $_[0] == $EVENT_ONSEEKED;
    return "onseeking"            if $_[0] == $EVENT_ONSEEKING;
    return "onselect"             if $_[0] == $EVENT_ONSELECT;
    return "onshow"               if $_[0] == $EVENT_ONSHOW;
    return "onstalled"            if $_[0] == $EVENT_ONSTALLED;
    return "onstorage"            if $_[0] == $EVENT_ONSTORAGE;
    return "onsubmit"             if $_[0] == $EVENT_ONSUBMIT;
    return "onsuspend"            if $_[0] == $EVENT_ONSUSPEND;
    return "ontimeupdate"         if $_[0] == $EVENT_ONTIMEUPDATE;
    return "ontoggle"             if $_[0] == $EVENT_ONTOGGLE;
    return "onunhandledrejection" if $_[0] == $EVENT_ONUNHANDLEDREJECTION;
    return "onunload"             if $_[0] == $EVENT_ONUNLOAD;
    return "onvolumechange"       if $_[0] == $EVENT_ONVOLUMECHANGE;
    return "onwheel"              if $_[0] == $EVENT_ONWHEEL;
    return "?";
}

#----- Типы документа ----------------------------------------------------------
#-------------------------------------------------------------------------------

sub documenttype_id_to_name
{
    return "+//silmaril//dtd html pro v0r11 19970101//"                                     if $_[0] == $DOCUMENTTYPE_SILMARILDTDHTMLPROV0R1119970101;
    return "-//advasoft ltd//dtd html 3.0 aswedit + extensions//"                           if $_[0] == $DOCUMENTTYPE_ADVASOFTLTDDTDHTML30ASWEDITEXTENSIONS;
    return "-//as//dtd html 3.0 aswedit + extensions//"                                     if $_[0] == $DOCUMENTTYPE_ASDTDHTML30ASWEDITEXTENSIONS;
    return "-//ietf//dtd html 2.0 level 1//"                                                if $_[0] == $DOCUMENTTYPE_IETFDTDHTML20LEVEL1;
    return "-//ietf//dtd html 2.0 level 2//"                                                if $_[0] == $DOCUMENTTYPE_IETFDTDHTML20LEVEL2;
    return "-//ietf//dtd html 2.0 strict level 1//"                                         if $_[0] == $DOCUMENTTYPE_IETFDTDHTML20STRICTLEVEL1;
    return "-//ietf//dtd html 2.0 strict level 2//"                                         if $_[0] == $DOCUMENTTYPE_IETFDTDHTML20STRICTLEVEL2;
    return "-//ietf//dtd html 2.0 strict//"                                                 if $_[0] == $DOCUMENTTYPE_IETFDTDHTML20STRICT;
    return "-//ietf//dtd html 2.0//"                                                        if $_[0] == $DOCUMENTTYPE_IETFDTDHTML20;
    return "-//ietf//dtd html 2.1e//"                                                       if $_[0] == $DOCUMENTTYPE_IETFDTDHTML21E;
    return "-//ietf//dtd html 3.0//"                                                        if $_[0] == $DOCUMENTTYPE_IETFDTDHTML30;
    return "-//ietf//dtd html 3.2 final//"                                                  if $_[0] == $DOCUMENTTYPE_IETFDTDHTML32FINAL;
    return "-//ietf//dtd html 3.2//"                                                        if $_[0] == $DOCUMENTTYPE_IETFDTDHTML32;
    return "-//ietf//dtd html 3//"                                                          if $_[0] == $DOCUMENTTYPE_IETFDTDHTML3;
    return "-//ietf//dtd html level 0//"                                                    if $_[0] == $DOCUMENTTYPE_IETFDTDHTMLLEVEL0;
    return "-//ietf//dtd html level 1//"                                                    if $_[0] == $DOCUMENTTYPE_IETFDTDHTMLLEVEL1;
    return "-//ietf//dtd html level 2//"                                                    if $_[0] == $DOCUMENTTYPE_IETFDTDHTMLLEVEL2;
    return "-//ietf//dtd html level 3//"                                                    if $_[0] == $DOCUMENTTYPE_IETFDTDHTMLLEVEL3;
    return "-//ietf//dtd html strict level 0//"                                             if $_[0] == $DOCUMENTTYPE_IETFDTDHTMLSTRICTLEVEL0;
    return "-//ietf//dtd html strict level 1//"                                             if $_[0] == $DOCUMENTTYPE_IETFDTDHTMLSTRICTLEVEL1;
    return "-//ietf//dtd html strict level 2//"                                             if $_[0] == $DOCUMENTTYPE_IETFDTDHTMLSTRICTLEVEL2;
    return "-//ietf//dtd html strict level 3//"                                             if $_[0] == $DOCUMENTTYPE_IETFDTDHTMLSTRICTLEVEL3;
    return "-//ietf//dtd html strict//"                                                     if $_[0] == $DOCUMENTTYPE_IETFDTDHTMLSTRICT;
    return "-//ietf//dtd html//"                                                            if $_[0] == $DOCUMENTTYPE_IETFDTDHTML;
    return "-//metrius//dtd metrius presentational//"                                       if $_[0] == $DOCUMENTTYPE_METRIUSDTDMETRIUSPRESENTATIONAL;
    return "-//microsoft//dtd internet explorer 2.0 html strict//"                          if $_[0] == $DOCUMENTTYPE_MICROSOFTDTDINTERNETEXPLORER20HTMLSTRICT;
    return "-//microsoft//dtd internet explorer 2.0 html//"                                 if $_[0] == $DOCUMENTTYPE_MICROSOFTDTDINTERNETEXPLORER20HTML;
    return "-//microsoft//dtd internet explorer 2.0 tables//"                               if $_[0] == $DOCUMENTTYPE_MICROSOFTDTDINTERNETEXPLORER20TABLES;
    return "-//microsoft//dtd internet explorer 3.0 html strict//"                          if $_[0] == $DOCUMENTTYPE_MICROSOFTDTDINTERNETEXPLORER30HTMLSTRICT;
    return "-//microsoft//dtd internet explorer 3.0 html//"                                 if $_[0] == $DOCUMENTTYPE_MICROSOFTDTDINTERNETEXPLORER30HTML;
    return "-//microsoft//dtd internet explorer 3.0 tables//"                               if $_[0] == $DOCUMENTTYPE_MICROSOFTDTDINTERNETEXPLORER30TABLES;
    return "-//netscape comm. corp.//dtd html//"                                            if $_[0] == $DOCUMENTTYPE_NETSCAPECOMMCORPDTDHTML;
    return "-//netscape comm. corp.//dtd strict html//"                                     if $_[0] == $DOCUMENTTYPE_NETSCAPECOMMCORPDTDSTRICTHTML;
    return "-//o'reilly and associates//dtd html 2.0//"                                     if $_[0] == $DOCUMENTTYPE_OREILLYANDASSOCIATESDTDHTML20;
    return "-//o'reilly and associates//dtd html extended 1.0//"                            if $_[0] == $DOCUMENTTYPE_OREILLYANDASSOCIATESDTDHTMLEXTENDED10;
    return "-//o'reilly and associates//dtd html extended relaxed 1.0//"                    if $_[0] == $DOCUMENTTYPE_OREILLYANDASSOCIATESDTDHTMLEXTENDEDRELAXED10;
    return "-//softquad software//dtd hotmetal pro 6.0::19990601::extensions to html 4.0//" if $_[0] == $DOCUMENTTYPE_SOFTQUADSOFTWAREDTDHOTMETALPRO6019990601EXTENSIONSTOHTML40;
    return "-//softquad//dtd hotmetal pro 4.0::19971010::extensions to html 4.0//"          if $_[0] == $DOCUMENTTYPE_SOFTQUADDTDHOTMETALPRO4019971010EXTENSIONSTOHTML40;
    return "-//spyglass//dtd html 2.0 extended//"                                           if $_[0] == $DOCUMENTTYPE_SPYGLASSDTDHTML20EXTENDED;
    return "-//sq//dtd html 2.0 hotmetal + extensions//"                                    if $_[0] == $DOCUMENTTYPE_SQDTDHTML20HOTMETALEXTENSIONS;
    return "-//sun microsystems corp.//dtd hotjava html//"                                  if $_[0] == $DOCUMENTTYPE_SUNMICROSYSTEMSCORPDTDHOTJAVAHTML;
    return "-//sun microsystems corp.//dtd hotjava strict html//"                           if $_[0] == $DOCUMENTTYPE_SUNMICROSYSTEMSCORPDTDHOTJAVASTRICTHTML;
    return "-//w3c//dtd html 3 1995-03-24//"                                                if $_[0] == $DOCUMENTTYPE_W3CDTDHTML319950324;
    return "-//w3c//dtd html 3.2 draft//"                                                   if $_[0] == $DOCUMENTTYPE_W3CDTDHTML32DRAFT;
    return "-//w3c//dtd html 3.2 final//"                                                   if $_[0] == $DOCUMENTTYPE_W3CDTDHTML32FINAL;
    return "-//w3c//dtd html 3.2//"                                                         if $_[0] == $DOCUMENTTYPE_W3CDTDHTML32;
    return "-//w3c//dtd html 3.2s draft//"                                                  if $_[0] == $DOCUMENTTYPE_W3CDTDHTML32SDRAFT;
    return "-//w3c//dtd html 4.0 frameset//"                                                if $_[0] == $DOCUMENTTYPE_W3CDTDHTML40FRAMESET;
    return "-//w3c//dtd html 4.0 transitional//"                                            if $_[0] == $DOCUMENTTYPE_W3CDTDHTML40TRANSITIONAL;
    return "-//w3c//dtd html 4.01 frameset//"                                               if $_[0] == $DOCUMENTTYPE_W3CDTDHTML401FRAMESET;  
    return "-//w3c//dtd html 4.01 transitional//"                                           if $_[0] == $DOCUMENTTYPE_W3CDTDHTML401TRANSITIONAL; 
    return "-//w3c//dtd html experimental 19960712//"                                       if $_[0] == $DOCUMENTTYPE_W3CDTDHTMLEXPERIMENTAL19960712;
    return "-//w3c//dtd html experimental 970421//"                                         if $_[0] == $DOCUMENTTYPE_W3CDTDHTMLEXPERIMENTAL970421;
    return "-//w3c//dtd w3 html//"                                                          if $_[0] == $DOCUMENTTYPE_W3CDTDW3HTML;
    return "-//w3c//dtd xhtml 1.0 frameset//"                                               if $_[0] == $DOCUMENTTYPE_W3CDTDXHTML10FRAMESET;
    return "-//w3c//dtd xhtml 1.0 transitional//"                                           if $_[0] == $DOCUMENTTYPE_W3CDTDXHTML10TRANSITIONAL;
    return "-//w3o//dtd w3 html 3.0//"                                                      if $_[0] == $DOCUMENTTYPE_W3ODTDW3HTML30;
    return "-//w3o//dtd w3 html strict 3.0//en//"                                           if $_[0] == $DOCUMENTTYPE_W3ODTDW3HTMLSTRICT30EN;
    return "-//webtechs//dtd mozilla html 2.0//"                                            if $_[0] == $DOCUMENTTYPE_WEBTECHSDTDMOZILLAHTML20;
    return "-//webtechs//dtd mozilla html//"                                                if $_[0] == $DOCUMENTTYPE_WEBTECHSDTDMOZILLAHTML;
    return "-/w3c/dtd html 4.0 transitional/en"                                             if $_[0] == $DOCUMENTTYPE_W3CDTDHTML40TRANSITIONALEN;
    return "html"                                                                           if $_[0] == $DOCUMENTTYPE_HTML;
    return "http://www.ibm.com/data/dtd/v11/ibmxhtml1-transitional.dtd"                     if $_[0] == $DOCUMENTTYPE_HTTPWWWIBMCOMDATADTDV11IBMXHTML1TRANSITIONALDTD;
    return "?";
}

1;