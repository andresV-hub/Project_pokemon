module Users
  class LogSignIn < BaseService

    def initialize(user:, ip: nil)
      @user, @ip = user, ip
    end

    def service_execute
      now = Time.now
      @user.update(
          sign_in_count: build_sign_in_count,
          current_sign_in_at: now,
          last_sign_in_at: now,
          current_sign_in_ip: @ip,
          last_sign_in_ip: @ip
      )

      ServiceResult.new(value: @user)

    end

    private

    def build_sign_in_count
      @user.sign_in_count + 1
    end

  end
end