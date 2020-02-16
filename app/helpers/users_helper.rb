module UsersHelper

  def set_user
    @user = User.find(params[:id])
  end
  
  def set_root
    @root = User.find_by(id: session[:user_id])
  end
  
  def set_user_session
    @user = User.find(session[:user_id])
  end
end
