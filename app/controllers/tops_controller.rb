class TopsController < ApplicationController
  before_action :require_user_logged_in, only: [:index]
  before_action :set_root, only: [:index]
  before_action :set_user_session, only: [:index]
  
  def index
    if @user.admin
      @stocks = Stock.joins(:store, :product).where('date <= ?', Time.zone.now).group("stocks.store_id").group("stocks.product_id").select("stocks.store_id, stocks.product_id, sum(stocks.total_number) as total_number, stores.name as store_name, products.name as product_name")
    else
      @stocks = Stock.joins(:store, :product).where('stocks.store_id = ? and date <= ?', @user.store_id, Time.zone.now).group("stocks.store_id").group("stocks.product_id").select("stocks.store_id, stocks.product_id, sum(stocks.total_number) as total_number, stores.name as store_name, products.name as product_name")
    end
    
    if @user.admin
      @stock_details = StockDetail.joins(:user, :operation, :store, :product).order(id: :desc).select("stock_details.*, users.name as user_name, operations.name as operation_name, stores.name as store_name, products.name as product_name")
    else
      @stock_details = StockDetail.joins(:user, :operation, :store, :product).where('stock_details.store_id = ?', @user.store_id).order(id: :desc).select("stock_details.*, users.name as user_name, operations.name as operation_name, stores.name as store_name, products.name as product_name")
    end
  end
end
