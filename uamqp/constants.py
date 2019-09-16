#-------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for
# license information.
#--------------------------------------------------------------------------

#: The IANA assigned port number for AMQP.The standard AMQP port number that has been assigned by IANA
#: for TCP, UDP, and SCTP.There are currently no UDP or SCTP mappings defined for AMQP.
#: The port number is reserved for future transport mappings to these protocols.
PORT = 5672


#: The IANA assigned port number for secure AMQP (amqps).The standard AMQP port number that has been assigned
#: by IANA for secure TCP using TLS. Implementations listening on this port should NOT expect a protocol
#: handshake before TLS is negotiated.
SECURE_PORT = 5671


MAJOR = 1  #: Major protocol version.
MINOR = 0  #: Minor protocol version.
REVISION = 0  #: Protocol revision.

#: The lower bound for the agreed maximum frame size (in bytes). During the initial Connection negotiation, the
#: two peers must agree upon a maximum frame size. This constant defines the minimum value to which the maximum
#: frame size can be set. By defining this value, the peers can guarantee that they can send frames of up to this
#: size until they have agreed a definitive maximum frame size for that Connection.
MIN_MAX_FRAME_SIZE = 512
