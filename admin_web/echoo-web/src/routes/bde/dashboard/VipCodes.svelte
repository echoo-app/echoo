<script lang="ts">
    import type { VipCode } from '$lib/types';
    import { onMount } from 'svelte';

    let vipCodes: VipCode[] = [];
    let loading = false;
    let error: string | null = null;
    let message: string | null = null;
    let editingCode: VipCode | null = null;
    let editPaymentUrl: string = '';

    function openEditDialog(code: VipCode) {
        editingCode = code;
        editPaymentUrl = code.payment_url;
    }

    function closeEditDialog() {
        editingCode = null;
        editPaymentUrl = '';
    }

    async function fetchVipCodes() {
        try {
            loading = true;
            error = null;
            const response = await fetch('/api/settings/vip-codes', {
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('auth_token')}`
                }
            });

            if (!response.ok) {
                throw new Error('获取激活码列表失败');
            }

            const data = await response.json();
            vipCodes = data.codes;
        } catch (err) {
            console.error('获取激活码错误:', err);
            error = err instanceof Error ? err.message : '未知错误';
        } finally {
            loading = false;
        }
    }

    async function generateVipCode() {
        try {
            loading = true;
            error = null;
            const response = await fetch('/api/settings/vip-codes', {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('auth_token')}`
                }
            });

            if (!response.ok) {
                throw new Error('生成激活码失败');
            }

            const data = await response.json();
            message = `已生成新激活码: ${data.code}\n\n支付链接:\n${data.payment_url}`;
            await fetchVipCodes();
        } catch (err) {
            console.error('生成激活码错误:', err);
            error = err instanceof Error ? err.message : '未知错误';
        } finally {
            loading = false;
        }
    }

    async function toggleVipCode(code: string, enabled: boolean) {
        try {
            loading = true;
            error = null;
            const response = await fetch(`/api/settings/vip-codes/${code}`, {
                method: 'PATCH',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${localStorage.getItem('auth_token')}`
                },
                body: JSON.stringify({ enabled })
            });

            if (!response.ok) {
                throw new Error('更新激活码状态失败');
            }

            message = `激活码状态已更新`;
            await fetchVipCodes();
        } catch (err) {
            console.error('更新激活码状态错误:', err);
            error = err instanceof Error ? err.message : '未知错误';
        } finally {
            loading = false;
        }
    }

    async function updatePaymentUrl() {
        if (!editingCode) return;

        try {
            loading = true;
            error = null;
            const response = await fetch(`/api/settings/vip-codes/${editingCode.code}`, {
                method: 'PATCH',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${localStorage.getItem('auth_token')}`
                },
                body: JSON.stringify({ payment_url: editPaymentUrl })
            });

            if (!response.ok) {
                throw new Error('更新支付链接失败');
            }

            message = '支付链接已更新';
            await fetchVipCodes();
            closeEditDialog();
        } catch (err) {
            console.error('更新支付链接错误:', err);
            error = err instanceof Error ? err.message : '未知错误';
        } finally {
            loading = false;
        }
    }

    async function deleteVipCode(code: string) {
        if (!confirm('确定要删除这个激活码吗？')) {
            return;
        }

        try {
            loading = true;
            error = null;
            const response = await fetch(`/api/settings/vip-codes/${code}`, {
                method: 'DELETE',
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('auth_token')}`
                }
            });

            if (!response.ok) {
                throw new Error('删除激活码失败');
            }

            message = '激活码已删除';
            await fetchVipCodes();
        } catch (err) {
            console.error('删除激活码错误:', err);
            error = err instanceof Error ? err.message : '未知错误';
        } finally {
            loading = false;
        }
    }

    onMount(fetchVipCodes);
</script>

<div>
    <h3>VIP 激活码管理</h3>
    
    <button class="refresh-btn" on:click={generateVipCode} disabled={loading}>
        生成新激活码
    </button>

    {#if error}
        <div class="message error">{error}</div>
    {/if}

    {#if message}
        <div class="message success">{message}</div>
    {/if}

    {#if loading}
        <div class="status-card loading">加载中...</div>
    {:else if vipCodes.length === 0}
        <div class="status-card">暂无激活码</div>
    {:else}
        <div class="user-list vip-codes">
            {#each vipCodes as code (code.id)}
                <div class="user-card">
                    <div class="card-header">
                        <h4>{code.code}</h4>
                        <div class="status-badges">
                            <span class="badge {code.enabled ? 'enabled' : 'disabled'}">
                                {code.enabled ? '已启用' : '已禁用'}
                            </span>
                            <span class="badge {code.used ? 'used' : 'unused'}">
                                {code.used ? '已使用' : '未使用'}
                            </span>
                        </div>
                    </div>
                    <div class="card-details">
                        <p>创建于: {new Date(code.created_at).toLocaleString()}</p>
                        {#if code.used}
                            <p>使用时间: {new Date(code.used_at).toLocaleString()}</p>
                        {/if}
                        <div class="payment-url">
                            <span class="label">支付链接:</span>
                            <div class="url-container">
                                <span class="url">{code.payment_url}</span>
                                <button 
                                    class="copy-btn"
                                    on:click={() => {
                                        navigator.clipboard.writeText(code.payment_url);
                                        message = '支付链接已复制到剪贴板';
                                        setTimeout(() => message = null, 3000);
                                    }}
                                >
                                    复制
                                </button>
                            </div>
                            {#if code.payment_url_expires_at}
                                <span class="expires">
                                    过期时间: {new Date(code.payment_url_expires_at).toLocaleString()}
                                </span>
                            {/if}
                        </div>
                    </div>
                    <div class="button-group">
                        {#if !code.used}
                            <button 
                                class="edit-btn"
                                on:click={() => openEditDialog(code)}
                                disabled={loading}
                            >
                                编辑链接
                            </button>
                            <button 
                                class={code.enabled ? 'delete-btn' : 'edit-btn'}
                                on:click={() => toggleVipCode(code.code, !code.enabled)}
                                disabled={loading}
                            >
                                {code.enabled ? '禁用' : '启用'}
                            </button>
                        {/if}
                        <button 
                            class="delete-btn"
                            on:click={() => deleteVipCode(code.code)}
                            disabled={loading}
                        >
                            删除
                        </button>
                    </div>
                </div>
            {/each}
        </div>
    {/if}
</div>

{#if editingCode}
    <div class="modal-overlay">
        <div class="modal">
            <h3>编辑支付链接</h3>
            <div class="modal-content">
                <div class="form-group">
                    <label for="payment_url">支付链接</label>
                    <input
                        type="text"
                        id="payment_url"
                        bind:value={editPaymentUrl}
                        placeholder="输入新的支付链接"
                        class="input"
                    />
                </div>
            </div>
            <div class="modal-actions">
                <button class="cancel-btn" on:click={closeEditDialog}>取消</button>
                <button class="save-btn" on:click={updatePaymentUrl}>保存</button>
            </div>
        </div>
    </div>
{/if}

<style lang="scss">
.modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.7);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
}

.modal {
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: var(--radius-2);
    padding: var(--space-4);
    width: 90%;
    max-width: 500px;

    h3 {
        margin-top: 0;
        margin-bottom: var(--space-3);
        font-size: 18px;
        color: var(--text);
    }
}

.modal-content {
    margin-bottom: var(--space-4);

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

.modal-actions {
    display: flex;
    justify-content: flex-end;
    gap: var(--space-2);

    button {
        height: var(--input-height);
        padding: 0 var(--space-3);
        border-radius: var(--radius-1);
        font-size: 13px;
        cursor: pointer;
        border: none;
        font-weight: 500;
        min-width: 80px;
        transition: all 0.2s;

        &.save-btn {
            background: var(--success-bg);
            color: var(--success-text);
            
            &:hover {
                background: var(--success-hover);
            }
        }

        &.cancel-btn {
            background: var(--danger-bg);
            color: var(--danger-text);
            
            &:hover {
                background: var(--danger-hover);
            }
        }
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
</style>
