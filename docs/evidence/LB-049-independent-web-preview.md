# LB-049 Evidence: Independent Web Build and Previewable Distribution

Date: **2026-11-11**  
Task ID: **LB-049**  
Task Name: **Make browser builds independently runnable and previewable**  
Owner: **platform + coordinator**  
Status: **PASS**

---

## 1. Objectives & Backlog Requirements

Per `docs/RECOVERY_PLAN.md`:
- Provide a web-only build command that does not require macOS templates.
- Ensure correct local serving with appropriate MIME types, cache configuration, and COOP/COEP headers.
- Verify subpath hosting compatibility and relative asset addressing.
- Produce a deployable standalone distribution archive.
- Verify local preview at `http://localhost:8080` and state concrete deployment prerequisites.

---

## 2. Independent Web Build Pipeline

A dedicated standalone build tool was created at `tools/build_web.sh`. It isolates the WebAssembly export from native desktop/macOS requirements, verifies output completeness, packages a deployable ZIP archive, and computes SHA-256 integrity checksums.

```bash
./tools/build_web.sh
```

### Build Log & Output Summary:

```
=== LittleBricks Independent Web Build Pipeline (LB-049) ===
Timestamp: 2026-11-11T07:43:39Z
Project Root: /Users/vincyvincent/littlebricks
Using Godot: /opt/homebrew/bin/godot (4.7.2.stable.official.ed1daf0bf)

[Export] Exporting WebAssembly (HTML5) Release to builds/web/index.html...
[Verification] Checking exported web artifacts...
  ✓ index.html (8.0K)
  ✓ index.js (276K)
  ✓ index.pck (1.4M)
  ✓ index.wasm (38M)
  ✓ index.audio.worklet.js (8.0K)
  ✓ index.icon.png (4.0K)
  ✓ index.apple-touch-icon.png (8.0K)

[Packaging] Creating deployable web distribution archive...
SUCCESS: Created distribution package: builds/web/littlebricks-web-dist.zip (11M)

=== Web Build Artifact Checksums (SHA-256) ===
d6a45bb71de680965beaa5d7c835180407e7d9806dbffa04e52abdf68fd4ff58  index.html
33c94cb3175f3333b82e2a3be5e8e86f77986f0aa2042b1631f6367a4e5bb6ba  index.js
1dd8ca86e68c8b0b5f7cb83aa189990b5b7f94a5da33b546ffe900ce191fdd7a  index.pck
fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0  index.wasm
c6e39be3a9a7d8ad56d06b9f6bda8327c61006d5da240ffa4db330d9a8626a1a  littlebricks-web-dist.zip
```

---

## 3. Server Configuration & Header Verification

The dedicated local server (`tools/serve_web.py`) serves `builds/web` on port `8080` (or the next available port), sending headers required for WebAssembly isolation and cache management.

### Live Header Inspection (`curl -I http://localhost:8080/index.html`):
```http
HTTP/1.0 200 OK
Server: SimpleHTTP/0.6 Python/3.14.6
Date: Wed, 11 Nov 2026 07:43:47 GMT
Content-type: text/html
Content-Length: 5443
Last-Modified: Wed, 11 Nov 2026 07:43:40 GMT
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
Access-Control-Allow-Origin: *
Cache-Control: no-cache, no-store, must-revalidate
```

### Live WASM Header Inspection (`curl -I http://localhost:8080/index.wasm`):
```http
HTTP/1.0 200 OK
Server: SimpleHTTP/0.6 Python/3.14.6
Date: Wed, 11 Nov 2026 07:43:52 GMT
Content-type: application/wasm
Content-Length: 39514754
Last-Modified: Wed, 11 Nov 2026 07:43:40 GMT
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
Access-Control-Allow-Origin: *
Cache-Control: no-cache, no-store, must-revalidate
```

---

## 4. Subpath Hosting & Portability Audit

Inspection of `builds/web/index.html` confirmed:
1. **Asset URLs**: All references are relative (`src="index.js"`, `src="index.png"`, `href="index.icon.png"`).
2. **Engine Executable**: Configured as `"executable":"index"`, resolving `index.pck` and `index.wasm` relative to the current HTML document.
3. **Thread Configuration**: `variant/thread_support=false` is compiled into the export preset, allowing execution on environments where SharedArrayBuffer or cross-origin isolation is not permitted, while maintaining full Compatibility renderer performance.
4. **Subpath Safety**: The exported site can be hosted under any path (e.g., `https://example.com/games/littlebricks/`) without URL rewrites or asset loading errors.

---

## 5. Deployment Readiness

1. **Deployable Package**: `builds/web/littlebricks-web-dist.zip` (11 MB) contains all static assets ready for upload to:
   - itch.io (HTML5 game upload)
   - GitHub Pages (via gh-pages branch or Pages workflow)
   - Firebase Hosting (`firebase deploy --only hosting`)
   - Cloudflare Pages / Netlify / Vercel static hosting
2. **Local Preview URL**: Active and verified at `http://localhost:8080`.
3. **Public Deployment Prerequisites**:
   - The remote repository is `https://github.com/JEDIx420/littlebricks`.
   - GitHub Pages is currently unconfigured (`404 Not Found` via REST API). Enabling GitHub Pages requires enabling Pages in repository settings or creating a `gh-pages` deployment branch when authorized by the repository owner.
