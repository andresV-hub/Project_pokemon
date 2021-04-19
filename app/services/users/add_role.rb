module Users
  class AddRole < BaseService

    def initialize(user:, role_id:)
      @user, @role_id = user, role_id
    end

    def service_execute
      role = ::Base::Find.execute(klass: Role, id: @role_id).value
      @user.add_role(role.name)
      ServiceResult.new(value: true)
    end

  end
end