import{s as J,n as O}from"../chunks/scheduler.BvLojk_z.js";import{S as K,i as L,e as n,b as q,s as b,c as i,d as f,f as y,g as o,h as k,m as Q,n as h,j as G,k as s,o as R}from"../chunks/index.cf6qNKHt.js";import{e as T}from"../chunks/each.CYtoICLu.js";function W(p,e,a){const c=p.slice();return c[1]=e[a],c}function z(p){let e,a,c=p[1].title+"",u,x,_,I=p[1].desc+"",A,j;return{c(){e=n("div"),a=n("h3"),u=q(c),x=b(),_=n("p"),A=q(I),j=b(),this.h()},l(g){e=i(g,"DIV",{class:!0});var d=f(e);a=i(d,"H3",{class:!0});var v=f(a);u=y(v,c),v.forEach(o),x=k(d),_=i(d,"P",{class:!0});var m=f(_);A=y(m,I),m.forEach(o),j=k(d),d.forEach(o),this.h()},h(){h(a,"class","svelte-11rjj7r"),h(_,"class","svelte-11rjj7r"),h(e,"class","feature-card svelte-11rjj7r")},m(g,d){G(g,e,d),s(e,a),s(a,u),s(e,x),s(e,_),s(_,A),s(e,j)},p:O,d(g){g&&o(e)}}}function U(p){let e,a,c,u,x,_,I,A,j,g,d,v,m,P="主要特性",H,C,V=T(p[0]),r=[];for(let l=0;l<V.length;l+=1)r[l]=z(W(p,V,l));return{c(){e=n("main"),a=n("div"),c=n("div"),u=n("h1"),x=q(B),_=b(),I=n("div"),A=b(),j=n("p"),g=q(F),d=b(),v=n("section"),m=n("h2"),m.textContent=P,H=b(),C=n("div");for(let l=0;l<r.length;l+=1)r[l].c();this.h()},l(l){e=i(l,"MAIN",{class:!0});var E=f(e);a=i(E,"DIV",{class:!0});var t=f(a);c=i(t,"DIV",{class:!0});var D=f(c);u=i(D,"H1",{class:!0});var $=f(u);x=y($,B),$.forEach(o),_=k(D),I=i(D,"DIV",{class:!0}),f(I).forEach(o),D.forEach(o),A=k(t),j=i(t,"P",{class:!0});var w=f(j);g=y(w,F),w.forEach(o),t.forEach(o),d=k(E),v=i(E,"SECTION",{class:!0});var S=f(v);m=i(S,"H2",{class:!0,"data-svelte-h":!0}),Q(m)!=="svelte-qwqd6m"&&(m.textContent=P),H=k(S),C=i(S,"DIV",{class:!0});var M=f(C);for(let N=0;N<r.length;N+=1)r[N].l(M);M.forEach(o),S.forEach(o),E.forEach(o),this.h()},h(){h(u,"class","svelte-11rjj7r"),h(I,"class","pulse svelte-11rjj7r"),h(c,"class","logo-container svelte-11rjj7r"),h(j,"class","description svelte-11rjj7r"),h(a,"class","hero svelte-11rjj7r"),h(m,"class","svelte-11rjj7r"),h(C,"class","features-grid svelte-11rjj7r"),h(v,"class","features svelte-11rjj7r"),h(e,"class","svelte-11rjj7r")},m(l,E){G(l,e,E),s(e,a),s(a,c),s(c,u),s(u,x),s(c,_),s(c,I),s(a,A),s(a,j),s(j,g),s(e,d),s(e,v),s(v,m),s(v,H),s(v,C);for(let t=0;t<r.length;t+=1)r[t]&&r[t].m(C,null)},p(l,[E]){if(E&1){V=T(l[0]);let t;for(t=0;t<V.length;t+=1){const D=W(l,V,t);r[t]?r[t].p(D,E):(r[t]=z(D),r[t].c(),r[t].m(C,null))}for(;t<r.length;t+=1)r[t].d(1);r.length=V.length}},i:O,o:O,d(l){l&&o(e),R(r,l)}}}const B="Echoo",F="Echoo 是一个多平台的智能对话应用，支持多种 AI 模型和本地部署。让 AI 对话变得简单而强大。";function X(p){return[[{title:"多模型支持",desc:"支持 Ollama 等多种 AI 模型，灵活切换不同对话体验"},{title:"本地部署",desc:"支持完全本地化部署，确保数据安全和隐私"},{title:"跨平台兼容",desc:"提供 Web、iOS、Android 等多平台支持，随时随地对话"},{title:"简约设计",desc:"现代简约的深色主题界面，专注于对话体验"}]]}class te extends K{constructor(e){super(),L(this,e,X,U,J,{})}}export{te as component};