class DOERef1980_2004_Model < A90_1_Model
  # Determine if temperature reset is required.
  # Not required for the older DOE buildings.
  def plant_loop_supply_water_temperature_reset_required?(plant_loop)
    reset_required = false
    return reset_required
  end
end