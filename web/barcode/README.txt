The web's barcode reader, used by ../barcode_reader.js where the browser
has no BarcodeDetector of its own for shop barcodes (iPhones, Firefox,
desktops). Copied unchanged from npm on 7 November 2026:

  ponyfill.js        barcode-detector 3.2.3, dist/iife/ponyfill.js
                     MIT licence, (c) 2023 Ze-Zheng Wu
                     https://github.com/Sec-ant/barcode-detector
  zxing_reader.wasm  zxing-wasm 3.1.6 (the version barcode-detector 3.2.3
                     asks for), dist/reader/zxing_reader.wasm
                     MIT licence, (c) 2023 Ze-Zheng Wu
                     https://github.com/Sec-ant/zxing-wasm
                     built from ZXing-C++, Apache licence 2.0
                     https://github.com/zxing-cpp/zxing-cpp

To update, copy both files from the same barcode-detector release and the
zxing-wasm version its package.json names.
