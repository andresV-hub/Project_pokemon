module Users
  class CreateByAdmin < BaseService

    attr_reader :params

    def initialize(params:)
      @params = params.dup
    end

    def service_execute
      user = User.new(build_params)
      user.save
      ServiceResult.new(value: user)
    end

    private

      def build_params
        api_key = GenerateApiKey.execute.value
        locale = @params[:locale] || GetDefaultLocale.execute.value
        password = Devise.friendly_token.first(Devise.password_length.min)
        @params.merge({
          api_key: api_key,
          locale: locale,
          password: password
        })
      end

  end
end