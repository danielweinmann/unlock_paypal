module UnlockPaypal
  module Models
    module Gateway

      include UnlockGateway::Models::Gateway

      def name
        "PayPal"
      end

      def description
        I18n.t('unlock_paypal.models.gateway.description')
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
        instructions = I18n.t('unlock_paypal.models.gateway.available_settings.instructions')
        settings << UnlockGateway::Setting.new(:username, I18n.t('unlock_paypal.models.gateway.available_settings.username'), instructions)
        settings << UnlockGateway::Setting.new(:password, I18n.t('unlock_paypal.models.gateway.available_settings.password'), instructions)
        settings << UnlockGateway::Setting.new(:signature, I18n.t('unlock_paypal.models.gateway.available_settings.signature'), instructions)
      end

    end
  end
end
