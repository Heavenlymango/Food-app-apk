class AppConfig {
  static const String supabaseUrl = 'https://qavwicfoiccfwfntumjj.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFhdndpY2ZvaWNjZndmbnR1bWpqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMwNDM4NjIsImV4cCI6MjA3ODYxOTg2Mn0.MLJpD4_4ULe08PvX0bw3Iuz8U7y5JzmEUxvOtgN-hbg';
  static const String apiBaseUrl =
      'https://qavwicfoiccfwfntumjj.supabase.co/functions/v1/make-server-36162e30';

  // Food recognition - Roboflow YOLOv8 nano API
  // Set your Roboflow API key here (get one free at roboflow.com)
  static const String roboflowApiKey = 'YOUR_ROBOFLOW_API_KEY';
  static const String roboflowApiUrl =
      'https://detect.roboflow.com/food-detection-51us1/1';

  // MobileNetV3 model
  static const String mobilenetModelPath = 'assets/models/mobilenet_food.tflite';
  static const String mobilenetLabelsPath = 'assets/models/food_labels.txt';
  static const int mobilenetInputSize = 224;

  // YOLOv11-small model (fallback when MobileNet confidence < threshold)
  static const String yoloModelPath = 'assets/models/yolo_small.tflite';
  static const int yoloInputSize = 640;

  // Two-stage confidence threshold: use YOLO if MobileNet is below this
  static const double confidenceThreshold = 0.80;

  // Kept for compatibility
  static const int modelInputSize = mobilenetInputSize;
}
