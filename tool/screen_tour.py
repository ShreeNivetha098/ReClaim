"""Screenshot tour of the iOS app for UI review.

Seeds the Firebase emulators with sample users, items and alerts, runs
integration_test/screen_tour_test.dart on an iOS simulator, and saves a
screenshot of each screen. Never touches the live Firebase project.

Usage (from the project root, with a simulator booted):
    firebase emulators:exec --project reclaim-c4695 --only auth,firestore \
        "python3 tool/screen_tour.py <simulator-id> <output-folder>"
"""
import datetime
import json
import os
import re
import subprocess
import sys
import urllib.request

PROJECT = 'reclaim-c4695'
FIRESTORE = f'http://localhost:8080/v1/projects/{PROJECT}/databases/(default)/documents'
AUTH = 'http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake'
PASSWORD = 'Passw0rd!x'  # emulator-only test account


def request(url, data=None, method='POST', headers=None):
    body = json.dumps(data).encode() if data is not None else None
    req = urllib.request.Request(url, data=body, method=method,
                                 headers={'Content-Type': 'application/json', **(headers or {})})
    return json.load(urllib.request.urlopen(req))


def sign_up(email):
    return request(AUTH, {'email': email, 'password': PASSWORD, 'returnSecureToken': True})['localId']


def encode(value):
    if isinstance(value, bool):
        return {'booleanValue': value}
    if isinstance(value, (int, float)):
        return {'doubleValue': value}
    if isinstance(value, datetime.datetime):
        return {'timestampValue': value.strftime('%Y-%m-%dT%H:%M:%SZ')}
    if value is None:
        return {'nullValue': None}
    return {'stringValue': str(value)}


def put(path, fields):
    request(f'{FIRESTORE}/{path}', {'fields': {k: encode(v) for k, v in fields.items()}},
            method='PATCH', headers={'Authorization': 'Bearer owner'})


def seed():
    now = datetime.datetime.now(datetime.timezone.utc)

    def ago(**kw):
        return now - datetime.timedelta(**kw)

    priya, arjun = sign_up('priya@psgtech.ac.in'), sign_up('arjun@psgtech.ac.in')

    def user(uid, name, email, roll, verified):
        return dict(uid=uid, name=name, email=email, phone='9876500000',
                    department='Computer Science & Applications', rollNumber=roll, role='Student',
                    isActive=True, verificationStatus='VERIFIED' if verified else 'NONE',
                    verifiedBy='Dr. Meena' if verified else None,
                    verifiedAt=ago(days=2) if verified else None,
                    createdAt=ago(days=20), updatedAt=ago(days=2))

    put(f'users/{priya}', user(priya, 'Priya Raman', 'priya@psgtech.ac.in', '25MX101', True))
    put(f'users/{arjun}', user(arjun, 'Arjun Kumar', 'arjun@psgtech.ac.in', '25MX117', False))

    def lost(doc, owner, by, name, category, brand, colour, place, when, description):
        put(f'lostItems/{doc}', dict(ownerId=owner, reporterName=by, reporterEmail='', itemName=name,
                                     category=category, description=description, brand=brand,
                                     colour=colour, dateLost=when, locationLost=place,
                                     approximateValue='N/A', imageUrl='', status='ACTIVE',
                                     createdAt=when, updatedAt=when))

    def found(doc, finder, by, name, category, brand, colour, place, when, description):
        put(f'foundItems/{doc}', dict(finderId=finder, reporterName=by, reporterEmail='', itemName=name,
                                      category=category, description=description, brand=brand,
                                      colour=colour, dateFound=when, locationFound=place, imageUrl='',
                                      currentHolder='Security Office', securityOfficeSubmitted=True,
                                      status='ACTIVE', createdAt=when, updatedAt=when))

    lost('l1', priya, 'Priya Raman', 'Black leather wallet', 'Wallet', 'Woodland', 'Black',
         'Central Library', ago(hours=5), 'Black leather wallet with college ID inside')
    lost('l2', arjun, 'Arjun Kumar', 'Casio fx-991EX calculator', 'Calculator', 'Casio', 'Grey',
         'Block B Lab 3', ago(hours=20), 'Scientific calculator, name sticker on back')
    lost('l3', arjun, 'Arjun Kumar', 'AirPods case', 'Electronics', 'Apple', 'White',
         'Canteen', ago(days=2), 'White charging case only')
    found('f1', arjun, 'Arjun Kumar', 'Black wallet', 'Wallet', 'Woodland', 'Black',
          'Central Library', ago(hours=2), 'Leather wallet found near the reading hall')
    found('f2', arjun, 'Arjun Kumar', 'Blue steel bottle', 'Bottle', 'Milton', 'Blue',
          'Gym', ago(hours=8), 'Steel water bottle with stickers')
    found('f3', priya, 'Priya Raman', 'Bike keys with red tag', 'Keys', 'N/A', 'Red',
          'Parking lot', ago(days=1), 'Two keys on a red keychain')
    found('f4', arjun, 'Arjun Kumar', 'Physics textbook', 'Books', 'Pearson', 'Green',
          'Seminar Hall', ago(days=3), 'HC Verma volume 1')

    def alert(doc, kind, title, body, when, read, item_type=None, target=''):
        put(f'notifications/{doc}', dict(userId=priya, recipientId=priya, title=title, body=body,
                                         message=body, type=kind, targetId=target, itemId=target,
                                         itemType=item_type, isRead=read, createdAt=when))

    alert('n1', 'POTENTIAL_MATCH', 'Possible match for your Black leather wallet (88%)',
          'Black wallet was found near Central Library. Tap to check if it is yours.',
          ago(hours=2), False, 'FOUND', 'f1')
    alert('n2', 'COMMON', 'New Lost Item Reported',
          'Grey Casio fx-991EX calculator was reported near Block B Lab 3.', ago(hours=20), False, 'LOST', 'l2')
    alert('n3', 'VERIFICATION_APPROVED', 'Your account is verified',
          'An admin checked your college ID. Your photo has been deleted.', ago(days=2), True)
    alert('n4', 'CLAIM_APPROVED', 'Claim approved: Blue steel bottle',
          'Your ownership was verified. Collect it from the Security Office.', ago(days=4), True, 'FOUND', 'f2')


def main():
    device, out_dir = sys.argv[1], sys.argv[2]
    os.makedirs(out_dir, exist_ok=True)
    seed()
    print('seeded', flush=True)

    proc = subprocess.Popen(
        ['flutter', 'test', 'integration_test/screen_tour_test.dart', '-d', device,
         '--dart-define=USE_FIREBASE_EMULATORS=true', '--dart-define=SCREEN_TOUR=true'],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    log = open(os.path.join(out_dir, 'flutter.log'), 'w')
    for line in proc.stdout:
        log.write(line)
        marker = re.search(r'SHOT:([\w-]+)', line)
        if marker:
            path = os.path.join(out_dir, marker.group(1) + '.png')
            subprocess.run(['xcrun', 'simctl', 'io', device, 'screenshot', path], capture_output=True)
            print('captured', marker.group(1), flush=True)
        elif re.search(r'EXCEPTION|The following|Expected|Some tests|All tests', line):
            print(line.rstrip()[:300], flush=True)
    sys.exit(proc.wait())


if __name__ == '__main__':
    main()
