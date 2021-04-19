module Devices
  class Search < Base::Search

    def initialize(filters: nil, sort: nil)
      super(klass: Device, filters: filters, sort: sort)
    end
      
    def apply_email_filter(filter_value)
      @value = @value.joins(:user).where("users.email LIKE ?", "%#{filter_value}%")
    end
      
    def apply_uuid_filter(filter_value)
      @value = @value.where("uuid LIKE ?", "%#{filter_value}%")
    end

  end
end