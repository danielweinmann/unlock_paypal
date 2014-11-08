class UnlockPaypal::ContributionsController < ::ApplicationController

  is_unlock_gateway

  def create

    if create_contribution

      # TODO create a way of passing this information on each request. As it is now it will cause severe problems on production because of Rails's cache_classes.
      require "paypal/recurring"
      PayPal::Recurring.configure do |config|
        config.sandbox = @contribution.gateway.sandbox?
        config.username = @contribution.gateway.settings["username"]
        config.password = @contribution.gateway.settings["password"]
        config.signature = @contribution.gateway.settings["signature"]
      end

      paypal = PayPal::Recurring.new({
        :return_url   => edit_paypal_contribution_url(@contribution),
        :cancel_url   => error_paypal_contribution_url(@contribution),
        :ipn_url      => ipn_paypal_contributions_url,
        :description  => @initiative.name,
        :amount       => ('%.2f' % @contribution.value),
        :currency     => "BRL"
      })

      response = paypal.checkout

      raise response.errors.inspect

      if response.valid?
        redirect_to response.checkout_url
      else
        if @contribution.gateway.sandbox?
          @contribution.errors.add(:base, "Parece que este Unlock não está autorizado a utilizar o ambiente de Sandbox do PayPal.#{ ' Você já solicitou acesso à API? Verifique também se configurou o nome de usuário, a senha e a assinatura de API no PayPal.' if @initiative.user == current_user }")
        else
          @contribution.errors.add(:base, "Parece que este Unlock não está autorizado a utilizar o ambiente de produção do PayPal.#{ ' Você já solicitou acesso à API? Verifique também se configurou o nome de usuário, a senha e a assinatura de API no PayPal.' if @initiative.user == current_user }")
        end
        return render '/initiatives/contributions/new'
      end

    end

  end

end
