module Users
  class GenerateApiKey < BaseService

    def service_execute
      loop do
        api_key = Devise.friendly_token
        return ServiceResult.new(value: api_key) unless User.exists?(api_key: api_key)
      end
    end

  end
end