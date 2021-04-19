module Sessions
  class Update < BaseService

    def initialize(session_code:, user: nil, email: nil, auth_successful: nil)
      @session_code = session_code
      @user = user
      @email = email
      @auth_successful = auth_successful
    end

    def service_execute

      session = Session.find_by(code: @session_code)

      if session

        update_params = Hash.new
        update_params[:user] = @user if @user
        update_params[:email] = @email if @email
        update_params[:auth_successful] = @auth_successful if @auth_successful
        session.update(update_params)
        ServiceResult.new(value: session)

      else

        ServiceResult.new(error: Exceptions::NotFoundError.new(Session))

      end

    end

  end
end