// 이미지에서 QR을 찾아 해석한다. ZXing(WASM)으로 브라우저 안에서만 처리하며, 여러 개도 한 번에 찾는다.
const ScreenQR = (() => {
  const MAX_SIDE = 3000;
  const LINK_SCHEMES = new Set(["http:", "https:", "mailto:", "tel:", "sms:"]);
  const runtime = (globalThis.browser ?? globalThis.chrome)?.runtime;

  ZXingWASM.prepareZXingModule({
    overrides: {
      locateFile: (path, prefix) =>
        path.endsWith(".wasm") && runtime?.getURL ? runtime.getURL("vendor/zxing_reader.wasm") : prefix + path,
    },
  });

  async function decodeDataURL(dataURL) {
    const image = new Image();
    image.src = dataURL;
    await image.decode();
    return decodeSource(image, image.naturalWidth, image.naturalHeight);
  }

  async function decodeSource(source, width, height) {
    const scale = Math.min(1, MAX_SIDE / Math.max(width, height));
    const canvas = document.createElement("canvas");
    canvas.width = Math.max(1, Math.round(width * scale));
    canvas.height = Math.max(1, Math.round(height * scale));
    const context = canvas.getContext("2d", { willReadFrequently: true });
    context.drawImage(source, 0, 0, canvas.width, canvas.height);

    const results = await ZXingWASM.readBarcodes(context.getImageData(0, 0, canvas.width, canvas.height), {
      formats: ["QRCode", "MicroQRCode", "Aztec", "DataMatrix"],
      maxNumberOfSymbols: 12,
      tryHarder: true,
    });

    // 큰 코드부터
    const area = ({ position: p }) =>
      Math.abs((p.topRight.x - p.topLeft.x) * (p.bottomLeft.y - p.topLeft.y));
    const payloads = [];
    for (const result of results.filter((r) => r.isValid && r.text).sort((a, b) => area(b) - area(a))) {
      if (!payloads.includes(result.text)) payloads.push(result.text);
    }
    return payloads;
  }

  /** 바로 열 수 있는 주소면 URL 문자열, 아니면 null */
  function linkFor(payload) {
    const text = payload.trim();
    try {
      const url = new URL(text);
      if (LINK_SCHEMES.has(url.protocol)) return url.href;
    } catch {}
    if (/^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+(\/\S*)?$/.test(text)) return "https://" + text;
    return null;
  }

  return { decodeDataURL, decodeSource, linkFor };
})();
