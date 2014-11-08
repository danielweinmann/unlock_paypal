module UnlockPaypal
  module Models
    module Contribution

      include UnlockGateway::Models::Contribution

      def state_on_gateway
        # TODO
      end

      def update_state_on_gateway!(state)
        # TODO
      end

    end
  end
end
