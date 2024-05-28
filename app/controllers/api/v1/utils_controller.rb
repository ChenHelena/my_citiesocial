class Api::V1::UtilsController < ApplicationController
  def subscribe
    email = params['subscribe']['email']
    sub = Subscribe.new(email: email)

    if sub.save
      render json: { status: 'ok', email: email }
    else
      render json: { status: 'duplicate', email: email }
    end

  end

  def cart
    # product = Product.friendly.find(params[:id])
    product = Product.joins(:skus).find_by(skus: { id: params[:sku] })
    if product
      quantity = params[:quantity].to_i
      current_cart.add_sku(params[:sku], quantity)

      session[:cart_session] = current_cart.serialize
      render json: { status: 'ok', items: current_cart.items.count }
    end
    
  end

  def update_cart
    cart = session[:cart_session] || {}
    sku_id = params[:sku].to_s
    quantity = params[:quantity].to_i

    Rails.logger.debug "Params: id=#{sku_id}, quantity=#{quantity}"
    Rails.logger.debug "Cart: #{cart.inspect}"

    item = cart['items'].find { |item| item['sku_id'] == sku_id }
    if item
      cart['items'].each do |item|
        if item['sku_id'] == sku_id
          item['quantity'] = quantity
          break
        end
      end

      session[:cart_session] = cart

      updated_total_price = current_cart.total_price
      updated_item_total_price = current_cart.items.find { |item| item.sku_id == sku_id }.total_price
      Rails.logger.debug "Updated total price: #{updated_total_price}, Updated item total price: #{updated_item_total_price}"

      render json: { status: 'ok', updated_total_price: updated_item_total_price, updated_cart_total: updated_total_price }
    else
      render json: { status: 'error', message: 'Item not found in cart' }, status: :not_found
    end
  end

end
