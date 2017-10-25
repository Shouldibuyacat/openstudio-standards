class A90_1_2013_Model < A90_1_Model
  include ASHRAE9012013CoolingTower

  # Apply the efficiency, plus Multicell heat rejection with VSD per 90.1-2013 6.5.2.2
  #
  # @param [OpenStudio::Model::CoolingTowerVariableSpeed] the cooling tower
  def cooling_tower_variable_speed_apply_efficiency_and_curves(cooling_tower_variable_speed)
    cooling_tower_apply_minimum_power_per_flow(cooling_tower_variable_speed)
    
    cooling_tower_variable_speed.setCellControl('MaximalCell')
      
    return true
  end
end