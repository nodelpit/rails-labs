class Api::V1::TokensController < Api::V1::BaseController
  skip_before_action :authenticate_with_api_token, only: [ :create ]

  def create
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      _, raw_token = user.generate_api_token
      render json: { api_token: raw_token, expires_in: 30.days.to_i }, status: :created
    else
      render json: { error: "Invalid credentials" }, status: :unauthorized
    end
  end

  def destroy
    current_user.revoke_all_api_tokens
    render json: { message: "API tokens révoqués" }, status: :ok
  end
end
