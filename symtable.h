// symtab.h
#ifndef SYMTAB_H
#define SYMTAB_H

#include <stdbool.h>

// ������� ������ ������� ���� ����� ���������
void declare_function(const char* name, const char* return_type, int param_count);

// ����� ��� �������� _main_ ����� ��� ��� ���� ����� ����� ������� ����� ������ ���
bool validate_main_function();

#endif // SYMTAB_H