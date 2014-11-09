class UnlockPaypal::ContributionsController < ::ApplicationController

  is_unlock_gateway

  def create

    if create_contribution

      # TODO don't use configure_paypal
      @contribution.configure_paypal

      paypal = PayPal::Recurring.new({
        return_url: edit_paypal_contribution_url(@contribution),
        cancel_url: new_initiative_contribution_url(@initiative.id),
        ipn_url: ipn_paypal_contributions_url,
        description: @initiative.name,
        amount:  ('%.2f' % @contribution.value),
        currency: "BRL"
      })

      checkout = paypal.checkout

      if checkout.valid?
        redirect_to checkout.checkout_url
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

  def edit
    edit! do
      authorize resource
      @initiative = @contribution.initiative
      @gateways = @initiative.gateways.without_state(:draft).order(:ordering)
      # TODO don't use configure_paypal
      @contribution.configure_paypal
      paypal = PayPal::Recurring.new(token: params[:token])
      details = paypal.checkout_details
      @contribution.gateway_data = {} unless @contribution.gateway_data
      @contribution.gateway_data["token"] = params[:token]
      @contribution.gateway_data["PayerID"] = params[:PayerID]
      @contribution.gateway_data["checkout_status"] = details.status
      @contribution.gateway_data["email"] = details.email
      @contribution.gateway_data["payer_status"] = details.payer_status
      @contribution.gateway_data["payer_status"] = details.payer_status
      @contribution.gateway_data["first_name"] = details.first_name
      @contribution.gateway_data["last_name"] = details.last_name
      @contribution.gateway_data["country"] = details.country
      @contribution.gateway_data["currency"] = details.currency
      @contribution.gateway_data["amount"] = details.amount
      @contribution.gateway_data["description"] = details.description
      @contribution.gateway_data["ipn_url"] = details.ipn_url
      @contribution.gateway_data["agreed"] = details.agreed?
      @contribution.save!
      paypal = PayPal::Recurring.new({
        token: params[:token],
        payer_id: params[:PayerID],
        description: details.description,
        amount:  details.amount,
        currency: details.currency
      })
      payment = paypal.request_payment
      if payment.approved? && payment.completed?
        recurring = PayPal::Recurring.new({
          ipn_url: details.ipn_url,
          description: details.description,
          amount: details.amount,
          currency: details.currency,
          frequency: 1,
          token: params[:token],
          period: :monthly,
          payer_id: params[:PayerID],
          start_at: Time.now,
          failed: 3,
          outstanding: :next_billing
        })
        profile = recurring.create_recurring_profile
        if profile.valid? && profile.profile_id.present? && profile.status == "ActiveProfile"
          profile_data = {}
          profile_data["profile_id"] = profile.profile_id
          profile_data["profile_status"] = profile.status
          @contribution.update gateway_data: @contribution.gateway_data.merge(profile_data)
          @contribution.activate!
          return redirect_to initiative_contribution_path(@initiative.id, @contribution)
        else
          if payment.errors.size > 0
            payment.errors.each do |error|
              error[:messages].each do |message|
                @contribution.errors.add(:base, "#{error[:code]} #{message} (PayPal)")
              end
            end
          else
            @contribution.errors.add(:base, "Ooops. Ocorreu um erro ao ativar seu perfil recorrente no PayPal.")
          end
          return render '/initiatives/contributions/new'
        end
      else
        if payment.errors.size > 0
          payment.errors.each do |error|
            error[:messages].each do |message|
              @contribution.errors.add(:base, "#{error[:code]} #{message} (PayPal)")
            end
          end
        else
          @contribution.errors.add(:base, "Ooops. Ocorreu um erro ao processar seu pagamento no PayPal.")
        end
        return render '/initiatives/contributions/new'
      end
    end
  end

end