module UnlockPaypal
  module Models
    module Gateway

      include UnlockGateway::Models::Gateway

      def name
        "PayPal"
      end

      def description
        "Gerencie mensalidades, assinaturas e cobranças recorrentes com o PayPal"
      end

      def image
        "unlock_paypal/logo.png"
      end

      def path
        "/paypal"
      end

      def available_settings
        settings = []
        instructions = "Com sua conta de negócios Paypal habilitada, vá em <a href='https://www.paypal.com.br/AdmMainMenuMyData.do?method=assinaturas' target='_blank'>Ferramentas › Paypal Assinaturas</a> e clique em Habilitar acesso. Depois, vá em <a href='https://www.paypal.com.br/AdmAPI.do?method=keys' target='_blank'>Ferramentas › API Paypal › Chaves de acesso</a>."
        settings << UnlockGateway::Setting.new(:token, "Token de acesso no Paypal", instructions)
        settings << UnlockGateway::Setting.new(:key, "Chave de acesso no Paypal", instructions)
      end

    end
  end
end
