# 目标期刊稿件归档与提交说明

更新时间：2026-09-07。三套活动投稿稿件均由当前 Markdown 源稿和同一组可复现实验文件重建；历史草稿仅作归档，不参与投稿。

## 原稿留存

原始最终稿未被覆盖，归档于 `paper/original_preserved_20260906/`：

- `EI_paper_final_CN.md`
- `EI_paper_submission.docx`
- `EI_paper_submission.pdf`

## 生成稿件

- 《系统工程与电子技术》：`paper/target_sys_ele/system_engineering_electronics_manuscript_CN.docx`，及其 PDF。
- Journal of Intelligent & Robotic Systems：`paper/jirs/jirs_manuscript_EN.docx`，及其 PDF。

对应的 LaTeX 源文件：

- EI 中文主稿：`paper/EI_paper_final_CN.tex`
- 《系统工程与电子技术》中文稿：`paper/target_sys_ele/system_engineering_electronics_manuscript_CN.tex`
- JIRS 英文稿：`paper/jirs/jirs_manuscript_EN.tex`

三个 `.tex` 文件均从当前 Markdown 主源转换，内置参考文献、表格和图路径，可用 XeLaTeX 编译；图文件使用 `../results/figures_unified/` 下的已核验版本。

两套目标期刊稿件与 EI 中文主稿共用同一套已核验实验结果、逐次运行结果、失败类型、时间分解、随机场景和感知压力测试；仅标题页、语言、版式和参考文献表达按目标期刊区分。声明段按当前作者指示暂不放入成稿。

## 当前提交前必须补齐

1. 作者单位、邮编和有效通信邮箱；JIRS 还应补 ORCID（如有）。
2. 参考文献[1]的正式卷、期、页码和 DOI；当前只保留已核验的网络首发信息，没有擅自编造出版字段。
3. 《系统工程与电子技术》投稿所需的保密审查/承诺材料，以及最终作者简介信息。
4. 若投 JIRS，提交时应按 Springer 系统要求上传图文件并填写在线投稿元数据。

## 版式与公式说明

中文稿采用官方模板的标题页单栏、正文双栏节奏；大表、图和长公式临时跨栏，避免每个表格另起一页。英文稿采用 JIRS Word 单栏稿式。公式已写入 Word 原生 OMML，可在 Word 中编辑，也可在后续环节转换或重排为 MathType 公式；当前文件并未伪造 MathType OLE 对象。

官方依据：

- [《系统工程与电子技术》稿件模板](https://www.sys-ele.com/CN/column/column10.shtml)
- [《系统工程与电子技术》投稿要求](https://www.sys-ele.com/CN/column/column3.shtml)
- [JIRS Aims and Scope](https://link.springer.com/journal/10846/aims-and-scope)
- [JIRS Submission Guidelines](https://link.springer.com/journal/10846/submission-guidelines)
