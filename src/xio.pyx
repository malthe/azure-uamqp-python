#-------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for
# license information.
#--------------------------------------------------------------------------

# Python imports
import logging

# C imports
cimport c_xio
cimport c_sasl_mechanism
cimport c_utils


_logger = logging.getLogger(__name__)


cpdef xio_from_tlsioconfig(IOInterfaceDescription io_desc, TLSIOConfig io_config):
    xio = XIO()
    xio.create(io_desc._c_value, &io_config._c_value)
    return xio


cpdef xio_from_openssl_tlsioconfig(IOInterfaceDescription io_desc, TLSIOConfig io_config):
    xio = XIO()
    xio.create(io_desc._c_value, &io_config._c_value)
    print("setting TLS version")
    xio.set_option(b"tls_version", 2)
    return xio


cpdef xio_from_saslioconfig(SASLClientIOConfig io_config):
    cdef const  c_xio.IO_INTERFACE_DESCRIPTION* interface
    interface = c_sasl_mechanism.saslclientio_get_interface_description()
    if <void*>interface == NULL:
        raise ValueError("Failed to create SASL Client IO Interface description")
    xio = XIO()
    xio.create(interface, &io_config._c_value)
    return xio


cdef class XIO(StructBase):

    cdef c_xio.XIO_HANDLE _c_value

    def __cinit__(self):
        pass

    def __dealloc__(self):
        _logger.debug("Deallocating {}".format(self.__class__.__name__))
        self.destroy()

    cdef _create(self):
        if <void*>self._c_value is NULL:
            self._memory_error()

    cpdef destroy(self):
        if <void*>self._c_value is not NULL:
            _logger.debug("Destroying {}".format(self.__class__.__name__))
            c_xio.xio_destroy(self._c_value)
            self._c_value = <c_xio.XIO_HANDLE>NULL

    cdef wrap(self, c_xio.XIO_HANDLE value):
        self.destroy()
        self._c_value = value
        self._create()

    cdef create(self, c_xio.IO_INTERFACE_DESCRIPTION* io_desc, void *io_params):
        self.destroy()
        self._c_value = c_xio.xio_create(io_desc, io_params)
        self._create()

    cpdef set_option(self, const char* option_name, value):
        cdef const void* option_value
        option_value = <const void*>value
        if c_xio.xio_setoption(self._c_value, option_name, option_value) != 0:
            raise self._value_error("Failed to set option {}".format(option_name))


cdef class IOInterfaceDescription:

    cdef c_xio.IO_INTERFACE_DESCRIPTION* _c_value

    def __cinit__(self):
        pass

    cdef wrap(self, c_xio.IO_INTERFACE_DESCRIPTION* value):
        self._c_value = value
