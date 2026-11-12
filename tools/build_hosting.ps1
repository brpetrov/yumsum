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

# web/index.html preloads Firebase's JS modules and adjusts two of them by
# their internal names, all for the JS SDK version FlutterFire loads. When a
# FlutterFire upgrade moves it on, stop: update the links and recheck the
# names (docs/features.md, Start-up on the web).
$packageConfig = Get-Content (Join-Path $root '.dart_tool\package_config.json') -Raw | ConvertFrom-Json
$coreWeb = $packageConfig.packages | Where-Object { $_.name -eq 'firebase_core_web' }
$coreWebDir = [System.Uri]::new($coreWeb.rootUri).LocalPath
$sdkVersionFile = Get-Content (Join-Path $coreWebDir 'lib\src\firebase_sdk_version.dart') -Raw
$flutterFireJs = [regex]::Match($sdkVersionFile, "supportedFirebaseJsSdkVersion = '([^']+)'").Groups[1].Value
$indexHtml = Get-Content (Join-Path $root 'web\index.html') -Raw
$preloadedJs = @([regex]::Matches($indexHtml, 'firebasejs/([0-9.]+)/') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
if (-not $flutterFireJs -or $preloadedJs.Count -ne 1 -or $preloadedJs[0] -ne $flutterFireJs) {
  throw "web/index.html is written for Firebase JS $($preloadedJs -join ', '), but FlutterFire loads $flutterFireJs."
}

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

# Each build's code gets a name of its own, main.<hash>.dart.js, so no
# browser can keep running an old copy out of its cache: on 12 November an
# iPhone's Brave still ran a 9 November copy after two reloads. build.json
# names the current file, so a tab left open can tell a newer copy is up
# and reload (web/flutter_bootstrap.js).
function Set-MainName($dir) {
  $hash = (Get-FileHash (Join-Path $dir 'main.dart.js') -Algorithm SHA256).Hash.Substring(0, 12).ToLower()
  $main = "main.$hash.dart.js"
  # flutter build leaves earlier builds' files in its folder.
  Get-ChildItem -LiteralPath $dir -File |
    Where-Object { $_.Name -match '^main\.[0-9a-f]{12}\.dart\.js$' } |
    Remove-Item
  Rename-Item -LiteralPath (Join-Path $dir 'main.dart.js') -NewName $main
  $references = @{
    'flutter_bootstrap.js' = '"mainJsPath":"main.dart.js"'
    'index.html'           = 'href="main.dart.js"'
  }
  foreach ($file in $references.Keys) {
    $path = Join-Path $dir $file
    $text = [IO.File]::ReadAllText($path)
    $old = $references[$file]
    if (-not $text.Contains($old)) {
      throw "$path no longer names main.dart.js as $old; update tools/build_hosting.ps1."
    }
    [IO.File]::WriteAllText($path, $text.Replace($old, $old.Replace('main.dart.js', $main)))
  }
  [IO.File]::WriteAllText((Join-Path $dir 'build.json'), "{`"main`":`"$main`"}")
}

Set-MainName $fastBuild
Set-MainName $webkitBuild

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
