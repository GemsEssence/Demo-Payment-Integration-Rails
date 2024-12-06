require 'httparty'
require 'digest'

class Orders::Phonepe
  BASE_URL = 'https://api-preprod.phonepe.com/apis/hermes' # Updated with /apis
  MERCHANT_ID = ENV['PHONEPE_MERCHANT_ID']
  MERCHANT_KEY = ENV['PHONEPE_MERCHANT_KEY']
  SALT = ENV['PHONEPE_SALT']

  def self.initiate_payment(order:, callback_url:)
    # payload = {
    #   merchantId: MERCHANT_ID,
    #   merchantTransactionId: 'MT7850590068188104', # Test transaction ID
    #   transactionId: order.id.to_s,
    #   # transactionId: "TXN#{SecureRandom.uuid}",
    #   merchantUserId: order.user.id.to_s,
    #   amount: order.price_cents,
    #   merchantOrderId: "ORDER#{order.id}",
    #   merchantCallbackUrl: callback_url,
    # }

    payload =   {
        "merchantId": MERCHANT_ID,
        "merchantTransactionId": "MT7850590068188104",
        "merchantUserId": "MUID123",
        "amount": 10000,
        "redirectUrl": "https://webhook.site/redirect-url",
        "redirectMode": "REDIRECT",
        "callbackUrl": "https://webhook.site/callback-url",
        "mobileNumber": "9999999999",
        "paymentInstrument": {
          "type": "PAY_PAGE"
      }
    }

    
    # Generate checksum

    payload_main = Base64.strict_encode64(payload.to_json)

    # Create the X-VERIFY header
    salt_index = 1 # Key index
    payload_to_sign = "#{payload_main}/pg/v1/pay#{MERCHANT_KEY}"
    sha256_hash = Digest::SHA256.hexdigest(payload_to_sign)
    final_x_header = "#{sha256_hash}####{salt_index}"

    uri = URI("https://api-preprod.phonepe.com/apis/hermes/pg/v1/pay")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request_body = { request: payload_main }.to_json
    headers = {
      'Content-Type' => 'application/json',
      'X-VERIFY' => final_x_header,
      'Accept' => 'application/json'
    }
    
    request = Net::HTTP::Post.new(uri, headers)
    request.body = request_body

    response = http.request(request)

    # Handle the response
    if response.is_a?(Net::HTTPSuccess)
      res = JSON.parse(response.body)

      if res['success'] == true
        payment_code = res['code']
        payment_msg = res['message']
        pay_url = res.dig('data', 'instrumentResponse', 'redirectInfo', 'url')
    
        # Redirect the user to the payment URL
        puts "Redirecting to payment URL: #{pay_url}"
        `xdg-open "#{pay_url}"` # Opens the URL in the default browser (for local testing)
      else
        puts "Payment initiation failed: #{res['message']}"
      end
    else
      puts "HTTP Request failed with code #{response.code}: #{response.message}"
    end    # Create the X-VERIFY header

  end

  def self.transection_status()
    payload =   {
        "merchantId": MERCHANT_ID,
        "merchantTransactionId": "MT7850590068188104",
        "merchantUserId": "MUID123",
        "amount": 10000,
        "redirectUrl": "https://webhook.site/redirect-url",
        "redirectMode": "REDIRECT",
        "callbackUrl": "https://webhook.site/callback-url",
        "mobileNumber": "9999999999",
        "paymentInstrument": {
          "type": "PAY_PAGE"
      }
    }


    payload_main = Base64.strict_encode64(payload.to_json)

    salt_index = 1 # Key index
    payload_to_sign = "#{payload_main}/pg/v1/pay#{MERCHANT_KEY}"
    sha256_hash = Digest::SHA256.hexdigest(payload_to_sign)
    final_x_header = "#{sha256_hash}####{salt_index}"

    uri = URI("https://api-preprod.phonepe.com/apis/hermes/pg/v1/status/SANDBOXTESTMID/MT7850590068188104")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request_body = { request: payload_main }.to_json
    headers = {
      'Content-Type' => 'application/json',
      'X-VERIFY' => final_x_header,
      'X-MERCHANT-ID' => "SANDBOXTESTMID",
    }

    request = Net::HTTP::Get.new(uri, headers)
    request.body = request_body

    response = http.request(request)

    # Handle the response
    if response.is_a?(Net::HTTPSuccess)
      res = JSON.parse(response.body)
    
      if res['success'] == '1'
        payment_code = res['code']
        payment_msg = res['message']
        pay_url = res.dig('data', 'instrumentResponse', 'redirectInfo', 'url')
      
        # Redirect the user to the payment URL
        puts "Redirecting to payment URL: #{pay_url}"
        `xdg-open "#{pay_url}"` # Opens the URL in the default browser (for local testing)
      else
        puts "Payment initiation failed: #{res['message']}"
      end
    else
      puts "HTTP Request failed with code #{response.code}: #{response.message}"
    end 
  end
end
