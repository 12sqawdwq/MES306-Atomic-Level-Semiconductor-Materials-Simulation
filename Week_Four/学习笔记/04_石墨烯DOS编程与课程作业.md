# 04 · 石墨烯 DOS 编程与课程作业

来源：[Lecture_Sixteen.pdf](../Lecture_Sixteen.pdf)，9 页。

[返回目录](README.md)

## 1. 石墨烯 DOS 程序分几步？〔pp. 2–3〕

### 课件截图

![Lecture Sixteen 第3页：程序流程图](课件截图/Lecture_Sixteen/page-03.png)

### 中文解释

教师示例程序的流程：参数设置 → 倒空间变换与近邻搜索 → 读取输入并生成 k 网格 → 构造并对角化哈密顿量 → 用三种方法计算 DOS（Lorentz 展宽、Gaussian 展宽、2D 四面体/三角形法）→ 释放内存并结束。这正是 Lecture Fourteen 四步流程的具体实现。

### 原理深入

流程图与源码的对应关系（详见 [08 代码导读](08_代码导读.md)）：

| 流程框 | 源码位置（`TIGHTBINDINGFORGRAPHENE.f90`） |
|---|---|
| Parameterization and Setup | 主程序第 165–183 行：晶格常数、原子坐标、$t=-2.7$ eV 均**写死在源码中** |
| Reciprocal Space / Neighbor Search | `KSPACE` 子程序（第 27–52 行）；`NEIGHBOURHAMILTONIAN`（第 68–119 行），以 1.42 Å ± 0.1 Å 搜索最近邻 |
| Input Parsing / k mesh | 第 199–228 行：只解析含冒号的关键词行；生成 $(i-1)/N$ 网格 |
| Hamiltonian / Diagonalization | 第 231–255 行：只填上三角，`ZHEEV('V','U',...)` |
| Multi-Method DOS | 第 257–377 行：Lorentz、Gaussian、2D 三角形法，分别写入三个 `.dat` 文件 |
| Deallocation | 第 380–397 行 |

### Ref

