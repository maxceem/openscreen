import { describe, expect, it } from "vitest";
import {
	normalizeNativeMacCaptureBounds,
	parseMacDisplayIdFromSourceId,
	parseMacWindowIdFromSourceId,
} from "./nativeMacRecording";

describe("nativeMacRecording source parsing", () => {
	it("parses Electron window source ids into ScreenCaptureKit window ids", () => {
		expect(parseMacWindowIdFromSourceId("window:12345:0")).toBe(12345);
		expect(parseMacWindowIdFromSourceId("window:987")).toBe(987);
	});

	it("rejects non-window source ids for window parsing", () => {
		expect(parseMacWindowIdFromSourceId("screen:1:0")).toBeNull();
		expect(parseMacWindowIdFromSourceId("window:not-a-number:0")).toBeNull();
		expect(parseMacWindowIdFromSourceId(null)).toBeNull();
	});

	it("parses Electron display source ids into ScreenCaptureKit display ids", () => {
		expect(parseMacDisplayIdFromSourceId("screen:1:0")).toBe(1);
		expect(parseMacDisplayIdFromSourceId("screen:69733248")).toBe(69733248);
	});

	it("rejects non-display source ids for display parsing", () => {
		expect(parseMacDisplayIdFromSourceId("window:123:0")).toBeNull();
		expect(parseMacDisplayIdFromSourceId("screen:not-a-number:0")).toBeNull();
		expect(parseMacDisplayIdFromSourceId(undefined)).toBeNull();
	});

	it("normalizes helper-reported capture bounds", () => {
		expect(normalizeNativeMacCaptureBounds({ x: 12, y: 34, width: 640, height: 360 })).toEqual({
			x: 12,
			y: 34,
			width: 640,
			height: 360,
		});
		expect(normalizeNativeMacCaptureBounds({ x: 0, y: 0, width: 0, height: 360 })).toBeNull();
		expect(
			normalizeNativeMacCaptureBounds({ x: 0, y: Number.NaN, width: 640, height: 360 }),
		).toBeNull();
	});
});
