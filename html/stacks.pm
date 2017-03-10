#===============================================================================
#       Стеки
#===============================================================================

package WebGear::HTML::Stacks;
use strict;

use Exporter qw(import);
our @EXPORT = qw(
    soe_push
    soe_insert_after
    soe_pop
    soe_pop_unless_bitset
    soe_pop_until_bitset
    soe_pop_until_id
    soe_remove
    soe_replace
    soe_search_id
    soe_search_id_until_bitset
    soe_search_bitset_until_bitset
    afe_push
    afe_insert_after
    afe_remove
    afe_replace
    afe_search_id
    afe_reconstruct
    afe_clear
    afe_insert_marker
);

use WebGear::HTML::Constants;
use WebGear::HTML::Filter;
use WebGear::HTML::DOM;
use WebGear::HTML::Utilities;

#----- STI ---------------------------------------------------------------------
#       Stack of template insertion modes
#
# https://html.spec.whatwg.org/multipage/syntax.html#stack-of-template-insertion-modes
# https://www.w3.org/TR/html/syntax.html#stack-of-template-insertion-modes
#
# В текущей реализации является массивом Перл.
# Подпрограммы sti_push и sti_pop реализована через FILTER.
#-------------------------------------------------------------------------------

#----- SOE ---------------------------------------------------------------------
#       The stack of open elements
#
# https://html.spec.whatwg.org/multipage/syntax.html#stack-of-open-elements
# https://www.w3.org/TR/html/syntax.html#the-stack-of-open-elements
#
# Стеки SOE и AFE реализованы в виде связанных списков, свзь в списках идет через
# соответствующие поля в элементах обеспечивая доступ к обоим стекам одновременно.
# Предполагается что в стеке присутствуют как минимум два узла - DOCUMENT и
# элемент <HTML>, узел DOCUMENT помещается в стек во время инициализации напрямую.
# Подпрограмма soe_contain реализована через FILTER.
#-------------------------------------------------------------------------------

sub soe_push
{
    my ($context, $element) = @_;

    $element->{'soeprevious'} = $context->{'soe'};

    $context->{'soe'}{'soenext'} = $element;
    $context->{'soe'} = $element;
}

sub soe_insert_after
{
    my ($context, $referenceelement, $element) = @_;

    if ($referenceelement->{'soenext'}) {
        $referenceelement->{'soenext'}{'soeprevious'} = $element;
    } else {
        $context->{'soe'} = $element;
    }

    $element->{'soeprevious'} = $referenceelement;
    $element->{'soenext'}     = $referenceelement->{'soenext'};

    $referenceelement->{'soenext'} = $element;
}

sub soe_pop
{
    my ($context) = @_;

    $context->{'soe'} = $context->{'soe'}{'soeprevious'};

    $context->{'soe'}{'soenext'}{'soeprevious'} = $NULL;
    $context->{'soe'}{'soenext'} = $NULL;
}

sub soe_pop_until_id
{
    my ($context, $tagid) = @_;
    my ($element);

    while ($element = $context->{'soe'}) {
        $context->{'soe'} = $element->{'soeprevious'};
        $context->{'soe'}{'soenext'} = $NULL;

        $element->{'soeprevious'} = $NULL;

        if ($element->{'id'} == $tagid) {
            last;
        }
    }
}

sub soe_pop_until_bitset
{
    my ($context, $bitset) = @_;
    my ($element);

    while ($element = $context->{'soe'}) {
        $context->{'soe'} = $element->{'soeprevious'};
        $context->{'soe'}{'soenext'} = $element->{'soeprevious'} = $NULL;

        if (bitset_test($bitset, $element->{'id'})) {
            last;
        }
    }
}

sub soe_pop_unless_bitset
{
    my ($context, $bitset) = @_;

    while (!bitset_test($bitset, $context->{'soe'}{'id'})) {
        $context->{'soe'} = $context->{'soe'}{'soeprevious'};
        $context->{'soe'}{'soenext'}{'soeprevious'} = $NULL;
        $context->{'soe'}{'soenext'} = $NULL;
    }
}

