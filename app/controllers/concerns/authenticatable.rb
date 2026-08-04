module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    token = request.headers["Authorization"]&.delete_prefix("Bearer ")
    @current_user = User.find_by(api_token: token) if token.present?

    return if @current_user

    skip_authorization if respond_to?(:skip_authorization)
    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def current_user
    @current_user
  end
end
