module Users
  class Search < Base::Search

    def initialize(filters: nil, sort: nil)
      super(klass: User, filters: filters, sort: sort)
    end
      
    def apply_email_filter(filter_value)
      @value = @value.where("email LIKE ?", "%#{filter_value}%")
    end
      
    def apply_role_id_filter(filter_value)
      @value = @value.joins(:roles).where("roles.id LIKE ?", "%#{filter_value}%")
    end

  end
end