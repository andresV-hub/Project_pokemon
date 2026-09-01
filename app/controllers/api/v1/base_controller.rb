module Api
  module V1
    # Base de la API JSON. Se apoya en la misma sesión de Devise que la parte
    # web, de modo que el front del propio proyecto puede consumirla sin montar
    # un esquema de tokens aparte.
    class BaseController < ApplicationController

      MAX_PER_PAGE = 60

      before_action :authenticate_user!

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

      private

      def render_not_found(exception)
        render json: { error: 'not_found', message: exception.message }, status: :not_found
      end

      def page_param
        params[:page]
      end

      # `per_page` llega del cliente, así que se acota para que nadie pueda
      # pedir la colección entera en una sola llamada.
      def per_page_param
        requested = params[:per_page].to_i
        return nil unless requested.positive?

        [requested, MAX_PER_PAGE].min
      end

      def authenticate_user!
        return super if request.format.html?

        render json: { error: 'unauthorized', message: 'Autenticacion requerida' }, status: :unauthorized unless user_signed_in?
      end

    end
  end
end
