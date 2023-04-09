# StuffText filter bypass in GoldSource Engine

### Introduction

Hey. In GoldSource Engine, as in any other game engines from Valve, there are console commands. This is a set of functions or variables that you can interact with using game console. With the help of various console commands it is possible to exert different influence on the player, for example, to set him the necessary key bind or to change graphics settings. However, the ability to execute console commands on client can be abused. There is a huge amount of products that perform a game breakdown, for example, **amx_sysbizz**. This product is an AMX plugin that is installed on the server and provides the possibility of console variables' mass corrupting to any client. Against this product there is a solution - setting the console variable "cl_filterstuffcmd" to "1", however, for the time being, attackers still have several ways to execute unwanted console commands on the client from the server side.

This problem is being tried to correct for several years, but it still remains relevant in Counter-Strike 1.6 community, so I think that it deserves some attention and that this report will make the game process more pleasant and safe.

### Description

The ability to execute unwanted console commands by the server is hidden in several places at once. I will try to describe in detail each of these execution ways and provide options for solving it.

##### Redirection

Out-of-band packet **S2C_REDIRECT** ('L'), which is processed in the **CL_ConnectionlessPacket** function, may execute console commands. Game engine expects to get the server address to which it will be redirected using console command **connect**, however, the attacker has the ability to write other console commands here. If we examine the handler of this OOB packet, we can understand what the problem lies in.

```cpp
void CL_ConnectionlessPacket()
{
	MSG_BeginReading();
	MSG_ReadLong();
	char *packet = MSG_ReadStringLine();

	// ...

	case S2C_REDIRECT:
	{
	  if ( IsFromConnectedServer(net_from) && cls.state == ca_connecting )
	  {
		char *payload = (packet + 1);
		_snprintf_s(&text, 260u, "connect %s\n", payload);
		Cbuf_AddText(&text);
		Con_Printf("Redirecting connection to %s.\n", payload);
		g_bRedirectedToProxy = 1;
	  }
	  
	  break;
	}

	// ...
}
```
As we can see, any information received from **MSG_ReadStringLine** function can be written in **Cbuf_AddText**, which means that an attacker can construct the next packet and execute any command on the client (in this case, **bind**), because it does not even fit into the filter:

```cpp
#define CONNECTIONLESS_HEADER (-1)
#define S2C_REDIRECT ('L')

MSG_WriteLong(CONNECTIONLESS_HEADER);
MSG_WriteByte(S2C_REDIRECT);
MSG_WriteString("127.0.0.1; bind w kill");

```

As a solution, I can suggest using the following code instead of the above:

```cpp
void CL_ConnectionlessPacket()
{
	MSG_BeginReading();
	MSG_ReadLong();
	char *packet = MSG_ReadStringLine();

	// ...

	case S2C_REDIRECT:
	{
	  if ( IsFromConnectedServer(net_from) && cls.state == ca_connecting )
	  {
		char *payload = (packet + 1);
		_snprintf_s(&text, 260u, "connect %s\n", payload);
		
		if (strchr(text, ';') != 0)
		{
			Con_Printf("Server tried to send command via redirect packet.\n");
			CL_Disconnect();
		}
		
		Cbuf_AddText(&text);
		Con_Printf("Redirecting connection to %s.\n", payload);
		g_bRedirectedToProxy = 1;
	  }
	  
	  break;
	}

	// ...
}
```

Since the presence of the character ';' is necessary to create a lot of console commands, then we can check its presence in the **text** variable, since this character can't be presented in server's IPv4 string or in its domain name. If we find this symbol, we will disconnect from the attacker's server and avoid unwanted console commands execution.

##### SVC_Director message

It's a game message, which is necessary for the spectator HUD to work. This message contains a nested message that is sent to the client library by using the **HUD_DirectorMessage** function, where it executes. We should focus on the **DRC_CMD_STUFFTEXT** message handler. It looks like this:

```cpp
void CHudSpectator::DirectorMessage(int iSize, void *pbuf)
{
	BEGIN_READ(pbuf, iSize);
	unsigned char opcode = READ_BYTE();

	// ...

	case DRC_CMD_STUFFTEXT:
	{
		char *cmd = READ_STRING();
		gEngfuncs.pfnClientCmd(cmd);
		break;
	}

	// ...
}
```
Variable **cmd** is passed to the function **hudClientCmd**, which is in the renderer library (hw/sw), where it immediately passes into **Cbuf_AddText**, without performing any validation. An attacker can use this and send any console command to client, bypassing stufftext filter.

The solution is to use the **ValidStuffText** function in the **DRC_CMD_STUFFTEXT** handler. Like this:

```cpp
void CHudSpectator::DirectorMessage(int iSize, void *pbuf)
{
	BEGIN_READ(pbuf, iSize);
	unsigned char opcode = READ_BYTE();

	// ...

	case DRC_CMD_STUFFTEXT:
	{
		char *cmd = READ_STRING();
		
		if (ValidStuffText(cmd))
		{
			gEngfuncs.pfnClientCmd(cmd);
		}
		
		break;
	}

	// ...
}
```

### How to reproduce

Using HLDS, send one of the data messages described above (redirect, director) to the connected client.

## Impact

Attackers are able to spoil the GoldSource Engine's game clients and perform other manipulations with them when they are connecting to server, bypassing stufftext filters.