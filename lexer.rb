#--
# DO NOT MODIFY!!!!
# This file is automatically generated by rex 1.0.5
# from lexical definition file "cotton.rex".
#++

require 'racc/parser'
class Cotton < Racc::Parser
  require 'strscan'

  class ScanError < StandardError ; end

  attr_reader   :lineno
  attr_reader   :filename
  attr_accessor :state

  def scan_setup(str)
    @ss = StringScanner.new(str)
    @lineno =  1
    @state  = nil
  end

  def action
    yield
  end

  def scan_str(str)
    scan_setup(str)
    do_parse
  end
  alias :scan :scan_str

  def load_file( filename )
    @filename = filename
    open(filename, "r") do |f|
      scan_setup(f.read)
    end
  end

  def scan_file( filename )
    load_file(filename)
    do_parse
  end


  def next_token
    return if @ss.eos?
    
    # skips empty actions
    until token = _next_token or @ss.eos?; end
    token
  end

  def _next_token
    text = @ss.peek(1)
    @lineno  +=  1  if text == "\n"
    token = case @state
    when nil
      case
      when (text = @ss.scan(/\/\/[^\n]*/))
        ;

      when (text = @ss.scan(/[ \t\n]+/))
        ;

      when (text = @ss.scan(/\bclass\b/))
         action {[:CLASS, text]}

      when (text = @ss.scan(/\bif\b/))
         action {[:IF, text]}

      when (text = @ss.scan(/\belse\b/))
         action {[:ELSE, text]}

      when (text = @ss.scan(/\belsif\b/))
         action {[:ELSIF, text]}

      when (text = @ss.scan(/\bwhile\b/))
         action {[:WHILE, text]}

      when (text = @ss.scan(/\bloop\b/))
         action {[:LOOP, text]}

      when (text = @ss.scan(/\bfor\b/))
         action {[:FOR, text]}

      when (text = @ss.scan(/\bin\b/))
         action {[:IN, text]}

      when (text = @ss.scan(/\bfn\b/))
         action {[:FN, text]}

      when (text = @ss.scan(/\btrue\b/))
         action {[:TRUE, true]}

      when (text = @ss.scan(/\bfalse\b/))
         action {[:FALSE, false]}

      when (text = @ss.scan(/\breturn\b/))
         action {[:RETURN, text]}

      when (text = @ss.scan(/\binclude\b/))
         action {[:INCLUDE, text]}

      when (text = @ss.scan(/\bop\b/))
         action {[:OPERATOR, text]}

      when (text = @ss.scan(/\bnil\b/))
         action {[:NIL, nil]}

      when (text = @ss.scan(/[;]+/))
         action {[:T, text]}

      when (text = @ss.scan(/[<>=!]=/))
         action {[:EQ, text]}

      when (text = @ss.scan(/[<>]/))
         action {[:EQ, text]}

      when (text = @ss.scan(/[+\-*\/%&|^\\!]{,2}=/))
         action {[:ASSIGNMENT, text[0...-1]]}

      when (text = @ss.scan(/0x[0-9a-fA-F]+/))
         action {[:INTEGER, text.to_i(16)]}

      when (text = @ss.scan(/0b[0-1]+/))
         action {[:INTEGER, text.to_i(2)]}

      when (text = @ss.scan(/0o[0-7]+/))
         action {[:INTEGER, text.to_i(8)]}

      when (text = @ss.scan(/[0-9]*(\.[0-9]+(e\-?[0-9]+)?)/))
         action {[:FLOAT, text.to_f]}

      when (text = @ss.scan(/[0-9]+e\-?[0-9]+/))
         action {[:FLOAT, text.to_f]}

      when (text = @ss.scan(/[0-9]+/))
         action {[:INTEGER, text.to_i]}

      when (text = @ss.scan(/\*\*/))
         action {[:POW, text]}

      when (text = @ss.scan(/[*\/%+\-][+\-*\/%&|^\\!]/))
         action {[:OP, text]}

      when (text = @ss.scan(/[*\/%]/))
         action {[:MULTOP, text]}

      when (text = @ss.scan(/[+\-]/))
         action {[:ADDOP, text]}

      when (text = @ss.scan(/[+\-*\/%&|^\\!]{1,2}/))
         action {[:OP, text]}

      when (text = @ss.scan(/"([^\"\\]|\\.)*"|'([^\'\\]|\\.)*'/))
         action {[:STRING, text[1...-1]]}

      when (text = @ss.scan(/[a-zA-Z][a-zA-Z0-9]*/))
         action {[:IDENTIFIER, text.to_sym]}

      when (text = @ss.scan(/./))
         action { [text, text] }

      else
        text = @ss.string[@ss.pos .. -1]
        raise  ScanError, "can not match: '" + text + "'"
      end  # if

    else
      raise  ScanError, "undefined state: '" + state.to_s + "'"
    end  # case state
    token
  end  # def _next_token

  def tokenize(code)
    scan_setup(code)
    tokens = []
    while token = next_token
      tokens << token
    end
    tokens
  end
end # class
