class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :ensure_login
  helper_method :current_user
  helper_method :add_rate_helper
  def ensure_login
  		# Always go to login page unless session contain user_id
  		redirect_to home_show_path unless session[:user_id]
  end
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  
  # Adding rates to selected Restaurant
  def add_rate_helper(rate_to_be_added,restaurant_id)  
      attributes = {
        "UserID" => current_user.id, 
        "RestaurantID" => restaurant_id,
        "Rate" => rate_to_be_added,
        "Comment" => "none"
      }
      new_rate = Rate.find_by( "UserID" => current_user.id, "RestaurantID" => restaurant_id)
      Rate.create(attributes) unless new_rate
      Rate.find_by("UserID" => current_user.id, "RestaurantID" => restaurant_id).update_attributes(attributes)
  end
end
