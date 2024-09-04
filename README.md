# Transput-Wubi

一个支持AI翻译的五笔输入法，基础框架fork自[Typut](https://github.com/ensan-hcl/Typut)


## Working Environment

Checked in March 2024.
* macOS 14.3
* Swift 5.10
* Xcode 15.3

## 演示

* AI翻译
![image](./show.gif)

## 快捷键

| 功能 | 描述 | 快捷键 |
| :-----: |  :----: | :----: |
| 中英切换 | 在输入法内切换中英文，便于翻译前的中英混合输入 | `Shift` |
| 翻译开关 | 开启/关闭翻译功能，方便非翻译场景下使用 | `Ctrl_t` or `/s` |
| 翻译        |  将当前的文本进行AI翻译后自动提交  |  `Ctrl_Enter` or `/t` |
| 提交文本 |  无需翻译，直接提交当前文本  | `Enter`  or  `/g` |
| 粘贴文本 |  从系统剪切板粘贴内容 | `/v` |





## 本地安装

* build
```bash

xcodebuild

cp -r build/Release/Transput-Wubi.app ~/Library/Input\ Methods/
```

* 注销当前用户

* 在系统输入法设置中添加Transput-Wubi


