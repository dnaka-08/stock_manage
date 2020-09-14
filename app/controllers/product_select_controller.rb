class ProductSelectController < ApplicationController
  before_action :require_user_logged_in
  before_action :set_root, only: [:index]
  before_action :set_user_session, only: [:index]
  
  def index
    @products = Product.order(id: :desc).page(params[:page]).per(15)
  end
end
