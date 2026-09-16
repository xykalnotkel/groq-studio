// Menambahkan prefix subpath (mis. /groq-studio/) ke seluruh referensi
// absolut di hasil build statis, supaya situs bisa dihosting di GitHub
// Pages project site tanpa mengubah source (base tetap '/').
//
// Pakai: ASTRO_BASE=/groq-studio/ node scripts/prefix-base.mjs
import { readdirSync, readFileSync, writeFileSync, statSync } from 'node:fs';
import { join } from 'node:path';

const base = process.env.ASTRO_BASE || '';
if (!base || base === '/') {
  console.log('prefix-base: tidak ada ASTRO_BASE, dilewati.');
  process.exit(0);
}
const b = base.endsWith('/') ? base : base + '/';
const dist = join(process.cwd(), 'dist');

let touched = 0;

function walk(dir) {
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    const st = statSync(p);
    if (st.isDirectory()) {
      walk(p);
      continue;
    }
    if (name.endsWith('.html')) {
      let s = readFileSync(p, 'utf8');
      const before = s;
      // src="/..." href="/..." (juga href="/" menjadi href="/groq-studio/")
      s = s.replace(/(src|href)="\//g, `$1="${b}`);
      // url(/...) di style inline
      s = s.replace(/url\(\//g, `url(${b}`);
      if (s !== before) {
        writeFileSync(p, s);
        touched++;
      }
    } else if (name.endsWith('.css')) {
      let s = readFileSync(p, 'utf8');
      const before = s;
      s = s.replace(/url\(\//g, `url(${b}`);
      if (s !== before) {
        writeFileSync(p, s);
        touched++;
      }
    } else if (name.endsWith('.js')) {
      let s = readFileSync(p, 'utf8');
      const before = s;
      // referensi aset public di bundle (kalau ada)
      s = s.replace(/["'(](\/(?:shots|logo\.png|favicon\.png|wa_popup_43\.png|wa-channel\.png|xyverse_[a-z_]+\.png))/g,
        (m, path) => m[0] + b + path.slice(1));
      if (s !== before) {
        writeFileSync(p, s);
        touched++;
      }
    }
  }
}

walk(dist);
console.log(`prefix-base: ${touched} berkas diprefix dengan ${b}`);
