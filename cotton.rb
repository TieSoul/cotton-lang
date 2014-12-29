require_relative 'parser'
require_relative 'cn_function'
require_relative 'cn_class'
require_relative 'cn_object'
require 'pp'
class FunctionNotFoundException < StandardError
end

def parse(program)
  Cotton.new.parse("#{program}\n")
end

def interpret(program)
  interpret_stmts(parse(program), [{}])
end

def interpret_stmts(stmts, env)
  x = nil
  stmts.each do |stmt|
    x = interpret_stmt(stmt, env)
  end
  x
end

class ReturnException < StandardError
  attr_reader :value
  def initialize(value)
    super("Can't return outside functions.")
    @value = value
  end
end

def interpret_stmt(stmt, env)
  return if stmt.nil?
  case stmt[0]
    when :EXPRESSION
      return interpret_expr(stmt[1], env)
    when :RETURN
      raise ReturnException.new(interpret_expr(stmt[1], env))
    when :FUNCTION
      env[-1][stmt[1]] = CnFunction.new(stmt[2], stmt[3])
    when :INCLUDE
      file = nil
      filename = interpret_expr(stmt[1], env)
      if File.file? "#{File.dirname __FILE__}/stdlib/#{filename}.cn"
        file = File.read("#{File.dirname __FILE__}/stdlib/#{filename}.cn")
      elsif File.file? "#{Dir.pwd}/#{filename}"
        file = File.read("#{Dir.pwd}/#{filename}")
      elsif File.file? "#{Dir.pwd}/#{filename}.cn"
        file = File.read("#{Dir.pwd}/#{filename}.cn")
      end
      interpret_stmts(parse(file), env)
    when :IF
      expr = interpret_expr(stmt[1], env)
      if expr
        interpret_stmts(stmt[2], env)
      end
    when :IFELSE
      expr = interpret_expr(stmt[1], env)
      if expr
        interpret_stmts(stmt[2], env)
      else
        interpret_stmts(stmt[3], env)
      end
    when :WHILE
      expr = interpret_expr(stmt[1], env)
      while expr
        interpret_stmts(stmt[2], env)
        expr = interpret_expr(stmt[1], env)
      end
    when :CLASS
      env[-1][stmt[1]] = CnClass.new(stmt[1].to_s, stmt[2], env)
      return env[-1][stmt[1]]
  end
end

class InvalidVariableException < StandardError
end

UNESCAPES = {
    'a' => "\x07", 'b' => "\x08", 't' => "\x09",
    'n' => "\x0a", 'v' => "\x0b", 'f' => "\x0c",
    'r' => "\x0d", 'e' => "\x1b", "\\\\" => "\x5c",
    "\"" => "\x22", "'" => "\x27"
}

