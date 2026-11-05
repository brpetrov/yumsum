function keepFlutterSurfaceSized() {
  const css = `
    html, body, flutter-view {
      width: 100%;
      height: 100%;
      margin: 0;
      overflow: hidden;
    }

    flutter-view {
      display: block !important;
      position: fixed !important;
      inset: 0;
      width: 100% !important;
      height: 100% !important;
    }

    flt-glass-pane,
    flt-text-editing-host,
    flt-semantics-host {
      display: block !important;
      position: absolute !important;
      inset: 0 !important;
      width: 100% !important;
      height: 100% !important;
    }

    flt-glass-pane {
      z-index: 0;
    }

    flt-text-editing-host {
      overflow: visible !important;
      pointer-events: none;
      z-index: 1;
    }

    flt-text-editing-host input,
    flt-text-editing-host textarea {
      pointer-events: auto;
    }

    flt-semantics-host {
      pointer-events: none;
      z-index: 2;
    }
  `;

  const style = document.createElement('style');
  style.textContent = css;
  document.head.appendChild(style);

  const shadowCss = `
    :host, flt-scene-host, flt-scene, flt-canvas-container {
      display: block !important;
      position: absolute !important;
      inset: 0 !important;
      width: 100% !important;
      height: 100% !important;
    }
  `;

  const applyShadowCss = () => {
    const glassPane = document.querySelector('flt-glass-pane');
    if (!glassPane?.shadowRoot) {
      return;
    }
    if (glassPane.shadowRoot.querySelector('#leanstreak-webkit-layout')) {
      return;
    }
    const shadowStyle = document.createElement('style');
    shadowStyle.id = 'leanstreak-webkit-layout';
    shadowStyle.textContent = shadowCss;
    glassPane.shadowRoot.appendChild(shadowStyle);
  };

  applyShadowCss();
  const interval = window.setInterval(applyShadowCss, 50);
  window.setTimeout(() => window.clearInterval(interval), 30000);
}

keepFlutterSurfaceSized();

function keepFlutterTextInputsFocused() {
  const focusEditorAt = (x, y) => {
    const host = document.querySelector('flt-text-editing-host');
    if (!host) {
      return;
    }

    const editors = Array.from(host.querySelectorAll('input, textarea'));
    const editor = editors.find((candidate) => {
      const rect = candidate.getBoundingClientRect();
      const style = window.getComputedStyle(candidate);
      const padding = 24;
      return (
        rect.width > 0 &&
        rect.height > 0 &&
        style.visibility !== 'hidden' &&
        style.display !== 'none' &&
        x >= rect.left - padding &&
        x <= rect.right + padding &&
        y >= rect.top - padding &&
        y <= rect.bottom + padding
      );
    });

    if (!editor || document.activeElement === editor) {
      return;
    }

    try {
      editor.focus({ preventScroll: true });
    } catch (_) {
      editor.focus();
    }
  };

  const handlePointerEnd = (event) => {
    const point = event.changedTouches?.[0] ?? event;
    const x = point.clientX;
    const y = point.clientY;

    focusEditorAt(x, y);
    window.requestAnimationFrame(() => focusEditorAt(x, y));
    window.setTimeout(() => focusEditorAt(x, y), 0);
    window.setTimeout(() => focusEditorAt(x, y), 50);
  };

  window.addEventListener('pointerup', handlePointerEnd);
  window.addEventListener('mouseup', handlePointerEnd);
  window.addEventListener('touchend', handlePointerEnd);
}

keepFlutterTextInputsFocused();

{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    canvasKitBaseUrl: 'canvaskit/',
  },
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    document.getElementById('loading')?.remove();
    await appRunner.runApp();
  },
});
