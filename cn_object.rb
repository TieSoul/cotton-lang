
class CnObject
  attr_accessor :fields, :classname
  attr_reader :constants, :functions, :operators
  def initialize(cls, args)
    @classname = cls.name
    @functions = cls.functions
    @fields = {cls: cls}
    @operators = cls.operators
    @constants = cls.fields
    if @functions[:init].nil?
      raise FunctionNotFoundException.new("Could not find function 'init' for class #{@classname}.")
    end
    env = [{this: self}]
    args.each_index do |i|
      env[-1][@functions[:init].parameters[i]] = args[i]
    end
    interpret_stmts(cls.functions[:init].body, env)
  end
end