module Users
  class Confirm < BaseService

    def initialize(email:, code:)
      @email, @code = email, code
    end

    def service_execute
      @user = User.find_by(email: @email)

      return ServiceResult.new(error: Exceptions::NotFoundError.new(User)) if @user.nil?

      return ServiceResult.new(error: Exceptions::InvalidStateError.new) if user_confirmed?

      return ServiceResult.new(error: Exceptions::InvalidCodeError.new) unless code_matches?

      return ServiceResult.new(error: Exceptions::ExpiredCodeError.new) if code_expired?

      now = Time.now.utc

      @user.update(
          confirmed_at: now
      )

      ServiceResult.new(value: @user)

    end

    private

    def user_confirmed?
      @user.confirmed_at?
    end

    def code_matches?
      @user.confirmation_token == @code
    end

    def code_expired?
      Devise.confirm_within && @user.confirmation_sent_at && (Time.now.utc > @user.confirmation_sent_at.utc + Devise.confirm_within)
    end

  end
end