module Users
  class GetDefaultLocale < BaseService

    def service_execute
      ServiceResult.new(value: Settings.locale.default)
    end

  end
end