sub soe_remove
{
    my ($context, $element) = @_;

    if ($element->{'soenext'}) {
        $element->{'soenext'}{'soeprevious'} = $element->{'soeprevious'};
    } else {
        $context->{'soe'} = $element->{'soeprevious'};
    }

    $element->{'soeprevious'}{'soenext'} = $element->{'soenext'};
    $element->{'soeprevious'} = $NULL;
    $element->{'soenext'}     = $NULL;
}

sub soe_replace
{
    my ($context, $oldelement, $element) = @_;

    if ($oldelement->{'soenext'}) {
        $oldelement->{'soenext'}{'soeprevious'} = $element;
    } else {
        $context->{'soe'} = $element;
    }

    $oldelement->{'soeprevious'}{'soenext'} = $element;

    $element->{'soeprevious'} = $oldelement->{'soeprevious'};
    $element->{'soenext'}     = $oldelement->{'soenext'};

    $oldelement->{'soeprevious'} = $NULL;
    $oldelement->{'soenext'}     = $NULL;
}

sub soe_search_id
{
    my ($context, $tagid) = @_;
    my ($element);

    $element = $context->{'soe'};

    while ($element) {

        if ($element->{'id'} == $tagid) {
            return $element;
        }

        $element = $element->{'soeprevious'};
    }

    return $NULL;
}

sub soe_search_id_until_bitset
{
    my ($context, $bitsetscope, $tagid) = @_;
    my ($element);

    $element = $context->{'soe'};

    while ($element) {

        if ($element->{'id'} == $tagid) {
            return $element;
        }

        if (bitset_test($bitsetscope, $element->{'id'})) {
            return $NULL;
        }

        $element = $element->{'soeprevious'};
    }
}

sub soe_search_bitset_until_bitset
{
    my ($context, $bitsetscope, $bitset) = @_;
    my ($element);

    $element = $context->{'soe'};

    while ($element) {

        if (bitset_test($bitset, $element->{'id'})) {
            return $element;
        }

        if (bitset_test($bitsetscope, $element->{'id'})) {
            return $NULL;
        }

        $element = $element->{'soeprevious'};
    }
}

#----- AFE ---------------------------------------------------------------------
#       The list of active formatting elements
#
# https://html.spec.whatwg.org/multipage/syntax.html#list-of-active-formatting-elements
# https://www.w3.org/TR/html/syntax.html#the-list-of-active-formatting-elements
#
# В отличии от SOE, стек может быть пустым, поэтому нужны дополнительные проверки
# в подпрограммах.
# "Маркер" определенный в спецификации не является отдельным элементом, а реализован
# в виде счетчика в соответствующем поле предшествующего элемента, если список пуст,
# маркер игнорируется. Идущие подряд маркеры увеличивают счетчик.
# Подпрограмма afe_contain реализована через FILTER.
#-------------------------------------------------------------------------------

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#push-onto-the-list-of-active-formatting-elements
# https://www.w3.org/TR/html/syntax.html#push-onto-the-list-of-active-formatting-elements
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub afe_push
{
    my ($context, $element) = @_;
    my ($counter, $previouselement, $earliestelement);

    $counter         = 0;
    $previouselement = $context->{'afe'};

    while ($previouselement && !$previouselement->{'afemarkers'}) {

        if ($previouselement->{'id'} == $element->{'id'} && element_compare_attributes($previouselement, $element)) {
            $earliestelement = $previouselement;
            $counter++;
        }

        $previouselement = $previouselement->{'afeprevious'};
    }

    if ($counter >= 3) {
        afe_remove($context, $earliestelement);
    }

    if ($context->{'afe'}) {
        $context->{'afe'}{'afenext'} = $element;
        $element->{'afeprevious'}    = $context->{'afe'};
    }

    $context->{'afe'} = $element;
}

