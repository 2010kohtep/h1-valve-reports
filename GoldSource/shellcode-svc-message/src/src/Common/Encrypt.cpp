#include "Encrypt.h"

#include <Windows.h>
#include <stdio.h>
#include "../Utils/File.h"

const unsigned char mungify_table2[] =
{
	0x05, 0x61, 0x7A, 0xED,
	0x1B, 0xCA, 0x0D, 0x9B,
	0x4A, 0xF1, 0x64, 0xC7,
	0xB5, 0x8E, 0xDF, 0xA0
};

void COM_Munge(unsigned char *data, int len, int seq, const unsigned char *mingify_table)
{
	int i;
	int mungelen;
	int c;
	int *pc;
	unsigned char *p;
	int j;

	mungelen = len & ~3;
	mungelen /= 4;

	for (i = 0; i < mungelen; i++)
	{
		pc = (int *)&data[i * 4];
		c = *pc;
		c ^= ~seq;
		c = _byteswap_ulong(c);

		p = (unsigned char *)&c;
		for (j = 0; j < 4; j++)
		{
			*p++ ^= (0xa5 | (j << j) | j | mingify_table[(i + j) & 0x0f]);
		}

		c ^= seq;
		*pc = c;
	}
}

void COM_MungeFile(const char *filename, int seq)
{
	FILE *f;
	fopen_s(&f, filename, "rb");

	int fSize = fsize(f);

	auto pBuf = (unsigned char *)malloc(fSize);

	fread(pBuf, fSize, 1, f);
	fclose(f);

	COM_Munge(pBuf + 8, fSize - 8, seq, mungify_table2);

	fopen_s(&f, filename, "wb");
	fwrite(pBuf, fSize, 1, f);
	fclose(f);

	free(pBuf);
}