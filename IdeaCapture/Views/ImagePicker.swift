//
//  ImagePicker.swift
//  IdeaCapture
//
//  图片选择器（相机/相册）和文档扫描
//

import SwiftUI
import PhotosUI
import VisionKit

// MARK: - Image Source Type
enum ImageSourceType {
    case camera
    case photoLibrary
    case documentScanner
}

// MARK: - Camera Picker
struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onImageCaptured: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator

        // 明确设置相机配置，避免设备不支持错误
        picker.cameraCaptureMode = .photo
        picker.cameraDevice = .rear
        picker.showsCameraControls = true
        picker.allowsEditing = false

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            // 先关闭相机UI
            picker.dismiss(animated: true) {
                // 相机完全关闭后，再传递图片数据
                if let image = info[.originalImage] as? UIImage {
                    self.parent.onImageCaptured(image)
                }
                // 最后关闭整个CameraPicker sheet
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.parent.dismiss()
                }
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Photo Library Picker
struct PhotoLibraryPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onImageSelected: (UIImage) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryPicker

        init(_ parent: PhotoLibraryPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()

            guard let result = results.first else { return }

            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self?.parent.onImageSelected(image)
                    }
                }
            }
        }
    }
}

// MARK: - Document Scanner
@available(iOS 13.0, *)
struct DocumentScanner: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onImageScanned: (UIImage) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScanner

        init(_ parent: DocumentScanner) {
            self.parent = parent
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            // 获取第一页扫描的图片
            guard scan.pageCount > 0 else {
                parent.dismiss()
                return
            }

            let image = scan.imageOfPage(at: 0)

            // 先关闭扫描器UI
            controller.dismiss(animated: true) {
                // 完全关闭后再传递图片数据
                self.parent.onImageScanned(image)
                // 延迟关闭整个DocumentScanner sheet
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.parent.dismiss()
                }
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            print("Document scanning failed: \(error.localizedDescription)")
            parent.dismiss()
        }
    }
}

// MARK: - Image Source Picker View
struct ImageSourcePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onImageSelected: (UIImage) -> Void

    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var showDocumentScanner = false

    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    showCamera = true
                }) {
                    Label("拍照", systemImage: "camera")
                }

                Button(action: {
                    showPhotoLibrary = true
                }) {
                    Label("从相册选择", systemImage: "photo.on.rectangle")
                }

                Button(action: {
                    showDocumentScanner = true
                }) {
                    Label("扫描文档", systemImage: "doc.text.viewfinder")
                }
            }
            .navigationTitle("选择图片来源")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker(onImageCaptured: handleImageSelection)
            }
            .sheet(isPresented: $showPhotoLibrary) {
                PhotoLibraryPicker(onImageSelected: handleImageSelection)
            }
            .sheet(isPresented: $showDocumentScanner) {
                DocumentScanner(onImageScanned: handleImageSelection)
            }
        }
    }

    private func handleImageSelection(_ image: UIImage) {
        // 传递图片数据并关闭选择器
        onImageSelected(image)
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    ImageSourcePickerView { image in
        print("Image selected: \(image.size)")
    }
}
