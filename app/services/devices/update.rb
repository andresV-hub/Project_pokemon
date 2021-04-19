module Devices
  class Update < BaseService

    def initialize(device:, operating_system_params: nil, device_token: nil, fcm_token: nil)
      @device = device
      @operating_system_params = operating_system_params
      @device_token = device_token
      @fcm_token = fcm_token
    end

    def service_execute

      attributes = {}

      if @operating_system_params
        @operating_system = OperatingSystem.find_by(name: @operating_system_params[:name])

        return ServiceResult.new(error: Exceptions::NotFoundError.new(OperatingSystem)) if @operating_system.nil?

        @operating_system_version = find_or_create_operating_system_version
        attributes[:operating_system_version] = @operating_system_version
      end

      attributes[:device_token] = @device_token unless @device_token.blank?
      attributes[:fcm_token] = @fcm_token unless @fcm_token.blank?

      @device.update(attributes)

      ServiceResult.new(value: @device)
    end

    private

    def find_or_create_operating_system_version
      Base::FindOrCreateBy.execute(
          klass: OperatingSystemVersion,
          params: {
              operating_system: @operating_system,
              name: @operating_system_params[:version]
          }).value
    end

  end
end