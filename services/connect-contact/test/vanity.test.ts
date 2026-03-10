import test from "node:test";
import assert from "node:assert/strict";
import { generateVanityNumbers, normalizePhoneNumber } from "../src/vanity.js";

test("normalizePhoneNumber strips non-digits and country code", () => {
  assert.equal(normalizePhoneNumber("+1 (800) 356-9377"), "8003569377");
});

test("generateVanityNumbers returns FLOWERS candidate for 8003569377", () => {
  const candidates = generateVanityNumbers("8003569377");
  assert.ok(candidates.some((value) => value.includes("FLOWERS")));
});

test("generateVanityNumbers respects requested limit", () => {
  const candidates = generateVanityNumbers("8005551234", 3);
  assert.ok(candidates.length <= 3);
});
