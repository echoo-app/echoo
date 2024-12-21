import type { Handle } from '@sveltejs/kit';

export const handle: Handle = async ({ event, resolve }) => {
    // 检查是否是 API 请求
    if (event.url.pathname.startsWith('/api/')) {
        // 获取原始请求的方法和头部信息
        const method = event.request.method;
        const headers = new Headers(event.request.headers);
        const body = method !== 'GET' && method !== 'HEAD' ? await event.request.text() : undefined;

        try {
            // 转发请求到后端（带重试）
            let response: Response | null = null;
            let retries = 3;
            let lastError: Error | null = null;

            // 本地开发环境
            const baseUrl = 'http://localhost:8080';

            while (retries > 0) {
                try {
                    console.log(`尝试连接后端 (剩余重试次数: ${retries})`);
                    const controller = new AbortController();
                    const timeoutId = setTimeout(() => controller.abort(), 5000);

                    try {
                        // 转发所有原始请求头
                        const forwardHeaders = new Headers(headers);
                        // 确保基本headers存在
                        if (!forwardHeaders.has('Content-Type')) {
                            forwardHeaders.set('Content-Type', 'application/json');
                        }
                        if (!forwardHeaders.has('Accept')) {
                            forwardHeaders.set('Accept', 'application/json');
                        }
                        forwardHeaders.set('Origin', event.url.origin);

                        // 添加CORS请求头
                        if (method === 'OPTIONS') {
                            return new Response(null, {
                                status: 204,
                                headers: {
                                    'Access-Control-Allow-Origin': event.url.origin,
                                    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
                                    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
                                    'Access-Control-Allow-Credentials': 'true',
                                }
                            });
                        }

                        response = await fetch(`${baseUrl}${event.url.pathname}`, {
                            method,
                            headers: forwardHeaders,
                            body,
                            signal: controller.signal,
                            credentials: 'include'
                        });
                        break;
                    } finally {
                        clearTimeout(timeoutId);
                    }
                } catch (error) {
                    lastError = error as Error;
                    retries--;
                    if (retries === 0) break;
                    console.log(`连接失败，等待重试...`);
                    await new Promise(resolve => setTimeout(resolve, 1000));
                }
            }

            if (!response) {
                throw lastError || new Error('无法连接到后端服务器');
            }

            // 记录请求信息
            console.log('请求URL:', `${baseUrl}${event.url.pathname}`);
            console.log('请求方法:', method);
            console.log('请求头:', Object.fromEntries(headers));
            if (body) console.log('请求体:', body);

            // 确保响应是有效的JSON
            let responseBody;
            const contentType = response.headers.get('content-type');
            
            // 记录响应信息用于调试
            console.log('Response status:', response.status);
            console.log('Response headers:', Object.fromEntries(response.headers));
            
            try {
                const rawText = await response.text();
                console.log('Raw response:', rawText);
                
                if (rawText) {
                    try {
                        // 尝试解析JSON
                        const jsonData = JSON.parse(rawText);
                        responseBody = JSON.stringify(jsonData);
                    } catch (e) {
                        console.error('JSON解析错误:', e);
                        // 如果不是JSON，直接返回原始文本
                        responseBody = rawText;
                    }
                } else {
                    responseBody = JSON.stringify({ message: 'No content' });
                }
            } catch (e) {
                console.error('读取响应错误:', e);
                responseBody = JSON.stringify({ error: '服务器响应错误' });
            }

            // 如果是204状态码，返回空响应
            if (response.status === 204) {
                return new Response(null, {
                    status: 204,
                    headers: response.headers
                });
            }

            // 构建响应头
            const responseHeaders = new Headers({
                'Access-Control-Allow-Origin': event.url.origin,
                'Access-Control-Allow-Credentials': 'true',
                'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization',
                'Content-Type': 'application/json'
            });

            // 转发所有原始响应头，包括Set-Cookie
            for (const [key, value] of response.headers.entries()) {
                if (key.toLowerCase() === 'set-cookie') {
                    // 确保Set-Cookie头部被正确保留
                    responseHeaders.append(key, value);
                } else {
                    responseHeaders.set(key, value);
                }
            }

            // 返回后端的响应
            return new Response(responseBody || null, {
                status: response.status,
                headers: responseHeaders
            });
        } catch (error) {
            console.error('API 代理错误:', error);
            return new Response(JSON.stringify({ error: 'API 请求失败' }), { 
                status: 500,
                headers: {
                    'Content-Type': 'application/json'
                }
            });
        }
    }

    // 对于非 API 请求，正常处理
    const response = await resolve(event);
    return response;
};
