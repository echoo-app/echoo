<script lang="ts">
    import { onMount } from 'svelte';
    import { goto } from '$app/navigation';
    import type { OpenRouterModel } from '$lib/types';
    import ModelList from './ModelList.svelte';
    import UserList from './UserList.svelte';
    import VipCodes from './VipCodes.svelte';
    import Settings from './Settings.svelte';
    import './styles.scss';

    let username = '';
    let apiKey = '';
    let apiKeyMessage = '';
    let models: OpenRouterModel[] = [];
    let loading = false;
    let error: string | null = null;
    let savedModelIds: string[] = [];
    let modelMessage = '';
    let searchQuery = '';

    // 当前激活的组件
    let activeComponent = 'settings';

    // 获取已保存模型的详细信息（不受搜索影响）
    $: savedModels = models
        .filter(model => savedModelIds.includes(model.id))
        .sort((a, b) => a.name.localeCompare(b.name));

    // 辅助函数：获取认证请求头
    function getAuthHeaders() {
        const token = localStorage.getItem('auth_token');
        return {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`,
        };
    }

    // 辅助函数：发送认证请求
    async function fetchWithAuth(url: string, options: RequestInit = {}) {
        const headers = getAuthHeaders();
        const response = await fetch(url, {
            ...options,
            headers: {
                ...headers,
                ...options.headers,
            },
        });
        
        if (response.status === 401) {
            // 如果未认证，重定向到登录页面
            goto('/bde');
            throw new Error('未认证');
        }
        
        return response;
    }

    onMount(async () => {
        try {
            const response = await fetchWithAuth('/api/check-admin');
            if (!response.ok) {
                goto('/bde');
                return;
            }
            const data = await response.json();
            username = data.username;

            const apiKeyResponse = await fetchWithAuth('/api/settings/openrouter-key');
            if (apiKeyResponse.ok) {
                const apiKeyData = await apiKeyResponse.json();
                if (apiKeyData.api_key) {
                    apiKey = apiKeyData.api_key;
                    await fetchModels();
                }
            }

            const savedModelResponse = await fetchWithAuth('/api/settings/saved-models');
            if (savedModelResponse.ok) {
                const savedModelData = await savedModelResponse.json();
                if (savedModelData.model_ids) {
                    savedModelIds = savedModelData.model_ids;
                }
            }
        } catch (error) {
            console.error('认证错误:', error);
            goto('/bde');
        }
    });

    async function saveApiKey() {
        try {
            const response = await fetchWithAuth('/api/settings/openrouter-key', {
                method: 'POST',
                body: JSON.stringify({ api_key: apiKey }),
            });

            if (!response.ok) {
                throw new Error('保存API密钥失败');
            }

            apiKeyMessage = 'API密钥已保存';
            await fetchModels();
            setTimeout(() => {
                apiKeyMessage = '';
            }, 3000);
        } catch (err) {
            console.error('保存API密钥错误:', err);
            apiKeyMessage = '保存API密钥失败';
        }
    }

    async function toggleModel(modelIds: string[]) {
        try {
            const response = await fetchWithAuth('/api/settings/saved-models', {
                method: 'POST',
                body: JSON.stringify({ 
                    model_ids: modelIds,
                    models: models
                }),
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || '保存模型失败');
            }

            savedModelIds = modelIds;
            modelMessage = '模型已更新';
            
            setTimeout(() => {
                modelMessage = '';
            }, 3000);
        } catch (err) {
            console.error('保存模型错误:', err);
            modelMessage = err instanceof Error ? err.message : '保存模型失败';
        }
    }

    async function fetchModels() {
        try {
            loading = true;
            error = null;
            const response = await fetchWithAuth('/api/models');

            if (!response.ok) {
                const errorText = await response.text();
                console.error('获取模型失败:', errorText);
                throw new Error('获取模型列表失败');
            }

            const data = await response.json();
            if (!Array.isArray(data)) {
                throw new Error('获取到的模型数据格式不正确');
            }
            
            models = data;
        } catch (err) {
            console.error('获取模型错误:', err);
            error = err instanceof Error ? err.message : '未知错误';
        } finally {
            loading = false;
        }
    }

    function handleLogout() {
        localStorage.removeItem('auth_token');
        goto('/bde');
    }
</script>

<div class="dashboard-container">
    <div class="dashboard-layout">
        <aside class="dashboard-sidebar">
            <div class="sidebar-header">
                <h2>管理员仪表板</h2>
                <div class="welcome-badge">
                    欢迎, {username}
                </div>
            </div>
            
            <div class="sidebar-nav">
                <button 
                    class="sidebar-btn"
                    class:active={activeComponent === 'settings'} 
                    on:click={() => activeComponent = 'settings'}>
                    系统设置
                </button>
                <button 
                    class="sidebar-btn"
                    class:active={activeComponent === 'models'} 
                    on:click={() => activeComponent = 'models'}>
                    模型列表
                </button>
                <button 
                    class="sidebar-btn"
                    class:active={activeComponent === 'users'} 
                    on:click={() => activeComponent = 'users'}>
                    用户列表
                </button>
                <button 
                    class="sidebar-btn"
                    class:active={activeComponent === 'vip'} 
                    on:click={() => activeComponent = 'vip'}>
                    VIP激活码
                </button>
            </div>

            <button on:click={handleLogout} class="sidebar-btn logout-btn">
                注销
            </button>
        </aside>

        <main class="dashboard-content">
            {#if activeComponent === 'settings'}
                <Settings
                    {apiKey}
                    {apiKeyMessage}
                    {savedModels}
                    onSaveApiKey={saveApiKey}
                />
            {:else if activeComponent === 'models'}
                <ModelList
                    {models}
                    {loading}
                    {error}
                    {savedModelIds}
                    {modelMessage}
                    {searchQuery}
                    onRefresh={fetchModels}
                    onToggleModel={toggleModel}
                />
            {:else if activeComponent === 'users'}
                <UserList />
            {:else if activeComponent === 'vip'}
                <VipCodes />
            {/if}
        </main>
    </div>
</div>
