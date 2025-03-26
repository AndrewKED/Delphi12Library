unit HTML_Ops;

interface

function RemoveHTML(line : String) : String;

implementation

uses
  Character_Ops, Str_Ops;

//***************************************************************************
//
//  FUNCTION  : RemoveHTML
//
//  I/P       : line : String - The input, potentially containing HTML.
//
//  O/P       : String - The original line, with all HTML tags removed
//
//  OPERATION : Remove all HTML tags and constructs from a string.
//
//              This is a crude attempt, based on my current HTML knowledge (!)
//
//  UPDATED   : 2025-01-07
//
//***************************************************************************
function RemoveHTML(line : String) : String;
begin
  // Replace HTML spaces with normal spaces
  line := SearchAndReplace(line, '&nbsp', ' ');

  // HTML may contain carriage return and/or line feeds without affecting the
  // text, so remove these.
  line := SearchAndReplace(line, CHAR_CR, '');
  line := SearchAndReplace(line, CHAR_LF, '');

  // Replace HTML line breaks with a CRLF pair
  line := SearchAndReplace(line, '<br>', CRLF);

  // Remove all tags
  RemoveMarkedSections(line, '<', '>');

  Result := line;
end; // RemoveHTML

end.
