# MES306TC · 第七周图文学习笔记

课程：**Atomic-Level Materials Simulation（原子级材料模拟）** · 教师：Kenan Song

原始资料：4 份 PDF（Lecture Twenty-Five–Twenty-Eight），共 **85 页**；另有 `Codes/` 中教师提供的石墨烯相干 NEGF 示例程序及其输出。以下 9 份 Markdown 均采用「课件截图 → 中文解释 → 原理深入 → Ref」结构。

> **截图是原讲义整页渲染，不是重新制作的幻灯片。** 原图中的笔误保留，正文单独解释正确写法。所有页码均为含封面的 PDF 物理页码。中文解释为整理，原理深入含补充推导与本笔记作者的数值核验，不能把二者都当作教师原话。凡标注〔补充〕的内容都不是课件原文。第 27 讲引用的研究论文已对照原文核对，但论文本身受版权限制**未随仓库分发**。

## 1. 怎样使用这套笔记？

### 课件截图

![Lecture Twenty-Six 第2页：NEGF基础三部分提纲](课件截图/Lecture_Twenty-Six/page-02.png)

*本周的主线：第 25 讲给出“电流 = 透射 × 占据差”，第 26 讲给出算透射的格林函数方法，第 27 讲加入散射与器件应用，第 28 讲用代码把它们跑出来。*

### 中文解释

第七周从“能带与电导率”转向**开放系统的量子输运**：器件连接无限长电极，电子从一端注入、从另一端流出。核心问题是怎样从原子级哈密顿量算出电流。

| 顺序 | 文件 | 内容 |
|---|---|---|
| 0 | 本页 README | 阅读方法、学习检查表、参考书目与课程补充文献 |
| 1 | [01_介观输运与Landauer公式.md](01_介观输运与Landauer公式.md) | 第 25 讲：接触电阻、Landauer 公式、线性响应、多端与 Hall 条 |
| 2 | [02_格林函数_自能与Fisher-Lee公式.md](02_格林函数_自能与Fisher-Lee公式.md) | 第 26 讲：推迟格林函数、自能、Fisher–Lee、Keldysh 方程、电流公式 |
| 3 | [03_非弹性散射与量子器件应用.md](03_非弹性散射与量子器件应用.md) | 第 27 讲：散射自能、SCBA、声子、Büttiker 探针、器件应用 |
| 4 | [04_石墨烯NEGF编程与结果.md](04_石墨烯NEGF编程与结果.md) | 第 28 讲：器件划分、透射、电导与 I–V 结果 |
| 5 | [05_公式与术语速查.md](05_公式与术语速查.md) | 公式、条件、代码变量与中英文术语 |
| 6 | [06_复习题与参考答案.md](06_复习题与参考答案.md) | 15 道自编练习：原图、题意、解析、来源 |
| 7 | [07_讲义勘误与易错点.md](07_讲义勘误与易错点.md) | 原图证据、问题、正确写法、核验理由；含论文引用核对 |
| 8 | [08_代码导读.md](08_代码导读.md) | `TIGHTBINDINGFORGRAPHENE.f90` 逐段解析与结果复算 |

### 原理深入

全周可以压缩为一条计算链：

```text
原子结构与紧束缚参数
  ↓ 划分：左引线 | 中心区 | 右引线
H_00, H_01（引线主层）、H_C、H_LC、H_CR
  ↓ 表面格林函数 g_s → 自能 Σ_L, Σ_R → 展宽 Γ_L, Γ_R
G^R_C = [E − H_C − Σ_L − Σ_R]^{-1}
  ↓ Fisher–Lee
T(E) = Tr[Γ_L G^R Γ_R G^A]
  ↓ Landauer（相干、弹性）        ↓ Keldysh（非平衡占据）
I = (2e/h) ∫ T (f_L − f_R) dE     G^< = G^R Σ^< G^A → 电荷、电流
  ↓ 加入散射自能 Σ_S（SCBA）
非弹性、退相干、能量弛豫 → 真实器件
```

