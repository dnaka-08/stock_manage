class StoresController < ApplicationController
  before_action :authenticaet_user
  before_action :require_admin_user
  #before_action :set_root, only: [:index, :new, :edit]
  before_action :set_store, only: [:edit, :update, :destroy]
  before_action :set_user_session, only: [:index, :new, :edit]

  def index
    @stores = Store.order(id: :desc).page(params[:page]).per(15)
  end

  def new
    @store = Store.new
  end

  def create
    @store = Store.new(name: store_params["name"])
    if @store.save 
      @api_rec = make_api_call('post', '/v1.0/groups', access_token, {'displayName': "#{ENV['ENVIRONMENT']}_#{store_params["name"]}", "mailEnabled": "false", "mailNickname": ENV['ENVIRONMENT'], "securityEnabled": "true" })
      @api_rec_add_group = make_api_call('post', "/v1.0/groups/#{ENV['ADMIN_GROUP']}/members/$ref", access_token, {'@odata.id': "https://graph.microsoft.com/v1.0/groups/#{@api_rec["id"]}"})
      if @store.update(ad_id: @api_rec["id"]) and @api_rec and @api_rec_add_group["error"].nil?
        flash[:success] = '店舗を登録しました。'
        redirect_to stores_path
      end
    else
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
    @api_rec_del_group = make_api_call('delete', "/v1.0/groups/#{@store.ad_id}", access_token)
    if @store.destroy and @api_rec_del_group["error"].nil?
      flash[:success] = '正常に削除されました。'
      redirect_back(fallback_location: root_path)
    else
      flash.now[:danger] = '削除されませんでした。'
      redirect_back(fallback_location: root_path)
    end
    
  end
  
  private
  
  def store_params
     params.require(:store).permit(:name)
  end
  
  def set_store
    @store = Store.find(params[:id])
  end
end
