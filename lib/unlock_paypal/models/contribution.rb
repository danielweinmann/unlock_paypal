module UnlockPaypal
  module Models
    module Contribution

      include UnlockGateway::Models::Contribution

      def gateway_identifier
        self.gateway_data && self.gateway_data["profile_id"]
      end

      def state_on_gateway
        # TODO don't use configure_paypal
        self.configure_paypal
        profile = PayPal::Recurring.new(profile_id: self.gateway_identifier).profile
        if profile.valid? && profile.active?
          :active
        else
          :suspended
        end
      end

      def update_state_on_gateway!(state)
        # TODO don't use configure_paypal
        configure_paypal
        profile = PayPal::Recurring.new(profile_id: self.gateway_identifier)
        case state
          when :active
            response = profile.reactivate
          when :suspended
            response = profile.suspend
        end
        response.valid?
      end

      def configure_paypal
        return unless self.gateway.present?
        # TODO create a way of passing this information on each request. As it is now it will cause severe problems on production because of Rails's cache_classes.
        PayPal::Recurring.configure do |config|
          config.sandbox = self.gateway.sandbox?
          config.username = self.gateway.settings["username"]
          config.password = self.gateway.settings["password"]
          config.signature = self.gateway.settings["signature"]
        end
      end

    end
  end
end
