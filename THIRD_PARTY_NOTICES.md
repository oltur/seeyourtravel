# Third-party components

The code of SeeYourTravel is under the [MIT License](LICENSE). It includes or uses the following components, which keep their own licences. The list was compiled by hand from the file headers and package pages; if you find a mistake, please open an issue.

## In the repository (`web/libs`, `web/Bin`, fonts)
| Component | Licence |
|-----------|---------|
| jQuery 1.11.2, jQuery UI 1.11.4, jQuery Cookie 1.4.1, jQuery TinyCarousel | MIT |
| Bootstrap 3.3.4, AngularJS 1.3.14, i18next, Chart.js, toastr, es6-promise, RequireJS | MIT (RequireJS: MIT or BSD-3) |
| Leaflet 1.9.4 | BSD-2-Clause |
| Leaflet.markercluster 1.5.3 | MIT |
| Leaflet Routing Machine | ISC |
| jquery.tour.js 0.0.2 | see the project page github.com/yckart/jquery.tour.js |
| jStorage, json2 | public domain / Unlicense |
| Entity Framework 6.1.3 | Apache-2.0 |
| Newtonsoft.Json 13.0.3 | MIT |
| Facebook C# SDK 7.0.6 | Apache-2.0 |
| Font Awesome 4.1.0 | fonts: SIL OFL 1.1, CSS: MIT |

## Data and services
| What | Terms |
|------|-------|
| Map tiles and map data © OpenStreetMap contributors | ODbL 1.0, attribution is shown on the map |
| Country borders (`web/App_Data/countries50.geojson`) from Natural Earth | public domain |
| Wikipedia / Wikimedia Commons text and photos shown on the map | their authors' licences (CC BY, CC BY-SA, CC0 …), shown with each photo |
| Google Maps, Places, Elevation, Sign-In and "powered by Google" images (`web/img/poweredbygoolge`) | Google's terms of service |
| Mapbox tiles | Mapbox terms of service |
| Google Gemini (assistant) | Google's terms; only the text of the question and the screen context is sent, never photos |

## AI models and Python packages (run in your own containers)
| What | Licence |
|------|---------|
| sentence-transformers, transformers, huggingface_hub | Apache-2.0 |
| PyTorch | BSD-3-Clause |
| CLIP ViT-B/32 and its multilingual text encoder (`clip-ViT-B-32`, `clip-ViT-B-32-multilingual-v1`) | MIT / Apache-2.0 (see the model cards) |
| numpy, scikit-learn, Pillow, opencv-python-headless, onnxruntime | BSD / HPND / Apache-2.0 / MIT |
| InsightFace 0.7.3 (code: MIT) | **The pretrained face models that InsightFace downloads are for non-commercial research use only.** Face recognition is optional (`tools/faces`); check the model licence or replace the model before you use it commercially. |
