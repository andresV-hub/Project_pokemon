# 
# Servicio 'new' genérico.
#
# Uso:
#
#   Base::New.execute(klass: User, params: {......})
# 
# @author [sonxurxo]
#
module Base
  class New < BaseService

    attr_reader :klass, :params

    def initialize(klass:, params:)
      @klass, @params = klass, params.dup
    end

    def service_execute
      model = @klass.new(@params)
      ServiceResult.new(value: model)
    end

  end
end