module Sessions
  class Create < BaseService

    def initialize(user: nil,
                   email: nil,
                   operating_system_params:,
                   device_params:,
                   app_params:,
                   browser_params: nil,
                   locale:,
                   network_type_code: nil,
                   ip:,
                   latitude: nil,
                   longitude: nil,
                   auth_successful: nil,
                   remember_me: nil)
      @user = user
      @email = email
      @operating_system_params = operating_system_params
      @device_params = device_params
      @app_params = app_params
      @browser_params = browser_params
      @locale = locale
      @network_type_code = network_type_code
      @ip = ip
      @latitude = latitude
      @longitude = longitude
      @auth_successful = auth_successful
      @remember_me = remember_me
    end

    def service_execute

      Session.transaction do

        @operating_system = OperatingSystem.find_by(name: @operating_system_params[:name])

        return ServiceResult.new(error: Exceptions::NotFoundError.new(OperatingSystem)) if @operating_system.nil?

        @operating_system_version = find_or_create_operating_system_version

        @app = App.find_by(code: @app_params[:code])

        return ServiceResult.new(error: Exceptions::NotFoundError.new(App)) if @app.nil?

        @app_version = find_or_create_app_version

        @device = get_device

        @code = generate_code

        @browser_version = find_or_create_browser_version

        session = Session.new(
            code: @code,
            user: @user,
            email: @email,
            app_version: @app_version,
            browser_version: @browser_version,
            device: @device,
            operating_system_version: @operating_system_version,
            locale: @locale,
            network_type: build_network_type,
            ip: @ip,
            latitude: @latitude,
            longitude: @longitude,
            auth_successful: @auth_successful,
            remember_me: @remember_me
        )
        session.save!

        ServiceResult.new(value: session)

      end
    end

    private

    def find_or_create_operating_system_version
      Base::FindOrCreateBy.execute(
          klass: OperatingSystemVersion,
          params: {
              operating_system: @operating_system,
              name: @operating_system_params[:version]
          }).value
    end

    def find_or_create_app_version
      Base::FindOrCreateBy.execute(
          klass: AppVersion,
          params: {
              app: @app,
              operating_system: @operating_system_version.operating_system,
              name: @app_params[:version]
          }).value
    end

    def find_or_create_browser_version
      if @browser_params
        browser = Base::FindOrCreateBy.execute(
            klass: Browser,
            params: {
                name: @browser_params[:name]
            }).value
        Base::FindOrCreateBy.execute(
            klass: BrowserVersion,
            params: {
                browser: browser,
                name: @browser_params[:version]
            }).value
      end
    end

    def get_device
      device_manufacturer = Base::FindOrCreateBy.execute(
          klass: DeviceManufacturer,
          params: {
              name: @device_params[:manufacturer]
          }).value

      device_model = Base::FindOrCreateBy.execute(
          klass: DeviceModel,
          params: {
              device_manufacturer: device_manufacturer,
              name: @device_params[:model]
          }).value

      uuid = @device_params[:uuid]

      if Device.exists?(uuid: uuid)
        device = Device.find_by(uuid: uuid)
        device = Base::Update.execute(
            model: device,
            params: {
                user: @user,
                operating_system_version: @operating_system_version
            }).value
      else
        device = Base::Create.execute(
            klass: Device,
            params: {
                user: @user,
                uuid: uuid,
                operating_system_version: @operating_system_version,
                device_model: device_model
            }).value
      end
      device
    end

    def build_network_type
      @network_type_code.nil? ? NetworkType.unknown : NetworkType.find_by(code: @network_type_code)
    end

    def generate_code
      loop do
        code = Devise.friendly_token
        return code unless Session.exists?(code: code)
      end
    end

  end
end