module Sessions
  class Search < Base::Search

    def initialize(filters: nil, sort: nil)
      super(klass: Session, filters: filters, sort: sort)
    end
      
    def apply_email_filter(filter_value)
      @value = @value.joins(:user).where("users.email LIKE ?", "%#{filter_value}%")
    end
      
    def apply_code_filter(filter_value)
      @value = @value.where("code LIKE ?", "%#{filter_value}%")
    end
      
    def apply_device_model_id_filter(filter_value)
      @value = @value.joins(:device).where(devices: { device_model_id: filter_value })
    end

  end
end