**透射、电导、电导率是三个不同的量**：$T(E)$ 无量纲（可大于 1），电导 $G$ 单位 S（器件性质），电导率是材料性质。本周结果图把电导标成 “Conductivity”，是最需要警惕的易错点。

阅读每个模块建议做四件事：

1. **看截图**：找到公式、下标约定与图中标签；
2. **读中文解释**：回答“这页在解决什么问题？”；
3. **读原理深入**：回答“为什么成立？适用条件是什么？讲义写法是否需要修正？”；
4. **查 Ref**：回到 PDF 页码；需要系统学习时查下方书目。

### Ref

- **原课件**：[Lecture Twenty-Five](../Lecture_Twenty-Five.pdf) · [Lecture Twenty-Six](../Lecture_Twenty-Six.pdf) · [Lecture Twenty-Seven](../Lecture_Twenty-Seven.pdf) · [Lecture Twenty-Eight](../Lecture_Twenty-Eight.pdf)。原 PDF 未修改。
- **代码**：[Codes 目录](../Codes/)。
- **来源记录**：[截图来源索引](课件截图/来源索引.json)，记录源 PDF 的 SHA-256、总页数及截图页码。

## 2. 学习顺序与完成标准

### 课件截图

![Lecture Twenty-Eight 第3页：石墨烯器件的引线-散射区-引线划分](课件截图/Lecture_Twenty-Eight/page-03.png)

### 中文解释

建议顺序：01（Landauer）→ 02（格林函数）→ 08 第 1–5 节（对照代码）→ 04（结果）→ 03（散射与应用）→ 05 → 06 → 07。

自学时间仅供参考：01 约 70 分钟，02 约 90 分钟，03 约 60 分钟，04 与 08 合计约 90 分钟，复习题约 60 分钟。

### 原理深入

“学会”的标准是能亲手完成：

- [ ] 推导一维 $g_{1D}\propto1/v$，说明为什么每个通道每单位能量注入 $2e/h$。
- [ ] 计算 $h/2e^2$，解释接触电阻为何与长度无关。
- [ ] 从 Landauer 公式推出线性电导与零温量子化，说明 $-\partial f/\partial E$ 的宽度。
- [ ] 用正确的求和规则写多端方程，并解出手性 Hall 条的 $R_{xy}$（注意因子 2）。
- [ ] 由分块矩阵消去引线，写出 $\Sigma=H_{C\alpha}g_\alpha H_{\alpha C}$。
- [ ] 解析求出一维链的表面格林函数与 $\Gamma=\hbar v/a$。
- [ ] 从 Fisher–Lee 公式推出单能级 Breit–Wigner 共振，包括不对称耦合。
- [ ] 证明平衡时 $G^<=ifA$，并把 NEGF 电流化为 Landauer 形式。
- [ ] 写出光学声子 $\Sigma^<$ 并解释吸收/发射项；描述 SCBA 循环。
- [ ] 在代码中找到 $H_{00}$、$H_{01}$、$\Sigma$、$\Gamma$、$G^R$、$T$ 的计算行，说明 $k$ 平均与 I–V 积分。
- [ ] 解释本周结果中 $T>1$、电导单位、I–V 超线性的原因及模型局限。

| 日期 | 已完成模块 | 能否独立推导 | 疑问与下一步 |
|---|---|---|---|
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |

### Ref

