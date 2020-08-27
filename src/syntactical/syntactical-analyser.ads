--  syntactical-analyser.ads ---

--  Copyright 2020 cnngimenez
--
--  Author: cnngimenez

--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.

--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <http://www.gnu.org/licenses/>.

-------------------------------------------------------------------------

with Lexical.Token;
use Lexical.Token;
with Lexical.Turtle_Lexer;
use Lexical.Turtle_Lexer;
with Turtle.Parser_States;
use Turtle.Parser_States;

--  Creates and manages the syntax analyser objects.
--
--  Each analyser object consists of a lexical analyser and a parser state
--  according to the RDF 1.1 Turtle standard. It also has got any state that
--  should be recorded through the transition of the syntax rules.
package Syntactical.Analyser is

    type Syntax_Analyser_Type is tagged private;

    function Get_Lexer (Syntax_Analyser : Syntax_Analyser_Type)
                       return Lexer_Type;
    function Get_Parser_State (Syntax_Analyser : Syntax_Analyser_Type)
                              return Parser_State_Type;
    function Get_Debug_Mode (Syntax_Analyser : Syntax_Analyser_Type)
                            return Boolean;
    function Get_Recursion_Level (Syntax_Analyser : Syntax_Analyser_Type)
                                 return Natural;
    procedure Set_Lexer (Syntax_Analyser : in out Syntax_Analyser_Type;
                         Lexer : Lexer_Type);
    procedure Set_Parser_State (Syntax_Analyser : in out Syntax_Analyser_Type;
                                Parser_State : Parser_State_Type);
    procedure Set_Debug_Mode (Syntax_Analyser : in out Syntax_Analyser_Type;
                              Debug_Mode : Boolean);

    procedure Add_Recursion_Level
      (Syntax_Analyser : in out Syntax_Analyser_Type);
    procedure Remove_Recursion_Level
      (Syntax_Analyser : in out Syntax_Analyser_Type);

    function Peek_Token (Syntax_Analyser : in out Syntax_Analyser_Type)
                        return Token_Type;
    function Take_Token (Syntax_Analyser : in out Syntax_Analyser_Type)
                        return Token_Type;
    function Is_End_Of_Source (Syntax_Analyser : in out Syntax_Analyser_Type)
                              return Boolean;
private

    type Syntax_Analyser_Type is tagged record
        Lexer : Lexer_Type;
        Parser_State : Parser_State_Type;

        --  Should the rules be printed at standard output?
        Debug_Mode : Boolean := False;
        --  It is used to show the syntax tree on the standard output.
        Recursion_Level : Natural := 0;
    end record;

end Syntactical.Analyser;