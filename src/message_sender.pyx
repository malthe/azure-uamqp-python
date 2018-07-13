#-------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for
# license information.
#--------------------------------------------------------------------------

# Python imports
import logging
import copy

# C imports
from libc cimport stdint

cimport c_message_sender
cimport c_link
cimport c_async_operation
cimport c_amqpvalue


_logger = logging.getLogger(__name__)


cpdef create_message_sender(cLink link, callback_context):
    sender = cMessageSender()
    sender.create(<c_link.LINK_HANDLE>link._c_value, on_message_sender_state_changed, <void*>callback_context)
    return sender


cdef class cMessageSender(StructBase):

    cdef c_message_sender.MESSAGE_SENDER_HANDLE _c_value

    def __cinit__(self):
        pass

    def __dealloc__(self):
        _logger.debug("Deallocating {}".format(self.__class__.__name__))
        self.destroy()

    def __enter__(self):
        self.open()
        return self

    def __exit__(self, *args):
        self.destroy()

    cpdef open(self):
        if c_message_sender.messagesender_open(self._c_value) != 0:
            self._value_error()

    cpdef close(self):
        if c_message_sender.messagesender_close(self._c_value) != 0:
            self._value_error()

    cdef _create(self):
        if <void*>self._c_value is NULL:
            self._memory_error()

    cpdef destroy(self):
        if <void*>self._c_value is not NULL:
            _logger.debug("Destroying {}".format(self.__class__.__name__))
            c_message_sender.messagesender_destroy(self._c_value)
            self._c_value = <c_message_sender.MESSAGE_SENDER_HANDLE>NULL

    cdef wrap(self, c_message_sender.MESSAGE_SENDER_HANDLE value):
        self.destroy()
        self._c_value = value
        self._create()

    cdef create(self, c_link.LINK_HANDLE link, c_message_sender.ON_MESSAGE_SENDER_STATE_CHANGED on_message_sender_state_changed, void* context):
        self.destroy()
        self._c_value = c_message_sender.messagesender_create(link, on_message_sender_state_changed, context)
        self._create()

    cpdef send(self, cMessage message, c_amqp_definitions.tickcounter_ms_t timeout, callback_context):
        operation = c_message_sender.messagesender_send_async(self._c_value, <c_message.MESSAGE_HANDLE>message._c_value, on_message_send_complete, <void*>callback_context, timeout)
        if <void*>operation is NULL:
            self._memory_error()

    cpdef set_trace(self, bint value):
        c_message_sender.messagesender_set_trace(self._c_value, value)


#### Callbacks

cdef void on_message_send_complete(void* context, c_message_sender.MESSAGE_SEND_RESULT_TAG send_result, c_amqpvalue.AMQP_VALUE delivery_state):
    cdef c_amqpvalue.AMQP_VALUE send_data
    if <void*>delivery_state == NULL:
        wrapped = None
    else:
        send_data = c_amqpvalue.amqpvalue_clone(delivery_state)
        wrapped = copy.deepcopy(value_factory(send_data).value)
    if context != NULL:
        context_obj = <object>context
        if hasattr(context_obj, "_on_message_sent"):
            context_obj._on_message_sent(context_obj, send_result, delivery_state=wrapped)


cdef void on_message_sender_state_changed(void* context, c_message_sender.MESSAGE_SENDER_STATE_TAG new_state, c_message_sender.MESSAGE_SENDER_STATE_TAG previous_state):
    if context != NULL:
        context_obj = <object>context
        if hasattr(context_obj, '_state_changed'):
            context_obj._state_changed(previous_state, new_state)
        elif callable(context_obj):
            context_obj(previous_state, new_state)


cdef create_message_sender_with_callback(cLink link,c_message_sender.ON_MESSAGE_SENDER_STATE_CHANGED callback, void* callback_context):
    sender = cMessageSender()
    sender.create(<c_link.LINK_HANDLE>link._c_value, callback, callback_context)
    return sender
