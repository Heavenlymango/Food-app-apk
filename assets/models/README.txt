FOOD RECOGNITION MODELS
=======================

OFFLINE MODEL (MobileNet)
--------------------------
File needed: mobilenet_food.tflite

Download a MobileNetV2 model trained on Food-101:
  Option 1 - TensorFlow Hub (recommended):
    https://www.kaggle.com/models/google/mobilenet-v2/tfLite/035-128-classification
    Pick any MobileNetV2 food classification .tflite

  Option 2 - Train your own:
    Use TensorFlow with Food-101 dataset (101 food categories)
    Export as TFLite FP16 quantized for best mobile performance
    Input: [1, 224, 224, 3] float32 normalized to [-1.0, 1.0]
    Output: [1, 101] softmax probabilities

  Option 3 - Use the provided script:
    pip install tensorflow tensorflow-hub
    python download_model.py  (see project root)

Place the downloaded file as: assets/models/mobilenet_food.tflite

ONLINE MODEL (YOLOv8 nano - nanoV3)
-------------------------------------
Uses the Roboflow inference API (no file needed - cloud-based).

Setup:
  1. Create a free account at https://roboflow.com
  2. Use an existing food detection model:
     - Search "food detection" in Roboflow Universe
     - Or upload your own dataset and train YOLOv8n
  3. Get your API key from Roboflow dashboard
  4. Update AppConfig.roboflowApiKey in lib/config/app_config.dart
  5. Update AppConfig.roboflowApiUrl with your model endpoint

Example URL format:
  https://detect.roboflow.com/{workspace}/{model}/{version}
