import firebase_admin
from firebase_admin import credentials, firestore
import json

def serialize_value(val):
    if hasattr(val, 'isoformat'):
        return val.isoformat()
    if isinstance(val, dict):
        return {k: serialize_value(v) for k, v in val.items()}
    if isinstance(val, list):
        return [serialize_value(v) for v in val]
    return val

def main():
    service_account_path = r"c:\Users\jgrullon\Documents\MISARCHIVOS\AppsFlutter\Barberia\barbershop-ee9c0-firebase-adminsdk-fbsvc-653020cef8.json"
    cred = credentials.Certificate(service_account_path)
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    
    collections = ['users', 'services', 'bookings', 'config']
    
    for coll_name in collections:
        print(f"\n==================== COLLECTION: {coll_name} ====================")
        docs = db.collection(coll_name).stream()
        count = 0
        for doc in docs:
            count += 1
            data = serialize_value(doc.to_dict())
            print(f"Document ID: {doc.id}")
            print(json.dumps(data, indent=2, ensure_ascii=False))
            print("-" * 40)
        print(f"Total documents in {coll_name}: {count}")

if __name__ == "__main__":
    main()
