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