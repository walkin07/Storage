const api = globalThis.browser ?? globalThis.chrome;

const status = document.getElementById("status");
const list = document.getElementById("results");
const retry = document.getElementById("retry");

retry.addEventListener("click", scan);
scan();

async function scan() {
  status.textContent = "QR 코드를 찾는 중…";
  list.replaceChildren();
  retry.hidden = true;

  const [tab] = await api.tabs.query({ active: true, currentWindow: true });

  // 1) 지금 보이는 화면에서 찾고, 2) 없으면 페이지 안의 이미지를 살펴본다.
  let payloads = [];
  let captured = false;
  try {
    const shot = await api.tabs.captureVisibleTab({ format: "png" });
    captured = true;
    payloads = await ScreenQR.decodeDataURL(shot);
  } catch {}

  if (payloads.length === 0 && tab?.id !== undefined) {
    try {
      const [injection] = await api.scripting.executeScript({
        target: { tabId: tab.id },
        func: collectPageImages,
      });
      for (const dataURL of injection?.result ?? []) {
        for (const payload of await ScreenQR.decodeDataURL(dataURL)) {
          if (!payloads.includes(payload)) payloads.push(payload);
        }
      }
    } catch {}
  }

  render(payloads, tab, captured);
}

function render(payloads, tab, captured) {
  if (payloads.length === 0) {
    status.textContent = captured ? "QR 코드를 찾지 못했어요." : "이 페이지에서는 사용할 수 없어요.";
    retry.hidden = !captured;
    return;
  }

  const results = payloads.map((payload) => ({ payload, url: ScreenQR.linkFor(payload) }));
  if (results.length === 1 && results[0].url) {
    open(results[0].url, tab);
    return;
  }

  status.textContent = results.length > 1 ? `QR 코드 ${results.length}개를 찾았어요.` : "QR 내용";
  for (const result of results) {
    const item = document.createElement("li");
    if (result.url) {
      const button = document.createElement("button");
      button.className = "link";
      button.textContent = result.payload;
      button.addEventListener("click", () => open(result.url, tab));
      item.append(button);
    } else {
      const text = document.createElement("p");
      text.className = "text";
      text.textContent = result.payload;
      const copy = document.createElement("button");
      copy.textContent = "복사";
      copy.addEventListener("click", async () => {
        await navigator.clipboard.writeText(result.payload);
        copy.textContent = "복사됨";
      });
      item.append(text, copy);
    }
    list.append(item);
  }
}

async function open(url, tab) {
  await api.tabs.create({ url, index: tab ? tab.index + 1 : undefined });
  window.close();
}

// 페이지 안에서 실행된다. 같은 출처(또는 CORS 허용) 이미지와 캔버스만 읽을 수 있다.
function collectPageImages() {
  const MAX_IMAGES = 20;
  const MAX_SIDE = 1600;
  const images = [];

  const big = (el) => {
    const rect = el.getBoundingClientRect();
    return rect.width >= 40 && rect.height >= 40;
  };

  const toDataURL = (source, width, height) => {
    const scale = Math.min(1, MAX_SIDE / Math.max(width, height));
    const canvas = document.createElement("canvas");
    canvas.width = Math.round(width * scale);
    canvas.height = Math.round(height * scale);
    canvas.getContext("2d").drawImage(source, 0, 0, canvas.width, canvas.height);
    return canvas.toDataURL("image/png");
  };

  for (const img of document.images) {
    if (images.length >= MAX_IMAGES) break;
    if (!img.complete || !img.naturalWidth || !big(img)) continue;
    try { images.push(toDataURL(img, img.naturalWidth, img.naturalHeight)); } catch {}
  }
  for (const canvas of document.querySelectorAll("canvas")) {
    if (images.length >= MAX_IMAGES) break;
    if (!canvas.width || !big(canvas)) continue;
    try { images.push(toDataURL(canvas, canvas.width, canvas.height)); } catch {}
  }
  return images;
}
