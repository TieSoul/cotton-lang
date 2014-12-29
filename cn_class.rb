class CnClass
  attr_reader :functions, :fields, :name, :operators
  def initialize(name, stmts, env)
    @name = name
    @functions = {}
    @operators = {}
    @fields = {}
    env << {this: self}
    stmts.each do |x|
      if x[0] == :FUNCTION
        @functions[x[1]] = CnFunction.new(x[2], x[3])
      elsif x[0] == :OPFUN
        @operators[x[1]] = CnFunction.new(x[2], x[3])
      elsif x[0] == :EXPRESSION and x[1][0] == :ASSIGNMENT
        if x[1][2] == ''
          @fields[x[1][1]] = interpret_expr(x[1][3], env)
        end
      end
    end
    env.pop
    self
  end
end