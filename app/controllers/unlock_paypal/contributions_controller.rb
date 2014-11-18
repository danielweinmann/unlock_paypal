class UnlockPaypal::ContributionsController < ::ApplicationController

  is_unlock_gateway
  after_action :verify_authorized, except: %i[ipn]

  def create

    if create_contribution

      paypal = PayPal::Recurring.new({
        return_url: edit_paypal_contribution_url(@contribution),
        cancel_url: new_initiative_contribution_url(@initiative.id),
        ipn_url: ipn_paypal_contributions_url,
        description: @initiative.name,
        amount:  ('%.2f' % @contribution.value),
        currency: @initiative.currency
      }.merge(@contribution.paypal_auth))

      checkout = paypal.checkout

      if checkout.valid?
        redirect_to checkout.checkout_url
      else
        error = t('flash.actions.create.alert', resource_name: @contribution.class.model_name.human)
        @contribution.errors.add(:base, "#{error} (PayPal - checkout_url)")
        return render '/initiatives/contributions/new'
      end

    end

  end

  def edit
    authorize @contribution
    @initiative = @contribution.initiative
    @gateways = @initiative.gateways.without_state(:draft).ordered
    paypal = PayPal::Recurring.new({token: params[:token]}.merge(@contribution.paypal_auth))
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
    }.merge(@contribution.paypal_auth))
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
      }.merge(@contribution.paypal_auth))
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
          error = t('flash.actions.create.alert', resource_name: @contribution.class.model_name.human)
          @contribution.errors.add(:base, "#{error} (PayPal - create_recurring_profile)")
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
        error = t('flash.actions.create.alert', resource_name: @contribution.class.model_name.human)
        @contribution.errors.add(:base, "#{error} (PayPal - request_payment)")
      end
      return render '/initiatives/contributions/new'
    end
  end

  def ipn
    # TODO implement ipn in the future
    head :ok
  end

end
