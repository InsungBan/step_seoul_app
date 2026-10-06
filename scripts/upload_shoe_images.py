"""Upload `assets/shoes/{shoe_id}.{jpg,jpeg,png,webp}` to Firebase Storage.

Prerequisites:
  pip install firebase-admin
  Set FIREBASE_SERVICE_ACCOUNT to the *local* service account JSON path.
  Put images in assets/shoes/, named exactly after the MySQL shoe_id.

The script updates `shoe.shoe_img_url` and the legacy `shoe.shoe_image_url`
only after each successful upload.
Do not commit the service account JSON file.
"""

import mimetypes
import os
import sys
from urllib.parse import quote
from uuid import uuid4
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, storage

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from db.database import db
from services.shoe_schema import ensure_shoe_schema

IMAGE_DIRECTORY = ROOT / "assets" / "shoes"
BUCKET_NAME = "stepseoulapp.firebasestorage.app"
SUPPORTED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}


def main():
    service_account = os.environ.get("FIREBASE_SERVICE_ACCOUNT")
    if not service_account:
        raise SystemExit("Set FIREBASE_SERVICE_ACCOUNT to a Firebase Admin service-account JSON file.")
    if not IMAGE_DIRECTORY.is_dir():
        raise SystemExit(f"Image directory not found: {IMAGE_DIRECTORY}")

    firebase_admin.initialize_app(credentials.Certificate(service_account), {"storageBucket": BUCKET_NAME})
    bucket = storage.bucket()
    images = [path for path in IMAGE_DIRECTORY.iterdir() if path.suffix.lower() in SUPPORTED_EXTENSIONS]
    if not images:
        raise SystemExit("No shoe images found. Use assets/shoes/{shoe_id}.jpg.")

    ensure_shoe_schema()
    conn = db()
    try:
        with conn.cursor() as cursor:
            for image_path in images:
                shoe_id = image_path.stem
                cursor.execute("SELECT 1 FROM `shoe` WHERE `shoe_id` = %s", (shoe_id,))
                if cursor.fetchone() is None:
                    print(f"SKIP {image_path.name}: shoe_id {shoe_id!r} does not exist")
                    continue
                object_name = f"shoes/{shoe_id}/main{image_path.suffix.lower()}"
                token = str(uuid4())
                blob = bucket.blob(object_name)
                blob.metadata = {"firebaseStorageDownloadTokens": token}
                blob.upload_from_filename(
                    image_path,
                    content_type=mimetypes.guess_type(image_path.name)[0] or "image/jpeg",
                )
                download_url = (
                    f"https://firebasestorage.googleapis.com/v0/b/{BUCKET_NAME}/o/"
                    f"{quote(object_name, safe='')}?alt=media&token={token}"
                )
                cursor.execute(
                    "UPDATE `shoe` SET `shoe_img_url` = %s, `shoe_image_url` = %s WHERE `shoe_id` = %s",
                    (download_url, download_url, shoe_id),
                )
                print(f"UPLOADED {shoe_id}: {download_url}")
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


if __name__ == "__main__":
    main()
