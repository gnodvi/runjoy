/*----------------------------------------------------------------------------*/
/* FILE : scan.c */
/*----------------------------------------------------------------------------*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

/*----------------------------------------------------------------------------*/
#include "j_glob.h"

/*----------------------------------------------------------------------------*/
#ifdef GC_BDW
#    include "gc/gc.h"
#    define malloc GC_malloc_atomic
#endif

#define EOLN '\n'
/*----------------------------------------------------------------------------*/

static FILE  *infile[INPSTACKMAX];
static int  ilevel;
static int  linenumber = 0;
static char linbuf[INPLINEMAX];
static int  linelength, currentcolumn = 0;
static int  errorcount = 0;

/*----------------------------------------------------------------------------*/
void 
inilinebuffer (void)
{
  ilevel = 0; 
  infile[ilevel] = srcfile;
}
/*----------------------------------------------------------------------------*/
void 
putline (void)
{
  if (echoflag > 2) printf ("%4d", linenumber);
  if (echoflag > 1) printf ("\t");

  printf ("%s\n", linbuf);
}
/*----------------------------------------------------------------------------*/
void 
gena_infile_to_linbuf ()
{
  char c;

  currentcolumn = 0; 
  linelength = 0;
  linenumber++;

  while ((c = getc (infile[ilevel])) != EOLN) { 
    // читаем посимвольно из входного потока
    linbuf[linelength++] = c;    // и тупо перезаписываем в буфер

    if (feof (infile[ilevel])) { // если кончился входной поток, то пред. уровень
      ilevel--;
      D (printf ("reset to level %d\n", ilevel));

      if (ilevel < 0) quit_(); // если это уже нижний уровень вложенности, то 
      // завершить совсем Joy
    } 
  }

  linbuf[linelength++] = ' ';   /* to help getsym for numbers */
  linbuf[linelength++] = '\0';  // завершили формирование строки

  if (echoflag) putline ();
 
  return;
}
/*----------------------------------------------------------------------------*/
void 
getch ()
{

  if (currentcolumn == linelength) {  // надо начинать новую строку обрабатывать

    while (1) {
      gena_infile_to_linbuf ();       // читаем строку из входного потока в буфер
      // здесь надо вставить простую читалку из списка строк (статических)

      if (linbuf[0] == SHELLESCAPE) { // если это шеловская команда, то 
        system (&linbuf[1 ]);         // запустить ее..
      } else
        break; // прочитали наконец нормальную строку
    }
  }

  // строка в буфере есть, встаем на след. символ
  ch = linbuf[currentcolumn++]; 

  return;
}
/*----------------------------------------------------------------------------*/
int 
endofbuffer (void)
{

  return (currentcolumn == linelength);
}
/*----------------------------------------------------------------------------*/
void 
error (char *message)
{
  int i;

  putline ();

  if (echoflag > 1) putchar ('\t');

  for (i = 0; i < currentcolumn-2; i++)
    if (linbuf[i] <= ' ')  putchar (linbuf[i]); 
    else                   putchar (' ');

  printf ("^\n\t%s\n",message);
  errorcount++;

  return;
}
/*----------------------------------------------------------------------------*/
int 
doinclude (char *filnam)
{

  if (ilevel+1 == INPSTACKMAX)
    execerror ("fewer include files", "include");

  if ((infile[ilevel+1] = fopen(filnam,"r")) != NULL) { 
    ilevel++; 
    return(1); 
  }

  execerror ("valid file name", "include");

  return 0;
}
/*----------------------------------------------------------------------------*/
char 
specialchar ()
{
  getch ();

  switch (ch) {
 
  case 'n' : return '\n';
  case 't' : return '\t';
  case 'b' : return '\b';
  case 'r' : return '\r';
  case 'f' : return '\f';
  case '\'': return '\'';
  case '\"': return '\"';

  default :
    if (ch >= '0' && ch <= '9') { 
      int i;
      num = ch - '0';

      for (i = 0; i < 2; i++) { 
        getch();
        if (ch < '0' || ch > '9') { 
          currentcolumn++; /* to get pointer OK */
          error("digit expected");
          currentcolumn--; 
        }
        num = 10 * num + ch - '0'; 
      }
      return num; 
    }
    else 
      return ch; 

  } /*switch  */

}
/*----------------------------------------------------------------------------*/
void 
getsym (void)
{
Start:

  while (ch <= ' ') getch (); // пропустили незначащие пробелы

  switch (ch) { 

  /*------------------*/
  case '(':
    getch (); // посмотрим, что там за скобкой дальше

    if (ch == '*') { // это - комментраий
      getch ();
      do {
        while (ch != '*') getch (); 
        getch ();
      }
      while (ch != ')'); // дочитали до конца комментария

      getch ();   // взяли последующий символ
      goto Start; // и начали все сначала
    }
    else { // нет коммента - просто левая скобка..
      sym =  LPAREN; 
      return;
    }
  /*------------------*/

  case '#': // тоже комментраий до конца строки ??
    currentcolumn = linelength; getch (); 
    goto Start;

  case ')':  sym = RPAREN;  getch ();  return;
  case '[':  sym = LBRACK;  getch ();  return;
  case ']':  sym = RBRACK;  getch ();  return;
  case '{':  sym = LBRACE;  getch ();  return;
  case '}':  sym = RBRACE;  getch ();  return;
  case '.':  sym = PERIOD;  getch ();  return;
  case ';':  sym = SEMICOL; getch ();  return;
  case '\'': // заслэшенный символ
    getch ();
    if (ch == '\\') ch = specialchar ();
    num = ch;
    sym = CHAR_; getch(); return;

  /*------------------*/
  case '"':
  { 
    char string[INPLINEMAX];
    register int i = 0;

    getch ();

    while (ch != '"' && !endofbuffer()) { 
      if (ch == '\\') ch = specialchar();
      string[i++] = ch; getch();
    }
    string[i] = '\0'; // прочитали и завершили строку

    getch (); // взяли след.символ

    D (printf ("getsym: string = %s\n", string));

    num = (long) malloc (strlen(string) + 1);
    strcpy ((char *) num, string); // там хранят прочитанные значения?

    sym = STRING_; // а это просто название этого значения
    return; 
  }
  /*------------------*/

  case '-': /* PERHAPS unary minus */
  case '0': case '1': case '2': case '3': case '4':
  case '5': case '6': case '7': case '8': case '9':
  { 
    char number[25];
    char *p = number;

    if ( isdigit(ch) || 
        ( currentcolumn < linelength && isdigit((int) linbuf[currentcolumn])) )
    { 
      do {
        *p++ = ch; 
        getch ();
      } while (strchr ("0123456789+-Ee.", ch));

      *p = 0;
      if (strpbrk (number, ".eE")) { 
        dbl = strtod (number, NULL);    sym = FLOAT_;   return;
      } else { 
        num = strtol (number, NULL, 0); sym = INTEGER_; return; 
      } 
    } 
  }
  /* ELSE '-' is not unary minus, fall through */

  default:
  { 
    int i = 0;
    hashvalue = 0; /* ensure same algorithm in inisymtab */

    do { 
      if (i < ALEN-1) {
        id[i++] = ch; 
        hashvalue += ch; // это что ? 
      }
      getch (); // читаем нормальные символы в буфер "id"
    }
    while (isalpha(ch) || isdigit(ch) ||
         ch == '=' || ch == '_' || ch == '-');

    id[i] = '\0'; // завершаем строку
    hashvalue %= HASHSIZE;

    if (isupper ((int) id[1])) { // если это большие буквы:
      if (strcmp (id, "LIBRA") == 0 || strcmp (id, "DEFINE") == 0) 
      { 
        sym = LIBRA; 
        return; 
      }
      if (strcmp (id, "HIDE") == 0)    { sym = HIDE;     return; }
      if (strcmp (id, "IN") == 0)      { sym = IN;       return; }
      if (strcmp (id, "END") == 0)     { sym = END;      return; }
      if (strcmp (id, "MODULE") == 0)  { sym = MODULE;   return; }
      if (strcmp (id, "PRIVATE") == 0) { sym = JPRIVATE; return; }
      if (strcmp (id, "PUBLIC") == 0)  { sym = JPUBLIC;  return; }

      /* possibly other uppers here */
    }

    if (strcmp (id, "!") == 0)  { /* should this remain or be deleted ? */
      sym = PERIOD; 
      return; 
    }

    if (strcmp (id, "=="    ) == 0) { sym = EQDEF;                   return; }
    if (strcmp (id, "true"  ) == 0) { sym = BOOLEAN_;  num = 1;      return; }
    if (strcmp (id, "false" ) == 0) { sym = BOOLEAN_;  num = 0;      return; }
    if (strcmp (id, "maxint") == 0) { sym = INTEGER_;  num = MAXINT; return; }

    // если ничего не совпало..
    sym = ATOM; 
    return; 
  } 

  } /* switch */

  return;
}
/*----------------------------------------------------------------------------*/
