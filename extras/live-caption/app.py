"""Live mic client for Whisper on OpenShift AI (proxies audio to vLLM)."""

from __future__ import annotations

import logging
import os
import time
from pathlib import Path
from typing import Any

import httpx
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles

STATIC_DIR = Path(__file__).resolve().parent / "static"

WHISPER_BASE_URL = os.environ.get("WHISPER_BASE_URL", "").rstrip("/")
WHISPER_BEARER_TOKEN = os.environ.get("WHISPER_BEARER_TOKEN", "").strip()
WHISPER_MODEL = os.environ.get("WHISPER_MODEL", "whisper-large-v3")
WHISPER_VERIFY_SSL = os.environ.get("WHISPER_VERIFY_SSL", "false").lower() in (
    "1",
    "true",
    "yes",
)
CHUNK_TIMEOUT_SEC = float(os.environ.get("WHISPER_CHUNK_TIMEOUT_SEC", "120"))

MLFLOW_ENABLED = os.environ.get("MLFLOW_ENABLED", "false").lower() in (
    "1",
    "true",
    "yes",
)
MLFLOW_TRACKING_URI = os.environ.get("MLFLOW_TRACKING_URI", "").strip()
MLFLOW_EXPERIMENT_NAME = os.environ.get(
    "MLFLOW_EXPERIMENT_NAME", "whisper-live-caption"
)
MLFLOW_TRACKING_TOKEN = os.environ.get("MLFLOW_TRACKING_TOKEN", "").strip()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

_mlflow_active = False


def _configure_mlflow() -> bool:
    global _mlflow_active
    if not MLFLOW_ENABLED or not MLFLOW_TRACKING_URI:
        return False

    try:
        import mlflow

        if MLFLOW_TRACKING_TOKEN:
            os.environ.setdefault(
                "MLFLOW_TRACKING_TOKEN", MLFLOW_TRACKING_TOKEN
            )

        mlflow.set_tracking_uri(MLFLOW_TRACKING_URI)
        mlflow.set_experiment(MLFLOW_EXPERIMENT_NAME)
        _mlflow_active = True
        logger.info(
            "MLflow tracing enabled (uri=%s experiment=%s)",
            MLFLOW_TRACKING_URI,
            MLFLOW_EXPERIMENT_NAME,
        )
        return True
    except Exception as exc:
        logger.warning("MLflow setup failed; tracing disabled: %s", exc)
        return False


_configure_mlflow()

app = FastAPI(title="Whisper live caption", version="0.3.0")


def _whisper_headers() -> dict[str, str]:
    if not WHISPER_BEARER_TOKEN:
        return {}
    return {"Authorization": f"Bearer {WHISPER_BEARER_TOKEN}"}


def _check_config() -> None:
    if not WHISPER_BASE_URL:
        raise HTTPException(
            status_code=503,
            detail="WHISPER_BASE_URL is not set on the live-caption pod.",
        )


def _trace_whisper_segment(
    *,
    mode: str,
    model_name: str,
    filename: str,
    content_type: str,
    audio_size_bytes: int,
    session_id: str | None,
    speech_duration_ms: int | None,
    temperature: str | None,
    whisper_latency_ms: float,
    total_latency_ms: float,
    http_status: int,
    text: str,
) -> None:
    if not _mlflow_active:
        return

    try:
        import mlflow

        inputs: dict[str, Any] = {
            "mode": mode,
            "model": model_name,
            "filename": filename,
            "content_type": content_type,
            "audio_size_bytes": audio_size_bytes,
            "session_id": session_id or "",
            "speech_duration_ms": speech_duration_ms,
            "temperature": temperature,
        }
        outputs: dict[str, Any] = {
            "text": text,
            "text_length": len(text),
            "whisper_latency_ms": round(whisper_latency_ms, 1),
            "total_latency_ms": round(total_latency_ms, 1),
            "http_status": http_status,
        }

        with mlflow.start_span(
            name="whisper_audio_segment",
            span_type="CHAIN",
        ) as span:
            span.set_inputs(inputs)
            span.set_outputs(outputs)
            span.set_attributes(
                {
                    "app": "whisper-live-caption",
                    "mode": mode,
                    "model": model_name,
                }
            )
            # Reserved session metadata — this is what the MLflow Sessions UI groups on.
            # A custom tag named session_id is not enough (MLflow 3.11+).
            preview = (text or "").strip()[:240] or "(empty)"
            mlflow.update_current_trace(
                session_id=session_id or None,
                user="whisper-live-caption",
                request_preview=preview,
                tags={
                    "app": "whisper-live-caption",
                    "mode": mode,
                    "model": model_name,
                },
            )
    except Exception as exc:
        logger.warning("MLflow trace logging failed: %s", exc)


