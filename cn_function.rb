class CnFunction
  attr_reader :parameters, :body
  def initialize(parameters, body)
    @parameters = parameters
    @body = body
  end
end