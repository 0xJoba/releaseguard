
const http = require("node:http");

const PORT = Number(process.env.PORT) || 3000;
const RELEASE_MODE = process.env.RELEASE_MODE || "healthy";
const RELEASE_VERSION = process.env.RELEASE_VERSION || "v1";

const server = http.createServer((req, res) => {
  res.setHeader("Content-Type", "application/json");

  if (req.url === "/healthz") {
    res.writeHead(200);
    return res.end(JSON.stringify({ status: "alive" }));
  }

  if (req.url === "/api/orders") {
    if (RELEASE_MODE === "broken") {
      console.error("INCIDENT: order processing failed in the current release");
      res.writeHead(500);
      return res.end(JSON.stringify({
        error: "Internal Server Error",
        message: "Order processing is unavailable"
      }));
    }

    res.writeHead(200);
    return res.end(JSON.stringify({
      release: RELEASE_VERSION,
      orders: [
        { id: "ORD-1001", status: "processing" },
        { id: "ORD-1002", status: "shipped" }
      ]
    }));
  }

  res.writeHead(404);
  res.end(JSON.stringify({ error: "Not Found" }));
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`ReleaseGuard API listening on port ${PORT}`);
  console.log(`Release mode: ${RELEASE_MODE}`);
});