async def _call_whisper(
    *,
    mode: str,
    model_name: str,
    filename: str,
    content_type: str,
    audio_bytes: bytes,
    temperature: str | None,
) -> tuple[dict[str, Any], float, int]:
    url = f"{WHISPER_BASE_URL}/v1/audio/{mode}"
    form_data: dict[str, str] = {"model": model_name}
    if temperature is not None and temperature.strip() != "":
        form_data["temperature"] = temperature.strip()

    whisper_start = time.perf_counter()
    async with httpx.AsyncClient(
        verify=WHISPER_VERIFY_SSL, timeout=CHUNK_TIMEOUT_SEC
    ) as client:
        response = await client.post(
            url,
            headers=_whisper_headers(),
            files={"file": (filename, audio_bytes, content_type)},
            data=form_data,
        )
    whisper_latency_ms = (time.perf_counter() - whisper_start) * 1000

    if response.status_code >= 400:
        raise HTTPException(
            status_code=response.status_code, detail=response.text
        )

    try:
        payload: dict[str, Any] = response.json()
    except ValueError:
        payload = {"text": response.text}

    return payload, whisper_latency_ms, response.status_code


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/api/config")
async def config() -> JSONResponse:
    return JSONResponse(
        {
            "whisperConfigured": bool(WHISPER_BASE_URL and WHISPER_BEARER_TOKEN),
            "model": WHISPER_MODEL,
            "defaultMode": "translations",
            "mlflowEnabled": _mlflow_active,
            "mlflowExperiment": MLFLOW_EXPERIMENT_NAME if _mlflow_active else None,
        }
    )


@app.post("/api/audio/{mode}")
async def proxy_audio(
    mode: str,
    file: UploadFile = File(...),
    model: str | None = Form(None),
    temperature: str | None = Form(None),
    session_id: str | None = Form(None),
    speech_duration_ms: str | None = Form(None),
) -> JSONResponse:
    _check_config()
    if mode not in ("transcriptions", "translations"):
        raise HTTPException(
            status_code=400,
            detail="mode must be transcriptions or translations",
        )

    model_name = (model or WHISPER_MODEL).strip()
    content = await file.read()
    if not content:
        raise HTTPException(status_code=400, detail="empty audio chunk")

    filename = file.filename or "chunk.webm"
    content_type = file.content_type or "application/octet-stream"

    parsed_speech_ms: int | None = None
    if speech_duration_ms and speech_duration_ms.strip().isdigit():
        parsed_speech_ms = int(speech_duration_ms.strip())

    total_start = time.perf_counter()
    try:
        payload, whisper_latency_ms, http_status = await _call_whisper(
            mode=mode,
            model_name=model_name,
            filename=filename,
            content_type=content_type,
            audio_bytes=content,
            temperature=temperature,
        )
    except HTTPException:
        raise
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Whisper request failed: {exc}",
        ) from exc
    total_latency_ms = (time.perf_counter() - total_start) * 1000

    text = str(payload.get("text", ""))
    _trace_whisper_segment(
        mode=mode,
        model_name=model_name,
        filename=filename,
        content_type=content_type,
        audio_size_bytes=len(content),
        session_id=session_id,
        speech_duration_ms=parsed_speech_ms,
        temperature=temperature,
        whisper_latency_ms=whisper_latency_ms,
        total_latency_ms=total_latency_ms,
        http_status=http_status,
        text=text,
    )

    return JSONResponse({"text": text, "raw": payload})


app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")


@app.get("/")
async def index() -> FileResponse:
    return FileResponse(STATIC_DIR / "index.html")
