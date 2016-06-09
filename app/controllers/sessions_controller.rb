class SessionsController < ApplicationController
 skip_before_action :ensure_login, only: [:new, :create]
  def create
    user = User.from_omniauth(env["omniauth.auth"])
    session[:user_id] = user.id
    redirect_to restaurants_path
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path
  end
end
