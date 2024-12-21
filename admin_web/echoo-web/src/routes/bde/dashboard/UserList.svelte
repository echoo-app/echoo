<script lang="ts">
    import { onMount } from 'svelte';
    import { goto } from '$app/navigation';
    import type { User } from '$lib/types';
    import './styles.scss';

    let users: User[] = [];
    let error: string | null = null;
    let loading = false;
    let searchQuery = '';
    let message = '';

    // 编辑用户的状态
    let editingUser: User | null = null;
    let editApiCalls: string = '';

    $: filteredUsers = users.filter(user => 
        user.username.toLowerCase().includes(searchQuery.toLowerCase()) ||
        user.id.toString().includes(searchQuery)
    );

    onMount(async () => {
        await fetchUsers();
    });

    // 辅助函数：发送认证请求
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

    async function fetchUsers() {
        try {
            loading = true;
            const response = await fetchWithAuth('/api/users');
            
            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || '获取用户列表失败');
            }
            users = await response.json();
        } catch (err) {
            console.error('获取用户列表错误:', err);
            error = err instanceof Error ? err.message : '未知错误';
        } finally {
            loading = false;
        }
    }

    function startEdit(user: User) {
        editingUser = user;
        editApiCalls = user.api_calls.toString();
    }

    function cancelEdit() {
        editingUser = null;
        editApiCalls = '';
    }

    async function saveEdit() {
        if (!editingUser) return;

        try {
            const response = await fetchWithAuth(`/api/users/${editingUser.id}/api-calls`, {
                method: 'POST',
                body: JSON.stringify({ api_calls: parseInt(editApiCalls) }),
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || '更新用户信息失败');
            }

            message = '用户信息更新成功';
            await fetchUsers();
            cancelEdit();
        } catch (err) {
            console.error('更新用户信息错误:', err);
            error = err instanceof Error ? err.message : '未知错误';
        }

        setTimeout(() => {
            message = '';
            error = null;
        }, 3000);
    }

    async function deleteUser(userId: number) {
        if (!confirm('确定要删除此用户吗？此操作不可撤销。')) {
            return;
        }

        try {
            const response = await fetchWithAuth(`/api/users/${userId}`, {
                method: 'DELETE'
            });

            if (response.status === 204) {
                message = '用户已删除';
                await fetchUsers();
            } else {
                const errorData = await response.json();
                throw new Error(errorData.error || '删除用户失败');
            }
        } catch (err) {
            console.error('删除用户错误:', err);
            error = err instanceof Error ? err.message : '未知错误';
        }

        setTimeout(() => {
            message = '';
            error = null;
        }, 3000);
    }

    function formatDate(dateStr: string): string {
        const date = new Date(dateStr);
        return date.toLocaleString('zh-CN', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        });
    }
</script>

<div class="user-list-container">
    <h3>用户列表</h3>

    <input
        type="text"
        bind:value={searchQuery}
        placeholder="搜索用户名或ID..."
        class="search-input"
    />

    {#if message}
        <div class="message success">
            {message}
        </div>
    {/if}

    {#if error}
        <div class="message error">
            {error}
        </div>
    {/if}

    {#if loading}
        <div class="status-card loading">
            <p>加载用户列表中...</p>
        </div>
    {:else if filteredUsers.length === 0}
        <div class="status-card">
            <p>{users.length === 0 ? '暂无用户数据' : '未找到匹配的用户'}</p>
        </div>
    {:else}
        <div class="user-list">
            {#each filteredUsers as user}
                <div class="user-card">
                    {#if editingUser && editingUser.id === user.id}
                        <div class="edit-form">
                            <div class="card-header">
                                <h4>{user.username}</h4>
                                <span class="user-id">ID: {user.id}</span>
                            </div>
                            <div class="form-group">
                                <label for="api_calls">调用次数</label>
                                <input 
                                    type="number" 
                                    id="api_calls"
                                    bind:value={editApiCalls} 
                                    step="1"
                                    class="input"
                                />
                            </div>
                            <div class="button-group">
                                <button class="save-btn" on:click={saveEdit}>保存</button>
                                <button class="cancel-btn" on:click={cancelEdit}>取消</button>
                            </div>
                        </div>
                    {:else}
                        <div class="card-header">
                            <h4>{user.username}</h4>
                            <span class="user-id">ID: {user.id}</span>
                        </div>
                        <div class="card-details">
                            <p>调用次数: {user.api_calls}</p>
                            <p>创建时间: {formatDate(user.created_at)}</p>
                        </div>
                        <div class="button-group">
                            <button class="edit-btn" on:click={() => startEdit(user)}>
                                编辑
                            </button>
                            <button class="delete-btn" on:click={() => deleteUser(user.id)}>
                                删除
                            </button>
                        </div>
                    {/if}
                </div>
            {/each}
        </div>
    {/if}
</div>

<style lang="scss">
.edit-form {
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