sub afe_insert_after
{
    my ($context, $referenceelement, $element) = @_;

    if ($referenceelement->{'afenext'}) {
        $referenceelement->{'afenext'}{'afeprevious'} = $element;
    } else {
        $context->{'afe'} = $element;
    }

    $element->{'afeprevious'} = $referenceelement;
    $element->{'afenext'}     = $referenceelement->{'afenext'};

    $referenceelement->{'afenext'} = $element;
}

sub afe_remove
{
    my ($context, $element) = @_;

    if ($element->{'afenext'}) {
        $element->{'afenext'}{'afeprevious'} = $element->{'afeprevious'};
    } else {
        $context->{'afe'} = $element->{'afeprevious'};
    }

    if ($element->{'afeprevious'}) {
        $element->{'afeprevious'}{'afenext'} = $element->{'afenext'};
    }

    $element->{'afeprevious'} = $NULL;
    $element->{'afenext'}     = $NULL;
}

sub afe_replace
{
    my ($context, $oldelement, $element) = @_;

    if ($oldelement->{'afeprevious'}) {
        $oldelement->{'afeprevious'}{'afenext'} = $element;
    }

    if ($oldelement->{'afenext'}) {
        $oldelement->{'afenext'}{'afeprevious'} = $element;
    } else {
        $context->{'afe'} = $element;
    }

    $element->{'afeprevious'} = $oldelement->{'afeprevious'};
    $element->{'afenext'}     = $oldelement->{'afenext'};

    $oldelement->{'afeprevious'} = $NULL;
    $oldelement->{'afenext'}     = $NULL;
}

sub afe_search_id
{
    my ($context, $tagid) = @_;
    my ($element);

    $element = $context->{'afe'};

    while ($element && !$element->{'afemarkers'}) {

        if ($element->{'id'} == $tagid) {
            return $element;
        }

        $element = $element->{'afeprevious'};
    }

    return $NULL;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#reconstruct-the-active-formatting-elements
# https://www.w3.org/TR/html/syntax.html#elements-reconstruct-the-active-formatting-element
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub afe_reconstruct
{
    my ($context) = @_;
    my ($element, $newelement);

    if (!$context->{'afe'} || $context->{'afe'}{'afemarkers'} || soe_contain($context, $context->{'afe'})) {
        return;
    }

    $element = $context->{'afe'};

    while ($element->{'afeprevious'}) {

        if ($element->{'afeprevious'}{'afemarkers'} || soe_contain($context, $element->{'afeprevious'})) {
            last;
        }

        $element = $element->{'afeprevious'};
    }

    while ($element) {
        $newelement = node_create_element(0, $element->{'id'}, '', 0);
        element_merge_attributes($newelement, $element);

        node_insert($context, $context->{'soe'}, $newelement);
        soe_push($context, $newelement);
        afe_replace($context, $element, $newelement);

        $element = $newelement->{'afenext'};
    }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# https://html.spec.whatwg.org/multipage/syntax.html#clear-the-list-of-active-formatting-elements-up-to-the-last-marker
# https://www.w3.org/TR/html/syntax.html#clear-the-list-of-active-formatting-elements-up-to-the-last-marker
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub afe_clear
{
    my ($context) = @_;
    my ($element);

    while ($element = $context->{'afe'}) {
        # Необходимо обнуление перед возможным выходом.
        $element->{'afenext'} = $NULL;

        if ($element->{'afemarkers'}) {
            $element->{'afemarkers'}--;
            last;
        }

        $context->{'afe'} = $element->{'afeprevious'};
        $element->{'afeprevious'} = $NULL;
    }
}

sub afe_insert_marker
{
    my ($context) = @_;
    
    if ($context->{'afe'}) { 
        $context->{'afe'}{'afemarkers'}++;
    }
}

1;