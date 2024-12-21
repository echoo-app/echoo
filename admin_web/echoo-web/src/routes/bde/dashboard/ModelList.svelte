<script lang="ts">
    import type { OpenRouterModel } from '$lib/types';

    export let models: OpenRouterModel[];
    export let loading: boolean;
    export let error: string | null;
    export let savedModelIds: string[];
    export let modelMessage: string;
    export let searchQuery: string;
    export let onRefresh: () => void;
    export let onToggleModel: (modelIds: string[]) => void;

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

    function handleModelSelect(modelId: string) {
        // 如果当前模型已经被选中，不做任何操作
        if (savedModelIds.includes(modelId)) {
            return;
        }
        // 选择新模型，传递一个只包含新模型ID的数组
        onToggleModel([modelId]);
    }

    $: filteredModels = models
        .filter(model => 
            model.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
            model.id.toLowerCase().includes(searchQuery.toLowerCase())
        )
        .sort((a, b) => a.name.localeCompare(b.name));
</script>

<h3>选择模型</h3>
<button on:click={onRefresh} class="refresh-btn">
    刷新列表
</button>

<input 
    type="text" 
    bind:value={searchQuery} 
    placeholder="搜索模型..."
    class="search-input"
/>

{#if loading}
    <div class="status-card loading">
        <p>加载模型列表中...</p>
    </div>
{:else if error}
    <div class="status-card error">
        <p>{error}</p>
    </div>
{:else if filteredModels.length === 0}
    <div class="status-card empty">
        <p>未找到匹配的模型</p>
    </div>
{:else}
    <ul class="models-list">
        {#each filteredModels as model}
            <li class:selected={savedModelIds.includes(model.id)}>
                <div class="model-info">
                    <span class="model-name">{model.name}</span>
                    <div class="model-price">
                        <span>输入: {formatPrice(model.pricing.prompt)}</span>
                        <span>输出: {formatPrice(model.pricing.completion)}</span>
                        <span>图片: {formatImagePrice(model.pricing.image)}</span>
                    </div>
                </div>
                <button 
                    class="select-btn" 
                    class:selected={savedModelIds.includes(model.id)}
                    on:click={() => handleModelSelect(model.id)}
                >
                    {savedModelIds.includes(model.id) ? '已选择' : '选择'}
                </button>
            </li>
        {/each}
    </ul>
    {#if modelMessage}
        <p class="message">{modelMessage}</p>
    {/if}
{/if}
