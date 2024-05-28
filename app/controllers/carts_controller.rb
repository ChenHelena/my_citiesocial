class CartsController < ApplicationController
  before_action :authenticate_user!
  
  def show
  end

  def checkout
    @order = current_user.orders.build
  end

  def destroy
    session[:cart_session] = nil
    redirect_to root_path, notice: '購物車已清空'
  end

  def remove_item
    cart = session[:cart_session] || {}
    item_id = params[:id].to_s

    if cart['items'].reject! { |item| item['sku_id'] == item_id }
      session[:cart_session] = cart
      redirect_to cart_path, notice: 'Item removed successfully'
    else
      redirect_to cart_path, notice: 'Item not found in cart'
    end
  end
end
