module Users
  class RequestConfirmationCode < BaseService

    def initialize(email:)
      @email = email
    end

    def service_execute
      @user = User.find_by(email: @email)

      return ServiceResult.new(error: Exceptions::NotFoundError.new(User)) if @user.nil?

      return ServiceResult.new(error: Exceptions::InvalidStateError.new) if user_confirmed?

      generate_confirmation_code! unless code_not_expired?

      send_confirmation_code_by_email

      ServiceResult.new(value: @user)

    end

    private

    def user_confirmed?
      @user.confirmed_at?
    end

    def generate_confirmation_code!
      @user.update(
          confirmation_token: Users::GenerateConfirmationCode.execute.value,
          confirmation_sent_at: Time.now.utc
      )
    end

    def code_not_expired?
      Devise.confirm_within && @user.confirmation_sent_at && (Time.now.utc < @user.confirmation_sent_at.utc + Devise.confirm_within)
    end

    def send_confirmation_code_by_email
      UserMailer.confirmation_code(@user.email).deliver_later
    end

  end
end