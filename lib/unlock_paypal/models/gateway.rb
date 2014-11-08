module UnlockPaypal
  module Models
    module Gateway

      include UnlockGateway::Models::Gateway

      def name
        "PayPal"
      end

      def description
        "Economize tempo e dinheiro com as Assinaturas e Cobranças recorrentes do PayPal"
      end

      def image
        "unlock_paypal/logo.png"
      end

      def url
        "https://www.paypal.com"
      end

      def path
        "/paypal"
      end

      def available_settings
        settings = []
        instructions = "Com sua conta de Especial ou Comercial habilitada no Paypal, vá em <a href='https://www.paypal.com/cgi-bin/customerprofileweb?cmd=_profile-api-access&upgrade.x=1' target='_blank'>Minha conta › Perfil › Mais opções › Minhas ferramentas de venda › Acesso à API › Atualizar</a> e escolha a <strong>Opção 2</strong>. Depois, clique em <a href='https://www.paypal.com/br/cgi-bin/webscr?cmd=_profile-api-signature' target='_blank'>Exibir assinatura de API</a>."
        settings << UnlockGateway::Setting.new(:username, "Nome do usuário de API", instructions)
        settings << UnlockGateway::Setting.new(:password, "Senha de API", instructions)
        settings << UnlockGateway::Setting.new(:signature, "Assinatura de API", instructions)
      end

    end
  end
end
