# MES306TC · 第四周图文学习笔记

课程：**Atomic-Level Materials Simulation（原子级材料模拟）** · 教师：Kenan Song

原始资料：4 份 PDF（Lecture Thirteen–Sixteen），共 **74 页**；另有 `Codes/` 中教师提供的石墨烯紧束缚 DOS 示例程序。以下 9 份 Markdown 均采用「课件截图 → 中文解释 → 原理深入 → Ref」结构。

> **截图是原讲义整页渲染，不是重新制作的幻灯片。** 原图中的笔误保留，正文单独解释正确写法。所有页码均为含封面的 PDF 物理页码。中文解释为整理，原理深入含补充推导与本笔记作者的数值核验，不能把二者都当作教师原话。凡标注〔补充〕的内容都不是课件原文。

## 1. 怎样使用这套笔记？

### 课件截图

![Lecture Fourteen 第7页：TB-DOS 计算的四个步骤](课件截图/Lecture_Fourteen/page-07.png)

*第四周的主线就是这四步：撒 k 点 → 对角化 → 统计 → 归一化。后面两讲只是把“统计”这一步做得更好。*

### 中文解释

第四周讨论**态密度（Density of States, DOS）**：如何把布里渊区里成千上万个 $E_n(\mathbf k)$ 压缩成一条只依赖能量的曲线 $g(E)$，以及如何在计算机上可靠地算出这条曲线。

| 顺序 | 文件 | 内容 |
|---|---|---|
| 0 | 本页 README | 阅读方法、学习顺序、参考书目和学习记录 |
| 1 | [01_态密度基础与VanHove奇点.md](01_态密度基础与VanHove奇点.md) | Lecture Thirteen：DOS 定义、几何公式、Van Hove 奇点、维度、Fermi–Dirac、PDOS、展宽的引入 |
| 2 | [02_k点采样与TB-DOS四步流程.md](02_k点采样与TB-DOS四步流程.md) | Lecture Fourteen：Monkhorst–Pack 网格、对角化、直方图统计、归一化、PDOS |
| 3 | [03_展宽方法与四面体法.md](03_展宽方法与四面体法.md) | Lecture Fifteen：Gaussian / Lorentz / Methfessel–Paxton 展宽、四面体（三角形）法、方法选择 |
| 4 | [04_石墨烯DOS编程与课程作业.md](04_石墨烯DOS编程与课程作业.md) | Lecture Sixteen：石墨烯 DOS 程序流程、输入、结果图、作业要求及与 CW1 文件的差异 |
| 5 | [05_公式与术语速查.md](05_公式与术语速查.md) | 对照原图记公式、条件及英文术语 |
| 6 | [06_复习题与参考答案.md](06_复习题与参考答案.md) | 每题配原图、题意说明、解析与来源 |
| 7 | [07_讲义勘误与易错点.md](07_讲义勘误与易错点.md) | 原图证据、问题、正确写法与核验理由 |
| 8 | [08_代码导读.md](08_代码导读.md) | `Codes/TIGHTBINDINGFORGRAPHENE.f90` 逐段导读、输入输出、编译运行与数值核验 |

### 原理深入

本周四讲可以串成一条计算链：

```text
实空间：晶格矢量、原子位置、跃迁 t_ij(R)
  ↓ 倒格矢 b_i，均匀撒满整个 BZ 的 k 网格（不是高对称路径）
每个 k：构造厄米 H(k) → ZHEEV 对角化 → E_n(k)（与本征矢 c）
  ↓ 把 δ[E − E_n(k)] 变成可计算的东西
直方图 / Gaussian / Lorentz / MP 展宽 / 四面体（2D 为三角形）线性插值
  ↓ 归一化：除以 N_k（和 ΔE），并约定是否乘自旋因子 2
DOS(E)、PDOS(E)，再结合 f(E,T) 得到载流子数、比热、磁化率……
```

**本周最需要警惕的一件事是“自旋因子 2 到底算不算”**：Lecture Thirteen 第 5 页强调不要忘记 $\gamma=2$；Lecture Fourteen 第 13 页却说石墨烯 DOS 的积分“必须等于 2.0”（即每个轨道只计 1 个态、不含自旋）；教师示例代码里 Gaussian 与四面体结果含因子 2，而 Lorentz 结果不含。三者各自都能自洽，但**不能混用**。详见 [07 勘误第 1 节](07_讲义勘误与易错点.md) 与 [08 代码导读](08_代码导读.md)。

阅读每个模块建议做四件事：

