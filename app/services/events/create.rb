module Events
  class Create < BaseService

    attr_reader :params

    def initialize(name:, event_date:, session:, user: nil, event_parameters: [])
      @name, @event_date, @user, @session, @event_parameters = name, event_date, user, session, event_parameters
    end

    def service_execute
      event = Event.new(
          name: @name,
          event_date: @event_date,
          user: @user,
          session: @session,
          event_parameters: build_event_parameters
      )
      event.save!
      ServiceResult.new(value: event)
    end

    private

    def build_event_parameters
      event_parameters = []
      @event_parameters.try(:each) do |event_parameter|
        event_parameters << new_event_parameter(name: event_parameter[:name], value: event_parameter[:value])
      end
      event_parameters
    end

    def new_event_parameter(name:, value:)
      Base::New.execute(klass: EventParameter, params: {name: name, value: value}).value
    end

  end
end