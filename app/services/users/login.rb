module Users
  class Login < BaseService

    def initialize(email:, password:, ip: nil)
      @email, @password, @ip = email, password, ip
    end

    def service_execute

      @user = User.find_by(email: @email)

      return ServiceResult.new(error: Exceptions::NotFoundError.new(User)) if @user.nil?

      return ServiceResult.new(error: Exceptions::InvalidPasswordError.new(User)) unless @user.valid_password?(@password)

      return ServiceResult.new(error: Exceptions::InvalidStateError.new) unless user_confirmed?

      Users::LogSignIn.execute(user: @user, ip: @ip)

      ServiceResult.new(value: @user)

    end

    private

    def build_sign_in_count
      @user.sign_in_count + 1
    end

    def user_confirmed?
      @user.confirmed_at?
    end

  end
end