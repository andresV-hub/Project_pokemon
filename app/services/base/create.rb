# 
# Servicio 'create' genérico.
#
# Uso:
#
#   Base::Create.execute(klass: User, params: {......})
# 
# @author [sonxurxo]
#
module Base
  class Create < BaseService

    attr_reader :klass, :params

    def initialize(klass:, params:)
      @klass, @params = klass, params.dup
    end

    def service_execute
      model = @klass.new(@params)
      model.save
      ServiceResult.new(value: model)
    end

  end
end
