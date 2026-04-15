# Steam商店页面配置
extends Node

# 商店页面元数据（用于自动生成商店描述）
const STORE_INFO: Dictionary = {
	"type": "game",
	"name": "Command & War",
	"short_description": "一款致敬经典的现代即时战略游戏",
	"full_description": """Command & War 是一款原创即时战略游戏，灵感来源于经典RTS游戏。

【游戏特色】
- 建造基地，采集资源，爆兵作战
- 多种单位类型，各有独特属性
- 兵种相克，策略为王
- AI对战，考验你的战术
- 战争迷雾，探索未知区域

【单位】
- 步兵：机动灵活，数量压制
- 坦克：火力强劲，攻守兼备
- 直升机：空中优势，机动突袭
- 火箭兵：建筑克星，特攻专家

【系统需求】
操作系统: Windows 10+
处理器: Intel Core i5
内存: 8 GB RAM
显卡: NVIDIA GTX 660
存储空间: 2 GB 可用空间

支持Steam成就和排行榜""",
	"supported_languages": ["schinese", "english"],
	"categories": ["Strategy", "RTS"],
	"genres": ["Strategy", "Indie"]
}

func get_store_info() -> Dictionary:
	return STORE_INFO
