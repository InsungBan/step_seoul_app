"""Copy a Firestore product image into its matching MySQL shoe variants."""

import json
import os
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen

import pymysql

from db.database import db

TEST_SHOE_ID = "airforce_black_m_280_00"
DEFAULT_PROJECT_ID = "stepseoulapp"


class ShoeImageSyncError(RuntimeError):
    """The source could not be read, so pending database writes must roll back."""


class InvalidShoeImageError(ValueError):
    """The document has no nonempty string shoeImage to copy."""


def firestore_shoe_document_id(shoe_id: str) -> str:
    """Remove a trailing gender_size_sequence suffix, keeping the product ID.

    Split from the right so product names containing underscores stay intact.
    Plain product IDs and IDs outside this variant format retain exact matching.
    """
    parts = shoe_id.rsplit("_", 3)
    if len(parts) == 4:
        product_id, gender, size, sequence = parts
        if (
            product_id
            and gender.lower() in ("m", "f", "u")
            and size.isascii()
            and size.isdigit()
            and sequence.isascii()
            and sequence.isdigit()
        ):
            return product_id
    return shoe_id


def read_firestore_shoe_image(shoe_id: str, *, project_id: str | None = None):
    project = project_id or os.getenv("FIREBASE_PROJECT_ID", DEFAULT_PROJECT_ID)
    document_id = firestore_shoe_document_id(shoe_id)
    url = (
        "https://firestore.googleapis.com/v1/projects/"
        f"{quote(project, safe='')}/databases/(default)/documents/shoe/"
        f"{quote(document_id, safe='')}"
    )
    headers = {"Accept": "application/json"}
    token = os.getenv("FIREBASE_AUTH_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"
    try:
        with urlopen(Request(url, headers=headers), timeout=15) as response:
            document = json.load(response)
    except HTTPError as error:
        status = error.code
        error.close()
        if status == 404:
            return None
        if status in (401, 403):
            raise ShoeImageSyncError(
                "Firestore denied access. Set FIREBASE_AUTH_TOKEN to an authorized "
                "Firebase ID token or Google OAuth access token."
            ) from None
        raise ShoeImageSyncError(f"Firestore request failed (HTTP {status}).") from None
    except (URLError, OSError, TimeoutError):
        raise ShoeImageSyncError("Could not connect to Firestore.") from None
    except (ValueError, UnicodeError):
        raise ShoeImageSyncError("Firestore returned invalid JSON.") from None

    if not isinstance(document, dict):
        raise ShoeImageSyncError("Firestore returned an invalid document.")
    fields = document.get("fields")
    image_field = fields.get("shoeImage") if isinstance(fields, dict) else None
    image = image_field.get("stringValue") if isinstance(image_field, dict) else None
    if not isinstance(image, str) or not image.strip():
        raise InvalidShoeImageError("Firestore shoeImage must be a nonempty string.")
    return image


def sync_shoe_images(
    shoe_id: str | None = None,
    *,
    project_id: str | None = None,
    create_test_shoe: bool = False,
    dry_run: bool = False,
):
    if create_test_shoe:
        if shoe_id is not None and shoe_id != TEST_SHOE_ID:
            raise ValueError(f"Test creation is only supported for {TEST_SHOE_ID}.")
        shoe_id = TEST_SHOE_ID
    if shoe_id is not None and (not shoe_id or len(shoe_id) > 45 or "/" in shoe_id):
        raise ValueError("shoe_id must contain 1 to 45 characters and no slash.")

    result = {
        "created": [],
        "updated": [],
        "unchanged": [],
        "skipped": [],
        "dry_run": dry_run,
    }
    conn = db()
    try:
        with conn.cursor(pymysql.cursors.DictCursor) as cursor:
            if shoe_id is None:
                cursor.execute("SELECT * FROM `shoe` ORDER BY `shoe_id`")
            else:
                cursor.execute(
                    "SELECT * FROM `shoe` WHERE BINARY `shoe_id` = BINARY %s",
                    (shoe_id,),
                )
            rows = list(cursor.fetchall())
            if not rows and shoe_id is not None:
                if create_test_shoe:
                    rows = [{"shoe_id": shoe_id, "_create_test_shoe": True}]
                else:
                    result["skipped"].append(
                        {"shoe_id": shoe_id, "reason": "MySQL shoe_id not found."}
                    )

            for row in rows:
                current_id = row["shoe_id"]
                try:
                    image = read_firestore_shoe_image(current_id, project_id=project_id)
                except InvalidShoeImageError as error:
                    result["skipped"].append({"shoe_id": current_id, "reason": str(error)})
                    continue
                if image is None:
                    result["skipped"].append(
                        {"shoe_id": current_id, "reason": "Firestore document not found."}
                    )
                    continue

                if row.get("_create_test_shoe"):
                    if not dry_run:
                        cursor.execute(
                            "INSERT INTO `shoe` (`shoe_id`, `shoe_img_url`, `shoe_image_url`) "
                            "VALUES (%s, %s, %s)",
                            (current_id, image, image),
                        )
                    result["created"].append(current_id)
                elif row.get("shoe_img_url") == image and row.get("shoe_image_url") == image:
                    result["unchanged"].append(current_id)
                else:
                    if not dry_run:
                        cursor.execute(
                            "UPDATE `shoe` SET `shoe_img_url` = %s, `shoe_image_url` = %s "
                            "WHERE BINARY `shoe_id` = BINARY %s",
                            (image, image, current_id),
                        )
                    result["updated"].append(current_id)
        if dry_run:
            conn.rollback()
        else:
            conn.commit()
        return result
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()
