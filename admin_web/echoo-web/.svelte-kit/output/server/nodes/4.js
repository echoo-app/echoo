

export const index = 4;
let component_cache;
export const component = async () => component_cache ??= (await import('../entries/pages/bde/dashboard/_page.svelte.js')).default;
export const imports = ["_app/immutable/nodes/4.jikebQ-7.js","_app/immutable/chunks/scheduler.BvLojk_z.js","_app/immutable/chunks/index.cf6qNKHt.js","_app/immutable/chunks/entry.7PKGXZch.js","_app/immutable/chunks/each.CYtoICLu.js"];
export const stylesheets = ["_app/immutable/assets/4.0W90ExPL.css"];
export const fonts = [];
