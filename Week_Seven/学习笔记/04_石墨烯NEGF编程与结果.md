# 04 · 石墨烯 NEGF 编程：器件划分与计算结果

来源：[Lecture_Twenty-Eight.pdf](../Lecture_Twenty-Eight.pdf)，8 页。

[返回目录](README.md)

> 本讲课件只有结构示意和三张结果图，具体实现“请参考 Fortran 代码”。逐段代码解析见 [08 代码导读](08_代码导读.md)；本文件把课件图与代码、数据对应起来。文中的数值（如 $T(0)$、小偏压电导）是本笔记作者读取 `Codes/` 中的输出文件得到的核验值，不是课件给出的数字。

## 1. 第 28 讲的任务是什么？〔pp. 2, 4〕

### 课件截图

![Lecture Twenty-Eight 第2页：提纲](课件截图/Lecture_Twenty-Eight/page-02.png)

![Lecture Twenty-Eight 第4页：请参考Fortran代码](课件截图/Lecture_Twenty-Eight/page-04.png)

*第 2 页大标题 “Many-Body Scattering, Energy Relaxation and Advanced Quantum Devices” 沿用了第 27 讲的标题；本讲内容实为“NEGF 编程与结果”。*

### 中文解释

本讲分两部分：用 Fortran 实现石墨烯的 NEGF 透射计算；展示透射系数、“电导率”（实为电导）和 $I$–$V$ 曲线。程序是 `Codes/TIGHTBINDINGFORGRAPHENE.f90`，输入为 `Codes/Graphene.vasp`。

### 原理深入

程序实现的是第 26 讲的**相干** NEGF 流程，加上第 25 讲的 Landauer 积分：

```text
读入晶格与参数 → 构造引线 H00、H01 与中心区 H_C、耦合矩阵
→ 对每个横向 k、每个能量 E：
     表面格林函数 g_L, g_R → Σ_L, Σ_R → Γ_L, Γ_R → G^R_C
     → T_k(E) = Tr[Γ_L G^R Γ_R G^A]
→ 对 k 取平均得 T(E) → G(E) = G0·T(E)
→ I(V) = G0 ∫ T(E)[f_L − f_R] dE
```

没有用到第 27 讲的散射自能，也没有用到 $G^<$；中心区与引线是同一种完美石墨烯。

### Ref