def unescape(str)
  # Escape all the things
  str.gsub(/\\(?:([#{UNESCAPES.keys.join}])|u([\da-fA-F]{4}))|\\0?x([\da-fA-F]{2})/) {
    if $1
      if $1 == '\\' then '\\' else UNESCAPES[$1] end
    elsif $2 # escape \u0000 unicode
      ["#$2".hex].pack('U*')
    elsif $3 # escape \0xff or \xff
      [$3].pack('H2')
    end
  }
end

def interpret_expr(expr, env)
  case expr[0]
    when :INTEGER, :FLOAT, :BOOL
      return expr[1]
    when :STRING
      return unescape(expr[1])
    when :ARRAY
      return expr[1].map {|x| interpret_expr(x, env)}
    when :CLASSFUNCALL
      obj = interpret_expr(expr[1], env)
      if obj.is_a? CnObject or obj.is_a? CnClass
        fun = obj.functions[expr[2]]
        env << {}
        fun.parameters.each_index do |i|
          env[-1][fun.parameters[i]] = interpret_expr(expr[3][i], env)
        end
        env[-1][:this] = obj
        returnvalue = nil
        begin
          interpret_stmts(fun.body, env)
        rescue ReturnException => e
          returnvalue = e.value
        end
        env.pop
        return returnvalue
      else
        case expr[2]
          when :toString
            return obj.to_s
          when :toInteger
            return obj.to_i
          when :toFloat
            return obj.to_f
        end
      end
    when :CLASSFIELD
      obj = interpret_expr(expr[1], env)
      if obj.is_a? CnObject
        return obj.fields[expr[2]] || obj.constants[expr[2]]
      elsif obj.is_a? CnClass
        return obj.fields[expr[2]]
      end
    when :CLASSASSIGN
      obj = interpret_expr(expr[1], env)
      if obj.is_a? CnObject
        if expr[3] == ''
          obj.fields[expr[2]] = interpret_expr(expr[4], env)
        else
          obj.fields[expr[2]] = interpret_expr([:BINOP, expr[3], [:CLASSFIELD, expr[1], expr[2]], expr[4]], env)
        end
      end
    when :INDEX
      obj = interpret_expr expr[1], env
      index = interpret_expr expr[2], env
      if obj.is_a? CnObject
        if obj.operators.has_key? '[]'
          fun = obj.operators['[]']
          if fun.parameters.length != 1
            raise StandardError.new("Index function of class #{obj.classname} does not have one parameter.")
          end
          env << {this: obj}
          env[-1][fun.parameters[0]] = index
          returnvalue = nil
          begin
            interpret_stmts(fun.body, env)
          rescue ReturnException => e
            returnvalue = e.value
          end
          env.pop
          return returnvalue
        end
        raise FunctionNotFoundException.new("Index function of class #{obj.classname} does not exist.")
      else
        return obj[index]
      end
    when :BINOP
      obj = interpret_expr expr[2], env
      arg = interpret_expr expr[3], env
      if obj.is_a? CnObject
        if obj.operators.has_key? expr[1]
          fun = obj.operators[expr[1]]
          if fun.parameters.length != 1
            raise StandardError.new("Operator function #{expr[1].to_s} of class #{obj.classname} does not have one parameter.")
          end
          env << {this: obj}
          env[-1][fun.parameters[0]] = arg
          returnvalue = nil
          begin
            interpret_stmts(fun.body, env)
          rescue ReturnException => e
            returnvalue = e.value
          end
          env.pop
          return returnvalue
        end
        raise FunctionNotFoundException.new("Operator function #{expr[1].to_s} of class #{obj.classname} does not exist.")
      end
      return expr[2..3].map {|x| interpret_expr(x, env)}.inject(expr[1].to_sym)
    when :UNOP
      obj = interpret_expr(expr[2], env)
      if obj.is_a? CnObject
        if obj.operators.include? expr[1] + '@'
          fun = obj.operators[expr[1] + '@']
          if fun.parameters.length != 0
            raise StandardError.new("Unary operator function #{expr[1].to_s} of class #{obj.classname} has parameters")
          end
          env << {this: obj}
          returnvalue = nil
          begin
            interpret_stmts(fun.body, env)
          rescue ReturnException => e
            returnvalue = e.value
          end
          env.pop
          return returnvalue
        end
        raise FunctionNotFoundException.new("Unary operator function #{expr[1].to_s} of class #{obj.classname} does not exist.")
      end
      begin
        return eval("#{expr[1].to_s}#{obj.inspect}")
      rescue SyntaxError
        raise FunctionNotFoundException.new("Unary operator function #{expr[1].to_s} is not available for primitives.")
      end
    when :ASSIGNMENT
      if expr[2] == ''
        env[-1][expr[1]] = interpret_expr(expr[3], env)
      else
        env[-1][expr[1]] = interpret_expr([:BINOP, expr[2], [:IDENTIFIER, expr[1]], expr[3]], env)
      end
      return env[-1][expr[1]]
    when :IDENTIFIER
      env.reverse.each do |scope|
        if scope.has_key? expr[1]
          return scope[expr[1]]
        end
      end
      raise InvalidVariableException.new("Variable '#{expr[1].to_s}' not found.")
    when :FUNCALL
      env.reverse.each do |scope|
        if scope[expr[1]].is_a? CnClass
          return CnObject.new(scope[expr[1]], expr[2].map {|x| interpret_expr(x, env)})
        end
        if scope[expr[1]].is_a? CnFunction
          fun = scope[expr[1]]
          if expr[2].length != fun.parameters.length
            raise StandardError.new("Function #{expr[1].to_s} called with an inappropriate amount of arguments.")
          end
          env << {}
          fun.parameters.each_index do |i|
            env[-1][fun.parameters[i]] = interpret_expr(expr[2][i], env)
          end
          returnvalue = nil
          begin
            interpret_stmts(fun.body, env)
          rescue ReturnException => e
            returnvalue = e.value
          end
          env.pop
          return returnvalue
        end
      end
      if expr[1] == :println
        if expr[2].length == 0
          raise StandardError.new("Function #{expr[1].to_s} called with an inappropriate amount of arguments.")
        end
        x = expr[2].map {|x| interpret_expr(x, env)}
        puts x
        return (x.length > 1 ? x : x[0])
      elsif expr[1] == :print
        if expr[2].length == 0
          raise StandardError.new("Function #{expr[1].to_s} called with an inappropriate amount of arguments.")
        end
        x = expr[2].map {|x| interpret_expr(x, env)}
        print x.map {|x| x.to_s}.join(' ')
        return (x.length > 1 ? x : x[0])
      elsif expr[1] == :input
        if expr[2].length > 1
          raise StandardError.new("Function #{expr[1].to_s} called with an inappropriate amount of arguments.")
        end
        if expr[2].length == 1
          print interpret_expr(expr[2][0], env)
        end
        return gets.chomp
      elsif expr[1] == :exit
        if expr[2].length > 1
          raise StandardError.new("Function #{expr[1].to_s} called with an inappropriate amount of arguments.")
        end
        if expr[2].length > 0
          exit(interpret_expr(expr[2][0], env))
        else
          exit
        end
      elsif expr[1] == :isInstanceOf
        if expr[2].length != 2
          raise StandardError.new("Function #{expr[1].to_s} called with an inappropriate amount of arguments.")
        end
        obj = interpret_expr(expr[2][0], env)
        cls = interpret_expr(expr[2][1], env)
        if cls.is_a? CnClass
          return (obj.is_a? CnObject and obj.classname == cls.name)
        else
          raise StandardError.new("Function isInstanceOf called with a non-class as second argument.")
        end
      elsif expr[1] == :isInteger
        if expr[2].length != 1
          raise StandardError.new("Function #{expr[1].to_s} called with an inappropriate amount of arguments.")
        end
        return interpret_expr(expr[2][0], env).is_a? Integer
      elsif expr[1] == :isFloat
        if expr[2].length != 1
          raise StandardError.new("Function #{expr[1].to_s} called with an inappropriate amount of arguments.")
        end
        return interpret_expr(expr[2][0], env).is_a? Float
      elsif expr[1] == :isString
        if expr[2].length != 1
          raise StandardError.new("Function #{expr[1].to_s} called with an inappropriate amount of arguments.")
        end
        return interpret_expr(expr[2][0], env).is_a? String
      elsif expr[1] == :isArray
        if expr[2].length != 1
          raise StandardError.new("Function #{expr[1].to_s} called with an inappropriate amount of arguments.")
        end
        return interpret_expr(expr[2][0], env).is_a? Array
      end
      raise FunctionNotFoundException.new("Function #{expr[1].to_s} not found.")
  end
end

if ARGV.length > 0
  interpret(File.read(ARGV[0]))
else
  env = [{}]
  while true
    print '> '
    begin
      x = interpret_stmts(parse(gets.chomp), env)
      puts (x.is_a? Array) ? x.inspect : x
    rescue => e
      $stderr.puts("Error: #{e.message.delete("\n")}")
    end
    $stderr.flush
  end
end

