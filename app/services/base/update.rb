# 
# Servicio 'update' genérico.
#
# Uso:
#
#   Base::Update.execute(model: model, params: : {......})
# 
# @author [sonxurxo]
# 
module Base
  class Update < BaseService

    attr_reader :model, :params

    def initialize(model:, params:)
      @model, @params = model, params.dup
    end

    def service_execute
      @model.update(@params)
      ServiceResult.new(value: @model)
    end

  end
end