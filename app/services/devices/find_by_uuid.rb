module Devices
  class FindByUUID < BaseService

    def initialize(uuid:)
      @uuid = uuid
    end

    def service_execute
      device = Device.find_by(uuid: @uuid)
      if device
        ServiceResult.new(value: device)
      else
        ServiceResult.new(error: Exceptions::NotFoundError.new(Device))
      end
    end

  end
end