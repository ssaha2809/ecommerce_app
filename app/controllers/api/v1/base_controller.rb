module Api
  module V1
    class BaseController < ApplicationController
      include Pundit::Authorization
      include Authenticatable

      skip_before_action :verify_authenticity_token

      after_action :verify_authorized

      rescue_from ActiveRecord::RecordNotFound,    with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid,     with: :render_unprocessable_entity
      rescue_from Pundit::NotAuthorizedError,      with: :render_forbidden

      private

      def render_not_found(exception)
        skip_authorization
        resource = exception.try(:model)&.demodulize || "Resource"
        render json: { error: "#{resource} not found" }, status: :not_found
      end

      def render_unprocessable_entity(exception)
        skip_authorization
        record = exception.record
        render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
      end

      def render_forbidden(_exception)
        render json: { error: "You are not authorized to perform this action" }, status: :forbidden
      end
    end
  end
end
