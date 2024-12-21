

export const index = 3;
let component_cache;
export const component = async () => component_cache ??= (await import('../entries/pages/bde/_page.svelte.js')).default;
export const imports = ["_app/immutable/nodes/3.D1yBH_zT.js","_app/immutable/chunks/scheduler.BvLojk_z.js","_app/immutable/chunks/index.cf6qNKHt.js","_app/immutable/chunks/entry.7PKGXZch.js"];
export const stylesheets = ["_app/immutable/assets/3.C_gYAiS1.css"];
export const fonts = [];
