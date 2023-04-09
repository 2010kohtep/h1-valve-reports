#pragma once

#include <iostream>

template <typename T> size_t fwrite(T *_Buffer, FILE* _Stream)
{
	return fwrite((void *)_Buffer, sizeof(T), 1, _Stream);
}

template <typename T> size_t fwrite(T _Buffer, FILE* _Stream)
{
	return fwrite((void *)&_Buffer, sizeof(T), 1, _Stream);
}

static size_t fsize(FILE* _Stream)
{
	int fPos = ftell(_Stream);

	fseek(_Stream, 0, 2);
	int fSize = ftell(_Stream);
	fseek(_Stream, fPos, 0);

	return fSize;
}