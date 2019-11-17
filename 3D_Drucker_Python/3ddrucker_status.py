
import requests
import time


global flagcheck
flagcheck = True
def check_status():
    resp = requests.get('http://192.168.0.104/api/job', headers={'X-Api-Key': 'ABA6A5E42A044CC596F1AA46C611A58F'})

    val_parsed = resp.json()

    current_state = val_parsed["state"]

    if current_state == "Online":
        flagcheck = False

    print(val_parsed)
    return val_parsed

value = check_status()

if(value["state"] == "Offline"):
    while(flagcheck):
        time.sleep(2)
        print("3D Drucker is Offline")
        check_status()
