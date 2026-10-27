# MES306TC · 第六周图文学习笔记

课程：**Atomic-Level Materials Simulation（原子级材料模拟）** · 教师：Kenan Song

原始资料：4 份 PDF，共 **69 页**（Lecture Twenty-One 15 页、Twenty-Two 17 页、Twenty-Three 31 页、Twenty-Four 6 页），外加 `Codes/` 中的 Fortran 紧束缚 Kubo–Greenwood 程序与计算结果。以下 9 份 Markdown 中的知识模块均采用「课件截图 → 中文解释 → 原理深入 → Ref」结构。

> **截图是原讲义整页渲染，不是重新制作的幻灯片。** 原图中的笔误保留，正文单独解释正确写法。所有页码均为含封面的 PDF 物理页码。中文解释为整理，原理深入含补充推导与数值核验，不能把二者都当作教师原话。第 23 讲中引用的研究论文只按课件内容归纳；论文原文因版权未随仓库分发。

## 1. 怎样使用这套笔记？

### 课件截图

![Lecture Twenty-One 第2页：线性响应与Kubo公式的四部分结构](课件截图/Lecture_Twenty_One/page-02.png)

*第六周从“外场如何扰动平衡态”出发，一路推到可以写进程序的 Kubo–Greenwood（KG）迹公式，最后用石墨烯程序给出 σ(E) 曲线。*

### 中文解释

前几周得到了石墨烯的能带与 DOS；本周回答最后一个实验目标：**电导率怎么从哈密顿量算出来**。核心链条是：弱电场 → 一阶密度矩阵 → 电流-电流关联函数（Kubo 公式）→ 非相互作用电子的本征态/格林函数表示（Kubo–Greenwood 公式）→ k 网格上的数值求和。

| 顺序 | 文件 | 内容 |
|---|---|---|
| 0 | 本页 README | 阅读方法、计算链、参考书目和学习记录 |
| 1 | [01_线性响应与Kubo公式.md](01_线性响应与Kubo公式.md) | Lecture 21：矢势耦合、Liouville 方程、Kubo 公式、因果性、KG 公式 |
| 2 | [02_KG公式的物理图像与数值诊断.md](02_KG公式的物理图像与数值诊断.md) | Lecture 22：迹的含义、格林函数、谱函数与寿命、局域化、收敛诊断 |
| 3 | [03_复杂材料中的电导率应用.md](03_复杂材料中的电导率应用.md) | Lecture 23：光学电导、磁光、应变/缺陷各向异性、Anderson 局域化、DMFT |
| 4 | [04_KG方法的参数与计算结果.md](04_KG方法的参数与计算结果.md) | Lecture 24：输入参数、程序入口、本征石墨烯 σ(E) 结果 |
| 5 | [05_公式与术语速查.md](05_公式与术语速查.md) | 规范形式的公式、条件与英文术语 |
| 6 | [06_复习题与参考答案.md](06_复习题与参考答案.md) | 14 道自编题，每题配原图、题意、解析与来源 |
| 7 | [07_讲义勘误与易错点.md](07_讲义勘误与易错点.md) | 原图证据、问题、正确写法与核验理由 |
| 8 | [08_代码导读.md](08_代码导读.md) | `TIGHTBINDINGFORGRAPHENE.f90` 逐段解读、单位换算与已复现的数值检查 |

### 原理深入

本周的计算链：

```text
H0（石墨烯最近邻紧束缚） + 弱电场 E(t) = −∂A/∂t
  ↓ V(t) = −∫ J·A d³r，密度矩阵一阶微扰 ρ = ρ0 + ρ1
⟨J⟩ 线性依赖于 A（或 E）
  ↓ 傅里叶变换，ω → ω + iη（因果性）
Kubo 公式：σ_μν(ω) 由平衡态电流-电流关联函数决定
  ↓ 非相互作用电子 + 本征态展开 + ω → 0
Kubo–Greenwood：σ ∝ ∫dE (−∂f/∂E) Tr[v δ(E−H) v δ(E−H)]
  ↓ δ(E−H) → −(G^R − G^A)/(2πi)，η 有限
程序：k 网格 × 本征值 × 速度矩阵元 × 洛伦兹展宽 → σxx(E)、σyy(E)
```

