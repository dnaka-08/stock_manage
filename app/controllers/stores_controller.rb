class StoresController < ApplicationController
  before_action :require_user_logged_in
  before_action :require_admin_user
  before_action :set_root, only: [:index, :new, :edit]
  before_action :set_store, only: [:edit, :update, :destroy]
  before_action :set_user_session, only: [:index, :new, :edit]

  def index
    @stores = Store.order(id: :desc).page(params[:page]).per(15)
  end

  def new
    @store = Store.new
  end

  def create
    @store = Store.new(store_params)
    
    if @store.save
      flash[:success] = '店舗を登録しました。'
      redirect_to stores_path
    else
      set_root
      set_user_session
      flash[:danger] = '店舗の登録に失敗しました。'
      render :new
    end  
  end

  def edit
  end

  def update
    if @store.update(store_params)
      flash[:success] = '正常に更新されました。'
      redirect_to stores_path
    else
      flash.now[:danger] = '更新されませんでした。'
      render :edit
    end
  end

  def destroy
    @store.destroy
    
    flash[:success] = '正常に削除されました。'
    redirect_back(fallback_location: root_path)
  end
  
  private
  
  def store_params
     params.require(:store).permit(:name)
  end
  
  def set_store
    @store = Store.find(params[:id])
  end
end
