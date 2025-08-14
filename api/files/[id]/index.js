const { CosmosClient } = require("@azure/cosmos");
const { BlobSASPermissions, generateBlobSASQueryParameters, SASProtocol, StorageSharedKeyCredential } = require("@azure/storage-blob");

module.exports = async function (context, req) {
  const id = context.bindingData.id;
  if (!id) return { status: 400, body: "id required" };

  const cosmos = new CosmosClient(process.env.COSMOS_CONNECTION);
  const container = cosmos.database("portfolio").container("files");

  try {
    const { resource: file } = await container.item(id, id).read();
    if (!file || !file.published) return { status: 404, body: "Not found" };

    const accountName = process.env.STORAGE_ACCOUNT_NAME;
    const accountKey  = process.env.STORAGE_ACCOUNT_KEY;
    const containerName = process.env.BLOB_CONTAINER || "uploads";

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
    return { status: 200, jsonBody: { url, fileName: file.fileName, contentType: file.contentType } };
  } catch (e) {
    context.log.error(e);
    return { status: 404, body: "Not found" };
  }
}
