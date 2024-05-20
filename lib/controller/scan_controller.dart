import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:tflite/tflite.dart';
import 'package:tensorflow_lite_flutter/tensorflow_lite_flutter.dart';

class ScanController extends GetxController {
  @override
  void onInit() {
    super.onInit();

    initCamera();
    initTfLite();
  }

  @override
  void dispose() {
    super.dispose();
    cameraController.dispose();
  }

  late CameraController cameraController;
  late List<CameraDescription> cameras;

  //late CameraImage cameraImage;
  var isCameraInitialized = false.obs;
  var cameraCount = 0;

  // ignore: prefer_typing_uninitialized_variables
  var x, y, w, h = 0.0;
  var label = "";
  initCamera() async {
    if (await Permission.camera.request().isGranted) {
      cameras = await availableCameras();

      cameraController = CameraController(cameras[1], ResolutionPreset.max);
      await cameraController.initialize().then((value) {
        cameraController.startImageStream((image) {
          cameraCount++;
          if (cameraCount % 10 == 0) {
            cameraCount = 0;
            objectDetector(image);
          }
          update();
        });
      });
      isCameraInitialized(true);
      update();
    } else {
      print("Permission denied");
    }
  }

  initTfLite() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
      isAsset: true,
      numThreads: 1,
      useGpuDelegate: false,
    );
  }

  objectDetector(CameraImage image) async {
    var detector = await Tflite.runModelOnFrame(
      bytesList: image.planes.map((e) {
        return e.bytes;
      }).toList(),
      asynch: true,
      imageHeight: image.height,
      imageWidth: image.width,
      imageMean: 127.5,
      imageStd: 127.5,
      numResults: 1,
      rotation: 90,
      threshold: 0.4,
    );
    if (detector != null) {
      // ignore: non_constant_identifier_names
      var OurDetectedObject = detector.first;
      if (OurDetectedObject['confidenceInClass'] * 100 > 58) {
        label = detector.first['detectedClass'].toString();
        h = OurDetectedObject['rect']['h'];
        w = OurDetectedObject['rect']['w'];
        x = OurDetectedObject['rect']['x'];
        y = OurDetectedObject['rect']['y'];
      }
      update();
    }
  }
}
