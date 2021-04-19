module Users
  class Logout < BaseService

    def initialize(user:)
      @user = user
    end

    def service_execute
      @user.update(
          current_sign_in_at: nil,
          current_sign_in_ip: nil
      )

      ServiceResult.new(value: @user)

    end

  end
end