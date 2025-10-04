# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

from firebase_functions import https_fn
from firebase_functions.options import set_global_options
from firebase_admin import initialize_app
import firebase_functions as functions
import firebase_admin
from firebase_admin import firestore, messaging

# For cost control, you can set the maximum number of containers that can be
# running at the same time. This helps mitigate the impact of unexpected
# traffic spikes by instead downgrading performance. This limit is a per-function
# limit. You can override the limit for each function using the max_instances
# parameter in the decorator, e.g. @https_fn.on_request(max_instances=5).
set_global_options(max_instances=10)

firebase_admin.initialize_app()

@functions.firestore.on_document_created(path="chats/{chatId}/messages/{messageId}")
def notify_new_message(event: functions.firestore.Event[firestore.DocumentSnapshot]) -> None:
    snap = event.data
    if not snap.exists:
        return

    data = snap.to_dict()
    sender_id = data.get("senderId")
    text = data.get("text", "")
    chat_id = event.params["chatId"]

    # Fetch chat participants
    chat_ref = firestore.client().collection("chats").document(chat_id)
    chat_doc = chat_ref.get()
    if not chat_doc.exists:
        return

    chat_data = chat_doc.to_dict()
    participants = chat_data.get("participants", [])

    # Exclude sender
    target_uids = [uid for uid in participants if uid != sender_id]

    tokens = []
    for uid in target_uids:
        user_doc = firestore.client().collection("users").document(uid).get()
        if user_doc.exists:
            fcm_token = user_doc.to_dict().get("fcmToken")
            if fcm_token:
                tokens.append(fcm_token)

    if not tokens:
        print("No tokens to notify")
        return

    # Send notification
    message = messaging.MulticastMessage(
        tokens=tokens,
        notification=messaging.Notification(
            title="New Message",
            body=text,
        ),
        data={"chatId": chat_id}
    )

    response = messaging.send_multicast(message)
    print(f"✅ Sent {response.success_count} notifications, {response.failure_count} failed")

# initialize_app()
#
#
# @https_fn.on_request()
# def on_request_example(req: https_fn.Request) -> https_fn.Response:
#     return https_fn.Response("Hello world!")