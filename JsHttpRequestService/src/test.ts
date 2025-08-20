import { HttpRequestService as http } from './main.js';

http.GET("https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json")
    .onProgress(function(this, event) {
        console.log(event.total);
        console.log(event.loaded);
    })
    .send()
    .then(x => {
        console.log(x);
    });