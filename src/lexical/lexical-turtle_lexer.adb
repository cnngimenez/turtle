--  lexical-turtle_lexer.adb ---

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

--  with Ada.Wide_Wide_Text_IO;
--  use Ada.Wide_Wide_Text_IO;
with Ada.Strings.Wide_Wide_Fixed;

with League.Strings;
use League.Strings;
with Lexical.Finite_Automata;
use Lexical.Finite_Automata;

package body Lexical.Turtle_Lexer is

    procedure Create (Lexer : in out Lexer_Type; Source : Source_Type) is
    begin
        Lexer.Source := Source;
        Lexer.Token_Buffered := False;
        Lexer.Token_Buffer := Invalid_Token;
    end Create;

    function Get_Column_Number (Lexer : Lexer_Type)
                               return Natural is
    begin
        return Lexer.Source.Get_Current_Column_Number;
    end Get_Column_Number;

    function Get_Line_Number (Lexer : Lexer_Type) return Natural is
    begin
        return Lexer.Source.Get_Current_Line_Number;
    end Get_Line_Number;

    function Get_Source (Lexer : Lexer_Type) return Source_Type is
    begin
        return Lexer.Source;
    end Get_Source;

    function Peek_Token (Lexer : in out Lexer_Type;
                         Ignore_Whitespaces : Boolean := True;
                         Ignore_Comments : Boolean := True)
                        return Token_Type is
    begin
        if not Lexer.Token_Buffered then
            Lexer.Token_Buffer := Lexer.Take_Token (Ignore_Whitespaces,
                                                    Ignore_Comments);
            Lexer.Token_Buffered := True;
        end if;

        return Lexer.Token_Buffer;
    end Peek_Token;

    --  First state of the automata.
    procedure Start (Lexer : in out Lexer_Type; Token : out Token_Type) is
        Automata : Automata_Type;
        Symbol : Wide_Wide_Character;
        Token_Str : Universal_String := Empty_Universal_String;
        use Ada.Strings.Wide_Wide_Fixed;
    begin
        Automata.Initialize;

        while not Is_End_Of_Source (Lexer.Source) and then
          not Automata.Is_Blocked
        loop
            Lexer.Source.Next (Symbol);
            Token_Str.Append (Symbol);
            Automata.Next (Symbol);
        end loop;

        if Token_Str.Length > 0 then
            Token_Str := Token_Str.Head (Token_Str.Length - 1);
            --  Some tokens can add spaces, for instance "[" ws* "]" and "["
            --  are both recognized tokens, when parsing "[ foaf:name" the
            --  returned Token_Str is "[ " but should be "[".
            Token_Str := To_Universal_String
              (Trim (To_Wide_Wide_String (Token_Str), Ada.Strings.Both));
        end if;
        Lexer.Source.Previous (Symbol);

        if Automata.Is_Blocked then
            Automata.Previous_State;
        end if;

        if Automata.Is_Accepted then
            Token.Initialize (Automata.Get_Current_State, Token_Str);
        else
            Token := Invalid_Token;
        end if;
    end Start;

    function Take_Token (Lexer : in out Lexer_Type;
                         Ignore_Whitespaces : Boolean := True;
                         Ignore_Comments : Boolean := True)
                        return Token_Type is
        Token : Token_Type;
    begin
        if Lexer.Token_Buffered then
            --  Buffer is not empty, then use buffered token.
            Lexer.Token_Buffered := False;
            return Lexer.Token_Buffer;
        end if;

        loop
            if not Lexer.Source.Is_End_Of_Source then
                Lexer.Start (Token);
            else
                return Invalid_Token;
            end if;

            --  Repeat while Ignore_Whitespaces and Token class is whitespace.
            --  Comments should be ignored too.
            exit when not (Ignore_Whitespaces and then
                             Token.Get_Class = Whitespace)
              and then not (Ignore_Comments and then
                              Token.Get_Class = Comment);
        end loop;

        Lexer.Token_Buffered := False;
        return Token;
    end Take_Token;

end Lexical.Turtle_Lexer;
