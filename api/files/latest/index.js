const { CosmosClient } = require("@azure/cosmos");
const { BlobSASPermissions, generateBlobSASQueryParameters, SASProtocol, StorageSharedKeyCredential } = require("@azure/storage-blob");

module.exports = async function (context, req) {
  const cosmos = new CosmosClient(process.env.COSMOS_CONNECTION);
  const container = cosmos.database("portfolio").container("files");

  const query = {
    query: "SELECT TOP 1 * FROM c WHERE c.published = true ORDER BY c.createdAt DESC"
  };
  const { resources } = await container.items.query(query).fetchAll();
  const file = resources[0];
  if (!file) return { status: 404, body: "No published file" };

  const accountName = process.env.STORAGE_ACCOUNT_NAME;
  const accountKey  = process.env.STORAGE_ACCOUNT_KEY;
  const containerName = process.env.BLOB_CONTAINER || "uploads";

  const { BlobSASPermissions, generateBlobSASQueryParameters, SASProtocol, StorageSharedKeyCredential } = require("@azure/storage-blob");
  const cred = new StorageSharedKeyCredential(accountName, accountKey);
  const expiresOn = new Date(Date.now() + 10 * 60 * 1000);
  const sas = generateBlobSASQueryParameters({
    containerName,
    blobName: file.blobPath,
    permissions: BlobSASPermissions.parse("r"),
    startsOn: new Date(Date.now() - 60 * 1000),
    expiresOn,
    protocol: SASProtocol.Https
  }, cred).toString();

  const url = `https://${accountName}.blob.core.windows.net/${containerName}/${file.blobPath}?${sas}`;
  return { status: 200, jsonBody: { url, id: file.id, fileName: file.fileName, contentType: file.contentType } };
}
