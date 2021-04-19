module Parameters
  class Search < Base::Search

    def initialize(filters: nil, sort: nil)
      super(klass: Parameter, filters: filters, sort: sort)
    end

    def apply_name_filter(filter_value)
      @value = @value.where("name LIKE ?", "%#{filter_value}%")
    end

  end
end