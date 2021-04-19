module Users
  class GenerateResetPasswordCode < BaseService

    def service_execute
      ServiceResult.new(value: [*0..9999].sample.to_s.rjust(4, "0"))
    end

  end
end