module Users
  class Enable < BaseService

    def initialize(user:)
      @user = user
    end

    def service_execute
      @user.update(enabled: true)
      ServiceResult.new(value: true)
    end

  end
end