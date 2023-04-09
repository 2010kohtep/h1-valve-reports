#pragma once

const int HEADER_LUMPS = 15;

const int LUMP_ENTITIES = 0;
const int LUMP_PLANES = 1;
const int LUMP_TEXTURES = 2;
const int LUMP_VERTEXES = 3;
const int LUMP_VISIBILITY = 4;
const int LUMP_NODES = 5;
const int LUMP_TEXINFO = 6;
const int LUMP_FACES = 7;
const int LUMP_LIGHTING = 8;
const int LUMP_CLIPNODES = 9;
const int LUMP_LEAFS = 10;
const int LUMP_MARKSURFACES = 11;
const int LUMP_EDGES = 12;
const int LUMP_SURFEDGES = 13;
const int LUMP_MODELS = 14;

struct lump_t
{
	int fileofs;
	int filelen;
};

struct dheader_t
{
	int    version;
	lump_t mps[HEADER_LUMPS];
};

struct wadinfo_t
{
	char identification[4];
	int numlumps;
	int infotableofs;
};

struct lumpinfo_t
{
	int filepos;
	int disksize;
	int size;
	char type;
	char compression;
	char pad1;
	char pad2;
	char name[16];
};

struct texlumpinfo_t
{
	lumpinfo_t lump;
	int iTexFile;
};

struct miptex_t
{
	char			name[16];
	unsigned		width;
	unsigned		height;
	unsigned		offsets[4];
};