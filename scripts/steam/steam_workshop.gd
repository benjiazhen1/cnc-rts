# Steam创意工坊集成
extends Node

var workshop_items: Array = []

func _ready():
	Steam.connect("item_created", _on_item_created)
	Steam.connect("item_updated", _on_item_updated)

# 发布地图到创意工坊
func publish_map(map_name: String, map_description: String, preview_image: String):
	if not get_node("/root/Game/SteamManager").is_steam_initialized:
		return
	
	var tags = ["Map", "RTS"]
	var visibility = Steam.PUBLISHED_FILE_VISIBILITY_PUBLIC
	
	# 创建新条目
	var item_id = Steam.createPublishedDocument(
		0,  # consumer app id (0 = self)
		"res://maps/" + map_name + ".tscn",
		visibility,
		map_description,
		tags
	)
	
	print("创意工坊发布请求: ", item_id)

func subscribe_item(item_id: int):
	Steam.subscribePublishedFile(item_id)

func unsubscribe_item(item_id: int):
	Steam.unsubscribePublishedFile(item_id)

func get_subscribed_items() -> Array:
	return Steam.getSubscribedPublishedFiles()

func download_item(item_id: int, high_priority: bool = true):
	Steam.downloadItem(item_id, high_priority)

func _on_item_created(result: int, item_id: int, _file_id: int):
	if result == 1:
		print("创意工坊项目创建成功: ", item_id)
	else:
		print("创意工坊项目创建失败")

func _on_item_updated(result: int, item_id: int):
	if result == 1:
		print("创意工坊项目更新成功: ", item_id)
	else:
		print("创意工坊项目更新失败")
