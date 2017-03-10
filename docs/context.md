# Контекст парсера

    context = {
    
        'flags'          => PARSER_FLAG_SCRIPTING           |
                            PARSER_FLAG_QUIRKS_MODE_QUIRKS  |
                            PARSER_FLAG_QUIRKS_MODE_LIMITED |
                            PARSER_FLAG_FOSTER_PARENTING    |
                            PARSER_FLAG_FRAMESET_OK*        |
                            PARSER_FLAG_FORM_POINTER,
    
        'inbuffer'       => \@,   # Буфер входных данных.
        'inbufferlength' => NUM,  # Количество байт во входном буфере.
        'inbufferindex'  => NUM,  # Текущий индекс входного буфера.

        'data'           => \@,   # Байтовый массив входных данных.
        'datalength'     => NUM,  # Количество байт во входном массиве.
        
        dataindex???
        'index'          => NUM,  # Текущий индекс входного массива.

        'scannerstate'   => \&,   # Обработчик текущего состояния сканера.
        'parserstate'    => \&,   # Обработчик текущего состояния парсера.
        
        'nodeready'      => BOOL, # Состояние готовности нового узла.
        'node'           => \%,   # Текущий обрабатываемый узел.
        
        'rawswitch'      => \%,   # Параметры обработки RAW-данных.

        'document'       => \%,   # Узел DOCUMENT.
        #'documenttype'   => \%,   # Узел DOCTYPE.
        
        #'htmlelement'    => \%,   # Элемент <HTML>
        #'headelement'    => \%,   # Элемент <HEAD>
        #'bodyelement'    => \%,   # Элемент <BODY>
       #?'formelement'    => \%,   # Указатель на элемент <FORM>.
       # 'contextelement' => \%,   # Контекстовый элемент фрагмента.
        'form'            => \%,   # Ссылка на <FORM>
        'context'         => \%,   # Ссылка на rонтекстовый элемент фрагмента.
        
        'afe'            => \%,   # Список AFE.
        'soe'            => \%,   # Список SOE.
        'sti'            => \@,   # Массив STI.
        
        'jscontext'      => NUM,  # Контекст JS движка.
        'jscallback'     => \&    # Обработчик скрипта.
    }
