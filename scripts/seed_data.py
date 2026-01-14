import firebase_admin
from firebase_admin import credentials, firestore, auth
import argparse
import os
from datetime import datetime

# Initialize Firebase Admin
# Expects GOOGLE_APPLICATION_CREDENTIALS to be set or use emulator
def init_firebase(project_id, use_emulator):
    if use_emulator:
        os.environ["FIRESTORE_EMULATOR_HOST"] = "localhost:8080"
        os.environ["FIREBASE_AUTH_EMULATOR_HOST"] = "localhost:9099"
        # No creds needed for emulator
        firebase_admin.initialize_app(options={'projectId': project_id})
    else:
        # For real firebase, you need a service account json
        # This is just a placeholder structure
        cred = credentials.ApplicationDefault()
        firebase_admin.initialize_app(cred, {'projectId': project_id})

def seed_data(db):
    print("Seeding data...")
    
    # 1. Create a Test User (or get UID if exists)
    email = "test@example.com"
    pwd = "password123"
    try:
        user = auth.get_user_by_email(email)
        print(f"User {email} already exists: {user.uid}")
        uid = user.uid
    except:
        user = auth.create_user(email=email, password=pwd)
        print(f"Created user {email}: {user.uid}")
        uid = user.uid

    # 2. Create 2 Devices for this user
    devices_ref = db.collection(u'devices')
    
    device1 = {
        u'ownerUid': uid,
        u'deviceName': u'Seeded Android Phone',
        u'platform': u'android',
        u'status': u'ACTIVE',
        u'fcmToken': u'fake_token_1',
        u'updatedAt': firestore.SERVER_TIMESTAMP
    }
    devices_ref.document('seeded_device_1').set(device1)
    print("Seeded device 1")

    device2 = {
        u'ownerUid': uid,
        u'deviceName': u'Seeded iPhone',
        u'platform': u'ios',
        u'status': u'LOST', # Start in LOST mode to test tracking immediately
        u'fcmToken': u'fake_token_2',
        u'lastLocation': {
            u'lat': 37.7749,
            u'lng': -122.4194,
            u'accuracy': 10.0,
            u'updatedAt': firestore.SERVER_TIMESTAMP
        },
        u'lostMode': {
            u'enabled': True,
            u'enabledAt': firestore.SERVER_TIMESTAMP
        },
        u'updatedAt': firestore.SERVER_TIMESTAMP
    }
    devices_ref.document('seeded_device_2').set(device2)
    print("Seeded device 2 (LOST mode)")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-id", required=True, help="Firebase Project ID")
    parser.add_argument("--emulator", action="store_true", help="Use local emulators")
    args = parser.parse_args()

    init_firebase(args.project_id, args.emulator)
    db = firestore.client()
    seed_data(db)
