Rails.application.configure do
  config.stripe.secret_key = ENV["sk_test_51QNXfEFqU08UvRiOT3Q3HOZ1Fp0IPF7cAekeTxPGYiaHTUuKmDeju2wBK1f8TIEnkbLlLfXBYmqr5wyXbuKWo9yT00sMyROe6W"]
  config.stripe.publishable_key = ENV["pk_test_51QNXfEFqU08UvRiOubbXqKtT1ZKLschnhfVnoK6aeg9UyZUbGGx8LyhTg3OUo1PoU9RqzqqP5uwGeu6RHZzr9IGS002CuaYUyM"]
end