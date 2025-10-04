importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "'AIzaSyB9MvGcZmwsb9vIgFt_dDjLUlUVO9H1m5Y",
  authDomain: "vaccinationsystem-d05f7.firebaseapp.com",
  projectId: "vaccinationsystem-d05f7",
  messagingSenderId: "734703459987",
  appId: "1:734703459987:android:f81b7f0cfbad3461db7766",
});

const messaging = firebase.messaging();