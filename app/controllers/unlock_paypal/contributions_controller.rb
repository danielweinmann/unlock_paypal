class UnlockPayPal::ContributionsController < ::ApplicationController

  inherit_resources
  actions :create, :edit
  custom_actions member: %i[activate suspend]
  respond_to :html, except: [:activate, :suspend]
  respond_to :json, only: [:activate, :suspend]

  after_action :verify_authorized
  after_action :verify_policy_scoped, only: %i[]
  before_action :authenticate_user!, only: %i[edit]

  def create

    # Getting the date from Pickadate
    if params[:pickadate_birthdate_submit]
      params[:contribution][:user_attributes][:birthdate] = params[:pickadate_birthdate_submit]
    end
    
    # Creating the contribution
    @initiative = Initiative.find(contribution_params[:initiative_id])
    @gateways = @initiative.gateways.without_state(:draft).order(:ordering)
    @contribution = @initiative.contributions.new(contribution_params)
    @contribution.gateway_state = @contribution.gateway.state
    authorize @contribution

    if @contribution.save

      data = {}
      # Storing the customer_code and subscription_code
      data["customer_code"] = @contribution.customer_code
      data["subscription_code"] = @contribution.subscription_code
      # Storing user information
      data["email"] = @contribution.user.email
      data["full_name"] = @contribution.user.full_name
      data["document"] = @contribution.user.document
      data["phone_area_code"] = @contribution.user.phone_area_code
      data["phone_number"] = @contribution.user.phone_number
      data["birthdate"] = @contribution.user.birthdate
      data["address_street"] = @contribution.user.address_street
      data["address_number"] = @contribution.user.address_number
      data["address_complement"] = @contribution.user.address_complement
      data["address_district"] = @contribution.user.address_district
      data["address_city"] = @contribution.user.address_city
      data["address_state"] = @contribution.user.address_state
      data["address_zipcode"] = @contribution.user.address_zipcode
      # Saving gateway_data
      @contribution.update gateway_data: data

      # Creating the plan, if needed
      begin
        response = Paypal::Assinaturas::Plan.details(@contribution.plan_code, @contribution.paypal_auth)
      rescue Paypal::Assinaturas::WebServerResponseError => e
        if @contribution.gateway.sandbox?
          @contribution.errors.add(:base, "Parece que este Unlock não está autorizado a utilizar o ambiente de Sandbox do Paypal Assinaturas.#{ ' Você já solicitou acesso ao Paypal Assinaturas? Verifique também se configurou o Token e a Chave de API.' if @initiative.user == current_user }")
        else
          @contribution.errors.add(:base, "Parece que este Unlock não está autorizado a utilizar o ambiente de produção do Paypal Assinaturas.#{ ' Você já homologou sua conta para produção no Paypal Assinaturas? Verifique também se configurou o Token e a Chave de API.' if @initiative.user == current_user }")
        end
        return render '/initiatives/contributions/new'
      rescue => e
        @contribution.errors.add(:base, "Ocorreu um erro de conexão ao verificar o plano de assinaturas no Paypal. Por favor, tente novamente.")
        return render '/initiatives/contributions/new'
      end
      unless response[:success]
        plan = {
          code: @contribution.plan_code,
          name: @contribution.plan_name,
          amount: (@contribution.value * 100).to_i
        }
        begin
          response = Paypal::Assinaturas::Plan.create(plan, @contribution.paypal_auth)
        rescue
          @contribution.errors.add(:base, "Ocorreu um erro de conexão ao criar o plano de assinaturas no Paypal. Por favor, tente novamente.")
          return render '/initiatives/contributions/new'
        end
        unless response[:success]
          if response[:errors] && response[:errors].kind_of?(Array)
            response[:errors].each do |error|
              @contribution.errors.add(:base, "#{response[:message]} (Paypal). #{error[:description]}")
            end
          else
            @contribution.errors.add(:base, "Ocorreu um erro ao criar o plano de assinaturas no Paypal. Por favor, tente novamente.")
          end
          return render '/initiatives/contributions/new'
        end
      end

      # Creating the client, if needed
      customer = {
        code: @contribution.customer_code,
        email: @contribution.user.email,
        fullname: @contribution.user.full_name,
        cpf: @contribution.user.document,
        phone_area_code: @contribution.user.phone_area_code,
        phone_number: @contribution.user.phone_number,
        birthdate_day: @contribution.user.birthdate.strftime('%d'),
        birthdate_month: @contribution.user.birthdate.strftime('%m'),
        birthdate_year: @contribution.user.birthdate.strftime('%Y'),
        address: {
          street: @contribution.user.address_street,
          number: @contribution.user.address_number,
          complement: @contribution.user.address_complement,
          district: @contribution.user.address_district,
          city: @contribution.user.address_city,
          state: @contribution.user.address_state,
          country: "BRA",
          zipcode: @contribution.user.address_zipcode
        }
      }
      begin
        response = Paypal::Assinaturas::Customer.details(@contribution.customer_code, @contribution.paypal_auth)
      rescue
        @contribution.errors.add(:base, "Ocorreu um erro de conexão ao verificar o cadastro de cliente no Paypal. Por favor, tente novamente.")
        return render '/initiatives/contributions/new'
      end
      if response[:success]
        begin
          response = Paypal::Assinaturas::Customer.update(@contribution.customer_code, customer, @contribution.paypal_auth)
          unless response[:success]
            if response[:errors] && response[:errors].kind_of?(Array)
              response[:errors].each do |error|
                @contribution.errors.add(:base, "#{response[:message]} (Paypal). #{error[:description]}")
              end
            else
              @contribution.errors.add(:base, "Ocorreu um erro ao atualizar o cadastro de cliente no Paypal. Por favor, tente novamente.")
            end
            return render '/initiatives/contributions/new'
          end
        rescue
          @contribution.errors.add(:base, "Ocorreu um erro de conexão ao atualizar o cadastro de cliente no Paypal. Por favor, tente novamente.")
          return render '/initiatives/contributions/new'
        end
      else
        begin
          response = Paypal::Assinaturas::Customer.create(customer, new_vault = false, @contribution.paypal_auth)
        rescue
          @contribution.errors.add(:base, "Ocorreu um erro de conexão ao realizar o cadastro de cliente no Paypal. Por favor, tente novamente.")
          return render '/initiatives/contributions/new'
        end
        unless response[:success]
          if response[:errors] && response[:errors].kind_of?(Array)
            response[:errors].each do |error|
              @contribution.errors.add(:base, "#{response[:message]} (Paypal). #{error[:description]}")
            end
          else
            @contribution.errors.add(:base, "Ocorreu um erro ao realizar o cadastro de cliente no Paypal. Por favor, tente novamente.")
          end
          return render '/initiatives/contributions/new'
        end
      end

      flash[:success] = "Apoio iniciado com sucesso! Agora é só realizar o pagamento :D"
      return redirect_to edit_paypal_contribution_path(@contribution)

    else
      return render '/initiatives/contributions/new'
    end
    
  end

  def edit
    edit! { authorize resource }
  end

  def activate
    transition_state("activate", :active)
  end
  
  def suspend
    transition_state("suspend", :suspended)
  end

  private

  def transition_state(transition, state)
    authorize resource
    errors = []
    if resource.send("can_#{transition}?")
      begin
        if resource.paypal_state_name != state
          response = Paypal::Assinaturas::Subscription.send(transition.to_sym, resource.subscription_code, resource.paypal_auth)
          resource.send("#{transition}!") if response[:success]
        else
          resource.send("#{transition}!")
        end
      rescue
        errors << "Não foi possível alterar o status de seu apoio."
      end
    else
      errors << "Não é permitido alterar o status deste apoio."
    end
    render(json: {success: (errors.size == 0), errors: errors}, status: ((errors.size == 0) ? 200 : 422))
  end
  
  def contribution_params
    params.require(:contribution).permit(*policy(@contribution || Contribution.new).permitted_attributes)
  end

end
