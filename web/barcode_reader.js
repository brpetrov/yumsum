// Reads a packet's barcode from the camera page's preview on the web
// (readWebBarcode, lib/screens/dashboard/helpers/web_barcode_web.dart):
// the browser's own BarcodeDetector where it reads shop barcodes (Chrome on
// Android), else the barcode-detector ponyfill and its zxing-wasm reader in
// barcode/, fetched the first time a barcode is looked for.
(() => {
  const formats = ["ean_13", "ean_8", "upc_a", "upc_e"];
  let reader = null;

  async function builtIn() {
    if (!("BarcodeDetector" in self)) return null;
    try {
      const supported = await BarcodeDetector.getSupportedFormats();
      return formats.every((format) => supported.includes(format))
        ? new BarcodeDetector({ formats })
        : null;
    } catch {
      return null;
    }
  }

  function load(src) {
    return new Promise((resolve, reject) => {
      const script = document.createElement("script");
      script.src = src;
      script.onload = resolve;
      script.onerror = () => reject(new Error(`Could not load ${src}`));
      document.head.append(script);
    });
  }

  async function ponyfill() {
    if (!self.BarcodeDetectionAPI) await load("barcode/ponyfill.js");
    const api = self.BarcodeDetectionAPI;
    const wasm = new URL("barcode/zxing_reader.wasm", document.baseURI).href;
    // Fetched now, from our own site, so a failure shows now.
    await api.prepareZXingModule({
      overrides: {
        locateFile: (path, prefix) => (path.endsWith(".wasm") ? wasm : prefix + path),
      },
      fireImmediately: true,
    });
    return new api.BarcodeDetector({ formats });
  }

  // The first barcode in the preview, or null; rejects only when no reader
  // could be loaded, and tries again on the next call.
  self.yumsumReadBarcode = async () => {
    const video = document.querySelector("video");
    if (!video || video.readyState < 2 || !video.videoWidth) return null;
    reader ??= (async () => (await builtIn()) ?? (await ponyfill()))();
    let detector;
    try {
      detector = await reader;
    } catch (error) {
      reader = null;
      throw error;
    }
    try {
      const codes = await detector.detect(video);
      return codes.length ? codes[0].rawValue : null;
    } catch {
      return null;
    }
  };
})();
