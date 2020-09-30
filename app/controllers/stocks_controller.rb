class StocksController < ApplicationController
  before_action :require_user_logged_in
  before_action :set_root, only: [:index]
  before_action :set_user_session, only: [:index]

  def index
    @stocks = Stock.joins(:store, :product).where("store_id = ? and product_id = ?", params[:store_id], params[:product_id]).order(date: :desc).page(params[:page]).per(5)
    @store = Store.find(params[:store_id])
    @product = Product.find(params[:product_id])
    
    date_col = Stock.where("store_id = ? and product_id = ?", params[:store_id], params[:product_id]).order(date: :asc).pluck("date")
    total_col = Stock.where("store_id = ? and product_id = ?", params[:store_id], params[:product_id]).order(date: :asc).pluck("out_number")
    @sample = LazyHighCharts::HighChart.new('graph') do |f|
      f.title(text: '出庫の推移')
      f.xAxis(categories: date_col)
      f.series(name: '出庫数', data: total_col)
    end
  end
end
