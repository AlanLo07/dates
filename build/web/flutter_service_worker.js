'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "0931492adb41eb742da6bd1f771fe5d3",
"assets/AssetManifest.bin.json": "7f192484c06b0f85936dafd87ee88865",
"assets/assets/alan.jpeg": "d0dff406dc2ebbced987682fe37c454f",
"assets/assets/beso.jpeg": "a85491677705507bd0611b4df87a4a11",
"assets/assets/board-game.png": "8f09d0a66a155954a800c48755f78ea6",
"assets/assets/boda.jpeg": "d4d8db1a47b5356ff4d67a90da248c75",
"assets/assets/cascada.jpeg": "d3f2ba6502d27d734600299020428258",
"assets/assets/chapultepec.png": "598acff46ab6e1340919634a5ec2fd95",
"assets/assets/churros.png": "d4373f217addc215be09f5e3ac0ef442",
"assets/assets/concert.png": "a0f3b9fe6743dda9646225833a288889",
"assets/assets/countries.png": "f7f0dd00d5371a8a1c982b18bca86d27",
"assets/assets/garage-sale.png": "04e9f44ab621fcd6a6a2e78d87ae0998",
"assets/assets/globo.jpeg": "b72262e14d4b438de38a29695469da36",
"assets/assets/ID.jpeg": "ccf801e3ce3f50a92dfb704552b1a205",
"assets/assets/lucha_libre.png": "c4897c13509378333c898b5aeb785018",
"assets/assets/lugarSeguro.jpeg": "daa824f4bd136efeee0bca0296d648c8",
"assets/assets/making-love.png": "85676f9df2c857a7f2bba88fb2477a30",
"assets/assets/massage.png": "881813379ec53b090e71ed805e22a5f6",
"assets/assets/mirror-ball.png": "b85a7868593db72d7310c8ce0bf7709f",
"assets/assets/monterrey.jpeg": "859ec6df96fae61851a123b81654fbdd",
"assets/assets/museum.png": "24d2ea529b3a96a5c2344b99dcc792cb",
"assets/assets/nati.jpeg": "b1d0e031b4a204cdafaa0c5fbfdb9e23",
"assets/assets/novios.jpeg": "ad2c1beefeb76895b47f00c771906b91",
"assets/assets/park.png": "a2248e0192d97fae13efd9ac57c9cfff",
"assets/assets/pirate-ship.png": "20bfd156069782053ce59e2ed98aad9f",
"assets/assets/playa.jpeg": "194a09d79db0c1cb669a1d3cb31f4076",
"assets/assets/skyscrapers.png": "65936e6801ea5253e7c10f66b3faf6b3",
"assets/assets/summer-holidays.png": "649c540a01a5799e1252481f45bd0d03",
"assets/assets/surprise.png": "215c6234ecfdf8ce1e42a4614b34ddf1",
"assets/assets/tepa.jpeg": "dc83fbd058bcbeeed0645ee7b0f085c1",
"assets/assets/viaje.jpeg": "f2b2dc30b9d8278aa52532fe1a0ae652",
"assets/assets/village.png": "a4dcb3899c032b6b8eff106c867401ad",
"assets/assets/waterfall.png": "2e14c43f401bdeeaace6edabdc7b9d03",
"assets/board-game.png": "8f09d0a66a155954a800c48755f78ea6",
"assets/chapultepec.png": "598acff46ab6e1340919634a5ec2fd95",
"assets/churros.png": "d4373f217addc215be09f5e3ac0ef442",
"assets/concert.png": "a0f3b9fe6743dda9646225833a288889",
"assets/countries.png": "f7f0dd00d5371a8a1c982b18bca86d27",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "5c3ad458092f76cc1b2509107faade07",
"assets/making-love.png": "85676f9df2c857a7f2bba88fb2477a30",
"assets/massage.png": "881813379ec53b090e71ed805e22a5f6",
"assets/mirror-ball.png": "b85a7868593db72d7310c8ce0bf7709f",
"assets/museum.png": "24d2ea529b3a96a5c2344b99dcc792cb",
"assets/NOTICES": "8fcbeede16ff7ce7931c2f01fb8830ba",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/park.png": "a2248e0192d97fae13efd9ac57c9cfff",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets/skyscrapers.png": "65936e6801ea5253e7c10f66b3faf6b3",
"assets/summer-holidays.png": "649c540a01a5799e1252481f45bd0d03",
"assets/surprise.png": "215c6234ecfdf8ce1e42a4614b34ddf1",
"assets/village.png": "a4dcb3899c032b6b8eff106c867401ad",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "0c7226d7c9c9a9de35ac06f7ced831d3",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "8e8d8288967e2ab7ae5f2a16aefb6d6f",
"/": "8e8d8288967e2ab7ae5f2a16aefb6d6f",
"main.dart.js": "4ef4586111cef8db941c62f963173588",
"manifest.json": "a9162921438038530b6b70c7167137ea",
"version.json": "63aa9c16c2143a286e62a55564c88662"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
