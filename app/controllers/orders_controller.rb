class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :prepare_new_order, only: [:paypal_create_payment, :paypal_create_subscription]

  def index
    products = Product.all
    @products_purchase = products.where(stripe_plan_name:nil, paypal_plan_name:nil)
    @products_subscription = products - @products_purchase
  end

  def submit
    @order = nil
    #Check which type of order it is

    if order_params[:payment_gateway] == "stripe"
      prepare_new_order

      Orders::Stripe.execute(order: @order, user: current_user)
    elsif order_params[:payment_gateway] == "paypal"
      @order = Orders::Paypal.finish(order_params[:charge_id])
    elsif order_params[:payment_gateway] == "phonepe"
      prepare_new_order
      @order&.save
      result = Orders::Phonepe.initiate_payment(order: @order, callback_url: success_order_path(id: @order.id))
    end
  ensure
    save_order_and_redirect
  end

  def paypal_create_payment
    result = Orders::Paypal.create_payment(order: @order, product: @product)
    if result
      render json: { token: result }, status: :ok
    else
      flash[:popup_message] = "Something went wrong while creating Payment"
      render json: {error: FAILURE_MESSAGE}, status: :unprocessable_entity
    end
  end

  def paypal_execute_payment
    if Orders::Paypal.execute_payment(payment_id: params[:paymentID], payer_id: params[:payerID])
      render json: {}, status: :ok
    else
      flash[:popup_message] = "Something went wrong while Executing Payment"
      render json: {error: FAILURE_MESSAGE}, status: :unprocessable_entity
    end
  end

  def paypal_create_subscription
    result = Orders::Paypal.create_subscription(order: @order, product: @product)

    if result
      render json: { token: result }, status: :ok
    else
      flash[:popup_message] = "Something went wrong while creating Subscription"
      render json: {error: FAILURE_MESSAGE}, status: :unprocessable_entity
    end
  end

  def paypal_execute_subscription
    result = Orders::Paypal.execute_subscription(token: params[:subscriptionToken])
    if result
      render json: { id: result}, status: :ok
    else
      flash[:popup_message] = "Something went wrong while Executing Subscription"
      render json: {error: FAILURE_MESSAGE}, status: :unprocessable_entity
    end
  end

  def success
    fetch_order_details
  end

  def error
    fetch_order_details
  end

  def phone_pe_redirect
    order = Order.find(params[:order_id])
    response = Orders::Phonepe.transaction_status(order: order)
    # Handle the response
    if response.is_a?(Net::HTTPSuccess)
      res = JSON.parse(response.body)
      if res['success'] == true && res['code'] == "PAYMENT_SUCCESS"
        if order.paid!
          flash[:popup_message] = "Your order was successfully placed!"
          redirect_to success_order_path(id: order.id)
        end
      end
    else
      flash[:popup_message] = order.error_message
      redirect_to error_order_path(id: order.id)
    end
  end

  private
  # Initialize a new order and and set its user, product and price.
  def fetch_order_details
    @order = Order.find(params[:id])
    @status = @order.status
  end

  def prepare_new_order
    @order = Order.new(order_params)
    @order.user_id = current_user.id
    @product = Product.find(@order.product_id)
    @order.price_cents = @product.price_cents
  end

  def save_order_and_redirect
    if @order&.save
      
      if @order.paid?
        flash[:popup_message] = "Your order was successfully placed!"
        redirect_to success_order_path(id: @order.id)
      elsif @order.failed? && !@order.error_message.blank?
        flash[:popup_message] = @order.error_message
        redirect_to error_order_path(id: @order.id)
      end
    else
      flash[:popup_message] = "Something went wrong. Please try again."
      redirect_to root_path
    end
  end

  def order_params
    params.require(:orders).permit(:product_id, :token, :payment_gateway, :charge_id)
  end
end