- **原课件**：[Lecture Twenty-Eight，PDF 第 3 页](../Lecture_Twenty-Eight.pdf#page=3)。
- **配套练习**：[15 道复习题](06_复习题与参考答案.md)。题目为学习整理自编，不是官方作业。

## 3. 如何核对公式与使用 Ref？

### 课件截图

![Lecture Twenty-Five 第21页：求和规则漏掉反射项](课件截图/Lecture_Twenty-Five/page-21.png)

*示例：截图忠实保留原文，不表示原式已经通过核验。此页的求和规则漏掉了反射项，正确写法见 07。*

### 中文解释

Ref 区分三种来源：

- **原课件**：本地 PDF 页码（`#page=` 跳转是否生效取决于阅读器，但页码已写明）。
- **推导依据 / 配套笔记**：指向正确公式、例题或核验步骤。
- **延伸阅读与论文**：推荐教材、课程引用论文；教材未逐章核读，未据此虚构页码。

### 原理深入

本周常用的核验手段：

- **方向与下标**：$T_{qp}$ 是“从 $p$ 到 $q$”；左引线用 $H_{01}^\dagger$、右引线用 $H_{01}$。
- **规范不变性**：所有端电压同加常数，电流不变——可检验多端公式。
- **极限**：平衡时 $f_L=f_R$，电流为零、$G^<=ifA$；对称单能级 $T_{\max}=1$。
- **量纲与数值**：$G_0T_{\max}$ 与图中纵轴峰值比较，可判断单位标注是否正确。
- **原文核对**：论文的期刊、作者、方法以原文首页与图注为准。

截图覆盖四份讲义除封面与结束页外的 **77 页**，保存在 `课件截图/Lecture_*/page-NN.png`；各笔记按主题选图。复制或分享笔记时请连同 `课件截图/` 一起保留。

### Ref

- **原课件**：[Lecture Twenty-Five，PDF 第 21 页](../Lecture_Twenty-Five.pdf#page=21)。
- **核对记录**：[讲义勘误与易错点](07_讲义勘误与易错点.md)。它是学习记录，不是教师官方勘误。

#### 延伸参考书目

<a id="ref-datta1"></a>
**[DATTA1]** Supriyo Datta, *Electronic Transport in Mesoscopic Systems*, Cambridge University Press, 1995。检索主题：特征长度、Landauer 公式、接触电阻、多端 Büttiker 公式、S 矩阵、格林函数。

<a id="ref-datta2"></a>
**[DATTA2]** Supriyo Datta, *Quantum Transport: Atom to Transistor*, Cambridge University Press, 2005。检索主题：自能、展宽矩阵、$G^n$/$\Sigma^{in}$ 记号、相干与非相干输运、Büttiker 探针。

<a id="ref-hj"></a>
**[HJ]** Hartmut Haug & Antti-Pekka Jauho, *Quantum Kinetics in Transport and Optics of Semiconductors*, 2nd ed., Springer, 2008。检索主题：Keldysh 格林函数、Langreth 规则、电子–声子自能。

<a id="ref-nb"></a>
**[NB]** Yuli V. Nazarov & Yaroslav M. Blanter, *Quantum Transport: Introduction to Nanoscience*, Cambridge University Press, 2009。检索主题：散射方法、Landauer 公式、量子 Hall 边缘态。

<a id="ref-lj"></a>
**[LJ]** Mark Lundstrom & Changwook Jeong, *Near-Equilibrium Transport: Fundamentals and Applications*, World Scientific, 2013。检索主题：模式数、Landauer 方法下的电导、热电系数。

#### 方法原始文献

<a id="ref-fl"></a>
**[FL]** D. S. Fisher & P. A. Lee, “Relation between conductivity and transmission matrix,” *Phys. Rev. B* **23**, 6851 (1981)。

<a id="ref-b86"></a>
**[B86]** M. Büttiker, “Four-terminal phase-coherent conductance,” *Phys. Rev. Lett.* **57**, 1761 (1986)。

<a id="ref-b88"></a>
**[B88]** M. Büttiker, “Absence of backscattering in the quantum Hall effect in multiprobe conductors,” *Phys. Rev. B* **38**, 9375 (1988)。

<a id="ref-mw"></a>
**[MW]** Y. Meir & N. S. Wingreen, “Landauer formula for the current through an interacting electron region,” *Phys. Rev. Lett.* **68**, 2512 (1992)。

<a id="ref-sr"></a>
**[SR]** M. P. López Sancho, J. M. López Sancho & J. Rubio, “Highly convergent schemes for the calculation of bulk and surface Green functions,” *J. Phys. F: Met. Phys.* **15**, 851 (1985)。

<a id="ref-cn"></a>
**[CN]** A. H. Castro Neto, F. Guinea, N. M. R. Peres, K. S. Novoselov & A. K. Geim, “The electronic properties of graphene,” *Rev. Mod. Phys.* **81**, 109 (2009)。

<a id="ref-supp"></a>
#### 课程补充文献（未随仓库分发）

以下 7 篇是第 27 讲引用的论文，教师随课程提供，但因版权原因**不放入本公开仓库**。书目信息取自各论文首页；课件中两处期刊名有误，已按原文更正（见 [07 第 4 节](07_讲义勘误与易错点.md)）。

<a id="ref-lake"></a>
**[LAKE]** Roger Lake, Gerhard Klimeck, R. Chris Bowen & Dejan Jovanovic, “Single and multiband modeling of quantum electron transport through layered semiconductor devices,” *J. Appl. Phys.* **81**, 7845 (1997)。DOI: [10.1063/1.365394](https://doi.org/10.1063/1.365394)。课件第 13–14 页（RTD）。

<a id="ref-lee"></a>
**[LEE]** S.-C. Lee & A. Wacker, “Nonequilibrium Green's function theory for transport and gain properties of quantum cascade structures,” *Phys. Rev. B* **66**, 245314 (2002)。DOI: [10.1103/PhysRevB.66.245314](https://doi.org/10.1103/PhysRevB.66.245314)。课件第 15–16 页（QCL）。

<a id="ref-neo"></a>
**[NEO]** Neophytos Neophytou & Hans Kosina, “Effects of confinement and orientation on the thermoelectric power factor of silicon nanowires,” *Phys. Rev. B* **83**, 245305 (2011)。DOI: [10.1103/PhysRevB.83.245305](https://doi.org/10.1103/PhysRevB.83.245305)。课件第 17–18 页（热电）。注：该文采用紧束缚 + 线性化 Boltzmann 输运。

<a id="ref-luisier"></a>
**[LUISIER]** Mathieu Luisier & Gerhard Klimeck, “Atomistic full-band simulations of silicon nanowire transistors: Effects of electron-phonon scattering,” *Phys. Rev. B* **80**, 155430 (2009)。DOI: [10.1103/PhysRevB.80.155430](https://doi.org/10.1103/PhysRevB.80.155430)。课件第 19–20 页（纳米线 FET、TFET）。

<a id="ref-aeb"></a>
**[AEB]** U. Aeberhard, “Theory and simulation of quantum photovoltaic devices based on the non-equilibrium Green's function formalism,” *J. Comput. Electron.* **10**, 394–413 (2011)。DOI: [10.1007/s10825-011-0375-6](https://doi.org/10.1007/s10825-011-0375-6)。课件第 21–22 页（光伏）。

<a id="ref-theo"></a>
**[THEO]** Ioannis Theodonis, Nicholas Kioussis, Alan Kalitsov, Mairbek Chshiev & W. H. Butler, “Anomalous bias dependence of spin torque in magnetic tunnel junctions,” *Phys. Rev. Lett.* **97**, 237205 (2006)。DOI: [10.1103/PhysRevLett.97.237205](https://doi.org/10.1103/PhysRevLett.97.237205)。课件第 23–27 页（课件误标为 *Phys. Rev. B*）。

<a id="ref-tai"></a>
**[TAI]** Jian Li, Rui-Lin Chu, J. K. Jain & Shun-Qing Shen, “Topological Anderson insulator,” *Phys. Rev. Lett.* **102**, 136806 (2009)。DOI: [10.1103/PhysRevLett.102.136806](https://doi.org/10.1103/PhysRevLett.102.136806)。课件第 28–29 页（课件误标为 *Phys. Rev. B*）。
