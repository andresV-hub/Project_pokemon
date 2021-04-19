module ApiRequests
  class Search < Base::Search

    def initialize(filters: nil, sort: nil)
      super(klass: ApiRequest, filters: filters, sort: sort)
    end
      
    def apply_email_filter(filter_value)
      @value = @value.joins(:user).where("users.email LIKE ?", "%#{filter_value}%")
    end
      
    def apply_session_code_filter(filter_value)
      @value = @value.joins(:session).where("sessions.code LIKE ?", "%#{filter_value}%")
    end
      
    def apply_path_filter(filter_value)
      @value = @value.where("path LIKE ?", "%#{filter_value}%")
    end

  end
end