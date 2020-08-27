--  syntactical-rules.adb ---

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

with Ada.Wide_Wide_Text_IO;
use Ada.Wide_Wide_Text_IO;

package body Syntactical.Rules is

    function Accept_Token (Analyser : in out Syntax_Analyser_Type;
                           Token_Class : Token_Class_Type)
                          return Boolean is
        Token : Token_Type;
    begin
        Token := Analyser.Peek_Token;

        Debug_Put (Analyser,
                   "| Accept token : "
                     & Token_Class'Wide_Wide_Image
                     & ". Readed :");
        Debug_Token (Analyser, Token);

        if Token.Get_Class = Token_Class then
            Token := Analyser.Take_Token;

            Debug_Put  (Analyser, "| --> True");

            return True;
        else
            Debug_Put (Analyser, "| --> False");
            return False;
        end if;
    end Accept_Token;

    function Accept_Token (Analyser : in out Syntax_Analyser_Type;
                           Token_Class : Token_Class_Type;
                           Value : Wide_Wide_String)
                          return Boolean is
        Token : Token_Type;
    begin
        Token := Analyser.Peek_Token;

        Debug_Put (Analyser,
                   "| Accept token : "
                     & Token_Class'Wide_Wide_Image
                     & " with value '"
                     & Value
                     & "'. Readed :");
        Debug_Token (Analyser, Token);

        if Token.Get_Class = Token_Class and then
          Token.Get_Value = To_Universal_String (Value)
        then
            Token := Analyser.Take_Token;

            Debug_Put (Analyser, "| --> True");

            return True;
        else
            Debug_Put (Analyser, "| --> False");
            return False;
        end if;
    end Accept_Token;

    --  [5] base ::= '@base' IRIREF '.'
    function Base (Analyser : in out Syntax_Analyser_Type)
                  return Boolean is
        Ret : Boolean;
        Token : Token_Type;
    begin
        Begin_Rule (Analyser, "Base");

        Ret := Accept_Token (Analyser, Language_Tag, "@base")
          and then Expect_Token (Analyser, IRI_Reference, Token)
          and then Expect_Token (Analyser, Reserved_Word, ".");

        if Ret then
            Base_Directive_Callback (Token.Get_Value);
        end if;

        End_Rule (Analyser);
        return Ret;
    end Base;

    procedure Begin_Rule (Analyser : in out Syntax_Analyser_Type;
                          Rule_Name : Wide_Wide_String) is
    begin
        Debug_Put (Analyser, Rule_Name & " ->");
        Analyser.Add_Recursion_Level;
    end Begin_Rule;

    --  [137s] BlankNode ::= BLANK_NODE_LABEL | ANON
    function Blank_Node (Analyser : in out Syntax_Analyser_Type)
                        return Boolean is
        Ret : Boolean;
    begin
        Begin_Rule (Analyser, "Blank_Node");

        Ret := Accept_Token (Analyser, Blank_Node_Label)
          or else Accept_Token (Analyser, Anon);

        End_Rule (Analyser);
        return Ret;
    end Blank_Node;

    --  [14] blankNodePropertyList ::= '[' predicateObjectList ']'
    function Blank_Node_Property_List
      (Analyser : in out Syntax_Analyser_Type)
      return Boolean
    is
        Ret : Boolean;
    begin
        Begin_Rule (Analyser, "Blank_Node_Property_List");

        Ret := Accept_Token (Analyser, Reserved_Word, "[")
          and then Predicate_Object_List (Analyser)
          and then Expect_Token (Analyser, Reserved_Word, "]");

        End_Rule (Analyser);
        return Ret;
    end Blank_Node_Property_List;

    --  [133s] BooleanLiteral ::= 'true' | 'false'
    function Boolean_Literal (Analyser : in out Syntax_Analyser_Type)
                             return Boolean is
        Ret : Boolean;
    begin
        Begin_Rule (Analyser, "Boolean_Literal");

        Ret := Accept_Token (Analyser, Boolean_Literal);

        End_Rule (Analyser);
        return Ret;
    end Boolean_Literal;

    --  [15] collection ::= '(' object* ')'
    function Collection (Analyser : in out Syntax_Analyser_Type)
                        return Boolean is
        Ret : Boolean;
    begin
        Begin_Rule (Analyser, "Collection");

        Ret := Accept_Token (Analyser, Reserved_Word, "(");

        while Object (Analyser) loop
            null;
        end loop;

        Ret := Ret and then Expect_Token (Analyser, Reserved_Word, ")");

        End_Rule (Analyser);
        return Ret;
    end Collection;

    procedure Debug_Put (Analyser : in out Syntax_Analyser_Type;
                         S : Wide_Wide_String) is
    begin
        if Analyser.Get_Debug_Mode then
            for i in 0 .. Analyser.Get_Recursion_Level loop
                Put ('-');
            end loop;
            Put (" " & Analyser.Get_Recursion_Level'Wide_Wide_Image & "| ");
            Put_Line (S);
        end if;
    end Debug_Put;

    procedure Debug_Token (Analyser : in out Syntax_Analyser_Type;
                           Token : Token_Type) is
    begin
        Debug_Put (Analyser,
                   "| Token : <"
                     & Token.Get_Class'Wide_Wide_Image
                     & "> '"
                     & To_Wide_Wide_String (Token.Get_Value)
                     & "'");
    end Debug_Token;

    --  [3] directive ::= prefixID | base | sparqlPrefix | sparqlBase
    function Directive (Analyser : in out Syntax_Analyser_Type)
                       return Boolean is
        Ret : Boolean;
    begin
        Begin_Rule (Analyser, "Directive");

        Ret := Prefix_ID (Analyser)
          or else Base (Analyser)
          or else Sparql_Prefix (Analyser)
          or else Sparql_Base (Analyser);

        End_Rule (Analyser);
        return Ret;
    end Directive;

    procedure End_Rule (Analyser : in out Syntax_Analyser_Type) is
    begin
        Analyser.Remove_Recursion_Level;
    end End_Rule;

    function Expect_Token (Analyser : in out Syntax_Analyser_Type;
                           Token_Class : Token_Class_Type;
                           Token : in out Token_Type)
                          return Boolean is
    begin
        Token := Analyser.Take_Token;

        Debug_Put (Analyser, "| Expect token : "
                     & Token_Class'Wide_Wide_Image
                     & ". Readed :");
        Debug_Token (Analyser, Token);

        if Token.Get_Class = Token_Class then
            Debug_Put (Analyser, "| --> True");

            return True;
        else
            raise Expected_Token_Exception with
              "Expected token of class '" & Token_Class'Image &
              "' and got '" & Token.Get_Class'Image & "'.";
            --  return False;
        end if;
    end Expect_Token;

    function Expect_Token (Analyser : in out Syntax_Analyser_Type;
                           Token_Class : Token_Class_Type)
                          return Boolean is
        Token : Token_Type;
    begin
        return Expect_Token (Analyser, Token_Class, Token);
    end Expect_Token;

    function Expect_Token (Analyser : in out Syntax_Analyser_Type;
                           Token_Class : Token_Class_Type;
                           Value : Wide_Wide_String)
                          return Boolean is
        Token : Token_Type;
        Ret : Boolean;
    begin
        Ret := Expect_Token (Analyser, Token_Class, Token);

        Debug_Put (Analyser, "| Expect token with value '" & Value & "'");

        if Ret and then Token.Get_Value = To_Universal_String (Value)
        then
            Debug_Put (Analyser, "| --> True");
            return True;
        else
            raise Expected_Token_Exception with
              "Unexpected token value.";
            --  return False;
        end if;
    end Expect_Token;

    --  [135s] iri ::= IRIREF | PrefixedName
    function IRI (Analyser : in out Syntax_Analyser_Type)
                 return Boolean is
        Ret : Boolean;
    begin
        Begin_Rule (Analyser, "IRI");

        Ret := Accept_Token (Analyser, IRI_Reference)
          or else Prefixed_Name (Analyser);

        End_Rule (Analyser);
        return Ret;
    end IRI;

    --  [13] literal ::= RDFLiteral | NumericLiteral | BooleanLiteral
    function Literal (Analyser : in out Syntax_Analyser_Type)
                     return Boolean is
        Ret : Boolean;
    begin
        Begin_Rule (Analyser, "Literal");

        Ret := RDF_Literal (Analyser)
          or else Numeric_Literal (Analyser)
          or else Boolean_Literal (Analyser);

        End_Rule (Analyser);
        return Ret;
    end Literal;

    --  [16] NumericLiteral ::= INTEGER | DECIMAL | DOUBLE
    function Numeric_Literal (Analyser : in out Syntax_Analyser_Type)
                             return Boolean is
        Ret : Boolean;
    begin
        Begin_Rule (Analyser, "Numeric_Literal");

        Ret := Accept_Token (Analyser, Lexical.Token.Integer)
          or else Accept_Token (Analyser, Lexical.Token.Decimal)
          or else Accept_Token (Analyser, Lexical.Token.Double);

        End_Rule (Analyser);
        return Ret;
    end Numeric_Literal;

    --  [12] object ::= iri | BlankNode | collection |
    --    blankNodePropertyList | literal
    function Object (Analyser : in out Syntax_Analyser_Type)
                    return Boolean is
        Ret : Boolean;
    begin
        Begin_Rule (Analyser, "Object");

        Ret := IRI (Analyser)
          or else Blank_Node (Analyser)
          or else Collection (Analyser)
          or else Blank_Node_Property_List (Analyser)
          or else Literal (Analyser);

        End_Rule (Analyser);
        return Ret;
    end Object;

    --  [8] objectList ::= object (',' object)*
    function Object_List (Analyser : in out Syntax_Analyser_Type)
                         return Boolean is
        Ret : Boolean;
    begin
        Begin_Rule (Analyser, "Object_List");

        Ret := Object (Analyser);

        while Accept_Token (Analyser, Reserved_Word, ",") loop
            Ret := Ret and then Object (Analyser);
        end loop;

        End_Rule (Analyser);
        return Ret;
    end Object_List;

    --  [11] predicate ::= iri
    function Predicate (Analyser : in out Syntax_Analyser_Type)
                       return Boolean is
        Ret : Boolean;
    begin
        Begin_Rule (Analyser, "Predicate");

        Ret := IRI (Analyser);

        End_Rule (Analyser);
        return Ret;
    end Predicate;

    --  [7] predicateObjectList ::= verb objectList (';' (verb objectList)?)*
    function Predicate_Object_List
      (Analyser : in out Syntax_Analyser_Type)
      return Boolean
    is
        Ret : Boolean;
    begin
        Begin_Rule (Analyser, "Predicate_Object_List");

        Ret := Verb (Analyser) and then Object_List (Analyser);

        while Ret and then Accept_Token (Analyser, Reserved_Word, ";")
        loop
            if Verb (Analyser) then
                Ret := Ret and then Object_List (Analyser);
            end if;
        end loop;

        End_Rule (Analyser);
        return Ret;
    end Predicate_Object_List;

    --  [4] prefixID ::= '@prefix' PNAME_NS IRIREF '.'
    function Prefix_ID (Analyser : in out Syntax_Analyser_Type)
                       return Boolean is
        Token_Prefix, Token_IRI : Token_Type;
        Prefix : Prefix_Type;
        Ret : Boolean;
    begin
        Begin_Rule (Analyser, "Prefix_ID");

        Ret :=  Accept_Token (Analyser, Language_Tag, "@prefix")
          and then Expect_Token (Analyser, Prefix_Namespace, Token_Prefix)
          and then Expect_Token (Analyser, IRI_Reference, Token_IRI)
          and then Expect_Token (Analyser, Reserved_Word, ".");

        if Ret then
            Prefix.Initialize (Token_Prefix.Get_Value, Token_IRI.Get_Value);
            Prefix_Directive_Callback (Prefix);
        end if;

        End_Rule (Analyser);
        return Ret;
    end Prefix_ID;

    --  [136s] PrefixedName ::= PNAME_LN | PNAME_NS
    function Prefixed_Name (Analyser : in out Syntax_Analyser_Type)
                           return Boolean is
        Ret : Boolean;
    begin
        Begin_Rule (Analyser, "Prefixed_Name");

        Ret := Accept_Token (Analyser, Prefix_With_Local)
          or else Accept_Token (Analyser, Prefix_Namespace);

        End_Rule (Analyser);
        return Ret;
    end Prefixed_Name;

    --  [128s] RDFLiteral ::= String (LANGTAG | '^^' iri)?
    function RDF_Literal (Analyser : in out Syntax_Analyser_Type)
                         return Boolean is
        Ret : Boolean;
    begin
        Begin_Rule (Analyser, "RDF_Literal");

        Ret := String (Analyser);

        if Accept_Token (Analyser, Language_Tag) then
            End_Rule (Analyser);
            return Ret;
        elsif Accept_Token (Analyser, Reserved_Word, "^^") then
            Ret := Ret and then IRI (Analyser);
        end if;

        End_Rule (Analyser);
        return Ret;
    end RDF_Literal;

    --  [5s] sparqlBase ::= "BASE" IRIREF
    function Sparql_Base (Analyser : in out Syntax_Analyser_Type)
                         return Boolean is
        Ret : Boolean;
    begin
        Begin_Rule (Analyser, "Sparql_Base");

        Ret := Accept_Token (Analyser, Reserved_Word, "BASE")
          and then Expect_Token (Analyser, IRI_Reference);

        End_Rule (Analyser);
        return Ret;
    end Sparql_Base;

    --  [6s] sparqlPrefix ::= "PREFIX" PNAME_NS IRIREF
    function Sparql_Prefix (Analyser : in out Syntax_Analyser_Type)
                           return Boolean is
        Ret : Boolean;
    begin
        Begin_Rule (Analyser, "Sparql_Prefix");

        Ret := Accept_Token (Analyser, Reserved_Word, "PREFIX")
          and then Expect_Token (Analyser, Prefix_Namespace)
          and then Expect_Token (Analyser, IRI_Reference);

        End_Rule (Analyser);
        return Ret;
    end Sparql_Prefix;

    --  [2] statement ::= directive | triples '.'
    function Statement (Analyser : in out Syntax_Analyser_Type)
                       return Boolean is
        Ret : Boolean;
    begin
        Begin_Rule (Analyser, "Statement");

        Ret := Directive (Analyser)
          or else (Triples (Analyser)
                     and then Accept_Token (Analyser,
                                            Reserved_Word, "."));

        End_Rule (Analyser);
        return Ret;
    end Statement;

    --  [17] String ::= STRING_LITERAL_QUOTE | STRING_LITERAL_SINGLE_QUOTE
    --    | STRING_LITERAL_LONG_SINGLE_QUOTE | STRING_LITERAL_LONG_QUOTE
    function String (Analyser : in out Syntax_Analyser_Type)
                    return Boolean is
        Ret : Boolean;
    begin
        Begin_Rule (Analyser, "String");

        Ret := Accept_Token (Analyser, String_Literal_Quote)
          or else Accept_Token (Analyser, String_Literal_Single_Quote)
          or else Accept_Token (Analyser,
                                String_Literal_Long_Single_Quote)
          or else Accept_Token (Analyser, String_Literal_Long_Quote);

        End_Rule (Analyser);
        return Ret;
    end String;

    --  [10] subject ::= iri | BlankNode | collection
    function Subject (Analyser : in out Syntax_Analyser_Type)
                     return Boolean is
        Ret : Boolean;
    begin
        Begin_Rule (Analyser, "Subject");

        Ret := IRI (Analyser)
          or else Blank_Node (Analyser)
          or else Collection (Analyser);

        End_Rule (Analyser);
        return Ret;
    end Subject;

    --  [6] triples ::= subject predicateObjectList
    --    | blankNodePropertyList predicateObjectList?
    function Triples (Analyser : in out Syntax_Analyser_Type)
                     return Boolean is
        Ret : Boolean;
    begin
        Begin_Rule (Analyser, "Triples");

        if Subject (Analyser) then
            Ret := Predicate_Object_List (Analyser);
        else
            Ret := Blank_Node_Property_List (Analyser)
              and then (Predicate_Object_List (Analyser) or else True);
        end if;

        End_Rule (Analyser);
        return Ret;
    end Triples;

    --  [1] turtleDoc ::= statement*
    function Turtle_Doc (Analyser : in out Syntax_Analyser_Type)
                        return Boolean is
        Ret : Boolean := True;
    begin
        Begin_Rule (Analyser, "Turtle_Doc");

        loop
            Ret := Ret and then Statement (Analyser);
            exit when (not Ret)
              or else Analyser.Is_End_Of_Source;
        end loop;

        End_Rule (Analyser);
        return True;
    end Turtle_Doc;

    --  [9] verb ::= predicate | 'a'
    function Verb (Analyser : in out Syntax_Analyser_Type)
                  return Boolean is
        Ret : Boolean;
    begin
        Begin_Rule (Analyser, "Verb");

        Ret := Predicate (Analyser)
          or else Accept_Token (Analyser, Reserved_Word, "a");

        End_Rule (Analyser);
        return Ret;
    end Verb;
end Syntactical.Rules;
