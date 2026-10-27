# MES306 · Atomic-Level Semiconductor Materials Simulation

MES306TC 原子级材料模拟课程学习资料与中文图文笔记。

**开始阅读：[第一周学习笔记目录](Week_One/学习笔记/README.md)**

| 周次 | 讲次 | 主题 | 笔记入口 |
|---|---|---|---|
| Week One | Lecture 1–4 | 课程导论、波函数与密度算符、哈密顿量与基组、周期势与 SOC | [Week_One/学习笔记](Week_One/学习笔记/README.md) |
| Week Two | Lecture 5–8 | 晶体几何、倒空间与布里渊区、对称性与能带、结构建模与 HPC | [Week_Two/学习笔记](Week_Two/学习笔记/README.md) |
| Week Three | Lecture 9–12 | 紧束缚与 Slater–Koster、Bloch 和、代码架构、石墨烯能带与开隙 | [Week_Three/学习笔记](Week_Three/学习笔记/README.md) |
| Week Four | Lecture 13–16 | 态密度、k 点采样、Gaussian/Lorentz 展宽与四面体法、石墨烯 DOS | [Week_Four/学习笔记](Week_Four/学习笔记/README.md) |
| Week Five | Lecture 17–20 | SOC（本征/Rashba/Dresselhaus）、Berry 相位与 Z₂、Wilson loop | [Week_Five/学习笔记](Week_Five/学习笔记/README.md) |
| Week Six | Lecture 21–24 | 线性响应与 Kubo 公式、Kubo–Greenwood 电导率及应用 | [Week_Six/学习笔记](Week_Six/学习笔记/README.md) |
| Week Seven | Lecture 25–28 | Landauer–Büttiker、NEGF、非弹性散射与量子器件 | [Week_Seven/学习笔记](Week_Seven/学习笔记/README.md) |

## 课件截图

![第一周讲义：13周课程内容框架](Week_One/学习笔记/课件截图/Lecture_One/page-30.png)

## 中文解释

本仓库整理第 1–7 周共 28 份讲义，每周配一套 Markdown 笔记。第一周 8 份；第二至七周每周 9 份，比第一周多一份 `08_代码导读.md`，逐段解读课上的 Fortran 程序：

```text
Week_X/
├── Lecture_*.pdf            原讲义（Week_Three 另存原始 .pptx，PDF 由 PowerPoint 转换）
├── Codes/                   课程 Fortran 代码、输入文件、教师输出数据与结果图（第二周起）
└── 学习笔记/
    ├── README.md            本周目录、学习顺序、延伸书目
    ├── 01–04_*.md           每讲一份
    ├── 05_公式与术语速查.md
    ├── 06_复习题与参考答案.md
    ├── 07_讲义勘误与易错点.md
    ├── 08_代码导读.md        （第二周起）
    └── 课件截图/             整页渲染 PNG 与 来源索引.json
```

课程主线：

```text
晶体结构与倒空间（W2）
  → 紧束缚哈密顿量 H(k) 与能带（W3）
  → 态密度 DOS（W4）
  → 自旋轨道耦合与拓扑不变量（W5）
  → 线性响应电导率 Kubo–Greenwood（W6）
  → 器件输运 Landauer / NEGF（W7）
```

## 原理深入

每个知识模块按 **课件截图 → 中文解释 → 原理深入 → Ref** 组织：

1. 对照原图理解课件在解决什么问题。
2. 阅读中文说明，确认符号、基底与物理含义。
3. 学习补充推导、适用条件与可手算的验证方法。
4. 沿 Ref 回到原 PDF 页码，或查阅延伸参考资料。

截图宽 1920 像素，共 522 张，覆盖全部讲义除封面、结束页外的页面。笔记按主题选图，原图中的笔误不做涂改，而在正文和勘误页说明。各周 `08_代码导读.md` 对课程代码的归一化、单位与已知问题做了核验（例如第四周三种 DOS 展宽相差自旋因子 2、第五周次近邻距离计算、第六周电导率单位），供完成实验与课程作业时参考。公式使用 Markdown + LaTeX；可在 GitHub 或支持数学公式的编辑器中阅读。

## Ref

- **原课件**：Kenan Song，MES306TC，*Atomic-Level Materials Simulation*；[课程框架所在页：Lecture One，第 30 页](Week_One/Lecture_One.pdf#page=30)。
- **详细引用与延伸书目**：见各周 `学习笔记/README.md`。
- **截图溯源**：各周 `学习笔记/课件截图/来源索引.json` 记录 PDF 的 SHA-256 与截图页码，例如[第一周](Week_One/学习笔记/课件截图/来源索引.json)。
- **课程补充文献**：第三、六、七周讲义附带的期刊论文未随仓库分发，完整引用列在对应周的 README 中。

> 中文笔记与补充推导不等于教师原话；复习题并非官方作业，勘误并非教师官方勘误。原课件及其中引用的图表、研究资料归相应权利人所有；本仓库未对这些材料授予额外许可。
