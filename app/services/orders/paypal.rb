class Orders::Paypal
  def self.finish(charge_id)
    order = Order.paypal_executed.recently_created.find_by(charge_id: charge_id)
    return nil if order.nil?
    order.set_paid
    order
  end

  def self.create_payment(order:, product:)
    payment_price = (product.price_cents/100.0).to_s
    currency = "USD"
    payment = PayPal::SDK::REST::Payment.new({
      intent:  "sale",
      payer:  {
        payment_method: "paypal" },
      redirect_urls: {
        return_url: "/",
        cancel_url: "/" },
      transactions:  [{
        item_list: {
          items: [{
            name: product.name,
            sku: product.name,
            price: payment_price,
            currency: currency,
            quantity: 1 }
            ]
          },
        amount:  {
          total: payment_price,
          currency: currency
        },
        description:  "Payment for: #{product.name}"
      }]
    })

    if payment.create
      order.token = payment.token
      order.charge_id = payment.id
      return payment.token if order.save
    end
  end

  def self.execute_payment(payment_id:, payer_id:)
    order = Order.recently_created.find_by(charge_id: payment_id)
    return false unless order
    payment = PayPal::SDK::REST::Payment.find(payment_id)
    if payment.execute( payer_id: payer_id )
      order.set_paypal_executed
      return order.save
    end
  end
end