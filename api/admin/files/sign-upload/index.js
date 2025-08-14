const { BlobSASPermissions, generateBlobSASQueryParameters, SASProtocol, StorageSharedKeyCredential } = require("@azure/storage-blob");
const { v4: uuid } = require("uuid");
const { parseClientPrincipal } = require("../../shared");

module.exports = async function (context, req) {
  try {
    const body = req.body || {};
    const fileName = (body.fileName||"").toString();
    const contentType = (body.contentType||"application/octet-stream").toString();
    if (!fileName) return { status: 400, body: "fileName required" };

    const user = parseClientPrincipal(req);
    if (!user?.userRoles?.includes("admin")) return { status: 403, body: "Forbidden" };

    const accountName = process.env.STORAGE_ACCOUNT_NAME;
    const accountKey  = process.env.STORAGE_ACCOUNT_KEY;
    const container   = process.env.BLOB_CONTAINER || "uploads";
    if (!accountName || !accountKey) return { status: 500, body: "Storage settings missing" };

    const blobPath = `uploads/${uuid()}-${fileName.replace(/[^a-zA-Z0-9._-]/g, "_")}`;
    const expiresOn = new Date(Date.now() + 10 * 60 * 1000);

    const cred = new StorageSharedKeyCredential(accountName, accountKey);
    const sas = generateBlobSASQueryParameters({
      containerName: container,
      blobName: blobPath,
      permissions: BlobSASPermissions.parse("cw"),
      startsOn: new Date(Date.now() - 60 * 1000),
      expiresOn,
      protocol: SASProtocol.Https
    }, cred).toString();

    const url = `https://${accountName}.blob.core.windows.net/${container}/${blobPath}?${sas}`;
    return { status: 200, jsonBody: { uploadUrl: url, blobPath, contentType } };
  } catch (e) {
    context.log.error(e);
    return { status: 500, body: "error" };
  }
}
