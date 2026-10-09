# 西北农林科技大学硕士／博士研究生开题报告 LaTeX 模板

适用于硕士、博士研究生学位论文开题报告。封面采用学校 Word 开题报告的 A4 页面布局、标题层次、字号、字段排列及下划线形式；目录、正文、参考文献和页眉页脚使用 [nwafuthesis](https://ctan.org/pkg/nwafuthesis) 文档类的原生格式。

## 页面组成

| 模式 | 页次安排 |
| --- | --- |
| oneside | 第 1 页封面；第 2 页目录；之后为正文与参考文献 |
| twoside | 第 1 页封面；第 2 页空白；第 3 页目录；之后为正文与参考文献，按照文档类规则从奇数页开始新章节 |

不生成摘要、关键词页、符号表、术语表、英文封面、原创性声明等学位论文前置页面。

## 使用方法

1. 安装 XeLaTeX、Biber、Noto Serif CJK SC、Noto Sans CJK SC、Tinos 等字体，以及 [nwafuthesis](https://ctan.org/pkg/nwafuthesis) v2.17 或更新版本。
2. 修改 main.tex 中的 type=master / type=doctor，oneside / twoside 选项；封面上的学位称谓自动随之变化。
3. 将 cover/information.example.tex 复制为 cover/information-private.tex，在本地填写个人信息。私人文件已被 .gitignore 忽略；中文、英文标题可以使用 LaTeX 双反斜杠换行。
4. 修改 contents/ 里的章节，在 bib/references.bib 中维护参考文献。
5. 在根目录运行：latexmk -xelatex main.tex，也可以按 XeLaTeX → Biber → XeLaTeX → XeLaTeX 的顺序编译。
6. 运行 bash scripts/test-build.sh，验证单面、双面和博士模板的编译结果。

## 文件结构

- main.tex：入口文件、目录与正文的组合。
- cover/cover.tex：Word 风格封面布局。
- cover/information.example.tex：公开示例封面信息。
- contents/：正文示例。
- bib/references.bib：引用示例。
- scripts/test-build.sh：编译和页次测试。

本项目依赖外部 nwafuthesis 文档类，不包含该文档类、第三方字体及原始 Word 文件。正文样式来自 [nwafuthesis-l3](https://gitee.com/nwafu_nan/nwafuthesis-l3)，封面样式依据学校开题报告 Word 版式设计。不同操作系统的字体渲染可能存在细微差异。

新增代码按照本仓库 [MIT License](LICENSE) 发布，外部文档类遵循其原有许可。本模板并非学校官方发行版本，提交前请以学校当期要求为准。
