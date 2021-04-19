# 
# Servicio 'find' genérico.
#
# Uso:
#
#   Base::Find.execute(klass: User, id: 1123)
# 
# @author [sonxurxo]
# 
module Base
  class Find < BaseService

    attr_reader :klass, :id

    def initialize(klass:, id:)
      @klass, @id = klass, id
    end

    def service_execute
      begin
        @klass.find(@id)
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end

  end
end