
const test = require("node:test");
const assert = require("node:assert/strict");

const BASE_URL = process.env.BASE_URL || "http://localhost:3000";

test("health endpoint responds successfully", async () => {
  const response = await fetch(`${BASE_URL}/healthz`);

  assert.equal(response.status, 200);
});

test("orders endpoint returns usable order data", async () => {
  const response = await fetch(`${BASE_URL}/api/orders`);

  assert.equal(response.status, 200);

  const body = await response.json();

  assert.ok(Array.isArray(body.orders));
  assert.ok(body.orders.length > 0);
});
