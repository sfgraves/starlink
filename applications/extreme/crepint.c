/*
*+
*  Name:
*     crepint
*
*  Purpose:
*     Replace int declarations by INT_BIG declarations in C source code.
*
*  Usage:
*     crepint [ in [ out ] ]
*
*  Description:
*     This program is a filter which takes C source code and replaces 
*     any occurrences of the type specifier `int' by the value
*     `INT_BIG'.  This should then be assigned a preprocessor value 
*     at compile time using a -DINT_BIG=int or -DINT_BIG=long flag on
*     the C compiler.
*
*     It's not quite as simple as replacing every occurrence; `short int'
*     and `long int' type specifiers will be left alone.
*
*  Authors:
*     MBT: Mark Taylor (STARLINK)
*
*  History:
*     25-JAN-2000 (MBT):
*        Initial version.
*-
*/


#include "ygen.h"
#include "ctokens.h"

#include <stdio.h>

/* Local function prototypes. */
   void crepint();

   int main( int argc, char **argv ) {
/*
*+
*  Name:
*     main
*
*  Purpose:
*     Main routine of C program.
*
*  Description:
*     Invoke the appropriate filter function.
*-
*/

/* Declare variables. */
      extern char *name;

/* Set up standard input and output correctly for a filter. */
      name = filter( argc, argv );

/* Filter input to output. */
      crepint();

/* Finish. */
      return 0;
   }


   void crepint() {
/*
*+
*  Name:
*     crepint
*
*  Purpose:
*     Perform data processing for crepint program.
*
*  Invocation:
*     crepint();
*
*  Description:
*     This routine reads characters from standard input and writes them to
*     standard output.  The output is as similar as possible to the input
*     except that (most) occurrences of the type specifier token `int' 
*     are replaced by a new string.
*
*     Tokenising the input stream is done using code generated by lex.
*-
*/

/* Local variable declarations. */
      char c;
      char c1;
      char *newint;
      int i;
      int incomm;
      int lnewint;
      int loldint;
      int skipspc;

      int tok;
      int tok1 = 0;

/* Get lengths. */
      newint = "INT_BIG";
      lnewint = strlen( newint );
      loldint = strlen( "int" );

/* Initialise. */
      skipspc = 0;

/* Cycle through the input stream getting tokens from yylex. */
      while ( ( tok = yylex() ) || ( yylval != NULL ) ) {

/* If we have reached the end of the file apart from trailing untokenised
   characters, output them and exit the loop. */
         if ( tok == 0 ) { 
            printf( "%s", yylval );
            break;
         }

/* Dispose of whitespace associated with (preceding) this token. */
         incomm = 0;
         for ( i = 0; i < ymatchst; i++ ) {
            c = yylval[ i ];
            c1 = i ? yylval[ i - 1 ] : 0;
            if ( c == ' ' ) {
               if ( skipspc > 0 && c1 == ' ' && ! incomm )
                  skipspc--;
               else
                  putchar( c );
            }
            else {
               if ( c1 == '/' && c == '*' ) incomm = 1;
               else if ( c1 == '*' && c == '/' ) incomm = 0;
               else if ( c == '\t' ) skipspc = 0;
               else if ( c == '\n' ) skipspc = 0;
               putchar( c );
            }
         }
         
/* See if there is a suitable INT token and replace it if so. */
         if ( tok == INT && tok1 != SHORT && tok1 != LONG ) {
            printf( "%s", newint );
            skipspc = lnewint - loldint;
         }
         else {
            while ( i < strlen( yylval ) ) 
               putchar( yylval[ i++ ] );
         }

/* Keep track of the last token. */
         tok1 = tok;
      }
   }



/* $Id$ */
