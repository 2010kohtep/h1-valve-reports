#pragma once

void COM_Munge(unsigned char *data, int len, int seq, const unsigned char *mingify_table);
void COM_MungeFile(const char *filename, int seq);