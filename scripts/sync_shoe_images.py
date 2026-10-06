"""Sync Firestore shoeImage to MySQL; optionally create the requested test shoe."""

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from services.shoe_image_sync_service import TEST_SHOE_ID, sync_shoe_images
from services.shoe_schema import ensure_shoe_schema


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--shoe-id", help="Sync only this exact shoe_id; defaults to all MySQL shoes.")
    parser.add_argument("--project-id", help="Firebase project (default: FIREBASE_PROJECT_ID or stepseoulapp).")
    parser.add_argument(
        "--create-test-shoe",
        action="store_true",
        help=f"Create {TEST_SHOE_ID} if absent, using its existing Firestore image.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Preview without changing rows or schema.")
    args = parser.parse_args()
    if args.create_test_shoe and args.shoe_id not in (None, TEST_SHOE_ID):
        parser.error(f"--create-test-shoe requires --shoe-id {TEST_SHOE_ID} (or omit --shoe-id).")
    if args.shoe_id is not None and (not args.shoe_id or len(args.shoe_id) > 45 or "/" in args.shoe_id):
        parser.error("--shoe-id must contain 1 to 45 characters and no slash.")
    if not args.dry_run:
        ensure_shoe_schema()
    result = sync_shoe_images(
        args.shoe_id,
        project_id=args.project_id,
        create_test_shoe=args.create_test_shoe,
        dry_run=args.dry_run,
    )
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
