#===============================================================================
#       The adoption agency algorithm
                    
# https://html.spec.whatwg.org/multipage/syntax.html#adoption-agency-algorithm
# https://www.w3.org/TR/html/syntax.html#closing-misnested-formatting-elements
#===============================================================================

package WebGear::HTML::AAA;
use strict;

use Exporter qw(import);
our @EXPORT = qw(
    aaa_process
);
                
use WebGear::HTML::Filter;
use WebGear::HTML::Constants;
use WebGear::HTML::DOM;
use WebGear::HTML::Stacks;
use WebGear::HTML::Tries;
use WebGear::HTML::Utilities;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Поле 'soenext' соответствует "below" в описании алгоритма и направлено к хвосту 
# списка, поле 'soeprevious' соответствует "above" и направлено к голове списка.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub aaa_process
{
    my ($context, $subject) = @_;
    my ($outercounter, $innercounter, $bookmark, $formattingelement, $furthestblock, $commonancestor, $previousnode, $node, $lastnode, $newelement);
    # Стековая переменная.
    $bookmark = {
        'soeprevious' => $NULL,
        'soenext'     => $NULL
    };
    # Шаг 2.
    if ($context->{'soe'}{'id'} == $subject && !afe_contain($context, $context->{'soe'})) {
        soe_pop($context); 
        return $TRUE;
    }
    # Шаг 3, 4, 5.
    for ($outercounter = 0; $outercounter < 8; $outercounter++) {
        # Шаг 6.
        $formattingelement = afe_search_id($context, $subject);

        if (!$formattingelement) {
            return $FALSE; # "any other end tag".
        }
        # Шаг 7.
        if (!soe_contain($context, $formattingelement)) {
            afe_remove($context, $formattingelement);
            return $TRUE;
        }
        # Шаг 8.
        if (!soe_search_id_until_bitset($context, $scopebitset1, $formattingelement->{'id'})) {
            return $TRUE;
        }
        # Шаг 10.
        $furthestblock = $formattingelement->{'soenext'};
    
        while ($furthestblock) {

            if (bitset_test($specialbitset1, $furthestblock->{'id'})) {
                goto L;
            }
            
            $furthestblock = $furthestblock->{'soenext'};
        }
        # Проваливание на Шаг 11.
        soe_pop_until_id($context, $formattingelement->{'id'});
        afe_remove($context, $formattingelement);
        return $TRUE;
     L:   
        # Шаг 12.
        $commonancestor = $formattingelement->{'soeprevious'};
        # Шаг 13.             
        afe_insert_after($context, $formattingelement, $bookmark);
        # Шаг 14.
        $lastnode = $furthestblock;
        # Нужно хранить указатель на предыдущий элемент на случай удаления.
        $previousnode = $furthestblock->{'soeprevious'};
        # Шаг 14.1.
        $innercounter = 0;

        while (1) {
            # Шаг 14.3.
            $node = $previousnode;
            $previousnode = $node->{'soeprevious'};
            # Шаг 14.4.
            if ($node == $formattingelement) {
                last;
            }
            # Шаг 14.2, 14.5.
            if ($innercounter++ >= 3 && afe_contain($context, $node)) {
                afe_remove($context, $node);
            }
            # Шаг 14.6
            if (!afe_contain($context, $node)) {
                soe_remove($context, $node);
                next;
            }
            # Шаг 14.7.
            # Непонятна установка "common ancestor" как родителя, здесь не 
            # используется. 
            $newelement = node_create_element(0, $node->{'id'}, '', 0);
            element_merge_attributes($newelement, $node);

            afe_replace($context, $node, $newelement);
            soe_replace($context, $node, $newelement);
                      
            $node = $newelement;
            # Шаг 14.8
            if ($lastnode == $furthestblock) {
                afe_remove($context, $bookmark);
                afe_insert_after($context, $newelement, $bookmark);
            }
            # Шаг 14.9. 
            # Может не иметь родителя, если элемент был создан на шаге 14.7.
            if ($lastnode->{'parent'}) {
                node_remove($lastnode->{'parent'}, $lastnode);
            }      

            node_append($node, $lastnode);
            # Шаг 14.10.
            $lastnode = $node;
        }
        # Шаг 15.
        # Может не иметь родителя, если элемент был создан на шаге 14.7.
        if ($lastnode->{'parent'}) {
            node_remove($lastnode->{'parent'}, $lastnode);
        } 
    
        node_insert($context, $commonancestor, $lastnode);
        # Шаг 16.
        $newelement = node_create_element(0, $node->{'id'}, '', 0);
        element_merge_attributes($newelement, $node);
        # Шаг 17.
        $newelement->{'firstchild'} = $furthestblock->{'firstchild'};
        $newelement->{'lastchild'}  = $furthestblock->{'lastchild'};
        # Изменяем родителя дочерних узлов.
        $node = $newelement->{'firstchild'};
    
        while ($node) {
            $node->{'parent'} = $newelement;
            $node = $node->{'nextsibling'};
        }
        # Шаг 18.
        # Необходимо обнулить указатели на дочерние узлы перед вызовом функции, 
        # или добавить новый элемент напрямую:
        # $newelement->{'parent'}        = $furthestblock;
        # $furthestblock->{'firstchild'} = $newelement;
        # $furthestblock->{'lastchild'}  = $newelement;
        $furthestblock->{'firstchild'} = $NULL;
        $furthestblock->{'lastchild'}  = $NULL;
        node_append($furthestblock, $newelement);
        # Шаг 19
        afe_remove($context, $formattingelement);
        afe_replace($context, $bookmark, $newelement);
        # Шаг 20
        soe_remove($context, $formattingelement);
        soe_insert_after($context, $furthestblock, $newelement);
    } 

    return $TRUE;
}

1;