// symtab.h
#ifndef SYMTAB_H
#define SYMTAB_H

#include <stdbool.h>

// פונקציה להוספת פונקציה חדשה לטבלת הסימבולים
void declare_function(const char* name, const char* return_type, int param_count);

// בדיקה האם פונקציית _main_ קיימת פעם אחת בלבד ואינה מקבלת פרמטרים ואינה מחזירה ערך
bool validate_main_function();

#endif // SYMTAB_H