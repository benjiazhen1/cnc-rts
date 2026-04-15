# Command & War 🛩️

一款致敬经典的现代即时战略游戏。

## 🎮 游戏特色

- **建造系统**: 指挥中心 → 发电厂 → 兵营/工厂/机场 → 爆兵
- **单位系统**: 步兵、坦克、直升机、火箭兵，各有独特属性
- **兵种相克**: 策略为王，克制关系决定胜负
- **AI对战**: 智能AI，考验你的战术
- **战争迷雾**: 探索未知区域，发现敌人

## 🛠️ 技术栈

- **引擎**: Godot 4.2
- **语言**: GDScript
- **目标平台**: Windows (Steam) + HTML5 (Web)

## 📁 项目结构

```
cnc-rts/
├── scripts/
│   ├── core/           # 核心系统
│   ├── entities/       # 单位/建筑实体
│   ├── systems/        # 游戏系统
│   ├── ui/            # 界面
│   └── steam/         # Steam集成
├── scenes/            # Godot场景
├── resources/         # 美术/音频资源
└── .github/workflows/ # CI/CD
```

## 🎯 开发进度

| 模块 | 状态 |
|------|------|
| 核心框架 | ✅ 完成 |
| 建筑系统 | ✅ 完成 |
| 单位系统 | ✅ 完成 |
| 寻路算法 | ✅ 完成 |
| 战斗系统 | ✅ 完成 |
| AI对手 | ✅ 完成 |
| 战争迷雾 | ✅ 完成 |
| 存档系统 | ✅ 完成 |
| 音效系统 | ✅ 完成 |
| Steam SDK | ✅ 完成 |
| 美术资源 | 🔄 进行中 |
| 音效资源 | ⏳ 待替换 |

## 🚀 构建状态

| 平台 | 状态 |
|------|------|
| Windows EXE | GitHub Actions自动构建 |
| HTML5 | GitHub Actions自动构建 |
| Linux | GitHub Actions自动构建 |

## 🎨 资源统计

- **脚本文件**: 48个 GDScript
- **精灵图**: 200+ PNG
- **音效**: 13个 SFX (占位符)
- **音乐**: 3首 BGM (占位符)

## 📦 发布计划

1. ✅ MVP核心玩法
2. 🔄 完善美术资源
3. ⏳ 替换真实音效
4. ⏳ Steam商店素材
5. ⏳ 提交审核

## 🔗 相关链接

- [Godot 4.2 下载](https://godotengine.org/download)
- [Steamworks 文档](https://partner.steamgames.com/doc/sdk)
- [MiniMax API](https://platform.minimaxi.com)

## 📄 License

MIT License