- **原课件**：[Lecture Sixteen，PDF 第 2–3 页](../Lecture_Sixteen.pdf#page=3)。
- **代码**：[`TIGHTBINDINGFORGRAPHENE.f90`](../Codes/TIGHTBINDINGFORGRAPHENE.f90)。

## 2. 输入文件 Graphene.vasp 包含什么？〔p. 4〕

### 课件截图

![Lecture Sixteen 第4页：Graphene.vasp 输入文件](课件截图/Lecture_Sixteen/page-04.png)

### 中文解释

输入文件仿照 VASP 的 POSCAR 格式：第一行为晶格常数 2.46 Å，随后三行晶格矢量（以晶格常数为单位，第二个矢量与第一个成 120°），元素 C、原子数 2、`Direct` 分数坐标 $(\tfrac23,\tfrac13,0)$ 与 $(\tfrac13,\tfrac23,0)$。末尾是 DOS 参数：onsite 能 `0.0 0.0`、k 网格 `500 500`、能量范围 `-5.0 5.0` eV、能量点数 `1000`、展宽值 `0.05`。

### 原理深入

- 由 $a=2.46$ Å 得最近邻 C–C 距离 $a/\sqrt3\approx1.420$ Å，与源码中的近邻判据 1.42 Å 一致。
- **只有带冒号的 5 行会被程序读取**〔核验自源码第 202–220 行〕：`onsite`、`k point mesh for DOS`、`Energy range for DOS`、`Energy point for DOS`、`Broadening value for DOS`。晶格常数、晶格矢量与原子坐标行**不会被读取**，程序使用源码中写死的同样数值。所以只改 `Graphene.vasp` 中的晶格信息不会改变结果；改 onsite、网格、能量范围、点数、展宽才有效。
- 能量网格包含两个端点：$E_i=E_{\min}+\frac{i-1}{N_E-1}(E_{\max}-E_{\min})$，间距 $10/999\approx0.01001$ eV。
- 同一个 `0.05` 同时用于 Gaussian 的 $\sigma$ 与 Lorentz 的参数，但两者在代码中的含义不同（见第 3 节与 [08](08_代码导读.md)）。
- onsite 两个值相等时 $E_F=0$；若设为 $\pm\Delta/2$ 以打开带隙，$E_F$ 位于隙中（半满），横轴“$E-E_F$”仍可按带隙中点理解〔补充〕。

### Ref

- **原课件**：[Lecture Sixteen，PDF 第 4 页](../Lecture_Sixteen.pdf#page=4)。
- **输入文件**：[`Graphene.vasp`](../Codes/Graphene.vasp)。

## 3. 三种方法得到的 DOS 有何异同？〔p. 5〕

### 课件截图

![Lecture Sixteen 第5页：Gaussian、Lorentz、2D 四面体法的石墨烯 DOS](课件截图/Lecture_Sixteen/page-05.png)

### 中文解释

三张图形状一致：$E=0$ 附近 V 形线性 DOS（Dirac 点），$\pm2.7$ eV 处两个尖峰（M 点鞍点的 Van Hove 奇点），$\pm5$ eV 处约 0.26（Gaussian、四面体）或 0.13（Lorentz）states/eV。峰高差异明显：Gaussian 约 0.72、Lorentz 约 0.34、四面体约 0.95 states/eV。

### 原理深入

**峰高的两个来源**：

1. **方法本身**：2D 鞍点处真实 DOS 对数发散；四面体法最接近真实值，峰最高最尖；Gaussian、Lorentz 的峰高被核宽度截断。
2. **归一化约定不同（容易被忽略）**：本笔记对教师给出的数据文件做梯形积分（$[-5,5]$ eV）：Gaussian **2.579**、四面体 **2.573**、Lorentz **1.285**。独立估算石墨烯 π 带在 $|E|<5$ eV 内的态占比约 64.5%，“每能带 1 个态”归一化时积分应约为 $2\times0.645\approx1.29$。因此：
   - Lorentz 结果 ≈ 1.29：**不含自旋**；
   - Gaussian、四面体 ≈ 2.58：**含自旋因子 2**。

所以 Lorentz 曲线整体只有另外两者的一半，峰高 0.34 不能直接与 0.72 比较；扣除因子 2 后，Lorentz 与 Gaussian 的差别才是核函数造成的差别。此外，代码中 Lorentz 参数是 FWHM（HWHM=0.025 eV），比 Gaussian 的有效宽度略窄。

**其他读图要点**：

- 四面体法 $E=0$ 处 DOS 为 0（数据中恰为 0.00000000），Gaussian 约 0.0029、Lorentz 约 0.0047：展宽核的尾巴把邻近态“漏”到了 $E=0$。
- 纵轴单位 states/eV 指**每原胞**（2 个 C 原子）。
- 由于 $[-5,5]$ eV 窗口只覆盖约 64.5% 的态，不能用这三张图验证“积分=2.0”；做归一化检查时应把窗口扩大到至少 $[-8.5,8.5]$ eV〔补充〕。

### Ref

- **原课件**：[Lecture Sixteen，PDF 第 5 页](../Lecture_Sixteen.pdf#page=5)。
- **数值核验**：[08 第 8 节](08_代码导读.md)；[07 第 1、9 节](07_讲义勘误与易错点.md)。

## 4. 能带图如何与 DOS 对应？〔p. 6〕

### 课件截图

![Lecture Sixteen 第6页：沿 Γ–K–M 的石墨烯能带](课件截图/Lecture_Sixteen/page-06.png)

### 中文解释

能带图沿 $\Gamma\to K\to M$：$\Gamma$ 点能量 $\pm8.1$ eV（能带极值），K 点两带在 $E_F=0$ 处线性相交（Dirac 点），M 点为 $\pm2.7$ eV。红色虚线为 Fermi 能级。

### 原理深入

能带图与 DOS 的对应（$|t|=2.7$ eV、onsite 为 0）〔补充〕：

| 能带图位置 | 能量 | $|f(\mathbf k)|$ | 临界点类型（2D） | DOS 特征 |
|---|---|---|---|---|
| $\Gamma$ | $\pm3|t|=\pm8.1$ eV | 3 | 极值（下带极小、上带极大） | 带边台阶（在图中 $[-5,5]$ 窗口外） |
| M | $\pm|t|=\pm2.7$ eV | 1 | 鞍点 | 对数发散的 Van Hove 峰 |
| K | 0 | 0 | 锥形点（非光滑） | $g\propto|E|$，V 形，$g(0)=0$ |

注意能带图只显示高对称路径，DOS 需要全 BZ 网格（[02 第 2 节](02_k点采样与TB-DOS四步流程.md)）。Dirac 点附近 $g(E)\approx\frac{2|E|}{\sqrt3\pi t^2}$（每原胞、不含自旋）；$E=1$ eV 时约 0.050 states/eV，与示例数据（Lorentz 0.054；Gaussian/四面体 0.105 ≈ 2×0.053）在数量级上吻合，残余差别来自远离 Dirac 点时的三角翘曲〔补充核验〕。

### Ref

- **原课件**：[Lecture Sixteen，PDF 第 6 页](../Lecture_Sixteen.pdf#page=6)。
- **延伸**：[GR09](README.md#ref-gr09)。

## 5. 第 16 讲作业说明与 CW1 正式文件有什么不同？〔pp. 7–8〕

### 课件截图

![Lecture Sixteen 第7页：编程任务一，能带](课件截图/Lecture_Sixteen/page-07.png)

![Lecture Sixteen 第8页：编程任务二，DOS](课件截图/Lecture_Sixteen/page-08.png)

### 中文解释

幻灯片中的两项任务：

- **任务一**：编写程序计算并绘制本征与掺杂石墨烯的能带；解释结果（如 Fermi 能级、掺杂石墨烯的带隙等）；附上源代码。
- **任务二**：用 Gaussian、Lorentz、四面体三种方法计算并绘制**本征**石墨烯的 DOS；讨论展宽参数的影响、DOS 随能量的变化、DOS 影响的物理性质（电导率、载流子浓度等）；附上源代码。
- 说明：语言可选 Fortran、C、C++、Matlab、Python 或 Julia；以 PDF 提交；无页数字数限制；截止时间为学期第 7 周末。

### 原理深入

本地另有官方作业文件 `CW1/Coursework for the Module MES306TC.pdf`（2 页，标题 *Practical Project: Tuning the electronic structure of graphene*）。对照后发现以下差异：

| 项目 | Lecture Sixteen 第 7–8 页 | CW1 正式文件 |
|---|---|---|
| 编程语言 | Fortran、C、C++、Matlab、Python、Julia | **仅 Fortran、C 或 C++**（哈密顿量构造、对角化、DOS 计算全部） |
| DOS 范围 | 只要求**本征**石墨烯的三种方法 DOS | 本征与**带隙（gapped/doped）**石墨烯都要能带与 DOS，且 DOS 都用三种方法 |
| 带隙 | “掺杂石墨烯的带隙” | 引入可调带隙的扰动，带隙数值自选 |
| 报告内容 | 解释结果 | 须写出石墨烯紧束缚哈密顿量；比较分析两种情形；解释真实材料中如何实现带隙 |
| 评分 | 未给出 | 本征能带代码 20%、本征 DOS 代码 20%、带隙能带代码 20%、带隙 DOS 代码 20%、个人报告 20% |
| 截止时间 | 第 7 周末 | 文件中未写 |
| 资源 | 未提及 | 可使用 HPC、Fortran/C/C++ 编译器、机房 |

**建议**：

1. 以范围更严格的 **CW1 正式文件为准**（用 Fortran/C/C++，并完成本征与带隙两种情形的能带和三种 DOS），截止时间以幻灯片/教学平台公告为准；对语言限制等不一致之处，尽早向任课教师确认。
2. 报告中写明 DOS 归一化约定（是否含自旋、每原胞还是每面积）、$\sigma$ 的定义、k 网格、能量窗口，并说明三种方法的结果为何不同。
3. 不要直接提交或改写示例程序充当“原创代码”：CW1 明确要求 *Original code*。示例程序可用来理解算法、核对自己的结果（例如对照 $\pm2.7$ eV 峰位和 $E=0$ 处的 V 形）。
4. 示例程序在归一化上不一致（见上一节和 [08](08_代码导读.md)），自己实现时应统一约定并用积分检查。

本笔记不提供作业解答代码。

### Ref

- **原课件**：[Lecture Sixteen，PDF 第 7–8 页](../Lecture_Sixteen.pdf#page=7)。
- **官方文件**：课程 CW1 文件 *Coursework for the Module MES306TC*（不在本仓库内，以教学平台发布版本为准）。
- **背景**：带隙与子格对称破缺见 [02 第 4 节](02_k点采样与TB-DOS四步流程.md) 的石墨烯模型；延伸 [GR09](README.md#ref-gr09)。