1. **看截图**：找到标题、坐标轴、公式中每个符号的含义。
2. **读中文解释**：回答“这页在解决什么问题？”
3. **读原理深入**：回答“为什么成立？如何推导？什么时候失效？”
4. **查 Ref**：回到指定 PDF 页；需要更系统理解时查延伸书目。

### Ref

- **原课件**：Kenan Song，[Lecture Fourteen，PDF 第 7 页](../Lecture_Fourteen.pdf#page=7)。
- **原始文件**：[Lecture Thirteen](../Lecture_Thirteen.pdf)（21 页）· [Lecture Fourteen](../Lecture_Fourteen.pdf)（21 页）· [Lecture Fifteen](../Lecture_Fifteen.pdf)（23 页）· [Lecture Sixteen](../Lecture_Sixteen.pdf)（9 页）。原 PDF 未修改。
- **代码**：[`Codes/`](../Codes/)，未修改。
- **来源记录**：[截图来源索引](课件截图/来源索引.json)，记录源 PDF 的 SHA-256、总页数及截图页码。

## 2. 学习顺序与完成标准

### 课件截图

![Lecture Sixteen 第5页：三种方法得到的石墨烯 DOS](课件截图/Lecture_Sixteen/page-05.png)

*学完本周，应能解释这三张图为什么形状相同、纵轴量级却不同（0.72 / 0.34 / 0.95）。*

### 中文解释

建议顺序：01 DOS 基础 → 02 计算流程 → 03 展宽与四面体 → 04 石墨烯编程 → 08 代码导读 → 06 复习题 → 07 勘误复核。以下自学时间仅供参考：01 约 70 分钟，02 约 50 分钟，03 约 70 分钟，04 约 30 分钟，08 约 60 分钟（建议边读边打开源码），复习约 45 分钟。

课程作业（CW1）以官方作业文件为准；第 16 讲幻灯片的作业描述与 CW1 文件在语言、任务范围上不一致，见 [04 第 5 节](04_石墨烯DOS编程与课程作业.md)。

### 原理深入

把“学会”定义为可以亲手完成：

- [ ] 从 $g(E)=\frac1V\sum_{n\mathbf k}\delta[E-E_n(\mathbf k)]$ 推出 $\frac{\gamma}{(2\pi)^3}\int_{S(E)}\frac{dS}{|\nabla_{\mathbf k}E|}$。
- [ ] 推导 3D、2D、1D 自由电子 DOS，并说清楚是否含自旋因子。
- [ ] 说出 Van Hove 临界点 $M_0$–$M_3$ 的含义，并解释石墨烯 DOS 在 $\pm|t|$ 处的尖峰来自 M 点鞍点。
- [ ] 写出 Monkhorst–Pack 公式，解释为什么 DOS 不能用高对称路径的 k 点。
- [ ] 写出直方图的 bin 指标公式与归一化 $\text{counts}/(N_k\Delta E)$，并用积分检查归一化。
- [ ] 证明 Gaussian 与 Lorentz 核的面积为 1，区分 $\sigma$、标准差、FWHM、HWHM。
- [ ] 推导 2D 三角形法在一个三角形内的 DOS 公式。
- [ ] 读懂示例 Fortran 程序的每个 DOS 分支，指出各自的归一化因子。
- [ ] 能按照 CW1 文件，说明 pristine 与 gapped 两种情况分别需要哪些图和代码。

| 日期 | 已完成模块 | 能否独立推导 | 疑问与下一步 |
|---|---|---|---|
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |

### Ref

- **原课件**：[Lecture Sixteen，PDF 第 5 页](../Lecture_Sixteen.pdf#page=5)、[第 7–8 页](../Lecture_Sixteen.pdf#page=7)。
- **配套练习**：[15 道复习题](06_复习题与参考答案.md)。这些题目为学习整理自编，不是官方作业。

## 3. 如何核对公式与使用 Ref？

### 课件截图

![Lecture Thirteen 第16页：Fermi–Dirac 分布示意图，需要核对台阶方向](课件截图/Lecture_Thirteen/page-16.png)

*示例：此图把 $T=0$ 的分布画成“低于 $E_F$ 为 0、高于 $E_F$ 为 1”，与图旁公式矛盾。截图忠实保留原文，不表示原图已经通过核验。*

### 中文解释

笔记的 Ref 区分三种来源：

- **原课件**：直接定位本知识点在本地 PDF 中的位置。
- **推导依据 / 配套笔记**：指向正确公式、例题或核验步骤。
- **延伸阅读**：推荐教材或原始论文，帮助进一步学习；不是声称已逐页读完这些外部资料，也未虚构页码。

### 原理深入

DOS 相关公式最常见的错误来自**归一化与约定**，可用以下方法快速核验：

- **代入极限**：$f(E,T=0)$ 在 $E<\mu$ 时应为 1（$e^{-\infty}+1=1$）。
- **积分守恒**：任何展宽核 $\int\delta_\sigma(x)dx=1$；DOS 在全能量范围积分应等于“每胞态数”（是否乘 2 取决于自旋约定）。
- **量纲**：$\Omega_k\propto k^3\propto E^{3/2}$，所以 $(2m^*E/\hbar^2)$ 的指数必须是 $3/2$，不是 3。
- **数值复算**：本笔记对教师给出的 `DOS_*.dat` 用梯形法积分，并用独立 Python 小脚本估算石墨烯在 $[-5,5]$ eV 内的态占比，以核对代码的归一化因子（见 [08](08_代码导读.md)）。

截图覆盖四份讲义除封面与结束页外的 **66 页**，保存在 `课件截图/Lecture_*/page-XX.png`；各笔记按主题选图。复制或分享笔记时请连同 `课件截图/` 一起保留。

### Ref

- **原课件**：[Lecture Thirteen，PDF 第 15–16 页](../Lecture_Thirteen.pdf#page=16)。
- **核对记录**：[讲义勘误与易错点](07_讲义勘误与易错点.md)。它是学习记录，不是教师官方勘误。
- **外部资料使用说明**：下列教材与论文为延伸书目，未逐章核读；未据此虚构页码。

#### 延伸参考书目与文档索引

<a id="ref-ss1"></a>
**[SS1]** Neil W. Ashcroft & N. David Mermin, *Solid State Physics*, Holt, Rinehart and Winston, 1976。检索主题：能级密度、Van Hove 奇点、Fermi–Dirac 统计、Sommerfeld 展开（电子比热）、Pauli 顺磁。

<a id="ref-ss2"></a>
**[SS2]** Charles Kittel, *Introduction to Solid State Physics*, 8th ed., Wiley, 2005。检索主题：自由电子气、态密度、电子比热、半导体能隙。

<a id="ref-es1"></a>
**[ES1]** Richard M. Martin, *Electronic Structure: Basic Theory and Practical Methods*, Cambridge University Press, 2004。检索主题：布里渊区积分、特殊 k 点、四面体法、展宽。

<a id="ref-vh"></a>
**[VH53]** L. Van Hove, “The Occurrence of Singularities in the Elastic Frequency Distribution of a Crystal”, *Phys. Rev.* **89**, 1189 (1953)。Van Hove 奇点的原始论文（讲义 Lecture Thirteen 第 8 页所称“1953”）。

<a id="ref-mp76"></a>
**[MP76]** H. J. Monkhorst & J. D. Pack, “Special points for Brillouin-zone integrations”, *Phys. Rev. B* **13**, 5188 (1976)。Monkhorst–Pack 网格。

<a id="ref-mp89"></a>
**[MP89]** M. Methfessel & A. T. Paxton, “High-precision sampling for Brillouin-zone integration in metals”, *Phys. Rev. B* **40**, 3616 (1989)。Methfessel–Paxton 展宽。

<a id="ref-bl94"></a>
**[BL94]** P. E. Blöchl, O. Jepsen & O. K. Andersen, “Improved tetrahedron method for Brillouin-zone integrations”, *Phys. Rev. B* **49**, 16223 (1994)。四面体法公式与 Blöchl 修正。

<a id="ref-gr09"></a>
**[GR09]** A. H. Castro Neto, F. Guinea, N. M. R. Peres, K. S. Novoselov & A. K. Geim, “The electronic properties of graphene”, *Rev. Mod. Phys.* **81**, 109 (2009)。石墨烯紧束缚能带、Dirac 锥附近线性 DOS、Van Hove 奇点。

<a id="ref-kpm"></a>
**[KPM]** A. Weiße, G. Wellein, A. Alvermann & H. Fehske, “The kernel polynomial method”, *Rev. Mod. Phys.* **78**, 275 (2006)。Lecture Fourteen 第 20 页提到的 KPM。

<a id="ref-lapack"></a>
**[LAPACK]** [LAPACK Users' Guide（netlib）](https://www.netlib.org/lapack/lug/)。用于核对 `ZHEEV` / `ZHEEVD` 的参数、只读取上或下三角等约定。
