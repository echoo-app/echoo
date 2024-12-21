<script lang="ts">
    import { goto } from '$app/navigation';
    import type { OpenRouterModel } from '$lib/types';

    export let apiKey: string;
    export let apiKeyMessage: string;
    export let onSaveApiKey: () => void;
    export let savedModels: OpenRouterModel[];

    function formatPrice(price: string): string {
        const numPrice = parseFloat(price);
        const pricePerMillion = numPrice * 1000000;
        return `$${pricePerMillion.toFixed(2)}/1M tokens`;
    }

    function formatImagePrice(price: string | undefined): string {
        if (!price) return '不支持图片生成';
        const numPrice = parseFloat(price);
        if (isNaN(numPrice)) return '不支持图片生成';
        const pricePerThousand = numPrice * 1000;
        return `$${pricePerThousand.toFixed(2)}/K imgs`;
    }

    let newUsername = '';
    let newPassword = '';
    let confirmPassword = '';
    let message = '';
    let error = '';

    async function fetchWithAuth(url: string, options: RequestInit = {}) {
        const token = localStorage.getItem('auth_token');
        const headers = {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`,
        };

        const response = await fetch(url, {
            ...options,
            headers: {
                ...headers,
                ...options.headers,
            },
        });
        
        if (response.status === 401) {
            goto('/bde');
            throw new Error('未认证');
        }
        
        return response;
    }

    async function updateAdminCredentials() {
        try {
            if (newPassword && newPassword !== confirmPassword) {
                error = '两次输入的密码不一致';
                return;
            }

            if (!newUsername && !newPassword) {
                error = '请至少输入新用户名或新密码';
                return;
            }

            const response = await fetchWithAuth('/api/settings/admin', {
                method: 'POST',
                body: JSON.stringify({
                    new_username: newUsername || undefined,
                    new_password: newPassword || undefined
                })
            });

            if (!response.ok) {
                const data = await response.json();
                throw new Error(data.error || '更新失败');
            }

            message = '管理员信息更新成功';
            error = '';

            newUsername = '';
            newPassword = '';
            confirmPassword = '';

            if (newUsername) {
                setTimeout(() => {
                    localStorage.removeItem('auth_token');
                    goto('/bde');
                }, 2000);
            }
        } catch (err) {
            console.error('更新管理员信息错误:', err);
            error = err instanceof Error ? err.message : '更新失败';
            message = '';
        }
    }
</script>

<h3>系统设置</h3>

<div class="settings-container">
    <div class="settings-card">
        <div class="card-header">
            <h4>OpenRouter设置</h4>
        </div>
        <div class="card-content">
            <div class="form-group">
                <label for="apiKey">API密钥</label>
                <div class="input-group">
                    <input 
                        type="password"
                        id="apiKey"
                        bind:value={apiKey} 
                        placeholder="输入OpenRouter API密钥"
                        class="input"
                    />
                    <button on:click={onSaveApiKey} class="btn success">
                        保存
                    </button>
                </div>
            </div>
            {#if apiKeyMessage}
                <p class="message success">{apiKeyMessage}</p>
            {/if}
        </div>
    </div>

    <div class="settings-card">
        <div class="card-header">
            <h4>管理员账户设置</h4>
        </div>

        {#if message}
            <div class="message success">{message}</div>
        {/if}

        {#if error}
            <div class="message error">{error}</div>
        {/if}

        <div class="card-content">
            <div class="form-group">
                <label for="newUsername">新用户名</label>
                <input
                    type="text"
                    id="newUsername"
                    bind:value={newUsername}
                    placeholder="输入新用户名（可选）"
                    class="input"
                />
            </div>

            <div class="form-group">
                <label for="newPassword">新密码</label>
                <input
                    type="password"
                    id="newPassword"
                    bind:value={newPassword}
                    placeholder="输入新密码（可选）"
                    class="input"
                />
            </div>

            {#if newPassword}
                <div class="form-group">
                    <label for="confirmPassword">确认密码</label>
                    <input
                        type="password"
                        id="confirmPassword"
                        bind:value={confirmPassword}
                        placeholder="再次输入新密码"
                        class="input"
                    />
                </div>
            {/if}

            <div class="button-group">
                <button class="btn success" on:click={updateAdminCredentials}>
                    更新信息
                </button>
            </div>
        </div>
    </div>

    <div class="settings-card">
        <div class="card-header">
            <h4>已保存模型</h4>
        </div>
        <div class="card-content">
            {#if savedModels.length === 0}
                <div class="empty-message">未保存任何模型</div>
            {:else}
                <div class="saved-models">
                    {#each savedModels as model}
                        <div class="saved-model">
                            <div class="saved-model-name">{model.name}</div>
                            <div class="saved-model-price">
                                <span>输入: {formatPrice(model.pricing.prompt)}</span>
                                <span>输出: {formatPrice(model.pricing.completion)}</span>
                                <span>图片: {formatImagePrice(model.pricing.image)}</span>
                            </div>
                        </div>
                    {/each}
                </div>
            {/if}
        </div>
    </div>
</div>

<style lang="scss">
.saved-models {
    display: grid;
    gap: var(--space-3);
}

.saved-model {
    background: var(--bg);
    border: 1px solid var(--border);
    border-radius: var(--radius-1);
    padding: var(--space-3);

    &-name {
        font-size: 15px;
        font-weight: 500;
        color: var(--text);
        margin-bottom: var(--space-2);
    }

    &-price {
        display: flex;
        flex-direction: column;
        gap: 4px;
        font-size: 13px;
        color: var(--text-2);
    }
}

.empty-message {
    text-align: center;
    color: var(--text-2);
    font-size: 14px;
    padding: var(--space-3);
}

.settings-container {
    display: grid;
    gap: var(--space-4);
    max-width: 900px;
    margin: 0 auto;
}

.settings-card {
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: var(--radius-1);
    padding: var(--space-4);

    .card-header {
        margin-bottom: var(--space-3);

        h4 {
            font-size: 16px;
            font-weight: 600;
            color: var(--text);
            margin: 0;
        }
    }

    .card-content {
        .form-group {
            margin-bottom: var(--space-3);

            label {
                display: block;
                font-size: 14px;
                color: var(--text);
                margin-bottom: var(--space-2);
            }
        }
    }
}

.input-group {
    display: flex;
    gap: var(--space-2);

    .input {
        flex: 1;
    }
}

.input {
    width: 100%;
    height: var(--input-height);
    padding: 0 var(--space-2);
    border-radius: var(--radius-1);
    border: 1px solid var(--border);
    background: var(--bg);
    color: var(--text);
    font-size: 14px;

    &:focus {
        border-color: var(--primary);
        outline: none;
    }

    &::placeholder {
        color: var(--text-2);
    }
}

.btn {
    height: var(--input-height);
    padding: 0 var(--space-3);
    border-radius: var(--radius-1);
    font-size: 13px;
    cursor: pointer;
    border: none;
    font-weight: 500;
    min-width: 80px;
    transition: background 0.2s;

    &.success {
        background: var(--success-bg);
        color: var(--success-text);
        
        &:hover {
            background: var(--success-hover);
        }
    }
}

.button-group {
    display: flex;
    justify-content: flex-end;
    gap: var(--space-2);
    margin-top: var(--space-3);
}
</style>
