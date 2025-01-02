require 'httparty'
require 'digest'

class Orders::Phonepe
  BASE_URL = 'https://api-preprod.phonepe.com/apis/hermes' # Updated with /apis
  MERCHANT_ID = ENV['PHONEPE_MERCHANT_ID']
  MERCHANT_KEY = ENV['PHONEPE_MERCHANT_KEY']
  SALT = ENV['PHONEPE_SALT']

  def self.initiate_payment(order:, callback_url:)
    payload = build_payload(order, callback_url)
    payload_encoded = Base64.strict_encode64(payload.to_json)
    x_verify_header = generate_x_verify(payload_encoded, '/pg/v1/pay')

    response = make_request(
      endpoint: '/pg/v1/pay',
      method: :post,
      headers: request_headers(x_verify_header),
      body: { request: payload_encoded }.to_json
    )

    handle_payment_response(response)
  end

  def self.transaction_status(order:)
    merchant_id = ENV['PHONEPE_MERCHANT_ID']
    salt_key = ENV['PHONEPE_MERCHANT_KEY']
    salt_key_index = ENV['PHONEPE_SALT']
    base_url =  BASE_URL
    transaction_id = order.id.to_s

    checksum_data = checksum(merchant_id, salt_key, salt_key_index, transaction_id)

    headers = { 'X-Verify': checksum_data, 'X-MERCHANT-ID': merchant_id, 'content_type': 'application/json' }

    url = "#{base_url}/pg/v1/status/#{merchant_id}/#{transaction_id}"

    uri = URI("#{url}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(url, headers)

    response = http.request(request)
  end


  private

  def self.build_payload(order, callback_url)
    {
      merchantId: MERCHANT_ID,
      merchantTransactionId: order.id.to_s,
      merchantUserId: order.user.id.to_s,
      amount: order.price_cents,
      redirectUrl: "http://localhost:3000/orders/phone_pe_redirect?order_id=#{order.id}",
      redirectMode: 'REDIRECT',
      callbackUrl: callback_url,
      mobileNumber: '9999999999',
      paymentInstrument: { type: 'PAY_PAGE' }
    }
  end

  def self.generate_x_verify(payload, endpoint)
    to_sign = "#{payload}#{endpoint}#{MERCHANT_KEY}"
    sha256_hash = Digest::SHA256.hexdigest(to_sign)
    "#{sha256_hash}####{SALT}"
  end



  def self.request_headers(x_verify)
    {
      'Content-Type' => 'application/json',
      'X-VERIFY' => x_verify,
      'Accept' => 'application/json',
      'X-MERCHANT-ID' => MERCHANT_ID
    }
  end

  def self.make_request(endpoint:, method:, headers:, body: nil)
    uri = URI("#{BASE_URL}#{endpoint}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = case method
              when :post
                Net::HTTP::Post.new(uri, headers).tap { |req| req.body = body }
              when :get
                Net::HTTP::Get.new(uri, headers)
              end

    http.request(request)
  end



  def self.handle_payment_response(response)
    if response.is_a?(Net::HTTPSuccess)
      res = JSON.parse(response.body)
      if res['success']
        pay_url = res.dig('data', 'instrumentResponse', 'redirectInfo', 'url')
        puts "Redirecting to payment URL: #{pay_url}"
        `xdg-open "#{pay_url}"` # For local testing, opens URL in the browser
      else
        puts "Payment initiation failed: #{res['message']}"
      end
    else
      log_http_error(response)
    end
  end

  def self.handle_status_response(response)
    if response.is_a?(Net::HTTPSuccess)
      res = JSON.parse(response.body)
      puts "Transaction status: #{res['message']}"
    else
      log_http_error(response)
    end
  end

  def self.log_http_error(response)
    puts "HTTP Request failed with code #{response.code}: #{response.message}"
  end

  def self.checksum(merchant_id, salt_key, salt_key_index, transaction_id)
    signature_data = "/pg/v1/status/#{merchant_id}/#{transaction_id}#{salt_key}"
    sha256_hash = Digest::SHA256.hexdigest(signature_data)

    "#{sha256_hash}####{salt_key_index}"
  end
end
