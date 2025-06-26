extends Node

# Example Inventory Manager Autoload Singleton
# This demonstrates the kind of functionality you can access from Lua scripts

class_name InventoryManager

# Inventory data
var items: Dictionary = {}
var max_items: int = 100
var gold: int = 0
var player_name: String = "DefaultPlayer"

# Signals
signal item_added(item_id: String, quantity: int)
signal item_removed(item_id: String, quantity: int)
signal inventory_changed()
signal gold_changed(new_amount: int)

func _ready():
	print("InventoryManager singleton initialized!")
	# Initialize with some default items
	add_item("health_potion", 5)
	add_item("mana_potion", 3)
	add_gold(100)

func add_item(item_id: String, quantity: int) -> bool:
	"""
	Add items to inventory.
	Returns true if successful, false if inventory is full.
	"""
	if get_total_items() + quantity > max_items:
		print("Cannot add items: inventory full")
		return false
	
	if items.has(item_id):
		items[item_id] += quantity
	else:
		items[item_id] = quantity
	
	print("Added " + str(quantity) + " " + item_id + " to inventory")
	item_added.emit(item_id, quantity)
	inventory_changed.emit()
	return true

func remove_item(item_id: String, quantity: int) -> bool:
	"""
	Remove items from inventory.
	Returns true if successful, false if not enough items.
	"""
	if not items.has(item_id) or items[item_id] < quantity:
		print("Cannot remove items: not enough " + item_id)
		return false
	
	items[item_id] -= quantity
	if items[item_id] <= 0:
		items.erase(item_id)
	
	print("Removed " + str(quantity) + " " + item_id + " from inventory")
	item_removed.emit(item_id, quantity)
	inventory_changed.emit()
	return true

func has_item(item_id: String) -> bool:
	"""Check if player has any of the specified item."""
	return items.has(item_id) and items[item_id] > 0

func get_item_count(item_id: String) -> int:
	"""Get the quantity of a specific item."""
	return items.get(item_id, 0)

func get_all_items() -> Dictionary:
	"""Get all items in inventory."""
	return items.duplicate()

func get_total_items() -> int:
	"""Get total number of items in inventory."""
	var total = 0
	for quantity in items.values():
		total += quantity
	return total

func clear_inventory():
	"""Clear all items from inventory."""
	items.clear()
	inventory_changed.emit()
	print("Inventory cleared")

func add_gold(amount: int):
	"""Add gold to player's wallet."""
	gold += amount
	gold_changed.emit(gold)
	print("Added " + str(amount) + " gold. Total: " + str(gold))

func remove_gold(amount: int) -> bool:
	"""
	Remove gold from player's wallet.
	Returns true if successful, false if not enough gold.
	"""
	if gold < amount:
		print("Not enough gold!")
		return false
	
	gold -= amount
	gold_changed.emit(gold)
	print("Removed " + str(amount) + " gold. Total: " + str(gold))
	return true

func get_gold() -> int:
	"""Get current gold amount."""
	return gold

func set_player_name(name: String):
	"""Set the player's name."""
	player_name = name
	print("Player name set to: " + name)

func get_player_name() -> String:
	"""Get the player's name."""
	return player_name

func get_inventory_info() -> Dictionary:
	"""Get comprehensive inventory information."""
	return {
		"player_name": player_name,
		"gold": gold,
		"items": items.duplicate(),
		"total_items": get_total_items(),
		"max_items": max_items,
		"free_space": max_items - get_total_items()
	}

func is_inventory_full() -> bool:
	"""Check if inventory is full."""
	return get_total_items() >= max_items

func get_free_space() -> int:
	"""Get available inventory space."""
	return max_items - get_total_items()

# Utility methods for Lua scripts
func calculate_item_value(item_id: String, quantity: int) -> int:
	"""Calculate the value of items (example pricing system)."""
	var base_prices = {
		"health_potion": 10,
		"mana_potion": 15,
		"sword": 100,
		"shield": 80,
		"armor": 200
	}
	
	var base_price = base_prices.get(item_id, 5)  # Default price
	return base_price * quantity

func can_afford_item(item_id: String, quantity: int) -> bool:
	"""Check if player can afford to buy items."""
	var cost = calculate_item_value(item_id, quantity)
	return gold >= cost

func buy_item(item_id: String, quantity: int) -> bool:
	"""
	Buy items with gold.
	Returns true if successful, false if not enough gold or inventory space.
	"""
	var cost = calculate_item_value(item_id, quantity)
	
	if not can_afford_item(item_id, quantity):
		print("Cannot afford " + str(quantity) + " " + item_id + " (cost: " + str(cost) + " gold)")
		return false
	
	if not add_item(item_id, quantity):
		print("Cannot add items to inventory")
		return false
	
	remove_gold(cost)
	print("Bought " + str(quantity) + " " + item_id + " for " + str(cost) + " gold")
	return true

func sell_item(item_id: String, quantity: int) -> bool:
	"""
	Sell items for gold.
	Returns true if successful, false if not enough items.
	"""
	if not remove_item(item_id, quantity):
		print("Cannot sell items: not enough " + item_id)
		return false
	
	var value = calculate_item_value(item_id, quantity)
	add_gold(value)
	print("Sold " + str(quantity) + " " + item_id + " for " + str(value) + " gold")
	return true 