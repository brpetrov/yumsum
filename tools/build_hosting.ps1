$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$buildRoot = Join-Path $root 'build'
$fastBuild = Join-Path $buildRoot 'web_fast'
$webkitBuild = Join-Path $buildRoot 'web_webkit'
$hostingBuild = Join-Path $buildRoot 'hosting'

function Reset-Directory($path) {
  if (Test-Path $path) {
    Remove-Item -LiteralPath $path -Recurse -Force
  }
  New-Item -ItemType Directory -Path $path | Out-Null
}

Set-Location $root

# Flutter keeps a web build cache per set of build options, with its own
# copy of the plugin list, and doesn't always refresh that list when a
# plugin is added: on 6 November the /app/ bundle was still built with an
# 18 October list, without Cloud Functions, so AI failed in every browser
# but Safari. Clearing the web caches makes each build start clean.
Get-ChildItem (Join-Path $root '.dart_tool\flutter_build') -Directory -ErrorAction SilentlyContinue |
  Where-Object { Test-Path (Join-Path $_.FullName 'web_plugin_registrant.dart') } |
  ForEach-Object { Remove-Item -LiteralPath $_.FullName -Recurse -Force }

Write-Host 'Building fast web bundle for Chrome, Edge, and Android browsers...'
flutter build web `
  --release `
  --base-href /app/ `
  --no-web-resources-cdn `
  --no-wasm-dry-run `
  -o $fastBuild

Write-Host 'Building WebKit web bundle for iOS browsers and Safari...'
flutter build web `
  --release `
  --base-href /webkit/ `
  --no-web-resources-cdn `
  --no-wasm-dry-run `
  -o $webkitBuild

Reset-Directory $hostingBuild

Copy-Item -Path $fastBuild -Destination (Join-Path $hostingBuild 'app') -Recurse
Copy-Item -Path $webkitBuild -Destination (Join-Path $hostingBuild 'webkit') -Recurse
# Legal pages, served at /privacy and /terms, and in Bulgarian at /privacy-bg and
# /terms-bg (firebase.json has cleanUrls on).
Copy-Item -Path (Join-Path $PSScriptRoot 'hosting\*.html') -Destination $hostingBuild
# Recipe photos, served at /recipes/<id>.webp; the app downloads them as needed.
Copy-Item -Path (Join-Path $PSScriptRoot 'hosting\recipes') -Destination (Join-Path $hostingBuild 'recipes') -Recurse

$detectorHtml = @'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="YumSum - A low-friction habit and calorie consistency tracker">
  <title>YumSum</title>
  <style>
    html,
    body {
      width: 100%;
      height: 100%;
      margin: 0;
      background: #FAF2E7;
      color: #76665A;
      font: 600 16px system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    }

    body {
      display: flex;
      align-items: center;
      justify-content: center;
    }

    @media (prefers-color-scheme: dark) {
      html,
      body {
        background: #1A1512;
        color: #BCAD9F;
      }
    }
  </style>
</head>
<body>
  <div>Loading YumSum...</div>
  <script>
    function isWebKitBrowser() {
      const ua = navigator.userAgent || '';
      const platform = navigator.platform || '';
      const isIOS = /iPad|iPhone|iPod/.test(ua) ||
        (platform === 'MacIntel' && navigator.maxTouchPoints > 1);
      const isSafari = /^((?!chrome|android|crios|fxios|edgios|opr|opera).)*safari/i.test(ua);
      return isIOS || isSafari;
    }

    async function clearOldFlutterServiceWorker() {
      try {
        if ('serviceWorker' in navigator) {
          const registrations = await navigator.serviceWorker.getRegistrations();
          await Promise.all(registrations.map((registration) => registration.unregister()));
        }
        if ('caches' in window) {
          const cacheNames = await caches.keys();
          await Promise.all(cacheNames.map((cacheName) => caches.delete(cacheName)));
        }
      } catch (error) {
        console.warn('Could not clear old Flutter cache', error);
      }
    }

    function targetUrl() {
      const base = isWebKitBrowser() ? '/webkit/' : '/app/';
      const path = window.location.pathname
        .replace(/^\/+/, '')
        .replace(/^(app|webkit)(\/|$)/, '');
      const routedPath = path || '';
      return base + routedPath + window.location.search + window.location.hash;
    }

    clearOldFlutterServiceWorker().finally(() => {
      window.location.replace(targetUrl());
    });
  </script>
</body>
</html>
'@

Set-Content -LiteralPath (Join-Path $hostingBuild 'index.html') -Value $detectorHtml -Encoding utf8

Write-Host "Firebase Hosting bundle ready at $hostingBuild"