- **原课件**：[Lecture Twenty-Eight，PDF 第 2 页](../Lecture_Twenty-Eight.pdf#page=2)、[第 4 页](../Lecture_Twenty-Eight.pdf#page=4)。
- **代码**：[08 代码导读](08_代码导读.md)。
- **勘误**：[07 第 5 节：标题沿用](07_讲义勘误与易错点.md)。

## 2. 器件如何划分？$H_{00}$、$H_{01}$ 与耦合块各是什么？〔p. 3〕

### 课件截图

![Lecture Twenty-Eight 第3页：左引线4个单元、散射区10个单元、右引线4个单元](课件截图/Lecture_Twenty-Eight/page-03.png)

### 中文解释

沿 $x$ 方向输运：左引线每个主层 4 个原胞，中心散射区 10 个原胞，右引线主层 4 个原胞；$y$ 方向（沿 $\mathbf a_2$）取 2 个原胞并做周期延拓。每个原胞含 2 个碳原子（A、B 子格）。

哈密顿矩阵分块：引线内部用主层哈密顿量 $H_{00}$ 和相邻主层耦合 $H_{01}$ 描述；引线与散射区之间是 $H_{\text{left-scattering}}$、$H_{\text{scattering-right}}$，并满足

$$
H_{\text{left-scattering}}=(H_{\text{scattering-left}})^\dagger,\qquad
H_{\text{scattering-right}}=(H_{\text{right-scattering}})^\dagger.
$$

### 原理深入

**矩阵维数**（代码中每个原胞 2 个轨道）：

| 块 | 维数 | 代码变量 |
|---|---|---|
| 引线主层 $H_{00}$、$H_{01}$ | $(4\times2\times2)^2=16\times16$ | `electrodeh00`、`electrodeh01` |
| 中心区 $H_C$ | $(10\times2\times2)^2=40\times40$ | `scatteringregion` |
| 左耦合 $H_{LC}$ | $16\times40$ | `leftscattering` |
| 右耦合 $H_{CR}$ | $40\times16$ | `rightscattering` |

**主层为什么取 4 个原胞**：主层必须足够长，使最近邻跳跃只连接**相邻**主层（$H_{02}=0$）。对最近邻石墨烯，1 个原胞其实就够；取 4 个原胞不影响结果，只是增大矩阵、同时让表面格林函数每次迭代“前进”更长距离。

**横向周期与 $k_y$**：$y$ 方向只取 2 个原胞，用 Bloch 相位 $e^{i\mathbf k\cdot\mathbf d}$ 处理周期边界，相当于模拟一块无限宽的石墨烯片，再对横向 $k$ 求平均。因此结果是“每个横向超胞宽度上的透射”，而不是有限宽纳米带的结果。代码要求引线与中心区的横向尺寸相同，否则直接报错退出。

**示意图与代码一致性**：课件图中 $H_{01}$ 标在左引线、$H_{00}$ 标在对角块，与代码相符；代码对左引线使用 $H_{01}^\dagger$ 作为“向外”耦合（[08 第 3 节](08_代码导读.md)）。

### Ref

- **原课件**：[Lecture Twenty-Eight，PDF 第 3 页](../Lecture_Twenty-Eight.pdf#page=3)。
- **理论**：[02 第 4–5 节](02_格林函数_自能与Fisher-Lee公式.md)。
- **代码**：[08 第 2、4 节](08_代码导读.md)。

## 3. 透射系数曲线说明了什么？〔p. 5〕

### 课件截图

![Lecture Twenty-Eight 第5页：透射系数T(E)](课件截图/Lecture_Twenty-Eight/page-05.png)

### 中文解释

$T(E)$ 在 $E=0$（Dirac 点）附近呈 V 形、趋近于零，随 $|E|$ 近似线性增大，在 $|E|\approx3$ eV 附近达到约 1.44 的最大值，之后下降；曲线关于 $E=0$ 对称。

### 原理深入

**为什么 $T$ 可以大于 1**：$T(E)$ 是对所有横向通道求和后的结果（再对 $k_y$ 平均），表示“每个横向超胞宽度上有多少个开放通道”，可以超过 1。

**为什么近似线性**：中心区是完美石墨烯，没有散射，$T(E)$ 就等于引线的模式数 $M(E)$。Dirac 锥附近每单位宽度的模式数〔补充估算〕

$$
\frac{M(E)}{W}\approx\frac{2|E|}{\pi\hbar v_F},\qquad \hbar v_F=\tfrac32|t|a_{cc}\approx5.75\ \text{eV·Å}.
$$

（因子 2 来自两个谷，自旋另计在 $G_0$ 中。）横向超胞在垂直于 $x$ 方向的宽度 $W=2\times|\mathbf a_2|\sin60^\circ\approx4.26$ Å，估算 $M(1\ \text{eV})\approx0.47$，与数据 $T(1\ \text{eV})=0.421$ 同一量级；差别来自三角翘曲与有限 $\eta$。

**$E=0$ 处不为零**：数据中 $T(0.005\ \text{eV})\approx0.0164$。原因是 $\eta=0.025$ eV 的人为展宽和有限 $k_y$ 网格。理想无限宽石墨烯中 $M(0)=0$。

**粒子–空穴对称**：最近邻、零格点能的石墨烯是二分格子，谱关于 $E=0$ 对称；数据中 $T(E)=T(-E)$ 精确成立。

**峰位**：最大值出现在 $|E|\approx2.99$ eV，靠近 M 点 van Hove 能量 $|t|=2.7$ eV；透射（模式数）与态密度的峰不必在同一能量。

### Ref

- **原课件**：[Lecture Twenty-Eight，PDF 第 5 页](../Lecture_Twenty-Eight.pdf#page=5)。
- **数据**：[`transmission.dat`](../Codes/transmission.dat)。
- **延伸**：[CN：石墨烯电子性质](README.md#ref-cn)。

## 4. “Conductivity” 图实际上画的是什么？〔p. 6〕

### 课件截图

![Lecture Twenty-Eight 第6页：标为Conductivity的结果图](课件截图/Lecture_Twenty-Eight/page-06.png)

*纵轴标注 “Conductivity ($e^2/h$)”，但数值约 $10^{-4}$，单位实为西门子（S），物理量是电导而不是电导率。*

### 中文解释

这张图与上一张形状完全相同，只是纵轴乘了一个常数：程序计算 $G(E)=G_0T(E)$，$G_0=2e^2/h=7.748\times10^{-5}$ S。它是零温 Landauer **电导**随 Fermi 能的变化。

### 原理深入

- **单位核验**：$T_{\max}=1.4376$，$G_0T_{\max}=1.114\times10^{-4}$，与图中峰值约 0.00011 一致——所以纵轴单位是 S，而不是 $e^2/h$（若以 $e^2/h$ 为单位，峰值应约为 2.9）。
- **电导 vs 电导率**：$G$ 是整个器件（含接触）的性质；电导率 $\sigma$ 是材料性质。对二维材料，要从 $G$ 得到 $\sigma_{2D}$，需要 $G=\sigma_{2D}W/L$ 且处于扩散区；本例是弹道输运，$G$ 与 $L$ 无关，不能这样换算。
- 输出文件 `Conductivity_along_x_axis.dat` 的表头本身写的是 “Landauer conductance G(E) (S)”，说明代码作者知道它是电导；文件名与图标注是历史遗留命名。
- 这是零温、线性响应下的 $G(E_F)$；有限温度的电导需按第 25 讲第 7 节对 $-\partial f/\partial E$ 加权平均。

### Ref

- **原课件**：[Lecture Twenty-Eight，PDF 第 6 页](../Lecture_Twenty-Eight.pdf#page=6)。
- **数据**：[`Conductivity_along_x_axis.dat`](../Codes/Conductivity_along_x_axis.dat)。
- **勘误**：[07 第 6 节](07_讲义勘误与易错点.md)。

## 5. $I$–$V$ 曲线为何不是直线？〔p. 7〕

### 课件截图

![Lecture Twenty-Eight 第7页：I-V曲线](课件截图/Lecture_Twenty-Eight/page-07.png)

![教师提供的结果合图：透射、电导与I-V](../Codes/results.png)

*第二张图是 `Codes/results.png`（教师用 xmgrace 绘制的三联图），中间子图同样把电导标成 “Conductivity ($e^2/h$)”，左图标题拼作 “Transimmison”。*

### 中文解释

程序取 $\mu_L=+eV/2$、$\mu_R=-eV/2$（$E_F=0$），$T=300$ K，在 $[-0.5,0.5]$ V 内 100 个偏压点用 Landauer 积分计算电流。曲线关于原点反对称，小偏压近似线性，偏压增大后电流增长快于线性（超线性）。

### 原理深入

**超线性的原因**：$T(E)\propto|E|$。零温下

$$
I(V)=\frac{2e}{h}\int_{-eV/2}^{eV/2}T(E)\,dE\approx\frac{2e}{h}\,\alpha\Big(\frac{eV}{2}\Big)^2\propto V^2,
$$

所以偏压越大，进入窗口的通道越多。数据验证：$I(0.25\ \text{V})=6.68\times10^{-7}$ A，$I(0.5\ \text{V})=2.23\times10^{-6}$ A，比值约 3.3（纯线性应为 2，纯平方应为 4；室温展宽和小偏压区的线性段使其介于两者之间）。

**小偏压电导**：$I(5.05\ \text{mV})=9.05\times10^{-9}$ A，故 $G\approx1.79\times10^{-6}$ S $\approx0.023\,G_0$，略大于 $G_0T(0)=1.27\times10^{-6}$ S——室温热窗口采到了 $E\ne0$ 处更大的透射。

**模型假设（重要）**：

1. $T(E)$ 只在零偏压下算一次，偏压只“刚性”地移动左右 Fermi 函数；没有在中心区加电势降，也没有与 Poisson 方程自洽。
2. 中心区是完美石墨烯，没有缺陷或散射，结果是纯弹道的；电流反映的是引线模式数，而不是“散射区”的性质。
3. 横向 $k$ 取平均，因此电流是“每个横向超胞宽度（约 4.26 Å）”的电流；要得到某个宽度 $W$ 的器件电流，需乘以 $W/4.26$ Å（假设宽到可以忽略边缘效应）。
4. 偏压点数为偶数（100），网格中没有 $V=0$ 点；横轴 “Voltage” 缺单位（V）。

本笔记作者用 `transmission.dat` 独立重做了 Landauer 积分，三个偏压点的结果与 `I_V_Curve.dat` 一致到有效数字（[08 第 7 节](08_代码导读.md)）。

### Ref

- **原课件**：[Lecture Twenty-Eight，PDF 第 7 页](../Lecture_Twenty-Eight.pdf#page=7)。
- **数据与图**：[`I_V_Curve.dat`](../Codes/I_V_Curve.dat)、[`results.png`](../Codes/results.png)、[`results.agr`](../Codes/results.agr)。
- **理论**：[01 第 6–7 节](01_介观输运与Landauer公式.md)。
- **勘误**：[07 第 6、7 节](07_讲义勘误与易错点.md)。
