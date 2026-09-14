extends Node

signal changed
const PERIODS := ["Morning", "Afternoon", "Evening", "Night"]
var day: int = 1
var period: int = 0

func reset_state() -> void:
	day = 1
	period = 0
	changed.emit()

func advance_time(steps: int = 1) -> void:
	if steps < 1 or steps > 100:
		GameManager.report("Time advancement must be between 1 and 100 periods", true)
		return
	var total := period + steps
	day += int(total / PERIODS.size())
	period = total % PERIODS.size()
	changed.emit()

func next_morning() -> void:
	day += 1
	period = 0
	changed.emit()

func get_current_day() -> int:
	return day

func get_current_period() -> String:
	return PERIODS[period]
