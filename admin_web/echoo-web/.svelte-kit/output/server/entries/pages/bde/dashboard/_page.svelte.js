import { c as create_ssr_component, f as add_attribute, e as escape, d as each, v as validate_component } from "../../../../chunks/ssr.js";
import { g as goto } from "../../../../chunks/client.js";
const css = {
  code: ".saved-models.svelte-1hnfn98.svelte-1hnfn98{display:grid;gap:var(--space-3)}.saved-model.svelte-1hnfn98.svelte-1hnfn98{background:var(--bg);border:1px solid var(--border);border-radius:var(--radius-1);padding:var(--space-3)}.saved-model-name.svelte-1hnfn98.svelte-1hnfn98{font-size:15px;font-weight:500;color:var(--text);margin-bottom:var(--space-2)}.saved-model-price.svelte-1hnfn98.svelte-1hnfn98{display:flex;flex-direction:column;gap:4px;font-size:13px;color:var(--text-2)}.empty-message.svelte-1hnfn98.svelte-1hnfn98{text-align:center;color:var(--text-2);font-size:14px;padding:var(--space-3)}.settings-container.svelte-1hnfn98.svelte-1hnfn98{display:grid;gap:var(--space-4);max-width:900px;margin:0 auto}.settings-card.svelte-1hnfn98.svelte-1hnfn98{background:var(--bg-card);border:1px solid var(--border);border-radius:var(--radius-1);padding:var(--space-4)}.settings-card.svelte-1hnfn98 .card-header.svelte-1hnfn98{margin-bottom:var(--space-3)}.settings-card.svelte-1hnfn98 .card-header h4.svelte-1hnfn98{font-size:16px;font-weight:600;color:var(--text);margin:0}.settings-card.svelte-1hnfn98 .card-content .form-group.svelte-1hnfn98{margin-bottom:var(--space-3)}.settings-card.svelte-1hnfn98 .card-content .form-group label.svelte-1hnfn98{display:block;font-size:14px;color:var(--text);margin-bottom:var(--space-2)}.input-group.svelte-1hnfn98.svelte-1hnfn98{display:flex;gap:var(--space-2)}.input-group.svelte-1hnfn98 .input.svelte-1hnfn98{flex:1}.input.svelte-1hnfn98.svelte-1hnfn98{width:100%;height:var(--input-height);padding:0 var(--space-2);border-radius:var(--radius-1);border:1px solid var(--border);background:var(--bg);color:var(--text);font-size:14px}.input.svelte-1hnfn98.svelte-1hnfn98:focus{border-color:var(--primary);outline:none}.input.svelte-1hnfn98.svelte-1hnfn98::placeholder{color:var(--text-2)}.btn.svelte-1hnfn98.svelte-1hnfn98{height:var(--input-height);padding:0 var(--space-3);border-radius:var(--radius-1);font-size:13px;cursor:pointer;border:none;font-weight:500;min-width:80px;transition:background 0.2s}.btn.success.svelte-1hnfn98.svelte-1hnfn98{background:var(--success-bg);color:var(--success-text)}.btn.success.svelte-1hnfn98.svelte-1hnfn98:hover{background:var(--success-hover)}.button-group.svelte-1hnfn98.svelte-1hnfn98{display:flex;justify-content:flex-end;gap:var(--space-2);margin-top:var(--space-3)}",
  map: `{"version":3,"file":"Settings.svelte","sources":["Settings.svelte"],"sourcesContent":["<script lang=\\"ts\\">import { goto } from '$app/navigation';\\nexport let apiKey;\\nexport let apiKeyMessage;\\nexport let onSaveApiKey;\\nexport let savedModels;\\nfunction formatPrice(price) {\\n    const numPrice = parseFloat(price);\\n    const pricePerMillion = numPrice * 1000000;\\n    return \`$\${pricePerMillion.toFixed(2)}/1M tokens\`;\\n}\\nfunction formatImagePrice(price) {\\n    if (!price)\\n        return '不支持图片生成';\\n    const numPrice = parseFloat(price);\\n    if (isNaN(numPrice))\\n        return '不支持图片生成';\\n    const pricePerThousand = numPrice * 1000;\\n    return \`$\${pricePerThousand.toFixed(2)}/K imgs\`;\\n}\\nlet newUsername = '';\\nlet newPassword = '';\\nlet confirmPassword = '';\\nlet message = '';\\nlet error = '';\\nasync function fetchWithAuth(url, options = {}) {\\n    const token = localStorage.getItem('auth_token');\\n    const headers = {\\n        'Content-Type': 'application/json',\\n        'Authorization': \`Bearer \${token}\`,\\n    };\\n    const response = await fetch(url, {\\n        ...options,\\n        headers: {\\n            ...headers,\\n            ...options.headers,\\n        },\\n    });\\n    if (response.status === 401) {\\n        goto('/bde');\\n        throw new Error('未认证');\\n    }\\n    return response;\\n}\\nasync function updateAdminCredentials() {\\n    try {\\n        if (newPassword && newPassword !== confirmPassword) {\\n            error = '两次输入的密码不一致';\\n            return;\\n        }\\n        if (!newUsername && !newPassword) {\\n            error = '请至少输入新用户名或新密码';\\n            return;\\n        }\\n        const response = await fetchWithAuth('/api/settings/admin', {\\n            method: 'POST',\\n            body: JSON.stringify({\\n                new_username: newUsername || undefined,\\n                new_password: newPassword || undefined\\n            })\\n        });\\n        if (!response.ok) {\\n            const data = await response.json();\\n            throw new Error(data.error || '更新失败');\\n        }\\n        message = '管理员信息更新成功';\\n        error = '';\\n        newUsername = '';\\n        newPassword = '';\\n        confirmPassword = '';\\n        if (newUsername) {\\n            setTimeout(() => {\\n                localStorage.removeItem('auth_token');\\n                goto('/bde');\\n            }, 2000);\\n        }\\n    }\\n    catch (err) {\\n        console.error('更新管理员信息错误:', err);\\n        error = err instanceof Error ? err.message : '更新失败';\\n        message = '';\\n    }\\n}\\n<\/script>\\n\\n<h3>系统设置</h3>\\n\\n<div class=\\"settings-container\\">\\n    <div class=\\"settings-card\\">\\n        <div class=\\"card-header\\">\\n            <h4>OpenRouter设置</h4>\\n        </div>\\n        <div class=\\"card-content\\">\\n            <div class=\\"form-group\\">\\n                <label for=\\"apiKey\\">API密钥</label>\\n                <div class=\\"input-group\\">\\n                    <input \\n                        type=\\"password\\"\\n                        id=\\"apiKey\\"\\n                        bind:value={apiKey} \\n                        placeholder=\\"输入OpenRouter API密钥\\"\\n                        class=\\"input\\"\\n                    />\\n                    <button on:click={onSaveApiKey} class=\\"btn success\\">\\n                        保存\\n                    </button>\\n                </div>\\n            </div>\\n            {#if apiKeyMessage}\\n                <p class=\\"message success\\">{apiKeyMessage}</p>\\n            {/if}\\n        </div>\\n    </div>\\n\\n    <div class=\\"settings-card\\">\\n        <div class=\\"card-header\\">\\n            <h4>管理员账户设置</h4>\\n        </div>\\n\\n        {#if message}\\n            <div class=\\"message success\\">{message}</div>\\n        {/if}\\n\\n        {#if error}\\n            <div class=\\"message error\\">{error}</div>\\n        {/if}\\n\\n        <div class=\\"card-content\\">\\n            <div class=\\"form-group\\">\\n                <label for=\\"newUsername\\">新用户名</label>\\n                <input\\n                    type=\\"text\\"\\n                    id=\\"newUsername\\"\\n                    bind:value={newUsername}\\n                    placeholder=\\"输入新用户名（可选）\\"\\n                    class=\\"input\\"\\n                />\\n            </div>\\n\\n            <div class=\\"form-group\\">\\n                <label for=\\"newPassword\\">新密码</label>\\n                <input\\n                    type=\\"password\\"\\n                    id=\\"newPassword\\"\\n                    bind:value={newPassword}\\n                    placeholder=\\"输入新密码（可选）\\"\\n                    class=\\"input\\"\\n                />\\n            </div>\\n\\n            {#if newPassword}\\n                <div class=\\"form-group\\">\\n                    <label for=\\"confirmPassword\\">确认密码</label>\\n                    <input\\n                        type=\\"password\\"\\n                        id=\\"confirmPassword\\"\\n                        bind:value={confirmPassword}\\n                        placeholder=\\"再次输入新密码\\"\\n                        class=\\"input\\"\\n                    />\\n                </div>\\n            {/if}\\n\\n            <div class=\\"button-group\\">\\n                <button class=\\"btn success\\" on:click={updateAdminCredentials}>\\n                    更新信息\\n                </button>\\n            </div>\\n        </div>\\n    </div>\\n\\n    <div class=\\"settings-card\\">\\n        <div class=\\"card-header\\">\\n            <h4>已保存模型</h4>\\n        </div>\\n        <div class=\\"card-content\\">\\n            {#if savedModels.length === 0}\\n                <div class=\\"empty-message\\">未保存任何模型</div>\\n            {:else}\\n                <div class=\\"saved-models\\">\\n                    {#each savedModels as model}\\n                        <div class=\\"saved-model\\">\\n                            <div class=\\"saved-model-name\\">{model.name}</div>\\n                            <div class=\\"saved-model-price\\">\\n                                <span>输入: {formatPrice(model.pricing.prompt)}</span>\\n                                <span>输出: {formatPrice(model.pricing.completion)}</span>\\n                                <span>图片: {formatImagePrice(model.pricing.image)}</span>\\n                            </div>\\n                        </div>\\n                    {/each}\\n                </div>\\n            {/if}\\n        </div>\\n    </div>\\n</div>\\n\\n<style lang=\\"scss\\">.saved-models {\\n  display: grid;\\n  gap: var(--space-3);\\n}\\n\\n.saved-model {\\n  background: var(--bg);\\n  border: 1px solid var(--border);\\n  border-radius: var(--radius-1);\\n  padding: var(--space-3);\\n}\\n.saved-model-name {\\n  font-size: 15px;\\n  font-weight: 500;\\n  color: var(--text);\\n  margin-bottom: var(--space-2);\\n}\\n.saved-model-price {\\n  display: flex;\\n  flex-direction: column;\\n  gap: 4px;\\n  font-size: 13px;\\n  color: var(--text-2);\\n}\\n\\n.empty-message {\\n  text-align: center;\\n  color: var(--text-2);\\n  font-size: 14px;\\n  padding: var(--space-3);\\n}\\n\\n.settings-container {\\n  display: grid;\\n  gap: var(--space-4);\\n  max-width: 900px;\\n  margin: 0 auto;\\n}\\n\\n.settings-card {\\n  background: var(--bg-card);\\n  border: 1px solid var(--border);\\n  border-radius: var(--radius-1);\\n  padding: var(--space-4);\\n}\\n.settings-card .card-header {\\n  margin-bottom: var(--space-3);\\n}\\n.settings-card .card-header h4 {\\n  font-size: 16px;\\n  font-weight: 600;\\n  color: var(--text);\\n  margin: 0;\\n}\\n.settings-card .card-content .form-group {\\n  margin-bottom: var(--space-3);\\n}\\n.settings-card .card-content .form-group label {\\n  display: block;\\n  font-size: 14px;\\n  color: var(--text);\\n  margin-bottom: var(--space-2);\\n}\\n\\n.input-group {\\n  display: flex;\\n  gap: var(--space-2);\\n}\\n.input-group .input {\\n  flex: 1;\\n}\\n\\n.input {\\n  width: 100%;\\n  height: var(--input-height);\\n  padding: 0 var(--space-2);\\n  border-radius: var(--radius-1);\\n  border: 1px solid var(--border);\\n  background: var(--bg);\\n  color: var(--text);\\n  font-size: 14px;\\n}\\n.input:focus {\\n  border-color: var(--primary);\\n  outline: none;\\n}\\n.input::placeholder {\\n  color: var(--text-2);\\n}\\n\\n.btn {\\n  height: var(--input-height);\\n  padding: 0 var(--space-3);\\n  border-radius: var(--radius-1);\\n  font-size: 13px;\\n  cursor: pointer;\\n  border: none;\\n  font-weight: 500;\\n  min-width: 80px;\\n  transition: background 0.2s;\\n}\\n.btn.success {\\n  background: var(--success-bg);\\n  color: var(--success-text);\\n}\\n.btn.success:hover {\\n  background: var(--success-hover);\\n}\\n\\n.button-group {\\n  display: flex;\\n  justify-content: flex-end;\\n  gap: var(--space-2);\\n  margin-top: var(--space-3);\\n}</style>\\n"],"names":[],"mappings":"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"}`
};
function formatPrice(price) {
  const numPrice = parseFloat(price);
  const pricePerMillion = numPrice * 1e6;
  return `$${pricePerMillion.toFixed(2)}/1M tokens`;
}
function formatImagePrice(price) {
  if (!price) return "不支持图片生成";
  const numPrice = parseFloat(price);
  if (isNaN(numPrice)) return "不支持图片生成";
  const pricePerThousand = numPrice * 1e3;
  return `$${pricePerThousand.toFixed(2)}/K imgs`;
}
const Settings = create_ssr_component(($$result, $$props, $$bindings, slots) => {
  let { apiKey } = $$props;
  let { apiKeyMessage } = $$props;
  let { onSaveApiKey } = $$props;
  let { savedModels } = $$props;
  let newUsername = "";
  let newPassword = "";
  if ($$props.apiKey === void 0 && $$bindings.apiKey && apiKey !== void 0) $$bindings.apiKey(apiKey);
  if ($$props.apiKeyMessage === void 0 && $$bindings.apiKeyMessage && apiKeyMessage !== void 0) $$bindings.apiKeyMessage(apiKeyMessage);
  if ($$props.onSaveApiKey === void 0 && $$bindings.onSaveApiKey && onSaveApiKey !== void 0) $$bindings.onSaveApiKey(onSaveApiKey);
  if ($$props.savedModels === void 0 && $$bindings.savedModels && savedModels !== void 0) $$bindings.savedModels(savedModels);
  $$result.css.add(css);
  return `<h3 data-svelte-h="svelte-pszqt2">系统设置</h3> <div class="settings-container svelte-1hnfn98"><div class="settings-card svelte-1hnfn98"><div class="card-header svelte-1hnfn98" data-svelte-h="svelte-1jtpl4z"><h4 class="svelte-1hnfn98">OpenRouter设置</h4></div> <div class="card-content"><div class="form-group svelte-1hnfn98"><label for="apiKey" class="svelte-1hnfn98" data-svelte-h="svelte-1lc0bm2">API密钥</label> <div class="input-group svelte-1hnfn98"><input type="password" id="apiKey" placeholder="输入OpenRouter API密钥" class="input svelte-1hnfn98"${add_attribute("value", apiKey, 0)}> <button class="btn success svelte-1hnfn98" data-svelte-h="svelte-7g9x1g">保存</button></div></div> ${apiKeyMessage ? `<p class="message success">${escape(apiKeyMessage)}</p>` : ``}</div></div> <div class="settings-card svelte-1hnfn98"><div class="card-header svelte-1hnfn98" data-svelte-h="svelte-tlapiw"><h4 class="svelte-1hnfn98">管理员账户设置</h4></div> ${``} ${``} <div class="card-content"><div class="form-group svelte-1hnfn98"><label for="newUsername" class="svelte-1hnfn98" data-svelte-h="svelte-jguoyo">新用户名</label> <input type="text" id="newUsername" placeholder="输入新用户名（可选）" class="input svelte-1hnfn98"${add_attribute("value", newUsername, 0)}></div> <div class="form-group svelte-1hnfn98"><label for="newPassword" class="svelte-1hnfn98" data-svelte-h="svelte-1gp7uve">新密码</label> <input type="password" id="newPassword" placeholder="输入新密码（可选）" class="input svelte-1hnfn98"${add_attribute("value", newPassword, 0)}></div> ${``} <div class="button-group svelte-1hnfn98"><button class="btn success svelte-1hnfn98" data-svelte-h="svelte-xkne5i">更新信息</button></div></div></div> <div class="settings-card svelte-1hnfn98"><div class="card-header svelte-1hnfn98" data-svelte-h="svelte-jg4gyj"><h4 class="svelte-1hnfn98">已保存模型</h4></div> <div class="card-content">${savedModels.length === 0 ? `<div class="empty-message svelte-1hnfn98" data-svelte-h="svelte-t77zgt">未保存任何模型</div>` : `<div class="saved-models svelte-1hnfn98">${each(savedModels, (model) => {
    return `<div class="saved-model svelte-1hnfn98"><div class="saved-model-name svelte-1hnfn98">${escape(model.name)}</div> <div class="saved-model-price svelte-1hnfn98"><span>输入: ${escape(formatPrice(model.pricing.prompt))}</span> <span>输出: ${escape(formatPrice(model.pricing.completion))}</span> <span>图片: ${escape(formatImagePrice(model.pricing.image))}</span></div> </div>`;
  })}</div>`}</div></div> </div>`;
});
function getAuthHeaders() {
  const token = localStorage.getItem("auth_token");
  return {
    "Content-Type": "application/json",
    "Authorization": `Bearer ${token}`
  };
}
const Page = create_ssr_component(($$result, $$props, $$bindings, slots) => {
  let savedModels;
  let username = "";
  let apiKey = "";
  let apiKeyMessage = "";
  let models = [];
  let loading = false;
  let error = null;
  let savedModelIds = [];
  async function fetchWithAuth(url, options = {}) {
    const headers = getAuthHeaders();
    const response = await fetch(url, {
      ...options,
      headers: { ...headers, ...options.headers }
    });
    if (response.status === 401) {
      goto();
      throw new Error("未认证");
    }
    return response;
  }
  async function saveApiKey() {
    try {
      const response = await fetchWithAuth("/api/settings/openrouter-key", {
        method: "POST",
        body: JSON.stringify({ api_key: apiKey })
      });
      if (!response.ok) {
        throw new Error("保存API密钥失败");
      }
      apiKeyMessage = "API密钥已保存";
      await fetchModels();
      setTimeout(
        () => {
          apiKeyMessage = "";
        },
        3e3
      );
    } catch (err) {
      console.error("保存API密钥错误:", err);
      apiKeyMessage = "保存API密钥失败";
    }
  }
  async function fetchModels() {
    try {
      loading = true;
      error = null;
      const response = await fetchWithAuth("/api/models");
      if (!response.ok) {
        const errorText = await response.text();
        console.error("获取模型失败:", errorText);
        throw new Error("获取模型列表失败");
      }
      const data = await response.json();
      if (!Array.isArray(data)) {
        throw new Error("获取到的模型数据格式不正确");
      }
      models = data;
    } catch (err) {
      console.error("获取模型错误:", err);
      error = err instanceof Error ? err.message : "未知错误";
    } finally {
      loading = false;
    }
  }
  savedModels = models.filter((model) => savedModelIds.includes(model.id)).sort((a, b) => a.name.localeCompare(b.name));
  return `<div class="dashboard-container"><div class="dashboard-layout"><aside class="dashboard-sidebar"><div class="sidebar-header"><h2 data-svelte-h="svelte-i8y5wy">管理员仪表板</h2> <div class="welcome-badge">欢迎, ${escape(username)}</div></div> <div class="sidebar-nav"><button class="${["sidebar-btn", "active"].join(" ").trim()}" data-svelte-h="svelte-1ghdoer">系统设置</button> <button class="${["sidebar-btn", ""].join(" ").trim()}" data-svelte-h="svelte-fx40jm">模型列表</button> <button class="${["sidebar-btn", ""].join(" ").trim()}" data-svelte-h="svelte-1yh0max">用户列表</button> <button class="${["sidebar-btn", ""].join(" ").trim()}" data-svelte-h="svelte-1ix8j64">VIP激活码</button></div> <button class="sidebar-btn logout-btn" data-svelte-h="svelte-1cnn1zj">注销</button></aside> <main class="dashboard-content">${`${validate_component(Settings, "Settings").$$render(
    $$result,
    {
      apiKey,
      apiKeyMessage,
      savedModels,
      onSaveApiKey: saveApiKey
    },
    {},
    {}
  )}`}</main></div></div>`;
});
export {
  Page as default
};
