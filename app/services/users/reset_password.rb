module Users
  class ResetPassword < BaseService

    def initialize(email:, code:, password:)
      @email, @code, @password = email, code, password
    end

    def service_execute
      @user = User.find_by(email: @email)

      return ServiceResult.new(error: Exceptions::NotFoundError.new(User)) if @user.nil?

      return ServiceResult.new(error: Exceptions::InvalidStateError.new) unless user_confirmed?

      return ServiceResult.new(error: Exceptions::InvalidCodeError.new) unless code_matches?

      return ServiceResult.new(error: Exceptions::ExpiredCodeError.new) if code_expired?

      now = Time.now.utc

      @user.update!(
          password: @password
      )

      ServiceResult.new(value: @user)

    end

    private

    def user_confirmed?
      @user.confirmed_at?
    end

    def code_matches?
      @user.reset_password_token == @code
    end

    def code_expired?
      Devise.reset_password_within && @user.reset_password_sent_at && (Time.now.utc > @user.reset_password_sent_at.utc + Devise.reset_password_within)
    end

  end
end