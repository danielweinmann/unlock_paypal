class UnlockMoip::ContributionsController < ::ApplicationController

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

      # Creating the plan, if needed
      begin
        response = Moip::Assinaturas::Plan.details(@contribution.plan_code, @contribution.moip_auth)
      rescue Moip::Assinaturas::WebServerResponseError => e
        if @contribution.gateway.sandbox?
          @contribution.errors.add(:base, "Parece que este Unlock não está autorizado a utilizar o ambiente de Sandbox do Moip Assinaturas.#{ ' Você já solicitou acesso ao Moip Assinaturas? Verifique também se configurou o Token e a Chave de API.' if @initiative.user == current_user }")
        else
          @contribution.errors.add(:base, "Parece que este Unlock não está autorizado a utilizar o ambiente de produção do Moip Assinaturas.#{ ' Você já homologou sua conta para produção no Moip Assinaturas? Verifique também se configurou o Token e a Chave de API.' if @initiative.user == current_user }")
        end
        return render '/initiatives/contributions/new'
      rescue => e
        @contribution.errors.add(:base, "Ocorreu um erro de conexão ao verificar o plano de assinaturas no Moip. Por favor, tente novamente.")
        return render '/initiatives/contributions/new'
      end
      unless response[:success]
        plan = {
          code: @contribution.plan_code,
          name: @contribution.plan_name,
          amount: (@contribution.value * 100).to_i
        }
        begin
          response = Moip::Assinaturas::Plan.create(plan, @contribution.moip_auth)
        rescue
          @contribution.errors.add(:base, "Ocorreu um erro de conexão ao criar o plano de assinaturas no Moip. Por favor, tente novamente.")
          return render '/initiatives/contributions/new'
        end
        unless response[:success]
          if response[:errors] && response[:errors].kind_of?(Array)
            response[:errors].each do |error|
              @contribution.errors.add(:base, "#{response[:message]} (Moip). #{error[:description]}")
            end
          else
            @contribution.errors.add(:base, "Ocorreu um erro ao criar o plano de assinaturas no Moip. Por favor, tente novamente.")
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
        response = Moip::Assinaturas::Customer.details(@contribution.customer_code, @contribution.moip_auth)
      rescue
        @contribution.errors.add(:base, "Ocorreu um erro de conexão ao verificar o cadastro de cliente no Moip. Por favor, tente novamente.")
        return render '/initiatives/contributions/new'
      end
      if response[:success]
        begin
          response = Moip::Assinaturas::Customer.update(@contribution.customer_code, customer, @contribution.moip_auth)
          unless response[:success]
            if response[:errors] && response[:errors].kind_of?(Array)
              response[:errors].each do |error|
                @contribution.errors.add(:base, "#{response[:message]} (Moip). #{error[:description]}")
              end
            else
              @contribution.errors.add(:base, "Ocorreu um erro ao atualizar o cadastro de cliente no Moip. Por favor, tente novamente.")
            end
            return render '/initiatives/contributions/new'
          end
        rescue
          @contribution.errors.add(:base, "Ocorreu um erro de conexão ao atualizar o cadastro de cliente no Moip. Por favor, tente novamente.")
          return render '/initiatives/contributions/new'
        end
      else
        begin
          response = Moip::Assinaturas::Customer.create(customer, new_vault = false, @contribution.moip_auth)
        rescue
          @contribution.errors.add(:base, "Ocorreu um erro de conexão ao realizar o cadastro de cliente no Moip. Por favor, tente novamente.")
          return render '/initiatives/contributions/new'
        end
        unless response[:success]
          if response[:errors] && response[:errors].kind_of?(Array)
            response[:errors].each do |error|
              @contribution.errors.add(:base, "#{response[:message]} (Moip). #{error[:description]}")
            end
          else
            @contribution.errors.add(:base, "Ocorreu um erro ao realizar o cadastro de cliente no Moip. Por favor, tente novamente.")
          end
          return render '/initiatives/contributions/new'
        end
      end

      flash[:success] = "Apoio iniciado com sucesso! Agora é só realizar o pagamento :D"
      return redirect_to edit_moip_contribution_path(@contribution)

    else
      return render '/initiatives/contributions/new'
    end
    
  end

  def edit
    edit! { authorize resource }
  end

  def activate
    authorize resource
    errors = []
    if @contribution.can_activate?
      begin
        if @contribution.moip_state_name != :active
          response = Moip::Assinaturas::Subscription.activate(@contribution.subscription_code, @contribution.moip_auth)
          @contribution.activate! if response[:success]
        else
          @contribution.activate!
        end
      rescue
        errors << "Não foi possível ativar sua assinatura no Moip Assinaturas"
      end
    else
      errors << "Não é permitido ativar este apoio."
    end
    render(json: {success: (errors.size == 0), errors: errors}, status: ((errors.size == 0) ? 200 : 422))
  end
  
  def suspend
    authorize resource
    errors = []
    if @contribution.can_suspend?
      begin
        if @contribution.moip_state_name != :suspended
          response = Moip::Assinaturas::Subscription.suspend(@contribution.subscription_code, @contribution.moip_auth)
          @contribution.suspend! if response[:success]
        else
          @contribution.suspend!
        end
      rescue
        errors << "Não foi possível suspender sua assinatura no Moip Assinaturas"
      end
    else
      errors << "Não é permitido suspender este apoio."
    end
    render(json: {success: (errors.size == 0), errors: errors}, status: ((errors.size == 0) ? 200 : 422))
  end

  private
  
  def contribution_params
    params.require(:contribution).permit(*policy(@contribution || Contribution.new).permitted_attributes)
  end

end
