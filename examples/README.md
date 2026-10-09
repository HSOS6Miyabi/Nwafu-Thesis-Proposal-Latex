# 排版用例手册

本目录提供独立可编译的排版示例，所用功能与写法依据压缩包 2 的 nwafuthesis-l3 `demo/Master-Academic`。该手册沿用相同文档类、字体和图表格式；它不属于正式开题报告，因而不会改变正文六章结构。

## 编译

在仓库根目录执行：

```bash
latexmk -xelatex examples/main.tex
# 或直接生成 dist/usage-examples.pdf
bash scripts/test-examples.sh
```

GitHub Actions 会同时编译本手册和三种开题报告配置，将 PDF 上传到 Artifacts。

## 用例索引

| 排版功能 | 演示位置或命令 |
| --- | --- |
| PDF、PNG、JPG 插图，图题与交叉引用 | `contents/figures-tables.tex` 的 `figure`、`\includegraphics`、`\label` |
| 子图、Ti\textit{k}Z 技术路线 | `subfigure`、`tikzpicture` |
| 中英文双语图表题注 | `\bicaption` |
| 三线表 | `tabular`、`\toprule`、`\midrule`、`\bottomrule` |
| CSV 自动生成表格 | `csvsimple-l3`、`\csvreader` |
| 横向页面与宽表格 | `landscape` |
| 数值、角度、国际单位 | `siunitx`、`\num`、`\SI`、`\ang` |
| 行间公式、多行公式、符号解释 | `contents/math-citations.tex` 的 `equation`、`aligned`、`\eqref` |
| 定义、定理、证明 | `definition`、`theorem`、`proof` |
| 著者－出版年引用、多文献引用 | `\cite`、`\textcite`、`\parencite` 和 Biber |
| `tabularray` 合并单元格、跨页长表格、表格注释 | 下方参考代码 |

图片采用 TeX Live 的 `mwe` 宏包提供的 `example-image-a`、`example-image-b`，CSV 和 Bib 文件均为通用示例，没有使用私人照片、姓名或学号。

## tabularray 排版代码

压缩包 2 还包含 `tblr`、`longtblr`、`talltblr` 等功能的实例。正式正文使用 `nwafuthesis` 文档类，已经预加载 `tabularray`；下面的代码可直接复制到对应章节并修改内容。

### 合并单元格与三线表

```latex
\begin{table}[htbp]
  \centering
  \caption{实验指标汇总}\label{tab:metrics}
  \begin{tblr}{
    colspec = lccc,
    cell{1}{1} = {r=2}{},
    cell{1}{2} = {c=3}{},
    hline{2} = {2-4}{},
    hline{3} = {solid},
  }
    类别 & 指标统计 & & \\
         & 最小值 & 均值 & 最大值 \\
    A & 1 & 2 & 3 \\
    B & 2 & 3 & 4 \\
  \end{tblr}
\end{table}
```

### 跨页长表格

```latex
\begin{longtblr}[
  theme = fancy,
  caption = {跨页数据表},
  label = {tab:long-example},
  note{a} = {数据仅作演示。},
  remark{来源} = {通用示例数据。},
]{
  colspec = {X[c] X[c] X[c]},
  rowhead = 1,
  hline{2} = {solid},
}
  序号 & 数值一 & 数值二 \\
  1 & 10 & 20 \\
  2 & 12 & 24 \\
  3 & 14 & 28 \\
\end{longtblr}
```

### 带表注的浮动表格

```latex
\begin{table}[htbp]
  \centering
  \begin{talltblr}[
    theme = fancy,
    caption = {表注示例},
    label = {tab:notes},
    note{a} = {示例说明。},
    remark{来源} = {通用测试数据。},
  ]{colspec={lll}, hline{2}={solid}}
    项目 & 数值 & 说明 \\
    A & 12\TblrNote{a} & 示例 \\
    B & 14 & 示例 \\
  \end{talltblr}
\end{table}
```

## 编写开题报告时的使用方式

将上述源代码复制到 `contents/` 中相应章节，并替换示例图像、实验数据与引用。正式参考文献写入根目录的 `bib/references.bib`。使用 `\label` 及 `\ref`、`\eqref` 建立图表和公式的交叉引用，使用 `\cite` 和 Biber 管理文献。跨页 `longtblr` 应直接使用，不需要再嵌套 `table` 浮动体。

本手册参考的功能和写法来自 [nwafuthesis-l3](https://gitee.com/nwafu_nan/nwafuthesis-l3)（木兰宽松许可证第 2 版）。示例文本和数据均采用通用内容。
