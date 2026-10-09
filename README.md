# 西北农林科技大学硕士／博士研究生开题报告 LaTeX 模板

适用于硕士、博士研究生学位论文开题报告。封面采用学校 Word 开题报告的 A4 页面布局、标题层次、字号、字段排列及下划线形式；目录、正文、参考文献和页眉页脚使用 [nwafuthesis](https://ctan.org/pkg/nwafuthesis) 文档类的原生格式。

## 页面组成

| 模式 | 页次安排 |
| --- | --- |
| oneside | 第 1 页封面；第 2 页目录；之后为正文与参考文献 |
| twoside | 第 1 页封面；第 2 页空白；第 3 页目录；之后为正文与参考文献，按照文档类规则从奇数页开始新章节 |

不生成摘要、关键词页、符号表、术语表、英文封面、原创性声明等学位论文前置页面。

## 使用方法

1. 安装 XeLaTeX、Biber、Fandol、XITS 等开源字体，以及 [nwafuthesis](https://ctan.org/pkg/nwafuthesis) v2.17 或更新版本。
2. 修改 main.tex 中的 type=master / type=doctor，oneside / twoside 选项；封面上的学位称谓自动随之变化。
3. 将 cover/information.example.tex 复制为 cover/information-private.tex，在本地填写个人信息。私人文件已被 .gitignore 忽略；中文、英文标题可以使用 LaTeX 双反斜杠换行。
4. 修改 contents/ 里的章节，在 bib/references.bib 中维护参考文献。
5. 在根目录运行：latexmk -xelatex main.tex，也可以按 XeLaTeX → Biber → XeLaTeX → XeLaTeX 的顺序编译。
6. 运行 bash scripts/test-build.sh，验证单面、双面和博士模板的编译结果。

## 开题报告章节结构

正文严格按照开题报告目录分为六章，各章独立保存在 `contents/` 文件夹：

1. **选题依据**：选题背景及意义；理论与技术依据（理论依据、技术依据）；国内外研究现状（三个研究方向小节）。
2. **研究内容及拟解决的关键问题**：研究内容（三个研究内容小节）；拟解决的关键问题。
3. **研究方法及研究路线**：研究思路与方法（四个方法小节）；技术路线。
4. **预期成果**：预期成果；创新之处；预期社会效益。
5. **工作进度安排及经费预算**：工作进展；所需设备；经费预算。
6. **已取得的阶段性成果**。

目录末尾为参考文献。属于具体研究课题的三个研究现状方向、三个研究内容、四种研究方法，均采用通用可编辑标题，正式撰写时自行替换。这些标题仅用于说明章节层级，不代表任何具体研究对象。

## 文件结构

- main.tex：入口文件、目录与正文的组合。
- fonts/font-setup.tex：根据已安装字体自动选择宋体、黑体和西文字体。
- cover/cover.tex：Word 风格封面布局。
- cover/information.example.tex：公开示例封面信息。
- contents/：按开题报告目录组织的六章正文示例，每章一个独立文件。
- bib/references.bib：引用示例。
- scripts/test-build.sh：编译和页次测试。
- scripts/check-structure.py：验证六章正文、节与小节的顺序及 PDF 目录对应内容。
- scripts/check-cover-layout.py：PDF 字体、封面标题间距检查。

本项目依赖外部 nwafuthesis 文档类，不包含该文档类、第三方字体及原始 Word 文件。正文样式来自 [nwafuthesis-l3](https://gitee.com/nwafu_nan/nwafuthesis-l3)，封面样式依据学校开题报告 Word 版式设计。模板通过 XeLaTeX 的 `\IfFontExistsTF` 自动检查可用字体：西文优先使用 **Times New Roman**（否则 XITS）；中文宋体优先使用 **SimSun／宋体**（否则 FandolSong）；中文黑体优先使用 **SimHei／黑体**（否则 FandolHei）。各字体独立判断，封面与正文共用选择结果；数学字体与楷体分别保持 XITS Math 和 FandolKai。请在本机依法安装所需字体，无需修改模板，也无需将商业字体文件提交至仓库。编译后可在 `main.log` 中搜索 `Proposal ... font:` 查看实际选中的字体。

新增代码按照本仓库 [MIT License](LICENSE) 发布，外部文档类遵循其原有许可。本模板并非学校官方发行版本，提交前请以学校当期要求为准。

## GitHub Actions 自动编译

仓库使用 [LaTeX CI](.github/workflows/latex-ci.yml) 工作流，在向 `main` 分支推送、提交 Pull Request 或手动运行时，自动检查并编译以下公开示例：

| 输出文件 | 版式 | 页次验证 |
| --- | --- | --- |
| `master-oneside.pdf` | 硕士单面 | 第 1 页封面、第 2 页目录 |
| `master-twoside.pdf` | 硕士双面 | 第 1 页封面、第 2 页空白、第 3 页目录 |
| `doctor-twoside.pdf` | 博士双面 | 第 1 页封面、第 2 页空白、第 3 页目录 |

CI 使用 TeX Live 2026（含 `nwafuthesis`）、XeLaTeX、Biber 和开源字体编译，检查学位称谓、公开占位信息、实际选用及嵌入 PDF 的字体、封面标题间距、目录位置、六章及各级标题、正文内容及 PDF 文件有效性。所有检查通过后，在对应 Actions 运行页面的 **Artifacts** 区域上传 `nwafu-proposal-example-pdfs`，内含上述 3 个 PDF，保留 30 天。

CI 始终使用 `cover/information.example.tex`，不会读取 `cover/information-private.tex`。为防止泄露真实个人信息，请不要把私人信息写入公开示例文件，也不要上传包含私人信息的预编译 PDF。

本地运行 `bash scripts/test-build.sh` 同样会把三个通过检查的 PDF 保存到 `dist/`，编译过程中产生的临时文件会自动清理。
