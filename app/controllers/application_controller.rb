class ApplicationController < ActionController::Base
  include SessionsHelper
  include UsersHelper
  
  private
  
  def require_user_logged_in
    @user_count = User.find_by(admin: true)
    if @user_count == 0 || @user_count == nil
      redirect_to signup_path
    else
      unless logged_in?
        redirect_to login_url
      end
    end
  end
  
  def require_admin_user
    current_user
    unless @current_user.admin
      redirect_to root_url
    end
  end
end
