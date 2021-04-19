module Users

  class Create < BaseService

    class Result < ServiceResult
      def initialize(value: nil, error: nil, user_created: false, password_valid: false, user_confirmed: false)
        super(value: value, error: error)
        @user_created = user_created
        @password_valid = password_valid
        @user_confirmed = user_confirmed
      end

      def user_created?;
        @user_created;
      end

      def password_valid?;
        @password_valid;
      end

      def user_confirmed?;
        @user_confirmed;
      end
    end

    attr_reader :params

    def initialize(email:, password:, ip: nil, locale: nil)
      @email, @password, @ip, @locale = email, password, ip, locale
    end

    def service_execute

      if User.exists?(email: @email)

        @user = User.find_by(email: @email)
        if @user.valid_password?(@password)
          # Ya existe, y tiene la misma contraseña -> es el propio usuario que en vez de ir a Login fue a Registro
          if user_confirmed?
            # Se inicia sesión automáticamente
            return Result.new(error: Exceptions::DuplicatedInstanceError.new, user_created: false, password_valid: true, user_confirmed: true)
          else
            # La cuenta está sin confirmar. Se envía email y se va a la pantalla de confirmar
            return Result.new(error: Exceptions::DuplicatedInstanceError.new, user_created: false, password_valid: true, user_confirmed: false)
          end
        else
          # Ya existe, pero la contraseña no es esta -> puede ser otra persona
          return Result.new(error: Exceptions::DuplicatedInstanceError.new, user_created: false, password_valid: false, user_confirmed: false)
        end

      else

        return Result.new(error: Exceptions::InvalidPasswordError.new, user_created: false, password_valid: false, user_confirmed: false) unless password_passes_validation?

        api_key = GenerateApiKey.execute.value
        locale = @locale || GetDefaultLocale.execute.value
        @user = User.new(
            email: @email,
            password: @password,
            api_key: api_key,
            locale: locale)

        User.transaction do
          @user.save!
          @user.add_role(:user)
        end

        Users::RequestConfirmationCode.execute(email: @email)
        return Result.new(value: @user, user_created: true, password_valid: true, user_confirmed: false)

      end

    end

    private

    def user_confirmed?
      @user.confirmed_at?
    end

    def password_passes_validation?
      Devise.password_length.include?(@password.length)
    end

  end

end