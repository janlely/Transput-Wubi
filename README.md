# Transput-Wubi

一个支持AI翻译的五笔输入法，基础框架fork自[Typut](https://github.com/ensan-hcl/Typut)


## Working Environment

Checked in March 2024.
* macOS 14.3
* Swift 5.10
* Xcode 15.3

## 使用指南

* AI翻译
![image](./show.gif)

* 使用shift在输入法内切换中英文

* 使用ctrl+t 开启/关闭AI翻译(需先设置apiKey)

* 输入法菜单中可以设置AI翻译的apikey

## 本地安装

* build
```bash

xcodebuild

cp -r build/Release/Transput-Wubi.app ~/Library/Input\ Methods/
```

* 注销当前用户

* 在系统输入法设置中添加Transput-Wubi


