# 
# Servicio 'find_or_initialize_by' genérico.
#
# Uso:
#
#   Base::FindOrInitializeBy.execute(klass: User, params: {......})
# 
# @author [sonxurxo]
# 
module Base
  class FindOrInitializeBy < BaseService

    attr_reader :klass, :params

    def initialize(klass:, params:)
      @klass, @params = klass, params.dup
    end

    def service_execute
      ServiceResult.new(value: @klass.find_or_initialize_by(@params))
    end

  end
end