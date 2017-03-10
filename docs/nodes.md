# Структуры узлов

### Типы узлов

 Используются следующие типы узлов определенные в [Node](https://dom.spec.whatwg.org/#node):

    NODE_TYPE_ELEMENT    1
    NODE_TYPE_ATTRIBUTE  2
    NODE_TYPE_TEXT       3
    NODE_TYPE_COMMENT    8
    NODE_TYPE_DOCUMENT   9
    NODE_TYPE_DOCTYPE   10

 Также добавлены новые типы используемые парсером:

    NODE_TYPE_START_TAG  1  синоним NODE_TYPE_ELEMENT
    NODE_TYPE_END_TAG   12
    NODE_TYPE_EVENT     13
    NODE_TYPE_EOF       14

## Корневой узел

    document => {
        'type'                => NODE_TYPE_DOCUMENT,
        'flags'               => 0,

        'parent'              => NULL, # Родительский узел всегда NULL.
        'previoussibling'     => NULL, # Предыдущий сестринский узел всегда NULL.
        'nextsibling'         => NULL, # Следующий сестринский узел всегда NULL.
        'firstchild'          => \%,   # Первый дочерний узел.
        'lastchild'           => \%,   # Последний дочерний узел.

        'documenttype'        => \%,   # Ссылка на <DOCTYPE>       
        'html'                => \%,   # Ссылка на <HTML>
        'head'                => \%,   # Ссылка на <HEAD>
        'title'               => \%,   # Ссылка на <TITLE>
        'body'                => \%,   # Ссылка на <BODY>
        
        'soeprevious'         => \%,   # Предыдущий узел в списке SOE. /Парсер
        'soenext'             => \%,   # Следующий узел в списке SOE.  /Парсер
        
        'object'              => NUM   # Ссылка на внешний объект.     /JS
    }
    
### `soe/afe`

 Корневой узел присутствует только в стеке `SOE`.    
    
## Элемент

    element => {
        'type'                => NODE_TYPE_ELEMENT | NODE_TYPE_START_TAG,
        'flags'               => 0 | TOKEN_FLAG_SELF_CLOSING,

        'parent'              => \%,   # Родительский узел.
        'previoussibling'     => \%,   # Предыдущий сестринский узел.
        'nextsibling'         => \%,   # Следующий сестринский узел.
        'firstchild'          => \%,   # Первый дочерний узел.
        'lastchild'           => \%,   # Последний дочерний узел.

        'id'                  => NUM,  # ID тега.
        'name'                => STR,  # Имя тега.
        'namelength'          => NUM,  # Длина имени тега в байтах.
        
        'attributes'          => \%,   # Хэш атрибутов.

        'soeprevious'         => \%,   # Предыдущий узел в списке SOE. /Парсер
        'soenext'             => \%,   # Следующий узел в списке SOE.  /Парсер
        'afeprevious'         => \%,   # Предыдущий узел в списке AFE. /Парсер
        'afenext'             => \%,   # Следующий узел в списке AFE.  /Парсер
        'afemarkers'          => NUM   # Маркеры AFE.                  /Парсер

        'object'              => NUM,  # Ссылка на внешний объект.     /JS
        
        'livenodelist'        => \%,   # Узел NodeList.                /JS
        'livehtmlcollections' => \%,   # Список HTMLCollection.        /JS
        
        'events'              => \%    # Хэш событий.                  /JS
    }


### `tagname`

 Имя тега имеет значение только для элементов с неопределенным `id`, также
в процессе работы парсера могут создаваться дополнительные узлы с определенными
тегами, но без имен в буфере данных.

### `attributes/events`

 Хэши с именами атрибутов или типов событий в качестве ключа.

### `soe/afe`

 Стеки
[The stack of open elements](https://html.spec.whatwg.org/multipage/syntax.html#stack-of-open-elements)
и
[The list of active formatting elements](https://html.spec.whatwg.org/multipage/syntax.html#push-onto-the-list-of-active-formatting-elements)
реализованны как связанные списки и используют соответствующие поля узла.

### `livenodelist`

  Поле хранит узел `NodeList` представляющий "живую" коллекцию всех дочерних элементов узла.

### `livehtmlcollections`

 Связанный список "живых" коллекций состоящих из узлов `HTMLCollection`.

## Закрывающий тег

 Узел закрывающего тега не используется в дереве `DOM`.

    endtag => {
        'type'                => TOKEN_TYPE_END_TAG,
        'flags'               => 0 | TOKEN_FLAG_SELF_CLOSING,

        'id'                  => NUM   # ID тега.
        'name'                => STR,  # Имя тега.
        'namelength'          => NUM,  # Длина имени тега в байтах.
    }

## Текст, Комментарий и CDATA

    text    => 
    comment => {
        'type'                => NODE_TYPE_TEXT | NODE_TYPE_COMMENT,
        'flags'               => 0 | TOKEN_FLAG_WHITESPACE,

        'parent'              => \%,   # Родительский узел.
        'previoussibling'     => \%,   # Предыдущий сестринский узел.
        'nextsibling'         => \%,   # Следующий сестринский узел.

        'data'                => STR,  # Текстовая строка.
        'datalength'          => NUM,  # Длина строки в байтах.

        'object'              => NUM   # Ссылка на внешний объект. /JS
    }

### `CDATA`

 Хотя CDATA распознается на этапе парсинга, создание объекта CDATASection в JS
должно вызывать исключение EXCEPTION_NOT_SUPPORTED_ERR, поэтому за ненадобностью
узел определен как комментарий.

### `TOKEN_FLAG_WHITESPACE`

 Флаг устанавливается для текстового узла с полностью пробельными символами.

## Тип документа

    doctype => {
        'type'                => NODE_TYPE_DOCTYPE,
        'flags'               => 0 | TOKEN_FLAG_FORCE_QUIRKS,

        'parent'              => \%,   # Родительский узел.
        'previoussibling'     => \%,   # Предыдущий сестринский узел.
        'nextsibling'         => \%,   # Следующий сестринский узел.

        'id'                  => NUM,  # ID типа документа.
        'name'                => STR,  # Имя типа документа.
        'namelength'          => NUM,  # Длина имени типа документа в байтах.

        'publicid'            => NUM,  # ID PUBLIC идентификатора.
        'public'              => STR,  # Имя PUBLIC идентификатора.
        'publiclength'        => NUM,  # Длина имени PUBLIC идентификатора в байтах.
        
        'systemid'            => NUM,  # ID SYSTEM идентификатора.
        'system'              => STR,  # Имя SYSTEM идентификатора.
        'systemlength'        => NUM,  # Длина имени SYSTEM идентификатора в байтах.    

        'object'              => NUM   # Ссылка на внешний объект. /JS
    }


## Атрибуты

    attribute => {
        'type'                => NODE_TYPE_ATTRIBUTE,

        'element'             => \%,  # Элемент которому пренадлежит атрибут.

        'id'                  => NUM, # ID атрибута.
        'name'                => NUM, # Имя атрибута.
        'namelength'          => STR, # Длина имени атрибута в байтах.

       x'valueid'             => NUM, # ID значения атрибута.
        'value'               => NUM, # Строка значения атрибута.
        'valuelength'         => STR, # Длина строки значения атрибута в байтах.

        'object'              => NUM  # Ссылка на внешний объект. /JS
    }

## События

 Событие на этапе парсинга определяется как имя атрибута с префиксом `on-`,
после создания узла, префикс убирается и становится именем типа события.

    event => {
        'type'                => NODE_TYPE_EVENT,
        'flags'               => 0 | CAPTURE,

        'element'             => \%,  # Элемент которому пренадлежит событие.

        'id'                  => NUM, # ID типа события.
        'type'                => NUM, # Имя типа событи.
        'typelength'          => STR, # Длина имени типа событи в байтах.

        'function'            => NUM, # Строка тела функции.
        'functionlength'      => STR, # Длина строки тела функции в байтах.

        'callback'            => NUM, # Скомпилированная версия функции.             /JS
        
        'previousnode'        => \%,  # Предыдущий узел в списке однотипных событий. /JS
        'nextnode'            => \%,  # Следующий узел в списке однотипных событий.  /JS 
        'lastnode'            => \%,  # Последний узел в списке однотипных событий.  /JS
        
        'nextphasenode'       => \%,  # Следующий узел в списке фазы.                /JS
    }


### `previousnode/nextnode/lastnode`

  Однотипные собыия связываются JS в список соответствующими полями. Поле `lastnode` 
первого узла указывает на самый последний узел в списке, если узел единственный
то указывает на самого себя. 

  Первый узел из списка доступен по ключу хэша `events` элемента.
  
  На этапе парсинга события обрабатываются по правилам атрибутов.

### `object`

 У события нет связи с внешним объектом.

### `functioncallback`

 Здесь хранится указатель на скомпилированную движком JS версию функции из
`functionbody`.

### `nextphasenode`

 При обработке событий `JS` строит связанный список обработчиков фазы, связывая
узлы через это поле.

## EOF

 Узел `EOF` не используется в дереве `DOM` и является последним узлом генерируемым
сканером, как и узел завершающего тега может быть определен в контексте парсера.

    eof => {
        'type'                => NODE_TYPE_EOF
    }

