#
# Servicio 'search' genérico.
#
# Uso:
#
#   Base::Find.execute(klass: User, filters: { param_1: value_1, param_2: value_2, ... }, sort: {name: :asc} )
# 
# @author [sonxurxo]
# 

module Base
  class Search < BaseService

    attr_reader :klass, :filters, :sort

    def initialize(klass:, filters: nil, sort: nil)
      @klass, @filters, @sort = klass, filters.dup, sort
    end

    def service_execute

      @value = @klass.all

      unless @filters.nil?
        @filters.each do |filter|
          filter_name = filter[0]
          filter_value = filter[1]
          apply_filter_method_name = build_apply_filter_method_for_filter_name(filter_name: filter_name)
          if self.class.method_defined?(apply_filter_method_name.to_sym)
            apply_filter_method(apply_filter_method_name: apply_filter_method_name, filter_value: filter_value)
          else
            conditions = ApplicationRecord.sanitize_sql({"#{filter_name}": filter_value})

            if attribute_is_string?(attribute_name: filter_name)
              @value = apply_like_on_string_filter(filter_name: filter_name, filter_value: filter_value)
            else
              @value = @value.where(conditions)
            end

          end
        end
      end

      apply_sort unless @sort.nil?

      ServiceResult.new(value: @value)
    end

    private

    def should_apply_sort?
      !@sort.nil?
    end

    def attribute_is_string?(attribute_name:)
      @klass.type_for_attribute(attribute_name).type == :string
    end

    def apply_like_on_string_filter(filter_name:, filter_value:)
      @value.where(filter_name + ' LIKE ?', "%#{filter_value}%")
    end

    def apply_sort
      @value = @value.order(@sort)
    end

    def build_apply_filter_method_for_filter_name(filter_name:)
      "apply_#{filter_name}_filter"
    end

    def apply_filter_method(apply_filter_method_name:, filter_value:)
      send(apply_filter_method_name, filter_value)
    end

  end
end