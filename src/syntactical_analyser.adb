-- syntactical_analyser.adb --- 

-- Copyright 2020 cnngimenez
--
-- Author: cnngimenez

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

-------------------------------------------------------------------------

with Ada.Command_Line;
use Ada.Command_Line;
with Ada.Wide_Wide_Text_IO;
use Ada.Wide_Wide_Text_IO;
with Ada.Strings.Wide_Wide_Unbounded;
use Ada.Strings.Wide_Wide_Unbounded;

with Source;
use Source;
with Lexical.Token;
use Lexical.Token;
with Lexical.Turtle_Lexer;
use Lexical.Turtle_Lexer;
with League.Strings;
use League.Strings;

procedure Lexical_Analizer is
    
    procedure Print_Triple (Triple : Triple_Type);
    procedure Print_Prefix (Prefix : Prefix_Type);
    procedure Print_Base (Base : Base_Type);
    function Read_File (Path : String) return Wide_Wide_String;
    
    package Analyser is new Syntactical.Rules 
      (
       Triple_Readed_Callback => Print_Triple;
       Prefix_Directive_Callback => Print_Prefix;
       Base_Directive_Callback => Print_Base;
      );
    use Analyzer;
    
    procedure Print_Triple (Triple : Triple_Type) is
    begin
        Put_Line ("Triple: ");
        Put_Line ("<"
                    & To_Wide_Wide_String (Triple.Get_Subject)
                    & ">");
        Put_Line ("<" 
                    & To_Wide_Wide_String (Triple.Get_Predicate)
                    & ">");
        Put_Line ("<"
                    & To_Wide_Wide_String (Triple.Get_Object)
                    & ">");
    end Print_Triple;
    
    procedure Print_Prefix (Prefix : Prefix_Type) is
    begin
        Put_Line ("Prefix: ");
        Put_Line (To_Wide_Wide_String (Prefix.Get_Name)
               & ": <"
               & To_Wide_Wide_Stirng (Prefix.Get_IRI)
                    & ">");
    end Print_Prefix;
    
    procedure Print_Base (Base : Universal_String) is
    begin
        Put_Line ("Base IRI:");
        Put_Line (To_Wide_Wide_String (Base));
    end Print_Base;
    
    function Read_File (Path : String) return Wide_Wide_String is
        Buffer : Unbounded_Wide_Wide_String;
        File : File_Type;
        Symbol : Wide_Wide_Character;
    begin
        Open (File, In_File, Path);

        while not End_Of_File (File) loop
            Get (File, Symbol);
            Append (Buffer, Symbol);
        end loop;

        Close (File);

        return To_Wide_Wide_String (Buffer);
    end Read_File;

    Lexer : Lexer_Type;
    Token : Token_Type;
    Source : Source_Type;
begin
    if Argument_Count < 1 then
        Put_Line ("Synopsis :");
        Put_Line ("    ./syntactical_analyser TURTLE_FILE");
        return;
    end if;

    Source.Initialize (Read_File (Argument (1)));

    Lexer.Create (Source);
    
    if Turtle_Doc (Lexer) then
        Put_Line ("Syntactical analysis: This is a valid RDF/Turtle file.");
    else
        Put_Line ("Syntactical analysis: This is not a valid RDF/urtle file.");
    end if;
end Lexical_Analizer;