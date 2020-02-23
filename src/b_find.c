/*----------------------------------------------------------------------------*/
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
/*----------------------------------------------------------------------------*/

// эта константа определяет ссколько памяти резервируется под временные данные;
// слишком маленькое значение может вызвать ошибку памяти;
#define MAX 65536

// максимальная длина определения в файле цели
#define DEFMAX 60

/* This constant exists to keep the system from spending an eternity trying
   to run non-terminating programs such as "[dup i] dup i".
   Set it too low and you may miss results. Set it too high
   (relative to MAX) and you may get a segfault, because of programs like
   "[dup i []] dup i" which expand indefinitely. */
#define TOOLONG 300

/* This define enables [[] i] to be considered a satisfactory equivalent
   of [], or such things. This for example allows "cat" to be constructed
   as "[[i] dip i] cons cons". If that is not what you want, then remove
   the next line. */
//#define LIVEQUOTES

/* Use this define if you want to disable all quotations in the construction */
//#define NOQUOTES

/*----------------------------------------------------------------------------*/
// Глобальные переменные ?? !!

int   numbases;
int   basearity[DEFMAX];
int   basesiz[DEFMAX];
char  base[DEFMAX][DEFMAX];
int   goalarity;
int   goalsiz=-1;
char  goal[DEFMAX];
int   size;
char  try[DEFMAX];
char  code[MAX];
int   datasize;
char  thedata[MAX];
char *data=thedata;
char  name[DEFMAX];
int   firstbase=0;
FILE *logfile;
int   noquotes;

/*----------------------------------------------------------------------------*/
int 
parse (FILE *f,char *s)
{
  char c;
  int i,n;

  i=0;

  for (;;) {
    c = fgetc(f);

    if      (c==' ') continue;
    else if (c=='\n' || c=='\r' || c==']' || c==EOF) break;
    else if (c=='[') {
      n = parse(f,s+i+1);
      s[i] = (char)n;
      i+=n+1;
    } else if (c>='0' && c<='9') {
      s[i++] = -DEFMAX - (c-'0');
    } else {
      int j;
      for (j=0;j<numbases;j++)
        if (name[j]==c) break;
      if (j==numbases) {
        printf ("Problem with goal file: %c\n",c);
        exit (1);
      }
      s[i++] = -j-1;
    }
  }

  return i;
}
/*----------------------------------------------------------------------------*/
// спец. функции для печати на экран и отдельно в файл.. зачем?
/*----------------------------------------------------------------------------*/
void logfileprint (char *s)
{
  printf ("%s", s);

  fprintf (logfile, "%s",s);
  fflush (logfile);
}
/*----------------------------------------------------------------------------*/
void 
logfileprintc (char c)
{
  putchar (c);

  putc (c, logfile);
  fflush(logfile);
}
/*----------------------------------------------------------------------------*/
void 
logfileprinti (int i)
{
  printf ("%d", i);

  fprintf (logfile, "%d", i);
  fflush (logfile);
}
/*----------------------------------------------------------------------------*/
void 
unp (char *s, int l)
{
  int i;

  for (i=0; i<l; i++) {

    if (s[i] <= -DEFMAX) {
      logfileprinti (-s[i]-DEFMAX);
    } else if (s[i] < 0) {
      logfileprintc (name[-s[i]-1]);
    } else {
      logfileprintc ('[');
      unp (s+i+1, s[i]);
      logfileprintc (']');
      i += s[i];
    }
  }

  return;
}
/*----------------------------------------------------------------------------*/
void 
unparse (char *s,int l)
{
  unp (s,l);
  logfileprintc ('\n');
}
/*----------------------------------------------------------------------------*/
void init ()
{
  FILE *f;
  char c;
  int  n;

  //f = fopen ("j_find.gol","r");
  f = fopen ("b_find.g","r");
  if (f == NULL) {
    perror ("error opening 'goal' file");
    exit (1);
  }
  logfile = fopen ("b_find.t","w");
  //logfile = fopen("b_find.log","w");
  //logfile = fopen("j_find.l","w"); - иногда вызывает "lex"
  if (logfile == NULL){ 
    perror("cannot open 'logfile'");
    exit (1);
  }

  for (;;) { // читаем и разбирнаем входной файл цели

    // пропускаем пробелы, табуляцию и концы строк
    do {c=fgetc(f);} while (c=='\n' || c=='\r' || c==' ' || c=='\t');

    if (c=='.') {
      firstbase = numbases;
      continue;
    }
    if (c=='_') {
      noquotes = 1;
      continue;
    }

    if (c==EOF) break;
    if (c<'0' || c>'9'){
      printf("bad base %d arity\n",numbases);
      exit(1);
    }
    n = c-'0';

    c = fgetc (f);
    if (c=='*') {
      goalarity = n;
      goalsiz = parse(f,goal);
    } else {
      name[numbases] = c;
      basearity[numbases] = n;
      basesiz[numbases] = parse(f,base[numbases]);
      numbases++;
    }
  }

  if (firstbase==numbases){
    printf ("No bases.");
    exit (1);
  }

  if (goalsiz==-1){
    printf ("No goal.");
    exit (1);
  }
}
/*----------------------------------------------------------------------------*/

