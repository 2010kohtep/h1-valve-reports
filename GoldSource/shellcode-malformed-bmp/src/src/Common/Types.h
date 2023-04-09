#pragma once

using CRC32_t = unsigned int;

#pragma pack(push, 1)

struct demoheader_t
{
	char szFileStamp[6 + 2];

	int nDemoProtocol;
	int nNetProtocolVersion;

	char szMapName[260];
	char szDllDir[260];

	CRC32_t mapCRC;

	int nDirectoryOffset;
};

struct demoentry_t
{
	int nEntryType;
	char szDescription[64];
	int nFlags;
	int nCDTrack;
	float fTrackTime;
	int nFrames;
	int nOffset;
	int nFileLength;
};

struct demomsgheader_t // custom structure for easy data storage 
{
	unsigned char id;
	float time;
	unsigned int frame;
};

#pragma pack(pop)