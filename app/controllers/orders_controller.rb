class OrdersController < ApplicationController
  before_action :authenticate_user!
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
      #PAYPAL WILL BE HANDLED HERE
    end
  ensure

    if @order&.save
      if @order.paid?
        # Success is rendered when order is paid and saved
        flash[:popup_message] = "Your order was successfully placed!"
        return redirect_to success_order_path(id: @order.id)
      elsif @order.failed? && !@order.error_message.blank?
        # Render error only if order failed and there is an error_message
        flash[:popup_message] = @order.error_message
        return redirect_to error_order_path(id: @order.id)
      end
    end
    flash[:popup_message] = "Something went wrong. Please try again."
    redirect_to root_path
  end

  def success
    fetch_order_details
  end

  def error
    fetch_order_details
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

  def order_params
    params.require(:orders).permit(:product_id, :token, :payment_gateway, :charge_id)
  end
end