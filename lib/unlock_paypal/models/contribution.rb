module UnlockPaypal
  module Models
    module Contribution

      include UnlockGateway::Models::Contribution

      def gateway_identifier
        self.gateway_data && self.gateway_data["profile_id"]
      end

      def state_on_gateway
        profile = PayPal::Recurring.new({profile_id: self.gateway_identifier}.merge(self.paypal_auth)).profile
        if profile.valid? && profile.active?
          :active
        else
          :suspended
        end
      end

      def update_state_on_gateway!(state)
        profile = PayPal::Recurring.new({profile_id: self.gateway_identifier}.merge(self.paypal_auth))
        case state
          when :active
            response = profile.reactivate
          when :suspended
            response = profile.suspend
        end
        response.valid?
      end

      def paypal_auth
        return {} unless self.gateway && self.gateway.settings
        {
          username: self.gateway.settings["username"],
          password: self.gateway.settings["password"],
          signature: self.gateway.settings["signature"],
          sandbox: self.gateway.sandbox?
        }
      end

    end
  end
end
