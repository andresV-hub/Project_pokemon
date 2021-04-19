class ServiceResult

  attr_reader :value, :error
  
  def initialize(value: nil, error: nil)
    @value = value
    @error = error
  end

  def success?
    # Si el objeto devuelto es un model de ActiveRecord, y contiene errores, se devuelve false
    if @value && @value.is_a?(ApplicationRecord)
      @value.errors.none?
    else
      !@error
    end
  end

end