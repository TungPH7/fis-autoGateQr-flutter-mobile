#!/usr/bin/env python3
"""
Script to add gates to Firebase Firestore database.

Usage:
    1. Install firebase-admin: pip install firebase-admin
    2. Download service account key from Firebase Console:
       - Go to Project Settings > Service Accounts
       - Click "Generate new private key"
       - Save the JSON file
    3. Set the path to your service account key below
    4. Run: python add_gates.py
"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# ========== CONFIGURATION ==========
# Path to your Firebase service account key JSON file
SERVICE_ACCOUNT_KEY_PATH = "../lib/keys/autogateqr-firebase-adminsdk-fbsvc-b69082406a.json"

# Gates to add
GATES_DATA = [
    {
        "gateCode": "GATE-01",
        "gateName": "Cổng chính",
        "gateType": "both",  # 'in', 'out', or 'both'
        "isActive": True,
        "assignedGuards": [],
        "location": None,  # GeoPoint(latitude, longitude) if needed
    },
    {
        "gateCode": "GATE-02",
        "gateName": "Cổng phụ",
        "gateType": "both",
        "isActive": True,
        "assignedGuards": [],
        "location": None,
    },
    {
        "gateCode": "GATE-03",
        "gateName": "Cổng nhập hàng",
        "gateType": "in",
        "isActive": True,
        "assignedGuards": [],
        "location": None,
    },
    {
        "gateCode": "GATE-04",
        "gateName": "Cổng xuất hàng",
        "gateType": "out",
        "isActive": True,
        "assignedGuards": [],
        "location": None,
    },
]
# ===================================


def initialize_firebase():
    """Initialize Firebase Admin SDK."""
    try:
        cred = credentials.Certificate(SERVICE_ACCOUNT_KEY_PATH)
        firebase_admin.initialize_app(cred)
        print("✅ Firebase initialized successfully")
        return firestore.client()
    except FileNotFoundError:
        print(f"❌ Error: Service account key not found at '{SERVICE_ACCOUNT_KEY_PATH}'")
        print("\nPlease download the service account key from Firebase Console:")
        print("  1. Go to Project Settings > Service Accounts")
        print("  2. Click 'Generate new private key'")
        print("  3. Save the JSON file and update SERVICE_ACCOUNT_KEY_PATH")
        return None
    except Exception as e:
        print(f"❌ Error initializing Firebase: {e}")
        return None


def add_gates(db):
    """Add gates to Firestore."""
    collection_ref = db.collection("gates")
    added_count = 0
    skipped_count = 0

    print("\n📋 Adding gates to Firestore...")
    print("-" * 50)

    for gate_data in GATES_DATA:
        gate_code = gate_data["gateCode"]

        # Check if gate already exists
        existing = collection_ref.where("gateCode", "==", gate_code).limit(1).get()

        if len(existing) > 0:
            print(f"⏭️  Skipped: {gate_data['gateName']} ({gate_code}) - already exists")
            skipped_count += 1
            continue

        # Prepare gate document
        now = datetime.now()
        gate_doc = {
            "gateCode": gate_data["gateCode"],
            "gateName": gate_data["gateName"],
            "gateType": gate_data["gateType"],
            "isActive": gate_data["isActive"],
            "assignedGuards": gate_data["assignedGuards"],
            "location": gate_data["location"],
            "createdAt": now,
            "updatedAt": None,
        }

        # Add to Firestore
        doc_ref = collection_ref.add(gate_doc)
        print(f"✅ Added: {gate_data['gateName']} ({gate_code}) - ID: {doc_ref[1].id}")
        added_count += 1

    print("-" * 50)
    print(f"\n📊 Summary:")
    print(f"   Added: {added_count}")
    print(f"   Skipped: {skipped_count}")
    print(f"   Total: {len(GATES_DATA)}")


def list_gates(db):
    """List all gates in Firestore."""
    collection_ref = db.collection("gates")
    gates = collection_ref.get()

    print("\n📋 Current gates in database:")
    print("-" * 60)
    print(f"{'ID':<25} {'Code':<12} {'Name':<20} {'Type':<8} {'Active'}")
    print("-" * 60)

    for gate in gates:
        data = gate.to_dict()
        print(f"{gate.id:<25} {data.get('gateCode', 'N/A'):<12} {data.get('gateName', 'N/A'):<20} {data.get('gateType', 'N/A'):<8} {data.get('isActive', False)}")

    print("-" * 60)
    print(f"Total: {len(gates)} gates")


def delete_all_gates(db):
    """Delete all gates (use with caution!)."""
    collection_ref = db.collection("gates")
    gates = collection_ref.get()

    print("\n⚠️  Deleting all gates...")

    for gate in gates:
        gate.reference.delete()
        print(f"🗑️  Deleted: {gate.id}")

    print(f"\n✅ Deleted {len(gates)} gates")


def main():
    print("=" * 60)
    print("🚪 Gate Management Script for AutoGateQR")
    print("=" * 60)

    # Initialize Firebase
    db = initialize_firebase()
    if db is None:
        return

    while True:
        print("\n📌 Options:")
        print("  1. Add gates (from GATES_DATA)")
        print("  2. List all gates")
        print("  3. Delete all gates (⚠️ caution!)")
        print("  4. Exit")

        choice = input("\nEnter choice (1-4): ").strip()

        if choice == "1":
            add_gates(db)
        elif choice == "2":
            list_gates(db)
        elif choice == "3":
            confirm = input("⚠️  Are you sure you want to delete ALL gates? (yes/no): ").strip().lower()
            if confirm == "yes":
                delete_all_gates(db)
            else:
                print("Cancelled.")
        elif choice == "4":
            print("\n👋 Goodbye!")
            break
        else:
            print("❌ Invalid choice. Please try again.")


if __name__ == "__main__":
    main()
