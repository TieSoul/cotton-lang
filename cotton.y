class Cotton
    prechigh
        nonassoc PARENS
        left CLASSFUN
        left CLASSFIELD
        nonassoc UNOP
        right POW
        left MULTOP
        left ADDOP
        left BINOP
        left EQ
        left IN
        right ASSIGNMENT
        nonassoc RETURN
    preclow
rule
    program : stmtblock

    stmtblock : statement stmtblock { result = [val[0]] + val[1] }
            | { result = [] }

    statement : FN IDENTIFIER '(' idlist ')' '{' stmtblock '}' { result = [:FUNCTION, val[1], val[3], val[6]] }
            | OPERATOR FN operator '(' idlist ')' '{' stmtblock '}' { result = [:OPFUN, val[2], val[4], val[7]] }
            | CLASS IDENTIFIER '{' stmtblock '}' { result = [:CLASS, val[1], val[3]] }
            | WHILE expression '{' stmtblock '}' { result = [:WHILE, val[1], val[3]] }
            | FOR IDENTIFIER IN expression '{' stmtblock '}' { result = [:FORIN, val[1], val[3], val[5]] }
            | IF expression '{' stmtblock '}' { result = [:IF, val[1], val[3]] }
            | IF expression '{' stmtblock '}' else { result = [:IFELSE, val[1], val[3], val[5]] }
            | expression T { result = [:EXPRESSION, val[0]] }
            | RETURN expression T { result = [:RETURN, val[1]] }
            | INCLUDE expression T { result = [:INCLUDE, val[1]] }
            | T { result = nil }

    operator : OP | ADDOP | MULTOP | POW | EQ | OP '@' {result=val[0]+'@'} | ADDOP '@' {result=val[0]+'@'} | MULTOP '@' {result=val[0]+'@'} | POW '@' {result=val[0]+'@'} | EQ '@' { result = val[0] + '@' }
             | '[' ']' {result = "[]" } | '[' ']' ASSIGNMENT {raise SyntaxError if val[2] != ''; result = '[]='}

    else : ELSE '{' stmtblock '}' { result = val[2] }
         | ELSIF expression '{' stmtblock '}' else { result = [[:IFELSE, val[1], val[3], val[5]]] }
         | ELSIF expression '{' stmtblock '}' { result = [[:IF, val[1], val[3]]] }

    idlist : IDENTIFIER ',' idlist { result = [val[0]] + val[2]}
            | IDENTIFIER { result = [val[0]] }
            | { result = [] }

    expression : expression OP expression  { result = [:BINOP, val[1], val[0], val[2]] } = BINOP
        | IDENTIFIER '(' explist ')' { result = [:FUNCALL, val[0], val[2]] }
        | expression EQ expression { result = [:BINOP, val[1], val[0], val[2]] }
        | expression ADDOP expression { result = [:BINOP, val[1], val[0], val[2]] }
        | expression MULTOP expression { result = [:BINOP, val[1], val[0], val[2]] }
        | expression POW expression { result = [:BINOP, val[1], val[0], val[2]] }
        | expression IN expression { result = [:IN, val[0], val[2]] }
        | OP expression { result = [:UNOP, val[0], val[1]] }  = UNOP
        | ADDOP expression { result = [:UNOP, val[0], val[1]] } = UNOP
        | MULTOP expression { result = [:UNOP, val[0], val[1]] } = UNOP
        | POW expression { result = [:UNOP, val[0], val[1]] } = UNOP
        | '(' expression ')' { result = val[1] } = PARENS
        | IDENTIFIER { result = [:IDENTIFIER, val[0]] }
        | IDENTIFIER ASSIGNMENT expression { result = [:ASSIGNMENT, val[0], val[1], val[2]] }
        | number
        | STRING { result = [:STRING, val[0]] }
        | expression '.' IDENTIFIER '(' explist ')' { result = [:CLASSFUNCALL, val[0], val[2], val[4]] } = CLASSFUN
        | expression '.' IDENTIFIER { result = [:CLASSFIELD, val[0], val[2]] } = CLASSFIELD
        | expression '.' IDENTIFIER ASSIGNMENT expression { result = [:CLASSASSIGN, val[0], val[2], val[3], val[4]] }
        | TRUE { result = [:BOOL, val[0]] }
        | FALSE { result = [:BOOL, val[0]] }
        | array { result = [:ARRAY, val[0]] }
        | expression '[' expression ']' ASSIGNMENT expression { result = [:INDEXASSIGN, val[0], val[2], val[4], val[5]] }
        | expression '[' expression ']' { result = [:INDEX, val[0], val[2]] }
        | NIL { result = [:NIL, nil] }

    array : '[' explist ']' { result = val[1] }

    explist : expression ',' explist { result = [val[0]] + val[2] }
            | expression { result = [val[0]] }
            | { result = [] }

    number :
          INTEGER { result = [:INTEGER, val[0]] } | FLOAT { result = [:FLOAT, val[0]] }
end

----header
    require_relative 'lexer'

----inner
    def parse(text)
        scan_str(text)
    end