
class OpenStudio::Model::AirTerminalSingleDuctVAVReheat
  # Set the minimum damper position based on OA
  # rate of the space and the template.
  # Zones with low OA per area get lower initial guesses.
  # Final position will be adjusted upward
  # as necessary by Standards.AirLoopHVAC.adjust_minimum_vav_damper_positions
  # @param template [String] the template
  # @param zone_min_oa [Double] the zone outdoor air flow rate, in m^3/s.
  # If supplied, this will be set as a minimum limit in addition to the minimum
  # damper position.  EnergyPlus will use the larger of the two values during sizing.
  # @param has_ddc [Bool] whether or not there is DDC control of the VAV terminal,
  # which impacts the minimum damper position requirement.
  # @return [Bool] returns true if successful, false if not
  # @todo remove exception where older vintages don't have minimum positions adjusted.
  def apply_minimum_damper_position(template, zone_min_oa = nil, has_ddc = true)
    # Minimum damper position
    min_damper_position = nil
    case template
    when 'DOE Ref Pre-1980', 'DOE Ref 1980-2004', '90.1-2004'
      min_damper_position = 0.3
    when '90.1-2007'
      min_damper_position = 0.3
    when '90.1-2010', '90.1-2013', 'NREL ZNE Ready 2017'
      case reheat_type
      when 'HotWater'
      min_damper_position = if has_ddc
                              0.2
                            else
                              0.3
                            end
      when 'Electricity', 'NaturalGas'
        min_damper_position = 0.3
      end
    end
    setConstantMinimumAirFlowFraction(min_damper_position)
    OpenStudio.logFree(OpenStudio::Debug, 'openstudio.standards.AirTerminalSingleDuctVAVReheat', "For #{name}: set minimum damper position to #{min_damper_position}.")

    # Minimum OA flow rate
    # If specified, will also add this limit
    # and the larger of the two will be used
    # for sizing.
    unless zone_min_oa.nil?
      setFixedMinimumAirFlowRate(zone_min_oa)
    end

    return true
  end

  def set_heating_cap
    flow_rate_fraction = constantMinimumAirFlowFraction
    if reheatCoil.to_CoilHeatingWater.is_initialized
      reheat_coil = reheatCoil.to_CoilHeatingWater.get
      if reheat_coil.autosizedRatedCapacity.to_f < 1.0e-6
        cap = 1.2 * 1000.0 * constantMinimumAirFlowFraction * autosizedMaximumAirFlowRate.to_f * (18.0 - 13.0)
	    reheat_coil.setPerformanceInputMethod("NominalCapacity")
        reheat_coil.setRatedCapacity(cap)
        setMaximumReheatAirTemperature(18.0)
	  end
    end
  end

  # Determines whether the terminal has a NaturalGas,
  # Electricity, or HotWater reheat coil.
  # @return [String] reheat type.  One of NaturalGas,
  # Electricity, or HotWater.
  def reheat_type
    type = nil

    # Get the reheat coil
    rht_coil = reheatCoil
    if rht_coil.to_CoilHeatingElectric.is_initialized
      type = 'Electricity'
    elsif rht_coil.to_CoilHeatingWater.is_initialized
      type = 'HotWater'
    elsif rht_coil.to_CoilHeatingGas.is_initialized
      type = 'NaturalGas'
    end

    return type
  end

end
