const handle = async ({ event, resolve }) => {
  if (event.url.pathname.startsWith("/api/")) {
    const method = event.request.method;
    const headers = new Headers(event.request.headers);
    const body = method !== "GET" && method !== "HEAD" ? await event.request.text() : void 0;
    try {
      let response2 = null;
      let retries = 3;
      let lastError = null;
      const baseUrl = "http://localhost:8080";
      while (retries > 0) {
        try {
          console.log(`尝试连接后端 (剩余重试次数: ${retries})`);
          const controller = new AbortController();
          const timeoutId = setTimeout(() => controller.abort(), 5e3);
          try {
            const forwardHeaders = new Headers(headers);
            forwardHeaders.set("Origin", event.url.origin);
            if (event.url.pathname === "/api/login") {
              forwardHeaders.set("Content-Type", "application/json");
              forwardHeaders.set("Accept", "application/json");
            }
            response2 = await fetch(`${baseUrl}${event.url.pathname}`, {
              method,
              headers: forwardHeaders,
              body,
              signal: controller.signal
            });
            break;
          } finally {
            clearTimeout(timeoutId);
          }
        } catch (error) {
          lastError = error;
          retries--;
          if (retries === 0) break;
          console.log(`连接失败，等待重试...`);
          await new Promise((resolve2) => setTimeout(resolve2, 1e3));
        }
      }
      if (!response2) {
        throw lastError || new Error("无法连接到后端服务器");
      }
      console.log("请求URL:", `${baseUrl}${event.url.pathname}`);
      console.log("请求方法:", method);
      console.log("请求头:", Object.fromEntries(headers));
      if (body) console.log("请求体:", body);
      let responseBody;
      const contentType = response2.headers.get("content-type");
      console.log("Response status:", response2.status);
      console.log("Response headers:", Object.fromEntries(response2.headers));
      try {
        const rawText = await response2.text();
        console.log("Raw response:", rawText);
        if (rawText) {
          try {
            const jsonData = JSON.parse(rawText);
            responseBody = JSON.stringify(jsonData);
          } catch (e) {
            console.error("JSON解析错误:", e);
            responseBody = rawText;
          }
        } else {
          responseBody = JSON.stringify({ message: "No content" });
        }
      } catch (e) {
        console.error("读取响应错误:", e);
        responseBody = JSON.stringify({ error: "服务器响应错误" });
      }
      if (response2.status === 204) {
        return new Response(null, {
          status: 204,
          headers: response2.headers
        });
      }
      return new Response(responseBody || null, {
        status: response2.status,
        headers: {
          ...Object.fromEntries(response2.headers),
          "Access-Control-Allow-Origin": event.url.origin,
          "Access-Control-Allow-Credentials": "true",
          "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type, Authorization",
          "Content-Type": "application/json"
        }
      });
    } catch (error) {
      console.error("API 代理错误:", error);
      return new Response(JSON.stringify({ error: "API 请求失败" }), {
        status: 500,
        headers: {
          "Content-Type": "application/json"
        }
      });
    }
  }
  const response = await resolve(event);
  return response;
};
export {
  handle
};
