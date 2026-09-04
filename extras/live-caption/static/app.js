const modeEl = document.getElementById("mode");
const captureModeEl = document.getElementById("captureMode");
const chunkSecEl = document.getElementById("chunkSec");
const chunkSecFieldEl = document.getElementById("chunkSecField");
const streamLineEl = document.getElementById("streamLine");
const startBtn = document.getElementById("startBtn");
const stopBtn = document.getElementById("stopBtn");
const clearBtn = document.getElementById("clearBtn");
const statusEl = document.getElementById("status");
const logEl = document.getElementById("log");
const liveLineEl = document.getElementById("liveLine");
const liveTextEl = document.getElementById("liveText");
const cursorEl = document.getElementById("cursor");
const chunkLogEl = document.getElementById("chunkLog");

let mediaStream = null;
let chunkTimer = null;
let vadTimer = null;
let audioContext = null;
let analyser = null;
let activeRecorder = null;
let activeChunks = [];
let recording = false;
let speechActive = false;
let speechStartedAt = 0;
let silenceStartedAt = 0;
let accumulatedText = "";
let sessionId = null;

const SPEECH_RMS = 0.018;
const SILENCE_MS = 1400;
const MIN_SPEECH_MS = 700;
const MAX_SPEECH_MS = 12000;
const VAD_POLL_MS = 120;

const HALLUCINATION_PATTERNS = [
  /\*[^*]+\*/i,
  /thank you(?: for watching)?/i,
  /captions by/i,
  /subscribe/i,
  /project readon/i,
  /i'm going to make a (?:cake|cup of coffee)/i,
  /i'm going to take a picture/i,
  /the end\b/i,
  /what's up\b/i,
  /hello\.?\s*thank you/i,
  /^\s*hello\.?\s*$/i,
  /^\s*okay\.?\s*$/i,
  /^\s*hey there\.?\s*$/i,
  /^\s*-\s*$/i,
];

function setStatus(text, klass = "") {
  statusEl.textContent = text;
  statusEl.className = `status ${klass}`.trim();
}

function showStreamMode(streamLine) {
  liveLineEl.classList.toggle("hidden", !streamLine);
  chunkLogEl.classList.toggle("hidden", streamLine);
}

function setCursorVisible(visible) {
  cursorEl.classList.toggle("hidden", !visible);
}

function scrollLogToEnd() {
  logEl.scrollTop = logEl.scrollHeight;
}

function clearTranscript() {
  accumulatedText = "";
  liveTextEl.textContent = "";
  chunkLogEl.innerHTML = "";
}

function updateCaptureUi() {
  const fixed = captureModeEl.value === "fixed";
  chunkSecFieldEl.classList.toggle("hidden", !fixed);
}

function getRms() {
  if (!analyser) return 0;
  const data = new Float32Array(analyser.fftSize);
  analyser.getFloatTimeDomainData(data);
  let sum = 0;
  for (let i = 0; i < data.length; i += 1) {
    sum += data[i] * data[i];
  }
  return Math.sqrt(sum / data.length);
}

function pickMimeType() {
  const candidates = [
    "audio/webm;codecs=opus",
    "audio/webm",
    "audio/ogg;codecs=opus",
    "audio/mp4",
  ];
  return candidates.find((t) => MediaRecorder.isTypeSupported(t)) || "";
}

function looksLikeHallucination(text) {
  const cleaned = (text || "").trim();
  if (!cleaned) return true;
  if (cleaned.includes("*")) return true;
  return HALLUCINATION_PATTERNS.some((pattern) => pattern.test(cleaned));
}

function cleanChunkText(text) {
  return (text || "").replace(/\s+/g, " ").trim();
}

/** Merge new chunk text onto the running line, trimming word overlap when possible. */
function mergeChunkText(accumulated, chunk) {
  const prev = accumulated.trim();
  const next = (chunk || "").trim();
  if (!next) return prev;
  if (!prev) return next;
  if (prev.endsWith(next)) return prev;

  const wordsA = prev.split(/\s+/);
  const wordsB = next.split(/\s+/);
  const maxOverlap = Math.min(wordsA.length, wordsB.length);

  for (let n = maxOverlap; n > 0; n -= 1) {
    const suffix = wordsA.slice(-n).join(" ");
    const prefix = wordsB.slice(0, n).join(" ");
    if (suffix.toLowerCase() === prefix.toLowerCase()) {
      const tail = wordsB.slice(n).join(" ");
      return tail ? `${prev} ${tail}` : prev;
    }
  }

  return `${prev} ${next}`;
}

