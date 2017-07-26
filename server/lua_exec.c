/*
Copyright (C) 1996-1997 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

#include "qwsvdef.h"

// leftovers from pr_
int pr_argc;
int num_prstr;

char *PR_GlobalString(int ofs);
char *PR_GlobalStringNoContents(int ofs);


//=============================================================================

/*
============
PR_StackTrace
============
*/
void PR_StackTrace(void)
{
}


/*
============
PR_Profile_f

============
*/
void PR_Profile_f(void)
{
}


/*
============
PR_RunError

Aborts the currently executing function
============
*/
void PR_RunError(char *error, ...)
{
    SV_Error("Program error");
}

/*
============================================================================
PR_ExecuteProgram

The interpretation main loop
============================================================================
*/

/*
====================
PR_EnterFunction

Returns the new program statement counter
====================
*/
int PR_EnterFunction(dfunction_t * f)
{
}

/*
====================
PR_LeaveFunction
====================
*/
int PR_LeaveFunction(void)
{
}

