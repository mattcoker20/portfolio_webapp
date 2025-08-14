function parseClientPrincipal(req) {
  try {
    const encoded = req.headers["x-ms-client-principal"];
    if (!encoded) return null;
    const decoded = Buffer.from(encoded, "base64").toString("ascii");
    return JSON.parse(decoded);
  } catch {
    return null;
  }
}
module.exports = { parseClientPrincipal };
