# 
# Servicio 'find_or_create_by' genérico.
#
# Uso:
#
#   Base::FindOrCreateBy.execute(klass: User, params: {......})
# 
# @author [sonxurxo]
# 
module Base
  class FindOrCreateBy < BaseService

    attr_reader :klass, :params

    def initialize(klass:, params:)
      @klass, @params = klass, params.dup
    end

    def service_execute
      ServiceResult.new(value: @klass.find_or_create_by(@params))
    end

  end
end