module Users
  class UpdatePassword < BaseService

    def initialize(user:, new_password:)
      @user, @new_password = user, new_password
    end

    def service_execute
      @user.update(
          password: @new_password
      )

      ServiceResult.new(value: @user)

    end

  end
end