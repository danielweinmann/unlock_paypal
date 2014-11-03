module UnlockMoip
  module ActiveRecord
    module Contribution

      def moip_auth
        return {} unless self.gateway && self.gateway.settings
        { moip_auth: { token: self.gateway.settings["token"], key: self.gateway.settings["key"], sandbox: self.gateway.sandbox? }}
      end

      def plan_code
        "#{self.initiative.permalink[0..29]}#{self.value.to_i}#{'sandbox' if self.gateway.sandbox?}"
      end
    
      # TODO make this a hash
      def customer_code
        "#{self.initiative.permalink[0..29]}#{self.user.id}#{'sandbox' if self.gateway.sandbox?}"
      end
      
      # TODO make this a hash
      def subscription_code
        "#{self.initiative.permalink[0..29]}#{self.id}#{'sandbox' if self.gateway.sandbox?}"
      end
      
      def moip_state
        begin
          response = Moip::Assinaturas::Subscription.details(self.subscription_code, moip_auth: self.moip_auth)
        rescue
          return nil
        end
        if response && response[:success]
          status = (response[:subscription]["status"].upcase rescue nil)
          case status
            when 'ACTIVE', 'OVERDUE'
              1
            when 'SUSPENDED', 'EXPIRED', 'CANCELED'
              2
          end
        end
      end

      def moip_state_name
        case self.moip_state
          when 1
            :active
          when 2
            :suspended
        end
      end

      def update_state_from_moip!
        if self.state != self.moip_state
          case self.moip_state_name
            when :active
              self.activate! if self.can_activate?
            when :suspended
              self.suspend! if self.can_suspend?
          end
        end
      end

    end
  end
end
