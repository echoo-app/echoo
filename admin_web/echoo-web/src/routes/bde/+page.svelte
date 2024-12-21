<script>
    import { goto } from '$app/navigation';

    let username = '';
    let password = '';
    let errorMessage = '';
    let isLoading = false;

    async function handleLogin() {
        try {
            isLoading = true;
            errorMessage = '';
            
            console.log('发送登录请求:', { username });
            
            const response = await fetch('/api/login', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                body: JSON.stringify({ username, password }),
                credentials: 'same-origin'
            });

            console.log('登录响应状态:', response.status);
            console.log('登录响应头:', Object.fromEntries(response.headers));

            const rawText = await response.text();
            console.log('原始响应:', rawText);

            let result;
            try {
                result = JSON.parse(rawText);
            } catch (e) {
                console.error('JSON解析错误:', e);
                throw new Error('服务器响应格式错误');
            }

            if (response.ok) {
                console.log('登录成功:', result);
                // 保存token到localStorage
                if (result.token) {
                    localStorage.setItem('auth_token', result.token);
                    // 设置Authorization header
                    const headers = new Headers();
                    headers.append('Authorization', `Bearer ${result.token}`);
                    console.log('Token已保存:', result.token);
                }
                // 登录成功，跳转到管理页面
                goto('/bde/dashboard');
            } else {
                console.error('登录失败:', result);
                // 登录失败，显示错误消息
                errorMessage = result.message || '登录失败';
            }
        } catch (error) {
            console.error('登录错误:', error);
            errorMessage = error.message || '网络错误，请重试';
        } finally {
            isLoading = false;
        }
    }
</script>

<div class="login-container">
    <div class="login-box">
        <h2>管理员登录</h2>
        {#if errorMessage}
            <div class="error-message">{errorMessage}</div>
        {/if}
        <form on:submit|preventDefault={handleLogin}>
            <div class="input-wrapper">
                <div class="input-group">
                    <label for="username">用户名</label>
                    <input 
                        type="text" 
                        id="username"
                        bind:value={username} 
                        placeholder="请输入用户名" 
                        required
                        disabled={isLoading}
                    />
                </div>
                <div class="input-group">
                    <label for="password">密码</label>
                    <input 
                        type="password" 
                        id="password"
                        bind:value={password} 
                        placeholder="请输入密码" 
                        required
                        disabled={isLoading}
                    />
                </div>
                <div class="button-group">
                    <button type="submit" class="login-btn" disabled={isLoading}>
                        {isLoading ? '登录中...' : '登录'}
                    </button>
                </div>
            </div>
        </form>
    </div>
</div>

<style>
    :global(html, body) {
        margin: 0;
        padding: 0;
        width: 100%;
        height: 100%;
        overflow: hidden;
        background-color: #090B10;
    }

    .login-container {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        display: flex;
        justify-content: center;
        align-items: center;
        background-color: #090B10;
        font-family: system-ui, -apple-system, sans-serif;
    }

    .login-box {
        background: rgba(20, 24, 36, 0.5);
        border-radius: 20px;
        border: 1px solid rgba(255, 255, 255, 0.05);
        box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        backdrop-filter: blur(20px);
        padding: 48px;
        width: 360px;
        text-align: center;
    }

    .error-message {
        color: #ff4d4f;
        margin-bottom: 16px;
        background: rgba(255, 77, 79, 0.1);
        padding: 10px;
        border-radius: 8px;
    }

    h2 {
        color: #fff;
        font-size: 24px;
        font-weight: 500;
        margin: 0 0 32px 0;
        letter-spacing: 0.5px;
    }

    .input-wrapper {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 24px;
    }

    .input-group {
        width: 100%;
    }

    label {
        display: block;
        margin-bottom: 8px;
        color: rgba(255, 255, 255, 0.6);
        text-align: left;
        font-size: 14px;
        font-weight: 500;
    }

    input {
        width: 100%;
        padding: 14px 16px;
        background: rgba(255, 255, 255, 0.05);
        border: 1px solid rgba(255, 255, 255, 0.1);
        border-radius: 12px;
        color: #fff;
        font-size: 15px;
        box-sizing: border-box;
        transition: all 0.2s ease;
    }

    input::placeholder {
        color: rgba(255, 255, 255, 0.3);
    }

    input:focus {
        outline: none;
        border-color: rgba(255, 255, 255, 0.2);
        background: rgba(255, 255, 255, 0.08);
    }

    input:disabled {
        opacity: 0.5;
        cursor: not-allowed;
    }

    .button-group {
        width: 100%;
        margin-top: 8px;
    }

    .login-btn {
        width: 100%;
        padding: 14px;
        background: rgba(255, 255, 255, 0.1);
        color: #fff;
        border: none;
        border-radius: 12px;
        font-size: 15px;
        font-weight: 500;
        cursor: pointer;
        transition: all 0.2s ease;
    }

    .login-btn:hover:not(:disabled) {
        background: rgba(255, 255, 255, 0.15);
        transform: translateY(-1px);
    }

    .login-btn:active:not(:disabled) {
        transform: translateY(1px);
    }

    .login-btn:disabled {
        opacity: 0.5;
        cursor: not-allowed;
    }
</style>
