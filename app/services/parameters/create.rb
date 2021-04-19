module Parameters
  class Create < BaseService

    def initialize(params:)
      @params = params.dup
    end

    def service_execute

      if @params[:code].nil?
        @params[:code] = generate_code
      end

      parameter = Parameter.new(@params)
      parameter.save

      ServiceResult.new(value: parameter)

    end

    private

    def generate_code
      maximum = Parameter.maximum(:code)
      maximum.nil? ? 1 : maximum + 1
    end

  end
end