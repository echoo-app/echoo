import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
    plugins: [sveltekit()],
    server: {
        proxy: {
            '/api': {
                target: 'http://localhost:8080',
                changeOrigin: true,
                secure: false,
                rewrite: (path) => path,
                configure: (proxy, options) => {
                    proxy.on('proxyReq', (proxyReq, req, res) => {
                        proxyReq.setHeader('Content-Type', 'application/json');
                        proxyReq.setHeader('Accept', 'application/json');
                    });
                    proxy.on('error', (err, req, res) => {
                        console.error('代理错误:', err);
                    });
                }
            }
        }
    }
});
