# TODO
$(document).ready ->
  if action() == "new" and controller() == "contributions" and namespace() == "initiatives"
    $('#contribution_value').maskMoney
      thousands: ''
      decimal: ''
      precision: 0
  if action() == "edit" and controller() == "contributions" and namespace() == "unlockpaypal"
