module Users
  class Disable < BaseService

    def initialize(user:)
      @user = user
    end

    def service_execute
      @user.update(enabled: false)
      ServiceResult.new(value: true)
    end

  end
end