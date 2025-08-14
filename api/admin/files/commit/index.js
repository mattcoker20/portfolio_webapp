const { CosmosClient } = require("@azure/cosmos");
const { v4: uuid } = require("uuid");
const { parseClientPrincipal } = require("../../shared");

module.exports = async function (context, req) {
  const user = parseClientPrincipal(req);
  if (!user?.userRoles?.includes("admin")) return { status: 403, body: "Forbidden" };

  const { blobPath, fileName, contentType, published = true } = req.body || {};
  if (!blobPath || !fileName) return { status: 400, body: "blobPath and fileName required" };

  const client = new CosmosClient(process.env.COSMOS_CONNECTION);
  const container = client.database("portfolio").container("files");

  const item = {
    id: uuid(),
    blobPath, fileName, contentType,
    published: !!published,
    createdAt: new Date().toISOString()
  };
  await container.items.create(item);
  return { status: 200, jsonBody: item };
}
