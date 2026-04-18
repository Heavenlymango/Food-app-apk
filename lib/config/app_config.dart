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

  // MobileNet model asset paths
  static const String mobilenetModelPath = 'assets/models/mobilenet_food.tflite';
  static const String mobilenetLabelsPath = 'assets/models/food_labels.txt';

  // Offline model input size
  static const int modelInputSize = 224;
}