两个贯穿全周的要点：

1. **η 有两重身份**：数学上保证傅里叶积分收敛与因果性；物理上可看作散射率（寿命的倒数）。在完美晶体的 KG 计算里，远离 Dirac 点的 σ 近似正比于 $1/\eta$，所以结果依赖于 η 的取值，不能把 η 当作可随意取的“小量”。
2. **讲义中的 KG 前置系数需要修正**：若 $G^R-G^A=-2\pi i\,\delta(E-H)$，则 $\operatorname{Tr}\{v(G^R-G^A)v(G^R-G^A)\}=-4\pi^2\operatorname{Tr}[v\delta v\delta]$，不能直接沿用 $\pi e^2\hbar/V$。详见 [07 勘误第 4 条](07_讲义勘误与易错点.md#4-kubogreenwood-公式的前置系数)。

阅读每个模块建议：**看截图 → 读中文解释 → 读原理深入 → 查 Ref**；遇到公式先做量纲与符号检查。

### Ref

- **原课件**：Kenan Song，[Lecture Twenty-One，PDF 第 2 页](../Lecture_Twenty_One.pdf#page=2)。
- **原始文件**：[Lecture Twenty-One](../Lecture_Twenty_One.pdf) · [Lecture Twenty-Two](../Lecture_Twenty_Two.pdf) · [Lecture Twenty-Three](../Lecture_Twenty_Three.pdf) · [Lecture Twenty-Four](../Lecture_Twenty_Four.pdf) · [Codes 目录](../Codes/)。原 PDF 与代码未修改。
- **来源记录**：[截图来源索引](课件截图/来源索引.json)，记录源 PDF 的 SHA-256、总页数及截图页码。

## 2. 学习顺序与完成标准

### 课件截图

![Lecture Twenty-Four 第5页：本征石墨烯沿x、y方向的电导率计算结果](课件截图/Lecture_Twenty_Four/page-05.png)

*本周的终点：读懂这张图的横轴、纵轴、形状和单位，并知道它是怎么由程序算出来的。*

### 中文解释

建议顺序：第 21 讲（推导主线）→ 第 22 讲（物理图像与诊断）→ 第 24 讲 + 代码导读（落地）→ 第 23 讲（应用拓展）→ 复习题 → 勘误复核。第 23 讲的论文案例偏阅读性质，可放在掌握程序之后。

参考自学时间（仅供安排）：第 21 讲约 120 分钟，第 22 讲约 60 分钟，代码导读约 90 分钟，第 23 讲约 60 分钟，复习与勘误约 60 分钟。

### 原理深入

把“学会”定义成能独立完成以下任务：

- [ ] 由 $i\hbar\dot\rho=[H,\rho]$ 推出 $\rho_1(t)$ 的积分表达式，并说明哪一项是二阶小量。
- [ ] 解释为什么 $[V,\rho_0]=0$ 时不存在线性响应。
- [ ] 写出正确的 Kubo 公式（典型关联形式），并指出讲义版本的问题。
- [ ] 说明 $\omega\to\omega+i\eta$ 与因果性、Kramers–Kronig 关系的联系。
- [ ] 证明 $G^R-G^A\to-2\pi i\,\delta(E-H)$，并据此写出前置系数正确的 KG 公式。
- [ ] 区分 KG 求和中的带内（$j=k$）与带间（$j\neq k$）贡献。
- [ ] 解释为何完美晶体中 σ 远离 Dirac 点时 $\propto1/\eta$，而 Dirac 点处趋于 $\sim e^2/h$ 量级的有限值。
- [ ] 说出本程序输出没有除以 k 点数、没有 $e^2/\hbar$、且“面积”用了 $\mathbf a_1\cdot\mathbf a_2$ 这三件事，并把输出换算成 $e^2/h$。
- [ ] 列出至少四项收敛/物理一致性检查（k 网格、η、系统尺寸、归一化、线性区）。
- [ ] 概括第 23 讲每个案例“算了什么、展示了什么”，并区分 DC 与光学电导。

| 日期 | 已完成模块 | 能否独立推导 | 疑问与下一步 |
|---|---|---|---|
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |

### Ref

- **原课件**：[Lecture Twenty-Four，PDF 第 3–5 页](../Lecture_Twenty_Four.pdf#page=5)。
- **配套练习**：[14 道复习题](06_复习题与参考答案.md)。题目为学习整理自编，不是官方作业。

## 3. 如何核对公式与使用 Ref？

### 课件截图

![Lecture Twenty-One 第13页：格林函数实现与KG公式，前置系数需要核对](课件截图/Lecture_Twenty_One/page-13.png)

*示例：本页由 δ 函数形式“换写”为格林函数形式时保留了同一个前置系数，但两者相差因子 $-1/(4\pi^2)$。截图忠实保留原文，不表示原式已通过核验。*

### 中文解释

Ref 区分三种来源：

- **原课件**：本地 PDF 的页码链接。
- **推导依据 / 配套笔记**：指向正确公式、核验步骤或代码行号。
- **延伸阅读**：教材与论文，用于系统学习；未据此虚构页码或章节号。

本周笔记的约定：单粒子哈密顿量 $H$、体积（二维时为面积）$\Omega$ 或 $V$；电子电荷 $-e$（$e>0$）；$\eta>0$；$f$ 为 Fermi–Dirac 分布；“每自旋”结果未乘自旋简并 2。讲义中 $V$ 同时表示体积与微扰，笔记在可能混淆处改用 $\Omega$ 表示体积。

### 原理深入

本周最有效的核验手段：

- **代换检查**：把 $G^R-G^A=-2\pi i\delta$ 代入，看前置系数是否自洽。
- **量纲**：二维电导率单位为 S（即“每方块”的电导），三维为 S/m；$e^2/h\approx3.874\times10^{-5}$ S。
- **符号**：耗散要求 $\operatorname{Re}\sigma_{\mu\mu}(\omega)\ge0$。
- **对称性**：石墨烯有 $C_3$ 对称性，二维二阶张量因此各向同性，$\sigma_{xx}=\sigma_{yy}$、$\sigma_{xy}=0$（无磁场时）。
- **极限**：$\eta$ 改变一倍时，金属区 σ 是否近似反比变化；Dirac 点处是否接近 $4e^2/(\pi h)$（含自旋）。
- **复现**：本笔记用独立 Python 脚本按程序算法重算了若干能量点，与 `Conductivity_along_x_axis.dat` 一致到全部有效数字，详见 [08 代码导读](08_代码导读.md)。

截图覆盖四份讲义除封面与结束页外的 **61 页**，保存在 `课件截图/Lecture_*/page-NN.png`。PDF 的 `#page=` 跳转是否生效取决于阅读器，但 Ref 中均写出页码。

### Ref

- **原课件**：[Lecture Twenty-One，PDF 第 13 页](../Lecture_Twenty_One.pdf#page=13)。
- **核对记录**：[讲义勘误与易错点](07_讲义勘误与易错点.md)。它是学习记录，不是教师官方勘误。
- **外部资料使用说明**：下列教材为延伸书目，未逐章核读；论文条目的作者、期刊、卷号与 DOI 已对照论文首页核对。

#### 延伸参考书目

<a id="ref-mahan"></a>
**[MAHAN]** Gerald D. Mahan, *Many-Particle Physics*, 3rd ed., Kluwer Academic/Plenum Publishers, 2000。检索主题：线性响应、Kubo 公式、电流-电流关联、格林函数与谱函数。

<a id="ref-bf"></a>
**[BF]** Henrik Bruus & Karsten Flensberg, *Many-Body Quantum Theory in Condensed Matter Physics: An Introduction*, Oxford University Press, 2004。检索主题：线性响应理论、Kubo 公式、推迟格林函数、电导率与杂质散射。

<a id="ref-am"></a>
**[AM]** Neil W. Ashcroft & N. David Mermin, *Solid State Physics*, Holt, Rinehart and Winston, 1976。检索主题：Drude 模型、半经典输运与弛豫时间近似、能带速度。

<a id="ref-datta"></a>
**[DATTA]** Supriyo Datta, *Electronic Transport in Mesoscopic Systems*, Cambridge University Press, 1995。检索主题：格林函数、自能与展宽、弱局域化与相干输运。

<a id="ref-kubo"></a>
**[KUBO57]** Ryogo Kubo, “Statistical-Mechanical Theory of Irreversible Processes. I. General Theory and Simple Applications to Magnetic and Conduction Problems”, *J. Phys. Soc. Jpn.* **12**, 570–586 (1957), DOI: 10.1143/JPSJ.12.570。Kubo 公式原始文献。

<a id="ref-greenwood"></a>
**[GREENWOOD58]** D. A. Greenwood, “The Boltzmann Equation in the Theory of Electrical Conduction in Metals”, *Proc. Phys. Soc.* **71**, 585–596 (1958), DOI: 10.1088/0370-1328/71/4/306。Kubo–Greenwood 公式来源之一。

<a id="ref-ludwig"></a>
**[LUDWIG94]** A. W. W. Ludwig, M. P. A. Fisher, R. Shankar & G. Grinstein, “Integer quantum Hall transition: An alternative approach and exact results”, *Phys. Rev. B* **50**, 7526 (1994), DOI: 10.1103/PhysRevB.50.7526。检索主题：Dirac 费米子的最小电导率 $\sim e^2/h$。

<a id="ref-castro"></a>
**[CASTRO09]** A. H. Castro Neto, F. Guinea, N. M. R. Peres, K. S. Novoselov & A. K. Geim, “The electronic properties of graphene”, *Rev. Mod. Phys.* **81**, 109 (2009), DOI: 10.1103/RevModPhys.81.109。检索主题：石墨烯紧束缚模型、Dirac 点、输运与光学电导。

#### 课程补充文献（未随仓库分发）

第 23 讲引用了以下 7 篇论文。教师随课件提供了 PDF，但因版权原因**未放入本公开仓库**；如需阅读请通过 DOI 或学校图书馆获取。条目信息已对照各论文首页核对。

<a id="ref-gusynin"></a>
**[GSC07]** V. P. Gusynin, S. G. Sharapov & J. P. Carbotte, “Magneto-optical conductivity in graphene”, *J. Phys.: Condens. Matter* **19**, 026222 (2007)（在线发表于 2006-12-15），DOI: 10.1088/0953-8984/19/2/026222。对应第 23 讲第 8–9 页。

<a id="ref-kuzmenko"></a>
**[KUZ08]** A. B. Kuzmenko, E. van Heumen, F. Carbone & D. van der Marel, “Universal Optical Conductance of Graphite”, *Phys. Rev. Lett.* **100**, 117401 (2008), DOI: 10.1103/PhysRevLett.100.117401。对应第 23 讲第 10–11 页。

<a id="ref-lic"></a>
**[LC13]** Zhou Li & J. P. Carbotte, “Magneto-optical conductivity in a topological insulator”, *Phys. Rev. B* **88**, 045414 (2013), DOI: 10.1103/PhysRevB.88.045414。对应第 23 讲第 12–14 页。

<a id="ref-pellegrino"></a>
**[PAP10]** F. M. D. Pellegrino, G. G. N. Angilella & R. Pucci, “Strain effect on the optical conductivity of graphene”, *Phys. Rev. B* **81**, 035411 (2010), DOI: 10.1103/PhysRevB.81.035411。对应第 23 讲第 16–18 页。

<a id="ref-lherbier"></a>
**[LHE12]** Aurélien Lherbier, Simon M.-M. Dubois, Xavier Declerck, Yann-Michel Niquet, Stephan Roche & Jean-Christophe Charlier, “Transport properties of graphene containing structural defects”, *Phys. Rev. B* **86**, 075402 (2012), DOI: 10.1103/PhysRevB.86.075402。对应第 23 讲第 19–21 页。

<a id="ref-fan"></a>
**[FUH14]** Zheyong Fan, Andreas Uppstu & Ari Harju, “Anderson localization in two-dimensional graphene with short-range disorder: One-parameter scaling and finite-size effects”, *Phys. Rev. B* **89**, 245422 (2014), DOI: 10.1103/PhysRevB.89.245422。对应第 23 讲第 24–27 页。

<a id="ref-freericks"></a>
**[FRE04]** J. K. Freericks, “Dynamical mean-field theory for strongly correlated inhomogeneous multilayered nanostructures”, *Phys. Rev. B* **70**, 195342 (2004), DOI: 10.1103/PhysRevB.70.195342。对应第 23 讲第 28–30 页。
