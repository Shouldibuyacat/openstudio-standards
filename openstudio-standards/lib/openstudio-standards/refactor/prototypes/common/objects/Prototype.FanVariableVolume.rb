
# open the class to add methods to return sizing values
class StandardsModel
  include PrototypeFan

  # Sets the fan pressure rise based on the Prototype buildings inputs
  # which are governed by the flow rate coming through the fan
  # and whether the fan lives inside a unit heater, PTAC, etc.
  def fan_variable_volume_apply_prototype_fan_pressure_rise(fan_variable_volume, building_type, climate_zone)
    # NECB
    if instvartemplate == 'NECB 2011'
      pressure_rise_pa = 1458.33 # 1000 Pa for supply fan and 458.33 Pa for return fan (accounts for efficiency differences between two fans)
      fan_variable_volume.setPressureRise(pressure_rise_pa)
      return true
    end

    # Get the max flow rate from the fan.
    maximum_flow_rate_m3_per_s = nil
    if fan_variable_volume.maximumFlowRate.is_initialized
      maximum_flow_rate_m3_per_s = fan_variable_volume.maximumFlowRate.get
    elsif fan_variable_volume.autosizedMaximumFlowRate.is_initialized
      maximum_flow_rate_m3_per_s = fan_variable_volume.autosizedMaximumFlowRate.get
    else
      OpenStudio.logFree(OpenStudio::Warn, 'openstudio.prototype.FanVariableVolume', "For #{fan_variable_volume.name} max flow rate is not available, cannot apply prototype assumptions.")
      return false
    end

    # Convert max flow rate to cfm
    maximum_flow_rate_cfm = OpenStudio.convert(maximum_flow_rate_m3_per_s, 'm^3/s', 'cfm').get

    # Pressure rise will be determined based on the
    # following logic.
    pressure_rise_in_h2o = 0.0

    # If the fan lives inside of a zone hvac equipment
    if fan_variable_volume.containingZoneHVACComponent.is_initialized
      zone_hvac = fan_variable_volume.ZoneHVACComponent.get
      if zone_hvac.to_ZoneHVACPackagedTerminalAirConditioner.is_initialized
        pressure_rise_in_h2o = 1.33
      elsif zone_hvac.to_ZoneHVACFourPipeFanCoil.is_initialized
        pressure_rise_in_h2o = 1.33
      elsif zone_hvac.to_ZoneHVACUnitHeater.is_initialized
        pressure_rise_in_h2o = 0.2
      else # This type of fan should not exist in the prototype models
        return false
      end
    # If the fan lives on an airloop
    elsif fan_variable_volume.airLoopHVAC.is_initialized

      # TODO: Inconsistency - Primary School uses CAV pressure rises
      # even thought it has a VAV system.  CAV system is listed in document,
      # so assume the system type was updated but forgot to update pressure rises.
      if building_type == 'PrimarySchool' && (instvartemplate == 'DOE Ref Pre-1980' || instvartemplate == 'DOE Ref 1980-2004')

        pressure_rise_in_h2o = if maximum_flow_rate_cfm < 7487
                                 2.5
                               elsif maximum_flow_rate_cfm >= 7487 && maximum_flow_rate_cfm < 20_000
                                 4.46
                               else # Over 20,000 cfm
                                 4.09
                               end

      else

        case instvartemplate
        when 'DOE Ref Pre-1980', 'DOE Ref 1980-2004', '90.1-2004'
          pressure_rise_in_h2o = if maximum_flow_rate_cfm < 4648
                                   4.0
                                 elsif maximum_flow_rate_cfm >= 4648 && maximum_flow_rate_cfm < 20_000
                                   6.32
                                 else # Over 20,000 cfm
                                   5.58
                                 end
        when '90.1-2007', '90.1-2010', '90.1-2013', 'NREL ZNE Ready 2017'
          pressure_rise_in_h2o = if maximum_flow_rate_cfm < 4648
                                   4.0
                                 else # Over 7,437 cfm
                                   5.58
                                 end
        end

      end
    end

    # Set the fan pressure rise
    pressure_rise_pa = OpenStudio.convert(pressure_rise_in_h2o, 'inH_{2}O', 'Pa').get
    fan_variable_volume.setPressureRise(pressure_rise_pa)

    OpenStudio.logFree(OpenStudio::Info, 'openstudio.model.FanVariableVolume', "For Prototype: #{fan_variable_volume.name}: #{maximum_flow_rate_cfm.round}cfm; Pressure Rise = #{pressure_rise_in_h2o}in w.c.")

    return true
  end
end
