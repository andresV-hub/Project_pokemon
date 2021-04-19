module ApiRequests
  class Create < BaseService

    attr_reader :params

    def initialize(path:, user: nil, session: nil, network_type: nil, api_request_parameters: {})
      @path, @user, @session, @network_type, @api_request_parameters = path, user, session, network_type, api_request_parameters
    end

    def service_execute
      api_request = ApiRequest.new(
          path: @path,
          user: @user,
          session: @session,
          network_type: build_network_type,
          api_request_parameters: build_api_request_parameters
      )
      api_request.save
      ServiceResult.new(value: api_request)
    end

    private

    def build_api_request_parameters
      api_request_parameters = []
      @api_request_parameters.try(:each) do |name, value|
        api_request_parameters << new_api_request_parameter(name: name, value: value)
      end
      api_request_parameters
    end

    def build_network_type
      @network_type || NetworkType.unknown
    end

    def new_api_request_parameter(name:, value:)
      Base::New.execute(klass: ApiRequestParameter, params: {name: name, value: filtered_value(name: name, value: value)}).value
    end

    def filtered_value(name:, value:)
      return '****' if name.to_sym == :password
      value
    end

  end
end