class Cotton
macro
  WHITESPACE [\ \t\n]+
  COMMENT \/\/[^\n]*
rule
  {COMMENT} # do nothing
  {WHITESPACE} # do nothing
  \bclass\b {[:CLASS, text]}
  \bif\b {[:IF, text]}
  \belse\b {[:ELSE, text]}
  \belsif\b {[:ELSIF, text]}
  \bwhile\b {[:WHILE, text]}
  \bloop\b {[:LOOP, text]}
  \bfor\b {[:FOR, text]}
  \bin\b {[:IN, text]}
  \bfn\b {[:FN, text]}
  \btrue\b {[:TRUE, true]}
  \bfalse\b {[:FALSE, false]}
  \breturn\b {[:RETURN, text]}
  \binclude\b {[:INCLUDE, text]}
  \bop\b {[:OPERATOR, text]}
  \bnil\b {[:NIL, nil]}
  [;]+ {[:T, text]}
  [<>=!]= {[:EQ, text]}
  [<>] {[:EQ, text]}
  [+\-*\/%&|^\\!]{,2}= {[:ASSIGNMENT, text[0...-1]]}
  0x[0-9a-fA-F]+ {[:INTEGER, text.to_i(16)]}
  0b[0-1]+ {[:INTEGER, text.to_i(2)]}
  0o[0-7]+ {[:INTEGER, text.to_i(8)]}
  [0-9]*(\.[0-9]+(e\-?[0-9]+)?) {[:FLOAT, text.to_f]}
  [0-9]+e\-?[0-9]+ {[:FLOAT, text.to_f]}
  [0-9]+ {[:INTEGER, text.to_i]}
  \*\* {[:POW, text]}
  [*\/%+\-][+\-*\/%&|^\\!] {[:OP, text]}
  [*\/%] {[:MULTOP, text]}
  [+\-] {[:ADDOP, text]}
  [+\-*\/%&|^\\!]{1,2} {[:OP, text]}
  "([^\"\\]|\\.)*"|'([^\'\\]|\\.)*' {[:STRING, text[1...-1]]}
  [a-zA-Z][a-zA-Z0-9]* {[:IDENTIFIER, text.to_sym]}
  . { [text, text] }



inner
  def tokenize(code)
    scan_setup(code)
    tokens = []
    while token = next_token
      tokens << token
    end
    tokens
  end
end