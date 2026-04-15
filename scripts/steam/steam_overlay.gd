# Steam社区/好友邀请集成
extends Node

var current_lobby_id: int = 0
var is_host: bool = false

func _ready():
	# Steam回调
	Steam.connect("lobby_created", _on_lobby_created)
	Steam.connect("lobby_joined", _on_lobby_joined)
	Steam.connect("lobby_invite", _on_lobby_invite)
	Steam.connect("game_lobby_join_requested", _on_join_requested)

func create_lobby():
	if not get_node("/root/Game/SteamManager").is_steam_initialized:
		return
	
	current_lobby_id = Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 8)
	is_host = true
	print("创建Steam大厅: ", current_lobby_id)

func join_lobby(lobby_id: int):
	Steam.joinLobby(lobby_id)
	is_host = false

func leave_lobby():
	if current_lobby_id > 0:
		Steam.leaveLobby(current_lobby_id)
		current_lobby_id = 0
		is_host = false

func _on_lobby_created(result: int, lobby_id: int):
	if result == 1:
		print("大厅创建成功: ", lobby_id)
		current_lobby_id = lobby_id
		Steam.setLobbyData(lobby_id, "name", "Command & War - %s" % Steam.getPersonaName())
		Steam.setLobbyData(lobby_id, "game_mode", "skirmish")
	else:
		print("大厅创建失败")

func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool):
	print("加入大厅成功: ", lobby_id)
	current_lobby_id = lobby_id

func _on_lobby_invite(_steam_id: int, _relationship: int, lobby_id: int):
	print("收到邀请加入大厅: ", lobby_id)

func _on_join_requested(lobby_id: int, _steam_id: int):
	print("请求加入大厅: ", lobby_id)
	join_lobby(lobby_id)

func send_lobby_chat_message(msg: String):
	if current_lobby_id > 0:
		Steam.sendLobbyChatMsg(current_lobby_id, msg.to_utf8_buffer())
