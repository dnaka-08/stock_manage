class TopsController < ApplicationController
  before_action :set_user_session, only: [:index]
  before_action :authenticaet_user, only: [:index]
  #before_action :set_root, only: [:index]
  
  def index
    if @user_admin
      @stocks = Stock.joins(:store, :product).where('date <= ?', Time.zone.now).group("stocks.store_id").group("stocks.product_id").group("stores.name").group("products.name").select("stocks.store_id, stocks.product_id, sum(stocks.total_number) as total_number, stores.name as store_name, products.name as product_name")
    else
      @stocks = Stock.joins(:store, :product).where(store_id: @user_target_store).where('date <= ?', Time.zone.now).group("stocks.store_id").group("stocks.product_id").group("stores.name").group("products.name").select("stocks.store_id, stocks.product_id, sum(stocks.total_number) as total_number, stores.name as store_name, products.name as product_name")
    end
   
    if @user_admin
      @stock_details = StockDetail.joins(:operation, :store, :product).order(id: :desc).select("stock_details.*, user_name as user_name, operations.name as operation_name, stores.name as store_name, products.name as product_name").page(params[:page]).per(15)
    else
      @stock_details = StockDetail.joins(:operation, :store, :product).where(store_id: @user_target_store).order(id: :desc).select("stock_details.*, user_name as user_name, operations.name as operation_name, stores.name as store_name, products.name as product_name").page(params[:page]).per(15)
    end
  end
end
