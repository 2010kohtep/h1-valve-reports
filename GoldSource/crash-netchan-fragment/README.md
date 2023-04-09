# Malformed fragment packet in GoldSource may lead to access violation

# Introduction

In GoldSource, if the amount of data transmitted over the network exceeds the permissible limits, or if there is a need to transfer a file, then a special function of the game protocol is used - stream. There are only two such streams - file and normal: file is used to transfer a file, and normal is used for a large amount of network data. This function splits the data into fragments, then transfers them one by one, one chunk in each packet. After receiving all the fragments, they are combined into one large data buffer, which is passed to the handler as a normal packet (normal), or saved to disk (file). Stream processing is implemented inside the Netchan_Process function.

However, having formed the packet in a special way, an attacker is able to corrupt network buffer where data is copied, causing damage to variables that are located next to the buffer in global memory. This will lead to crash of the server or client with an access violation.

# Description

How does streams work? First you need to know that any engine packet starts with four bytes (Int32), which describe an incoming packet. These four bytes are also called sequence. It works like this:

* If sequence equals -1, then this packet is out-of-band, that is, a packet that does not belong to the main game protocol (the protocol by which the server communicates with the client as with a player). Such packets are needed to get some information about the server (hostname, map, players, rules), as well as to initialize the client's connection to the server.
* If sequence is -2, then this packet is out-of-band, but of a slightly different type. This packet works on the stream principle, but it is used for packets starting with -1. Such a packet is needed if there is too much out-of-band information. This information includes, for example, 'details' - a packet with the values ​​of server variables, and in some cases it can be large and cannot be transmitted in one -1 packet.
* In all other cases, the packet belongs to the main protocol.

If handling the main protocol, then sequence is followed by sequence_ack - another Int32 that stores the index of the packet to which sequence responded. I will not describe its structure in detail, since it is not important to us. In total, the packet format for the main protocol is already the following:

[sequence: Int32] [sequence_ack: Int32]

Moreover, if the packet belongs to the main protocol, then sequence has a special bit format:

* 0-29: packet index.
* 30: if 1, the packet is categorized as 'reliable', which determines its guaranteed delivery. The recipient must give an answer to the sender that the packet has been received.
* 31: if 1, then the packet contains stream fragments.

We are just interested in 31 bits. If this bit is set, special processing of the packet begins. The recipient expects a packet in the following format:

[sequence: Int32] [sequence_ack: Int32]
[MsgNormal: Int8] [MsgNormalId: Int32] [MsgNormalOffset: Int16] [MsgNormalLength: Int16]
[MsgFile: Int8] [MsgFileId: Int32] [MsgFileOffset: Int16] [MsgFileLength: Int16]

Let's analyze these fields:

* sequence: index of the incoming packet.
* sequence_ack: the index of the packet that sequence responds to.
* MsgNormal: bool, and if its value is true then read normal stream is required.
* MsgNormalId: a bitfield that stores two variables at the same time:
    * 0-15: number of fragments to be processed.
    * 16-31: index of the current fragment.
* MsgNormalOffset: offset relative to the entire current packet, at which the fragment is stored.
* MsgNormalLength: fragment size.
* MsgFile: bool, and if true, read file stream.
* MsgFileId: a bitfield that stores two variables at the same time:
    * 0-15: number of fragments to be processed.
    * 16-31: index of the current fragment.
* MsgFileOffset: offset relative to the entire current packet, at which the fragment is stored.
* MsgFileLength: fragment size.

How does reading these streams work? All data received from the sender is stored in the net_message buffer. The function, having read the streams data, removes this data from the net_message buffer, since in addition to streams, the buffer can also contain game messages, for example, information about the player's movement (clc_move). The read data are stored in separate buffers, which are processed when fully received.

And there is a problem with this scheme. If both normal and file streams are transmitted simultaneously, the data from the buffer where the streams data are stored is deleted by the memmove() function after reading the data of the first stream, and after removing this data, the function subtracts the value of the MsgNormalLength variable from MsgFileOffset. The problem is that the MsgFileOffset value can be negative as a result, thus causing a 'buffer underflow' situation when the data of the file stream is deleted.

I developed a library for the client that sets the fields described above in the right way, thereby provoking a server crash. You need to use it as follows:

1. Put TrackerUI.dll in the cstrike\bin folder;
2. Connect to HLDS server or start LAN server;
3. Run the netcrash console command.

As a result, the recipient program (HLDS or LAN host) will crash when trying to read data at 0xDEADBEEF.

To demonstrate the vulnerability, I recorded a video showing HLDS and LAN servers crash.

LAN crash:
{F1000293}

HLDS crash:
{F1000294}

# How to fix

I believe that the values ​​of the variables that store the length and offset of streams should be unsigned (replacing MSG_ReadShort with MSG_ReadWord and changing variable types from int to unsigned int). This should fix the 'buffer underflow' problem. However, there is a chance that these fixes will not be enough. To implement a more reliable fix, I recommend referring to the source codes of the ReHLDS project, which, as it turned out, already contains fixes that solve this problem: https://github.com/dreamstalker/rehlds/blob/master/rehlds/engine/net_chan.cpp#L648-L673 (I was unable to reproduce this vulnerability here). Perhaps these two solutions can be combined, since Netchan_Validate does exactly the conversion of int to unsigned int when checking the values ​​of frag_length and frag_offset arguments.

## Impact

An attacker is able to crash the game server.