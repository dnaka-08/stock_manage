class SessionsController < ApplicationController
  def new
  end

  def create
    user_id = params[:session][:user_id]
    password = params[:session][:password]
    if login(user_id, password)
      flash[:success] = 'ログインに成功しました。'
      redirect_to root_url
    else
      flash.now[:danger] = 'ログインに失敗しました。'
      render :new
    end
  end

  def destroy
    session[:user_id] = nil
    flash[:success] = 'ログアウトしました。'
    redirect_to root_url
  end
  
  private
  
  def login(user_id, password)
    @user = User.find_by(user_id: user_id)
    if @user && @user.authenticate(password)
      session[:user_id] = @user.id
      return true
    else
      return false
    end
  end
end
