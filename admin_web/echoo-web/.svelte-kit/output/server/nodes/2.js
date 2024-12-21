

export const index = 2;
let component_cache;
export const component = async () => component_cache ??= (await import('../entries/pages/_page.svelte.js')).default;
export const imports = ["_app/immutable/nodes/2.CbXxKOk1.js","_app/immutable/chunks/scheduler.BvLojk_z.js","_app/immutable/chunks/index.cf6qNKHt.js","_app/immutable/chunks/each.CYtoICLu.js"];
export const stylesheets = ["_app/immutable/assets/2.B3Rz7h5g.css"];
export const fonts = [];
