module Users
  class SendResetPasswordInstructions < BaseService

    def initialize(user:)
      @user = user
    end

    def service_execute
      @user.send_reset_password_instructions
      ServiceResult.new(value: true)
    end

  end
end