// This program uses a brute-force technique to search for constructions of
// concatenative combinators.

// It takes no command-line parameters. The settings are contolled by a file
// called "goal". The first line of this file describes the goal combinator
// (i.e., the combinator that the program will search for). The remaining lines
// describe combinators that the program will use as bases in the construction.

// The first character on each line should be a digit telling how many stack
// items the combinator will use. The next character should be a single letter
// giving a name for the combinator (except for the goal combinator, for which
// this name is omitted). The body of the combinator definition is best
// described by some examples. For "dip" you'd use

/*----------------------------------------------------------------------------*/
void 
announce () 
{
  int i;
  if (noquotes) logfileprint ("_\n");

  logfileprinti (goalarity);
  logfileprint ("* ");
  unparse (goal, goalsiz);

  for (i=0; i<numbases; i++) {
    if (i==firstbase && i!=0) logfileprint(".\n");

    logfileprinti (basearity[i]);
    logfileprintc (name[i]);
    logfileprintc (' ');
    unparse (base[i],basesiz[i]);
  }

  return;
}
/*----------------------------------------------------------------------------*/
int 
indexdata (int i)
{
  int pos=datasize-1;

  for(; i>0; i--) {
    if (pos<0 || data[pos]<0) return -1;
    else pos -= data[pos]+1;
  }

  if (data[pos] < 0) return -1;

  return pos;
}
/*----------------------------------------------------------------------------*/
int 
findsize (int s)
{
  int i,m=basesiz[s];
  int siz=0;
  int c;

  for (i=0; i<m; i++) {
    c = base[s][i];

    if (c<=-DEFMAX) {
      int z=indexdata(-c-DEFMAX);
      if (z==-1) return -1;
      siz += data[z];
    } else siz++;
  }

  return siz;
}
/*----------------------------------------------------------------------------*/
int 
substitute (int b, int j, int m, int i) 
{
  int c;
  int siz=0;

  for (; j<m; j++) {
    c = base[b][j];
    if (c<=-DEFMAX) {
      int z=indexdata(-c-DEFMAX);
      if (z==-1) return -1;
      memcpy (code+i, data+z-data[z], data[z]);
      i += data[z];
      siz += data[z];
    } else if (c<0) {
      code[i++]=c;
      j++;
      siz++;
    } else {
      code[i] = substitute (b, j+1, j+1+c, i+1);
      if (code[i]==-1) return -1;
      siz += code[i]+1;
      i += code[i]+1;
      j += c;
    }
  }
  return siz;
}
/*----------------------------------------------------------------------------*/

int longest=0;
int furthest;

