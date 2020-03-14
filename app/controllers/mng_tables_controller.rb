class MngTablesController < ApplicationController
  before_action :require_user_logged_in
  before_action :set_root, only: [:index]
  before_action :set_user_session, only: [:index]

  def index
    @stock_detail = StockDetail.joins(:operation, :store).where("stock_details.date >= '2020-03-01' and stock_details.date <= '2020-03-31'").group("stores.name").group("stock_details.date").group("operations.name").select("stores.name as store_name, stock_details.date as date, operations.name as operation_name, sum(stock_details.number) as stock_sum")
    @stock = Stock.joins(:store).where("stocks.date >= '2020-03-01' and stocks.date <= '2020-03-31'").select("stores.name as store_name, stocks.date as date, stocks.total_number")
    @stock_before = Stock.joins(:store).where("stocks.date < '2020-03-01'").group("stores.name").select("stores.name as store_name, sum(stocks.total_number) as total_number_sum")
    @store = StockDetail.joins(:store).where("date >= '2020-03-01' and date <= '2020-03-31'").select("stores.name as store_name").distinct
    @operation = Operation.all

    @mng_table = []
    @store.each do |store|
      @operation.each do |ope|
        @mng_rec = {}
        @mng_rec.store("store", store.store_name)
        @mng_rec.store("ope", ope.name)
        (Date.parse('2020-03-01')..Date.parse('2020-03-31')).each do |date|
          @stock_detail.each do |stock_detail|
            if stock_detail.date == date and stock_detail.store_name == store.store_name and stock_detail.operation_name == ope.name
              @mng_rec.store(date, stock_detail.stock_sum)
              break
            else
              @mng_rec.store(date, 0)
            end
          end
        end
        @mng_table.push(@mng_rec)
      end
      
      @mng_rec = {}
      @mng_rec.store("store", store.store_name)
      @mng_rec.store("ope", "在庫")
      total_number = 0
      @stock_before.each do |stock_before|
        if stock_before.store_name == store.store_name
          total_number = stock_before.total_number_sum
          break
        end
      end      
      (Date.parse('2020-03-01')..Date.parse('2020-03-31')).each do |date|
        @stock.each do |stock|
          if stock.date == date and stock.store_name == store.store_name
            @mng_rec.store(date, total_number + stock.total_number)
            total_number = total_number + stock.total_number
            break
          else
            @mng_rec.store(date, total_number)
          end
        end
      end
      @mng_table.push(@mng_rec)
    end
  end
end