function appendStreamText(text) {
  accumulatedText = mergeChunkText(accumulatedText, text);
  liveTextEl.textContent = accumulatedText;
  scrollLogToEnd();
}

function appendChunkEntry(text, label) {
  const entry = document.createElement("div");
  entry.className = "entry";
  const meta = document.createElement("span");
  meta.className = "meta";
  meta.textContent = label;
  entry.appendChild(meta);
  entry.appendChild(document.createTextNode(text || "(empty)"));
  chunkLogEl.prepend(entry);
}

async function loadConfig() {
  try {
    const res = await fetch("/api/config");
    const cfg = await res.json();
    if (!cfg.whisperConfigured) {
      setStatus(
        "Server missing WHISPER_BASE_URL or WHISPER_BEARER_TOKEN.",
        "error",
      );
      startBtn.disabled = true;
      return;
    }
    if (cfg.mlflowEnabled) {
      setStatus(
        `Ready — model: ${cfg.model} · MLflow: ${cfg.mlflowExperiment}`,
        "ok",
      );
    } else {
      setStatus(`Ready — model: ${cfg.model}`, "ok");
    }
  } catch (err) {
    setStatus(`Config check failed: ${err}`, "error");
    startBtn.disabled = true;
  }
}

async function sendChunk(blob, mode, speechDurationMs = null, chunkSessionId = sessionId) {
  if (!blob || blob.size < 1200) {
    setStatus("Listening… (skipped tiny segment)", "recording");
    return;
  }

  const form = new FormData();
  const ext = blob.type.includes("wav") ? "wav" : "webm";
  form.append("file", blob, `chunk.${ext}`);
  form.append("temperature", "0");
  if (chunkSessionId) form.append("session_id", chunkSessionId);
  if (speechDurationMs != null) {
    form.append("speech_duration_ms", String(Math.round(speechDurationMs)));
  }

  setStatus("Sending speech segment to Whisper…", "recording");

  const res = await fetch(`/api/audio/${mode}`, {
    method: "POST",
    body: form,
  });

  const body = await res.json().catch(() => ({}));
  if (!res.ok) {
    const detail = body.detail || res.statusText;
    throw new Error(typeof detail === "string" ? detail : JSON.stringify(detail));
  }

  const text = cleanChunkText(body.text || "");
  if (!text || looksLikeHallucination(text)) {
    setStatus("Listening…", "recording");
    return;
  }

  const label =
    mode === "translations"
      ? "Translation → English"
      : "Transcription";

  if (streamLineEl.checked) {
    appendStreamText(text);
  } else {
    appendChunkEntry(text, `${label} · ${new Date().toLocaleTimeString()}`);
  }

  setStatus("Listening…", "recording");
}

function beginSpeechCapture() {
  if (!mediaStream || activeRecorder) return;

  const mimeType = pickMimeType();
  activeChunks = [];
  activeRecorder = new MediaRecorder(
    mediaStream,
    mimeType ? { mimeType } : undefined,
  );

  activeRecorder.ondataavailable = (ev) => {
    if (ev.data && ev.data.size > 0) activeChunks.push(ev.data);
  };

  activeRecorder.start();
  speechActive = true;
  speechStartedAt = Date.now();
  silenceStartedAt = 0;
  setStatus("Speaking…", "recording");
}

async function finishSpeechCapture() {
  if (!activeRecorder) return;

  const recorder = activeRecorder;
  const mimeType = recorder.mimeType || "audio/webm";
  activeRecorder = null;
  speechActive = false;
  silenceStartedAt = 0;

  const blob = await new Promise((resolve) => {
    recorder.onstop = () => {
      if (!activeChunks.length) {
        resolve(null);
        return;
      }
      resolve(new Blob(activeChunks, { type: mimeType }));
    };
    if (recorder.state === "recording") recorder.stop();
    else resolve(null);
  });

  activeChunks = [];
  const speechMs = Date.now() - speechStartedAt;
  const chunkSessionId = sessionId;
  if (!blob || speechMs < MIN_SPEECH_MS) {
    setStatus("Listening…", "recording");
    return;
  }

  try {
    await sendChunk(blob, modeEl.value, speechMs, chunkSessionId);
  } catch (err) {
    setStatus(`Whisper error: ${err.message}`, "error");
    stopMic();
  }
}