/*----------------------------------------------------------------------------*/
int 
run (int where)
{
  int i;
  int tick=TOOLONG;

  for (furthest=i=MAX-where;i<MAX && tick--;) {

    if (i > furthest) furthest = i;

    if (code[i]>=0) {
      int siz=code[i];
      memcpy (data+datasize, code+i+1, siz);
      data[datasize+siz] = siz;
      datasize+=siz+1;
      i+=siz+1;
    } else if (code[i] > -DEFMAX) {
      int b = -code[i]-1;
      int s = findsize(b);

      if (s==-1) return -1;
      i -= s-1;
      if (substitute(b, 0, basesiz[b],i) == -1) return -1;

      for (s=0; s<basearity[b]; s++){
        if (datasize==0 || data[datasize-1]<0) return -1;
        datasize -= data[datasize-1]+1;
      }
    } else {
      data[datasize] = code[i];
      datasize++;
      i++;
    }
  }

  if (tick == -1){
    static int z=DEFMAX;
    if (size <= z) {
      z = size;
      logfileprint ("\rLooper: ");
      unparse (try, size);
    }
  }

  return 0;
}
/*----------------------------------------------------------------------------*/
int 
test (char *g, int gsiz, int where)
{
//  unparse(code+MAX-where,where);

  if (run(where)) return 0;

#ifdef LIVEQUOTES
  {
    int datapos,goalpos;

    datapos=datasize-1;
    goalpos=gsiz-1;
    datasize=0;
    while(datapos>=0){
      int z=data[datapos];

      if(goalpos<0) return 0;
      if(z<=0){
        if(g[goalpos] != z) return 0;
        datapos--;
        goalpos--;
      }else{
        if(g[goalpos] < 0) return 0;
        memcpy(code+MAX-z, data+datapos-z, z);
        datapos -= z+1;
        data += datapos+1;
        if(!test(g+goalpos-g[goalpos], g[goalpos], z)){
          data -= datapos+1;
          return 0;
        }
        data -= datapos+1;
        goalpos -= g[goalpos]+1;
      }
    }
    if(goalpos==-1) return 1;
    else            return 0;
  }

#else
  if (gsiz==datasize && memcmp(g,data,datasize)==0){
    return 1;
  }else 
    return 0;

#endif
}
/*----------------------------------------------------------------------------*/
void 
search (int startsize)
{
  int i,k;
  char baton[4] = {'-','\\','|','/'};
  int  b=0;

  size = goalsiz;
  memcpy (code+MAX-size, goal, size);

  run (size);
  goalsiz = datasize;
  memcpy (goal, data, datasize);

  for (size=startsize; size</* DEFMAX emgena */12; size++) {

    logfileprint ("(size ");
    logfileprinti (size);
    logfileprint (")\n");

    for (i=0; i<size; i++) {
      try[i] = -numbases;
    }

    for (;;) {
      printf ("%c (%d)\r", baton[b&3], b); // печать сделанных процентов ?
      b++;

      for (k=0; k<65536; k++) {
        memcpy (code+MAX-size, try, size);
        datasize = goalarity<<1;

        for (i=0; i<goalarity; i++) {
          data[i<<1]     = -59-goalarity+i;
          data[(i<<1)+1] = 1;
        }
        if (test (goal,goalsiz, size)) {
          logfileprint ("  ");
          unparse (try,size);
          printf ("%c\r", baton[b&3]);
        }

        if (noquotes) {
          i = furthest-(MAX-size); // Backtrack where error (if any) occured
        } else {
          i = 0;
        }

        for (;;) {
          if (noquotes) {
            if (i<0) goto here;
            if (try[i]<-firstbase-1) {
              try[i]++;
            } else {
              try[i]=-numbases;
              i--;
              continue;
            }
          } else {
            if (i>=size) goto here;
            if (try[i]<-firstbase-1){
              try[i]++;
            } else if (try[i]==-firstbase-1){
              try[i]=0;
            } else {
              int j = i+try[i]+1;
              if (j>=size) {
                try[i]=-numbases;
                i++;
                continue;
              } else if (try[j]<=0) {
                try[i]++;
              } else {
                try[i] += try[j]+1;
              }
            }
          }
          break;
        }
      }
    }

  here:;
  }

}
/*----------------------------------------------------------------------------*/
int 
main (int argc,char **argv)
{
  int startsize = 0;

  init();

  if (argc>=2) startsize = atoi(argv[1]);

  printf ("====================== \n");
  announce ();
  printf ("====================== \n");

  search (startsize);

  return 0;
}
/*----------------------------------------------------------------------------*/
