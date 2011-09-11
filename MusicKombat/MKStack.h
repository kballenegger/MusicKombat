//
//  MKStack.h
//  MusicKombat
//
//  Created by Kenneth Ballenegger on 9/11/11.
//  Copyright 2011 Azure Talon. All rights reserved.
//

#ifndef MusicKombat_MKStack_h
#define MusicKombat_MKStack_h

#define MK_STACK_END 9999999


struct proto_mk_stack_element {
    struct proto_mk_stack_element *next;
    int value;
};

typedef struct proto_mk_stack_element mk_stack_element;

mk_stack_element * mk_stack_make_element(mk_stack_element *, int);

void mk_stack_free(mk_stack_element *);

void mk_stack_push(mk_stack_element **, int);

mk_stack_element * mk_stack_pop(mk_stack_element **);

mk_stack_element * mk_stack_make(int, ...);


#endif
