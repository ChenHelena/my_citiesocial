class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :header_nonce

  def index 
    @orders = current_user.orders.includes(order_items: [:sku,:product]).order(id: :desc).page(params[:page]).per(20)

    logger.debug @orders.inspect
  end

  def create

    @order = current_user.orders.build(order_params)

    @order.num ||= @order.generate_order_num

    current_cart.items.each do |item|
      @order.order_items.build(sku_id: item.sku_id, quantity: item.quantity)
    end

    request_body = generate_body(:request)
    request_uri = request_uri(:request)

    if @order.save

      res = Faraday.post("#{ENV['line_pay_endpoint']}#{request_uri}") do |req|
        set_request_header(req, request_body, request_uri)
        req.body = request_body.to_json
      end

      result = JSON.parse(res.body)

      if result["returnCode"] == '0000'
        payment_url = result["info"]["paymentUrl"]["web"]
        redirect_to payment_url
        session[:order_num] = @order.num
        puts "訂單成功保存。訂單編號：#{@order.num}"
      else
        flash[:notice] = '付款發生錯誤'
        render 'carts/checkout'
        puts "保存訂單時出錯：#{result}"
      end
      
    else
      render 'carts/checkout'
      puts "保存訂單時出錯：#{@order.errors}"
    end
  end

  def confirm
    confirm_body = generate_body(:confirm)
    request_uri = request_uri(:confirm)

    res = Faraday.post("#{ENV['line_pay_endpoint']}#{request_uri}") do |req|
       set_request_header(req, confirm_body, request_uri)
       req.body = confirm_body.to_json
       puts "Request headers: #{req.headers}"
    end
    result = JSON.parse(res.body)

    puts "Confirm Response: #{res.body}"

    if result["returnCode"] == '0000'
      order_id = result["info"]['orderId']
      transaction_id = result["info"]['transactionId']
      # 變更 order 狀態
      order_num = session[:order_num]
      order = current_user.orders.find_by(num: order_num)
      order.update(num: order_id)
      

      order.pay!(transaction_id: transaction_id)
      # 清空購物車
      session[:cart_session] = nil

      redirect_to root_path, notice: '付款已完成'
      puts "訂單確認成功。訂單：#{result}"
    else
      redirect_to root_path, notice: '付款發生錯誤'
    end
  end

  def cancel
    @order = current_user.orders.find(params[:id])
    refund_body = generate_body(:refund)
    request_uri = request_uri(:refund)

    if @order.paid?
      res = Faraday.post("#{ENV['line_pay_endpoint']}#{request_uri}") do |req|
        set_request_header(req, refund_body, request_uri)
        req.body = refund_body.to_json
      end
      result = JSON.parse(res.body)


      if result["returnCode"] == '0000'
        @order.cancel!
        redirect_to orders_path, notice: "訂單 #{@order.num} 已取消，並完成退款"
      else
        redirect_to orders_path, notice: "退款發生錯誤"
        puts "退款發生錯誤: #{result}"
      end

    else
      @order.cancel!
      redirect_to orders_path, notice: "訂單 #{@order.num} 已取消"
    end
  end

  def pay
    @order = current_user.orders.find(params[:id])
    pay_body = generate_body(:pay)
    request_uri = request_uri(:request)

    res = Faraday.post("#{ENV['line_pay_endpoint']}#{request_uri}") do |req|
      set_request_header(req, pay_body, request_uri)
      req.body = pay_body.to_json
    end

    result = JSON.parse(res.body)

    if result["returnCode"] == '0000'
      payment_url = result["info"]["paymentUrl"]["web"]
      redirect_to payment_url
    else
      redirect_to orders_path, notice: '付款發生錯誤'
      puts "付款發生錯誤: #{result}"
    end
  end


  def pay_confirm 
    @order = current_user.orders.find(params[:id])

    pay_confirm_body = generate_body(:pay_confirm)
    request_uri = request_uri(:confirm)

    res = Faraday.post("#{ENV['line_pay_endpoint']}#{request_uri}") do |req|
       set_request_header(req, pay_confirm_body, request_uri)
       req.body = pay_confirm_body.to_json
    end
    result = JSON.parse(res.body)

    if result["returnCode"] == '0000'
      transaction_id = result["info"]['transactionId']

      @order.pay!(transaction_id: transaction_id)

      redirect_to orders_path, notice: '付款已完成'
    else
      redirect_to orders_path, notice: '付款發生錯誤'
      puts "付款發生錯誤: #{result}"
    end
  end

  private

  def order_params
    params.require(:order).permit(:recipient, :tel, :address, :note)
  end

  def header_nonce
    @nonce = SecureRandom.uuid
  end
  
  def packages_id
    "package#{SecureRandom.uuid}"
  end

  def request_uri(type)
    if type == :request
      "/v3/payments/request"
    elsif type == :confirm
      "/v3/payments/#{params[:transactionId]}/confirm"
    elsif type == :refund
      "/v3/payments/#{@order.transaction_id}/refund"
    end
  end

  def generate_body(type)
     packages = current_cart.items.map do |item|
      {
        "name" => item.product.name,
        "quantity" => item.quantity,
        "price" => item.product.sell_price.to_i
      }
    end

    total_amount = packages.sum { |package| package["quantity"] * package["price"] }.to_i

    if type == :request
      body = {
        "amount" => total_amount,
        "currency" => "JPY",
        "orderId" => @order.num,
        "packages" => [
          {
            "id" => packages_id,
            "amount" => total_amount,
            "products" => packages
          }
        ],
        "redirectUrls" => {
            "confirmUrl" => "http://localhost:3000/orders/confirm",
            "cancelUrl" => "http://localhost:3000/orders/#{@order.id}/cancel"
        }
      }

    elsif type == :confirm
      body = {
        "amount" => total_amount,
        "currency" => "JPY"
      }
    elsif type == :refund
      body = {
        "refundAmount" => @order.total_price.to_i,
      }
    elsif type == :pay
      packages = @order.order_items.map do |item|
        {
          "name" => item.product.name,
          "quantity" => item.quantity,
          "price" => item.product.sell_price.to_i
        }
      end

      total_amount = packages.sum { |package| package["quantity"] * package["price"] }.to_i

      body = {
        "amount" => @order.total_price.to_i,
        "currency" => "JPY",
        "orderId" => @order.num,
        "packages" => [
          {
            "id" => packages_id,
            "amount" => @order.total_price.to_i,
            "products" => packages
          }
        ],
        "redirectUrls" => {
            "confirmUrl" => "http://localhost:3000/orders/#{@order.id}/pay_confirm",
            "cancelUrl" => "http://localhost:3000/orders/#{@order.id}/cancel"
        }
      }
      elsif type == :pay_confirm
      packages = @order.order_items.map do |item|
        {
          "name" => item.product.name,
          "quantity" => item.quantity,
          "price" => item.product.sell_price.to_i
        }
      end

      total_amount = packages.sum { |package| package["quantity"] * package["price"] }.to_i
      
      body = {
        "amount" => total_amount,
        "currency" => "JPY"
      }
    end

    logger.info "Body parameters: #{body}"
    body
  end

  
  def set_request_header(req, body, request_uri)
    req.headers['Content-Type'] = 'application/json'
    req.headers['X-LINE-ChannelId'] = ENV['line_pay_channel_id']
    req.headers['X-LINE-Authorization-Nonce'] = @nonce
    req.headers['X-LINE-Authorization'] = signature(body, request_uri)
  end
  

  
  def signature(body, request_uri)
    secrect = ENV['line_pay_channel_secret']
    message = "#{secrect}#{request_uri}#{body.to_json}#{@nonce}"
    hash = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), secrect, message)
    encoded_hash = Base64.strict_encode64(hash)
    encoded_hash
  end

  
end
