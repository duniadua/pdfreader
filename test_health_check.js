const { getFunctions, httpsCallable } = require('firebase/functions');
const { initializeApp } = require('firebase/app');
const { getAnalytics } = require('firebase/analytics');

// Firebase config from your project
const firebaseConfig = {
  apiKey: "AIzaSyD_YOUR_API_KEY", // This won't work for callable test
};

// Alternative: Use Firebase Functions shell for local testing
console.log('📋 To test health check properly, use one of these methods:');
console.log('');
console.log('1. From your Flutter app (recommended):');
console.log('   final result = await FirebaseFunctions.instance.httpsCallable("healthCheck")();');
console.log('');
console.log('2. Using Firebase Functions shell:');
console.log('   cd functions && npm run shell');
console.log('   Then call: healthCheck()');
console.log('');
console.log('3. Check deployment status:');
console.log('   firebase functions:list');
