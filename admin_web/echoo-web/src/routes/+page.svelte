<script>
    const projectName = 'Echoo';
    const description = 'Echoo 是一个多平台的智能对话应用，支持多种 AI 模型和本地部署。让 AI 对话变得简单而强大。';
    const features = [
        {
            title: '多模型支持',
            desc: '支持 Ollama 等多种 AI 模型，灵活切换不同对话体验'
        },
        {
            title: '本地部署',
            desc: '支持完全本地化部署，确保数据安全和隐私'
        },
        {
            title: '跨平台兼容',
            desc: '提供 Web、iOS、Android 等多平台支持，随时随地对话'
        },
        {
            title: '简约设计',
            desc: '现代简约的深色主题界面，专注于对话体验'
        }
    ];
</script>

<main>
    <div class="hero">
        <div class="logo-container">
            <h1>{projectName}</h1>
            <div class="pulse"></div>
        </div>
        <p class="description">{description}</p>
    </div>
    
    <section class="features">
        <h2>主要特性</h2>
        <div class="features-grid">
            {#each features as feature}
                <div class="feature-card">
                    <h3>{feature.title}</h3>
                    <p>{feature.desc}</p>
                </div>
            {/each}
        </div>
    </section>
</main>

<style>
    :global(body) {
        background-color: #090B10;
        margin: 0;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
        color: #ffffff;
    }

    main {
        max-width: 1200px;
        margin: 0 auto;
        padding: 4rem 2rem;
    }

    .hero {
        text-align: center;
        margin-bottom: 6rem;
    }

    .logo-container {
        position: relative;
        display: inline-block;
    }

    .pulse {
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        width: 150px;
        height: 150px;
        border-radius: 50%;
        background: rgba(100, 149, 237, 0.1);
        animation: pulse 2s infinite;
        z-index: -1;
    }

    @keyframes pulse {
        0% {
            transform: translate(-50%, -50%) scale(0.8);
            opacity: 0.5;
        }
        70% {
            transform: translate(-50%, -50%) scale(1.1);
            opacity: 0.2;
        }
        100% {
            transform: translate(-50%, -50%) scale(0.8);
            opacity: 0.5;
        }
    }

    h1 {
        font-size: 4rem;
        font-weight: 700;
        margin: 0;
        background: linear-gradient(45deg, #6495ED, #9370DB);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        text-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }

    .description {
        font-size: 1.4rem;
        color: #B0B0B0;
        max-width: 800px;
        margin: 2rem auto;
        line-height: 1.6;
    }

    .features {
        text-align: center;
    }

    .features h2 {
        font-size: 2.5rem;
        margin-bottom: 3rem;
        color: #ffffff;
    }

    .features-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
        gap: 2rem;
        padding: 0 1rem;
    }

    .feature-card {
        background: rgba(255, 255, 255, 0.05);
        padding: 2rem;
        border-radius: 16px;
        transition: transform 0.3s ease, background 0.3s ease;
    }

    .feature-card:hover {
        transform: translateY(-5px);
        background: rgba(255, 255, 255, 0.08);
    }

    .feature-card h3 {
        font-size: 1.5rem;
        margin: 0 0 1rem 0;
        color: #6495ED;
    }

    .feature-card p {
        color: #B0B0B0;
        margin: 0;
        line-height: 1.6;
    }

    @media (max-width: 768px) {
        main {
            padding: 2rem 1rem;
        }

        h1 {
            font-size: 3rem;
        }

        .description {
            font-size: 1.2rem;
            padding: 0 1rem;
        }

        .features-grid {
            grid-template-columns: 1fr;
        }
    }
</style>
