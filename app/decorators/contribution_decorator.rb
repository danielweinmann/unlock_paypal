module ContributionDecorator

  def moip_auth
    { token: self.gateway.settings["token"], key: self.gateway.settings["key"], sandbox: self.gateway.sandbox? }
  end
 
end
