extends "res://scripts/run_model.gd"
# Test-only fixed forward speed; no command-line bypass in shipped gameplay.
var fixed_speed: float=380.0
func base_speed() -> float:
 return minf(fixed_speed,700.0)
