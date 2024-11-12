import "@typespec/http";
import "@typespec/rest";
import "@typespec/openapi3";

import "@typespec/http";
import "@typespec/rest";
import "@typespec/versioning";

using TypeSpec.Http;
using TypeSpec.Rest;
using TypeSpec.Versioning;

@service({
  title: "SteelStack API",
})
namespace SteelStack;

@error
model Error {
  code: string;
  message: string;
  details?: Record<unknown>;
}

// Base components for production line
model Furnace {
  type: "electric_arc" | "induction";
  power_rating_mw: float32;
  max_batch_size_tons: float32;
}

model AodConverter {
  capacity_tons: float32;
  gas_injection_ports: int32;
}

model Caster {
  type: "slab" | "bloom" | "billet";
  mold_width_mm: int32;
  cooling_zones: int32;
}

model RollingMill {
  type: "hot_rolling" | "cold_rolling";
  max_width_mm: int32;
  min_thickness_mm: float32;
}

model QualityControlPoint {
  location: string;
  analyzers: string[];
}

// Core resources
model ProductionLine {
  @visibility("read", "update")
  @path
  id: string;

  name: string;
  description?: string;
  capacity_tons_per_day: float32;
  components: {
    furnace: Furnace;
    aod_converter: AodConverter;
    caster: Caster;
    rolling_mill: RollingMill;
  };
  grade_capabilities: string[];
  quality_control_points: QualityControlPoint[];
}

model CompositionRange {
  min: float32;
  max: float32;
}

model GradeRecipe {
  @visibility("read", "update")
  @path
  id: string;

  grade: string;
  description?: string;
  composition: {
    carbon_max: float32;
    chromium_range: CompositionRange;
    nickel_range: CompositionRange;
  };
  process_parameters: {
    aod_temperature: float32;
    decarburization_target: float32;
    hot_rolling_temperature: float32;
  };
  quality_requirements: {
    tensile_strength_min_mpa: float32;
    yield_strength_min_mpa: float32;
    elongation_min_percent: float32;
  };
}

model Equipment {
  type: string;
  "model": string;
  measurement_range_mm: {
    min: float32;
    max: float32;
  };
}

model QCStation {
  @visibility("read", "update")
  @path
  id: string;

  name: string;
  location: string;
  equipment: Equipment[];
  alert_thresholds: Record<unknown>;
}

model MaintenanceTask {
  component: string;
  operating_hours: int32;
  tasks: string[];
}

model MaintenanceSchedule {
  @visibility("read", "update")
  @path
  id: string;

  equipment_id: string;
  schedule_type: "predictive" | "preventive" | "reactive";
  intervals: MaintenanceTask[];
  condition_monitoring: {
    sensors: string[];
    alert_conditions: Record<unknown>;
  };
}

// Resource state response
model ResourceState {
  production_lines: {
    total: int32;
    active: int32;
    maintenance: int32;
  };
  grade_recipes: {
    total: int32;
    active: int32;
    deprecated: int32;
  };
  qc_stations: {
    total: int32;
    operational: int32;
    calibration_needed: int32;
  };
}

// API interfaces
@route("/production-lines")
@tag("Production Lines")
interface ProductionLines {
  @get list(): ProductionLine[] | Error;
  @get read(@path id: string): ProductionLine | Error;
  @post create(...ProductionLine): ProductionLine | Error;
  @put update(...ProductionLine): ProductionLine | Error;
  @delete delete(@path id: string): void | Error;
}

@route("/grade-recipes")
@tag("Grade Recipes")
interface GradeRecipes {
  @get list(): GradeRecipe[] | Error;
  @get read(@path id: string): GradeRecipe | Error;
  @post create(...GradeRecipe): GradeRecipe | Error;
  @put update(...GradeRecipe): GradeRecipe | Error;
  @delete delete(@path id: string): void | Error;
}

@route("/qc-stations")
@tag("Quality Control")
interface QCStations {
  @get list(): QCStation[] | Error;
  @get read(@path id: string): QCStation | Error;
  @post create(...QCStation): QCStation | Error;
  @put update(...QCStation): QCStation | Error;
  @delete delete(@path id: string): void | Error;
}

@route("/maintenance-schedules")
@tag("Maintenance")
interface MaintenanceSchedules {
  @get list(): MaintenanceSchedule[] | Error;
  @get read(@path id: string): MaintenanceSchedule | Error;
  @post create(...MaintenanceSchedule): MaintenanceSchedule | Error;
  @put update(...MaintenanceSchedule): MaintenanceSchedule | Error;
  @delete delete(@path id: string): void | Error;
}

@route("/state")
@tag("System State")
interface State {
  @get read(): ResourceState | Error;
}