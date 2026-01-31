import { PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3'
import { getSignedUrl } from '@aws-sdk/s3-request-presigner'
import client from '@src/config/s3-client'
import { config } from '@src/config'
import path from 'path'

function buildS3Key(originalName: string) {
    const ext = path.extname(originalName).toLowerCase();
    const filename = path
        .basename(originalName, ext)
        .toLowerCase()
        .replace(/[^a-z0-9-_]/g, "-");

    const suffix = Math.random().toString(36).slice(2, 2 + 5);

    return `uploads/${filename}/${suffix}${ext}`;
}

export async function getUploadUrl(filename: string, type: string) {
    const key = buildS3Key(filename);
    const command = new PutObjectCommand({
        Bucket: config.bucketName,
        Key: key,
        ContentType: type,
    });
    const uploadUrl = await getSignedUrl(client, command, { expiresIn: 3600 })
    return { uploadUrl, key }
}

export async function getDownloadUrl(key: string) {
    const command = new GetObjectCommand({
        Bucket: config.bucketName,
        Key: key,
    });

    return getSignedUrl(client, command, { expiresIn: 3600 });
}

export async function uploadFile(file: Express.Multer.File) {
    const { uploadUrl, key } = await getUploadUrl(file.originalname, file.mimetype);
    await fetch(uploadUrl, {
        method: "PUT",
        body: file.buffer,
        headers: {
            "Content-Type": file.mimetype,
        },
    });
    return key;
}