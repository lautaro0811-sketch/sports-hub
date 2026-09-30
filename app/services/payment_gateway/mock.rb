module PaymentGateway
  class Mock
    # Simula la creación de una preferencia de pago (equivalente a MercadoPago).
    # Devuelve un hash con id, init_point y amount.
    def create_preference(reservation, amount)
      preference_id = SecureRandom.uuid

      {
        id: preference_id,
        init_point: "https://sandbox.mercadopago.com.ar/checkout/v1/redirect?pref_id=#{preference_id}",
        amount: amount
      }
    end
  end
end
