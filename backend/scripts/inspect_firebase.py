import os
import json
import firebase_admin
from firebase_admin import credentials, db

SERVICE_ACCOUNT = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'agrisense-ed6c9-firebase-adminsdk-fbsvc-8111f401b3.json')
DATABASE_URL = 'https://agrisense-ed6c9-default-rtdb.firebaseio.com/'

def main():
    cred = credentials.Certificate(SERVICE_ACCOUNT)
    app = firebase_admin.initialize_app(cred, {'databaseURL': DATABASE_URL})

    print("Fetching /AgriSense/live...")
    ref = db.reference('/AgriSense/live')
    data = ref.get()
    print("Type of /AgriSense/live:", type(data))
    print("Content:")
    print(json.dumps(data, indent=2))

    # Also check if there are any other nodes under AgriSense
    agri_ref = db.reference('/AgriSense')
    agri_data = agri_ref.get()
    print("All keys under /AgriSense:", list(agri_data.keys()) if isinstance(agri_data, dict) else agri_data)

if __name__ == '__main__':
    main()
