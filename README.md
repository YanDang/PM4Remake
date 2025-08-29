# PM4 Reimagined (美少女梦工厂4 重置版)

**PM4 Reimagined** 是对经典游戏《美少女梦工厂4（Princess Maker 4）》的重置版项目。项目使用 [Godot Engine](https://godotengine.org/) 开发，参考了 PM4 完璧版、NDS 版、比目鱼 Flash 盗版等版本以及国内的精神续作火山的女儿，旨在重现原作的精髓并加入现代化的改进。

该项目完全开源，欢迎任何对游戏开发、剧情重制、角色设计感兴趣的开发者参与。

---

## 开发进度
- [] 开始界面
    - [x] 基本UI
    - [x] 开始游戏跳转
    - [] 继续游戏
    - [] 画廊
    - [x] 退出游戏
- [] 基础界面
    - [] 人物立绘
        - [x] 眨眼动画
            - [x] 基本眨眼动画
            - [x] 脚本实现
        - [] 服装切换
        - [] 年龄变更
        - [] 健康状态变更
    - [] UI界面
        - [x] 时间显示
            - [x] 年月日
            - [] 季节
        - [x] 全局属性
            - [x] 所持金
            - [x] 人物身材
            - [] 饮食策略
        - [x] 状态
            - [x] 全局脚本绑定
        - [] 对话
        - [] 健康
            - [] 饮食策略调整
        - [] 道具
            - [] 仓库系统
        - [] 上街
            - [] 道具店
            - [] 洋装店
            - [] 餐厅
            - [] 教会
            - [] 医院
        - [] 安排行程
            - [] 行程GUI
            - [] 交互显示
            - [] 行程事件
                - [] 属性结算
- [] 外出
    - [] 城
    - [] 广场
    - [] 繁华街
    - [] 道具店
    - [] 洋装店
    - [] 餐厅
    - [] 教会
    - [] 医院
    - [] 街道
    - [] 黑街
    - [] 市场
    - [] 城外
- [] 度假
- [] 人物事件
    - [] 基础事件编辑器
    - [] 王子们的事件
        - [] 夏洛璐
        - [] 巴洛亚
        - [] 利伊
    - [] 父亲的事件
    - [] 好友的事件
        - [] 莉洁
        - [] 克莉丝提娜
        - [] 玛丽
    - [] 其他
- [] 结局结算
- [] 战斗
    - [x] 基础战斗轮
        - [x] 人物属性
    - [] 装备系统
- [] 收获季
    
## 🎮 特性

- **剧情重置与优化**：基于多个版本的剧情和结局进行整理和优化  
- **现代化 UI**：在 Godot 引擎中实现可自适应分辨率的用户界面  
- **角色养成系统**：重现原作的养成机制，同时优化操作体验  
- **多平台支持**：计划支持 Windows、Linux 和 macOS  
- **开源开放**：所有资源和代码均在 GitHub 上公开
<img width="804" height="602" alt="image" src="https://github.com/user-attachments/assets/7b76b74d-2248-453f-ad4d-d03ac74004b2" />
<img width="1280" height="967" alt="image" src="https://github.com/user-attachments/assets/88b2fd8b-fca9-4325-aad9-8de2b3d4c7cf" />
<img width="1169" height="668" alt="339fd32cd64b57ce38596cbef484700d_720" src="https://github.com/user-attachments/assets/252775b8-d92d-464b-ad9b-9bb3b202ab3c" />

---

## 💾 安装与运行

1. 克隆项目到本地：
    ```bash
    git clone https://github.com/YanDang/PM4Remake.git
    cd pm4-reimagined
    ```
2. 下载并安装 [Godot Engine 4.x](https://godotengine.org/download)
3. 打开 Godot 项目：
    - 启动 Godot
    - 选择 **"Import Existing Project"**
    - 指向项目根目录
4. 运行游戏：
    - 点击 **Play** 或使用快捷键 **F5**

---

## 🛠 开发指南

1. 游戏资源（图片、音效、音乐）请遵循 **开源或自制原则**  
2. 所有功能模块均在 `scripts/` 下，建议遵循 Godot 的节点结构进行开发  
3. 提交前请确保：
    - 代码通过 Godot 内置的 linter 检查
    - 游戏在至少一个平台上正常运行

---

## 🤝 贡献

欢迎贡献剧情、角色设计、系统改进或 Bug 修复：

1. Fork 本仓库  
2. 创建你的 feature 分支：  
    ```bash
    git checkout -b feature/你的功能
    ```  
3. 提交修改并推送到远程分支  
4. 提交 Pull Request，描述你的修改内容  

---

## 📜 许可证

本项目采用 **MIT 许可证**，允许任何人自由使用、修改和分发，但请保留原作者信息。

---

## ⚠️ 注意事项

- 本项目为重置版，仅供学习和研究使用  
- 游戏素材需遵守原版权规定，非自制资源请确保合法使用  
- 禁止用于商业目的

---

## 📌 联系方式

如有问题或建议，请通过 GitHub Issues 或邮件联系：

- GitHub: [https://github.com/YanDang/PM4Remake](https://github.com/YanDang/PM4Remake)
- 邮箱: yilog017@gmail.com
