# 提交前全文检查报告

检查日期：2026-09-07

| 检查项 | 结果 | 证据 |
|---|---|---|
| 标题、作者、英文摘要和关键词 | PASS | source/DOCX/results machine check |
| 正文无未回填占位符 | PASS | source/DOCX/results machine check |
| 图编号连续且唯一 | PASS | source/DOCX/results machine check |
| 表编号连续且唯一 | PASS | source/DOCX/results machine check |
| 公式存在且指标定义齐全 | PASS | source/DOCX/results machine check |
| 参考文献编号连续 | PASS | source/DOCX/results machine check |
| 固定场景逐运行结果为 48 行 | PASS | source/DOCX/results machine check |
| 压力测试逐运行结果为 48 行 | PASS | source/DOCX/results machine check |
| 随机场景逐运行结果为 144 行 | PASS | source/DOCX/results machine check |
| 四种方法均有记录 | PASS | source/DOCX/results machine check |
| 训练机动协议包含 helix | PASS | source/DOCX/results machine check |
| DWA 拒绝阈值为 0.25 m | PASS | source/DOCX/results machine check |
| 模型哈希已写入数据说明 | PASS | source/DOCX/results machine check |
| 声明段按当前要求省略 | PASS | source/DOCX/results machine check |
| 参考文献核验记录存在 | PASS | source/DOCX/results machine check |
| DOCX 字体颜色全黑 | PASS | source/DOCX/results machine check |

- 图编号：[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]；表编号：[1, 2, 3, 4, 5, 6, 7, 8, 9]；公式块：8；参考文献：13 条。
- 固定场景逐运行：48 行；压力测试：48 行；随机场景：144 行。
- 黑色字体检查覆盖正文、页眉页脚和表格中的 DOCX runs；表格底色已统一为白色。
- 参考文献 [1] 已按作者提供的记录写入题名、作者、期刊、[J/OL]、页码、日期和 CNKI 链接；卷期和 DOI 未提供，未在文稿中补造，见 REFERENCE_CHECK.md。
- 排版已生成通用 EI 风格 A4 Word 稿；用户未提供具体会议名称或官方模板，因此“完全匹配具体会议模板”仍需收到模板后复核。
