import type { Rectangle } from "electron";
import type { CursorCaptureMode } from "./recordingSession";

export type NativeMacSourceType = "display" | "window";

export type NativeMacRecordingRequest = {
	schemaVersion: 1;
	recordingId?: number;
	source: {
		type: NativeMacSourceType;
		sourceId: string;
		displayId?: number;
		windowId?: number;
		bounds?: Rectangle;
	};
	video: {
		fps: number;
		width: number;
		height: number;
		bitrate?: number;
		hideSystemCursor: boolean;
	};
	audio: {
		system: {
			enabled: boolean;
		};
		microphone: {
			enabled: boolean;
			deviceId?: string;
			deviceName?: string;
			gain: number;
		};
	};
	webcam: {
		enabled: boolean;
		deviceId?: string;
		deviceName?: string;
		width: number;
		height: number;
		fps: number;
	};
	cursor: {
		mode: CursorCaptureMode;
	};
	outputs: {
		screenPath: string;
		manifestPath?: string;
	};
};

export type NativeMacHelperReadyEvent = {
	event: "ready";
	schemaVersion: 1;
};

export type NativeMacHelperRecordingStartedEvent = {
	event: "recording-started";
	timestampMs: number;
};

export type NativeMacHelperRecordingStoppedEvent = {
	event: "recording-stopped";
	screenPath: string;
};

export type NativeMacHelperWarningEvent = {
	event: "warning";
	code: string;
	message: string;
};

export type NativeMacHelperErrorEvent = {
	event: "error";
	code: string;
	message: string;
};

export type NativeMacHelperEvent =
	| NativeMacHelperReadyEvent
	| NativeMacHelperRecordingStartedEvent
	| NativeMacHelperRecordingStoppedEvent
	| NativeMacHelperWarningEvent
	| NativeMacHelperErrorEvent;

export type NativeMacRecordingStartResult = {
	success: boolean;
	recordingId?: number;
	path?: string;
	helperPath?: string;
	error?: string;
};

export function parseMacWindowIdFromSourceId(sourceId?: string | null) {
	if (!sourceId?.startsWith("window:")) {
		return null;
	}

	const windowIdPart = sourceId.split(":")[1];
	if (!windowIdPart || !/^\d+$/.test(windowIdPart)) {
		return null;
	}

	return Number(windowIdPart);
}

export function parseMacDisplayIdFromSourceId(sourceId?: string | null) {
	if (!sourceId?.startsWith("screen:")) {
		return null;
	}

	const displayIdPart = sourceId.split(":")[1];
	if (!displayIdPart || !/^\d+$/.test(displayIdPart)) {
		return null;
	}

	return Number(displayIdPart);
}

export function normalizeNativeMacCaptureBounds(value: unknown): Rectangle | null {
	if (!value || typeof value !== "object") {
		return null;
	}

	const candidate = value as Partial<Rectangle>;
	const x = Number(candidate.x);
	const y = Number(candidate.y);
	const width = Number(candidate.width);
	const height = Number(candidate.height);

	if (
		!Number.isFinite(x) ||
		!Number.isFinite(y) ||
		!Number.isFinite(width) ||
		!Number.isFinite(height) ||
		width <= 0 ||
		height <= 0
	) {
		return null;
	}

	return { x, y, width, height };
}
