module Users
  class RequestResetPasswordCode < BaseService

    def initialize(email:)
      @email = email
    end

    def service_execute
      @user = User.find_by(email: @email)

      return ServiceResult.new(error: Exceptions::NotFoundError.new(User)) if @user.nil?

      return ServiceResult.new(error: Exceptions::InvalidStateError.new) unless user_confirmed?

      generate_reset_password_code! unless code_not_expired?

      send_reset_password_code_by_email

      ServiceResult.new(value: @user)

    end

    private

    def user_confirmed?
      @user.confirmed_at?
    end

    def generate_reset_password_code!
      @user.update(
          reset_password_token: Users::GenerateResetPasswordCode.execute.value,
          reset_password_sent_at: Time.now.utc
      )
    end

    def code_not_expired?
      Devise.reset_password_within && @user.reset_password_sent_at && (Time.now.utc < @user.reset_password_sent_at.utc + Devise.reset_password_within)
    end

    def send_reset_password_code_by_email
      UserMailer.reset_password_code(@user.email).deliver_later
    end

  end
end