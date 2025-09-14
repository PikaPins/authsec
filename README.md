# 自动抓取 wechat.doonsec.com /api/v1/es/（GitHub Actions）

说明
- 该仓库文件包含一个 GitHub Actions 工作流和脚本，用于按计划抓取 `https://wechat.doonsec.com/api/v1/es/` 的 POST 响应并将响应及解析结果以 artifact 上传。
- 强烈建议把凭证添加到仓库 Secrets（推荐做法）：
  - `DOONSEC_CSRFTOKEN`（必需）
  - `DOONSEC_COOKIE`（可选，如需登录）

如何工作
1. `.github/workflows/fetch-es.yml` 会每小时运行（并支持手动触发）。
2. 工作流在运行时把 Secrets 注入环境变量，执行 `scripts/fetch_es.sh`。
3. `scripts/fetch_es.sh` 使用 curl（HTTP/2）发送请求并把响应保存到 `artifacts/`。
4. `scripts/parse_es.py` 会尽力从响应中提取“技术资源”并输出结构化 JSON。
5. 工作流会将 `artifacts/` 作为 artifact 上传，可下载查看。

部署指南（概览）
1. 在仓库 Settings → Secrets and variables → Actions 添加 `DOONSEC_CSRFTOKEN` 与（可选）`DOONSEC_COOKIE`。
2. 将本仓库文件添加到仓库并推送（如果仓库为空，下面有推送示例）。
3. 在 GitHub Actions 页面手动触发一次或等待计划任务执行。

安全与合规
- 请勿将真实凭证明文提交到仓库；使用 Secrets。
- 在启用自动抓取前，请确认符合目标站点的使用条款与法律法规。
