import argparse
import sys
import firebase_admin
from firebase_admin import credentials, firestore

def main():
    parser = argparse.ArgumentParser(description="Seed/Update a user role in Firestore")
    parser.add_argument("--uid", default="1cr4sy9smlg7rlZONMSNLE5zmdX2", help="The Firebase Auth UID of the user")
    parser.add_argument("--email", default="luisgrullon369@gmail.com", help="Email address of the user")
    parser.add_argument("--name", default="Luis Grullón", help="Display name of the user")
    parser.add_argument("--role", default="barber", choices=["barber", "admin", "client"], help="Role to assign")
    parser.add_argument("--shop-id", default="barberia", help="shopId to assign (required for barber/admin under multi-tenant rules)")

    args = parser.parse_args()
    
    # Path to service account JSON
    service_account_path = r"c:\Users\jgrullon\Documents\MISARCHIVOS\AppsFlutter\Barberia\barbershop-ee9c0-firebase-adminsdk-fbsvc-653020cef8.json"
    
    try:
        cred = credentials.Certificate(service_account_path)
        firebase_admin.initialize_app(cred)
    except Exception as e:
        print(f"Error initializing Firebase Admin SDK: {e}")
        sys.exit(1)
        
    db = firestore.client()
    
    user_ref = db.collection("users").document(args.uid)
    
    # Prepare user data based on role
    user_data = {
        "id": args.uid,
        "name": args.name,
        "email": args.email.lower().strip(),
        "role": args.role,
        "phone": None,
        "phoneNormalized": None,
        "photoUrl": None,
        "isAnonymous": False,
        "createdAt": firestore.SERVER_TIMESTAMP,
    }
    
    if args.role in ("barber", "admin"):
        # shopId es obligatorio para barber/admin bajo las reglas
        # multi-tenant (ver firestore.rules `sameShop`) — sin él,
        # getAvailability/reserveSlot rechazan cualquier fecha con
        # "El servicio no pertenece al negocio de este barbero" porque
        # el shopId del barbero (None) nunca matchea el del servicio.
        user_data["shopId"] = args.shop_id

    if args.role == "barber":
        user_data.update({
            "inviteStatus": "accepted",
            "specialty": "Master Barber",
            "isAvailable": True,
            "workingHours": {str(d): [9, 19] for d in range(1, 7)}, # Mon-Sat 9-19
        })

    print(f"Writing user document to Firestore collection 'users' for UID: {args.uid}...")
    try:
        user_ref.set(user_data, merge=True)
        print("Success! User document written successfully:")
        print(f"  UID: {args.uid}")
        print(f"  Email: {args.email}")
        print(f"  Name: {args.name}")
        print(f"  Role: {args.role}")
    except Exception as e:
        print(f"Error writing to Firestore: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
