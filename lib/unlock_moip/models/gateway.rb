module UnlockMoip
  module Models
    module Gateway

      def name
        "Moip Assinaturas"
      end

      def description
        "Gerencie mensalidades, assinaturas e cobranças recorrentes com o Moip"
      end

      def image
        "unlock_moip/logo.png"
      end

      def has_sandbox?
        true
      end

      def available_settings
        settings = []
        instructions = "Com sua conta de negócios Moip habilitada, vá em <a href='https://www.moip.com.br/AdmMainMenuMyData.do?method=assinaturas' target='_blank'>Ferramentas › Moip Assinaturas</a> e clique em Habilitar acesso. Depois, vá em <a href='https://www.moip.com.br/AdmAPI.do?method=keys' target='_blank'>Ferramentas › API Moip › Chaves de acesso</a>."
        settings << UnlockMoip::Setting.new(:token, "Token de acesso no Moip", instructions)
        settings << UnlockMoip::Setting.new(:key, "Chave de acesso no Moip", instructions)
      end

    end
  end
end
