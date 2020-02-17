class StocksController < ApplicationController
  before_action :require_user_logged_in
  before_action :set_root, only: [:index]
  before_action :set_user_session, only: [:index]

  def index
    @stocks = Stock.joins(:store, :product).where("store_id = ? and product_id = ?", params[:store_id], params[:product_id]).order(date: :desc).page(params[:page]).per(15)
    @store = Store.find(params[:store_id])
    @product = Product.find(params[:product_id])
  end
end
