module Users
  class EmailInquire < BaseService

    def initialize(email:)
      @email = email
    end

    def service_execute

      response = ::EmailInquire.validate(@email)

      ServiceResult.new(value: response)

    end

  end
end