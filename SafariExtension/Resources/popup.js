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

  // 1) 지금 보이는 화면을 찍어서 찾고, 2) 못 찾으면 페이지 안의 이미지를 직접 살펴본다.
  let results = [];
  try {
    const shot = await api.tabs.captureVisibleTab();
    results = await decode({ dataURLs: [shot], urls: [] });
  } catch {}

  if (results.length === 0 && tab?.id !== undefined) {
    try {
      const [injection] = await api.scripting.executeScript({
        target: { tabId: tab.id },
        func: collectPageImages,
      });
      results = await decode(injection?.result ?? { dataURLs: [], urls: [] });
    } catch {}
  }

  render(results, tab);
}

async function decode(images) {
  const response = await api.runtime.sendNativeMessage("com.example.screenqr", images);
  return response?.results ?? [];
}

function render(results, tab) {
  if (results.length === 0) {
    status.textContent = "QR 코드를 찾지 못했어요.";
    retry.hidden = false;
    return;
  }

  if (results.length === 1 && results[0].isLink) {
    open(results[0].url, tab);
    return;
  }

  status.textContent = results.length > 1 ? `QR 코드 ${results.length}개를 찾았어요.` : "QR 내용";
  for (const result of results) {
    const item = document.createElement("li");
    if (result.isLink) {
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

// 페이지 안에서 실행된다. 같은 출처 이미지는 픽셀로, 다른 출처 이미지는 주소로 넘긴다.
function collectPageImages() {
  const MAX_IMAGES = 20;
  const MAX_SIDE = 1600;
  const dataURLs = [];
  const urls = [];

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
    if (dataURLs.length + urls.length >= MAX_IMAGES) break;
    if (!img.complete || !img.naturalWidth || !big(img)) continue;
    try {
      dataURLs.push(toDataURL(img, img.naturalWidth, img.naturalHeight));
    } catch {
      const src = img.currentSrc || img.src;
      if (/^https?:/.test(src)) urls.push(src);
    }
  }

  for (const canvas of document.querySelectorAll("canvas")) {
    if (dataURLs.length + urls.length >= MAX_IMAGES) break;
    if (!canvas.width || !big(canvas)) continue;
    try {
      dataURLs.push(toDataURL(canvas, canvas.width, canvas.height));
    } catch {}
  }

  return { dataURLs, urls };
}
