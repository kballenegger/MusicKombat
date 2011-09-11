//
//  MKStack.c
//  MusicKombat
//
//  Created by Kenneth Ballenegger on 9/11/11.
//  Copyright 2011 Azure Talon. All rights reserved.
//

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include "MKStack.h"

// Simple stack


//mk_stack_element * mk_stack_make_element(mk_stack_element *stack, int val) {
//    mk_stack_element *element = (mk_stack_element *)malloc(sizeof(mk_stack_element));
//    element->head = stack;
//    element->value = val;
//    return element;
//}

//void mk_stack_free(mk_stack_element *stack) {
//    if (stack == NULL) return;
//    if (stack->head != NULL) {
//        mk_stack_free(stack->head);
//    }
//    free(stack);
//}


void mk_stack_push(mk_stack_element **head, int val) {
    mk_stack_element *element = (mk_stack_element *)malloc(sizeof(mk_stack_element));
    element->next = *head;
    element->value = val;
    *head = element;
}

mk_stack_element * mk_stack_pop(mk_stack_element **element) {
    if (*element == NULL) {
        return NULL;
    }

    mk_stack_element *head = *element;
    
    *element = (*element)->next;

    return head;
}


mk_stack_element * mk_stack_make(int first, ...) {
    va_list ap;

    mk_stack_element *last = NULL;
    
    va_start(ap, first);
    for(int val = first; val != MK_STACK_END; val = va_arg(ap, int)) {
        mk_stack_push(&last, val);
    }
    va_end(ap);
    
    return last;
}