function pollVad() {
  if (!recording || !mediaStream) return;

  const rms = getRms();
  const now = Date.now();

  if (rms >= SPEECH_RMS) {
    silenceStartedAt = 0;
    if (!speechActive) beginSpeechCapture();
    if (speechActive && now - speechStartedAt >= MAX_SPEECH_MS) {
      finishSpeechCapture();
    }
    return;
  }

  if (!speechActive) {
    setStatus("Listening… (waiting for speech)", "recording");
    return;
  }

  if (!silenceStartedAt) silenceStartedAt = now;
  if (now - silenceStartedAt >= SILENCE_MS) {
    finishSpeechCapture();
  }
}

function startVadCapture() {
  pollVad();
  vadTimer = setInterval(pollVad, VAD_POLL_MS);
}

function startFixedChunkCycle() {
  const ms = Math.max(2, Number(chunkSecEl.value) || 6) * 1000;

  const recordOnce = () => {
    if (!recording || !mediaStream) return;

    const mimeType = pickMimeType();
    const chunks = [];
    const recorder = new MediaRecorder(
      mediaStream,
      mimeType ? { mimeType } : undefined,
    );

    recorder.ondataavailable = (ev) => {
      if (ev.data && ev.data.size > 0) chunks.push(ev.data);
    };

    recorder.onstop = async () => {
      if (!chunks.length) return;
      const blob = new Blob(chunks, { type: recorder.mimeType || "audio/webm" });
      try {
        await sendChunk(blob, modeEl.value);
      } catch (err) {
        setStatus(`Whisper error: ${err.message}`, "error");
        stopMic();
      }
    };

    recorder.start();
    setTimeout(() => {
      if (recorder.state === "recording") recorder.stop();
    }, ms);
  };

  recordOnce();
  chunkTimer = setInterval(recordOnce, ms);
}

async function startMic() {
  if (!navigator.mediaDevices?.getUserMedia) {
    setStatus("Microphone API not available in this browser.", "error");
    return;
  }

  try {
    mediaStream = await navigator.mediaDevices.getUserMedia({
      audio: {
        echoCancellation: true,
        noiseSuppression: true,
        autoGainControl: true,
      },
    });
  } catch (err) {
    setStatus(`Microphone permission denied: ${err.message}`, "error");
    return;
  }

  audioContext = new AudioContext();
  const source = audioContext.createMediaStreamSource(mediaStream);
  analyser = audioContext.createAnalyser();
  analyser.fftSize = 2048;
  source.connect(analyser);

  showStreamMode(streamLineEl.checked);
  clearTranscript();
  sessionId = crypto.randomUUID();
  recording = true;
  startBtn.disabled = true;
  stopBtn.disabled = false;
  clearBtn.disabled = true;
  modeEl.disabled = true;
  captureModeEl.disabled = true;
  chunkSecEl.disabled = true;
  streamLineEl.disabled = true;
  setCursorVisible(streamLineEl.checked);

  if (captureModeEl.value === "vad") {
    setStatus("Listening…", "recording");
    startVadCapture();
  } else {
    setStatus("Listening…", "recording");
    startFixedChunkCycle();
  }
}

function stopMic() {
  recording = false;

  if (speechActive) {
    finishSpeechCapture();
  }

  if (chunkTimer) {
    clearInterval(chunkTimer);
    chunkTimer = null;
  }
  if (vadTimer) {
    clearInterval(vadTimer);
    vadTimer = null;
  }

  if (mediaStream) {
    mediaStream.getTracks().forEach((t) => t.stop());
    mediaStream = null;
  }

  if (audioContext) {
    audioContext.close().catch(() => {});
    audioContext = null;
    analyser = null;
  }

  activeRecorder = null;
  activeChunks = [];
  speechActive = false;
  sessionId = null;

  startBtn.disabled = false;
  stopBtn.disabled = true;
  clearBtn.disabled = false;
  modeEl.disabled = false;
  captureModeEl.disabled = false;
  chunkSecEl.disabled = false;
  streamLineEl.disabled = false;
  setCursorVisible(false);
  setStatus("Stopped.", "");
}

startBtn.addEventListener("click", startMic);
stopBtn.addEventListener("click", stopMic);
clearBtn.addEventListener("click", clearTranscript);
streamLineEl.addEventListener("change", () => showStreamMode(streamLineEl.checked));
captureModeEl.addEventListener("change", updateCaptureUi);

showStreamMode(streamLineEl.checked);
updateCaptureUi();
loadConfig();
