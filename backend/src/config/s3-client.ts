import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { config } from '@src/config'

const client = new S3Client({
  region: "us-east-1",
  endpoint: "https://s3.filebase.com",
  credentials: {
    accessKeyId: config.accessKeyId,
    secretAccessKey: config.secretAccessKey,
  },
  forcePathStyle: true, // IMPORTANT for Filebase
});

export default client
