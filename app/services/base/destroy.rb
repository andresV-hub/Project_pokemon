# 
# Servicio 'destroy' genérico.
#
# Uso:
#
#   Base::Destroy.execute(model: model)
# 
# @author [sonxurxo]
# 
module Base
  class Destroy < BaseService

    attr_reader :model

    def initialize(model:)
      @model = model
    end

    def service_execute
      @model.destroy
      ServiceResult.new(value: true)
    end

  end
end