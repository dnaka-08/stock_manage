class UsersController < ApplicationController
  before_action :require_user_logged_in, only: [:index, :edit, :update, :destroy]
  before_action :require_admin_user, only: [:index, :destroy]
  before_action :set_user, only: [:edit, :update, :destroy]
  before_action :set_root, only: [:index, :new, :edit]
  before_action :set_user_session, only: [:index]
  
  def index
    @users = User.order(id: :desc).page(params[:page]).per(15)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    
    if @user.save
      flash[:success] = 'ユーザを登録しました。'
      redirect_to users_path
    else
      flash[:danger] = 'ユーザの登録に失敗しました。'
      render :new
    end
  end
  
  def edit
  end
  
  def update
    if @user.update(user_params)
      flash[:success] = '正常に更新されました。'
      redirect_to users_path
    else
      flash.now[:danger] = '更新されませんでした。'
      render :edit
    end
  end
  
  def destroy
    @user.destroy
    
    flash[:success] = '正常に削除されました。'
    redirect_back(fallback_location: root_path)
  end
  
  private
  
  def user_params
    params.require(:user).permit(:id, :user_id, :name, :password, :password_confirmation, :admin, :store_id)
  end
end
